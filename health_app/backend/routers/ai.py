
from fastapi import APIRouter, HTTPException, Depends
import google.generativeai as genai
import os
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
import sql_models

router = APIRouter()

class ChatRequest(BaseModel):
    message: str
    history: list = []
    patient_id: int = None

@router.post("/chat")
async def chat_with_doctor_ai(request: ChatRequest, db: Session = Depends(get_db)):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {
            "response": "I'm sorry, but my brain (API Key) is missing. Please contact the administrator to set up the Gemini API Key."
        }
    
    try:
        client = genai.Client(api_key=api_key)
        
        # System prompt for medical assistant
        system_prompt = """You are a helpful and empathetic AI medical assistant. 

When provided with patient test results (blood pressure, sugar levels, cholesterol, etc.), you SHOULD analyze them and provide:
1. Assessment of whether values are normal, borderline, or concerning
2. Health recommendations based on the results
3. Lifestyle advice if needed
4. Reminder to consult with a healthcare professional for proper diagnosis

You answer health-related questions concisely and clearly. You are not a replacement for a real doctor, but you can help patients understand their test results better."""
        
        # Check if user is asking about their reports/test results
        report_keywords = ['report', 'test result', 'analysis', 'analyze', 'my results', 'vitals', 'blood pressure', 'sugar', 'cholesterol', 'blood test', 'my blood', 'my test', 'check my']
        asking_about_reports = any(keyword in request.message.lower() for keyword in report_keywords)
        
        # Fetch patient's recent vitals and reports if they're asking about reports OR if patient_id is provided
        vitals_context = ""
        if request.patient_id and asking_about_reports:
            try:
                # Get most recent vitals
                recent_vitals = db.query(sql_models.Vital).filter(
                    sql_models.Vital.patient_id == request.patient_id
                ).order_by(sql_models.Vital.recorded_at.desc()).first()
                
                # Get recent reports WITH PDF TEXT
                recent_reports = db.query(sql_models.Report).filter(
                    sql_models.Report.patient_id == request.patient_id
                ).order_by(sql_models.Report.created_at.desc()).limit(3).all()
                
                if recent_vitals or recent_reports:
                    vitals_context = f"\n\n=== PATIENT'S MEDICAL DATA (AUTOMATICALLY FETCHED FROM DATABASE) ===\n"
                    
                    # Add vitals data
                    if recent_vitals:
                        vitals_context += f"\nMost Recent Test Results (from {recent_vitals.recorded_at.strftime('%Y-%m-%d')}):\n"
                        vitals_context += f"- Blood Pressure: {recent_vitals.bp_systolic}/{recent_vitals.bp_diastolic} mmHg\n"
                        vitals_context += f"- Blood Sugar Level: {recent_vitals.sugar_level} mg/dL\n"
                        vitals_context += f"- Cholesterol: {recent_vitals.cholesterol} mg/dL\n"
                    
                    # Add reports information WITH PDF CONTENT
                    if recent_reports:
                        vitals_context += f"\n📄 Recent Medical Reports:\n"
                        for idx, report in enumerate(recent_reports, 1):
                            vitals_context += f"\n{idx}. {report.title} - {report.department} Department\n"
                            vitals_context += f"   Uploaded: {report.created_at.strftime('%Y-%m-%d')}\n"
                            
                            # Get vitals associated with this report
                            report_vitals = db.query(sql_models.Vital).filter(
                                sql_models.Vital.report_id == report.id
                            ).first()
                            
                            if report_vitals:
                                vitals_context += f"   - BP: {report_vitals.bp_systolic}/{report_vitals.bp_diastolic} mmHg\n"
                                vitals_context += f"   - Sugar: {report_vitals.sugar_level} mg/dL\n"
                                vitals_context += f"   - Cholesterol: {report_vitals.cholesterol} mg/dL\n"
                            
                            # ADD PDF TEXT CONTENT FOR RAG
                            if report.pdf_text:
                                # Limit to first 2000 characters to avoid token limits
                                pdf_excerpt = report.pdf_text[:2000]
                                vitals_context += f"\n   📄 PDF Content:\n   {pdf_excerpt}\n"
                                if len(report.pdf_text) > 2000:
                                    vitals_context += f"   ... (PDF has more content)\n"
                    
                    vitals_context += "\n=== END OF MEDICAL DATA ===\n\n"
                    vitals_context += "IMPORTANT: I have automatically fetched the patient's actual medical data above, including PDF content. DO NOT ask them to provide values. Analyze the data I provided (including PDF text) and give a detailed assessment with recommendations based on what's written in the reports."
                else:
                    vitals_context = "\n\n=== NO MEDICAL DATA FOUND ===\n"
                    vitals_context += "The patient does not have any test results or reports uploaded in the system yet.\n"
                    vitals_context += "Please inform them that they need to:\n"
                    vitals_context += "1. Ask their doctor or admin to upload their medical reports (PDF files)\n"
                    vitals_context += "2. Go to the 'Reports' section to view uploaded reports\n"
                    vitals_context += "3. Once reports are uploaded, I can analyze them automatically.\n"
                    vitals_context += "=== END ===\n"
            except Exception as e:
                print(f"Error fetching medical data: {e}")
        
        # Create the full prompt
        full_prompt = f"{system_prompt}\n\nUser: {request.message}{vitals_context}\n\nProvide a helpful, concise response:"
        
        # Try Gemini 2.5 and fallback models
        model_names = ['gemini-2.5-flash', 'gemini-1.5-flash', 'gemini-1.5-pro']
        
        response_text = None
        for model_name in model_names:
            try:
                response = client.models.generate_content(
                    model=model_name,
                    contents=full_prompt
                )
                response_text = response.text
                print(f"Successfully used model: {model_name}")
                break
            except Exception as model_error:
                print(f"Model {model_name} failed: {model_error}")
                continue
        
        if response_text:
            return {"response": response_text}
        else:
            raise Exception("All models failed")
            
    except Exception as e:
        print(f"Gemini Error: {e}")
        # Return a helpful fallback response
        return {
            "response": "I'm here to help with health questions! However, I'm having a technical issue right now. Please try asking your question again, or consult with a healthcare professional for medical advice."
        }
