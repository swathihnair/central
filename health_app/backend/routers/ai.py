from fastapi import APIRouter, HTTPException, Depends
from google import genai
import os
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
import sql_models
import PyPDF2

router = APIRouter()

class ChatRequest(BaseModel):
    message: str
    history: list = []
    patient_id: int = None

def extract_text_from_pdf(file_path):
    """Extract text content from PDF file in uploads folder"""
    try:
        if not os.path.exists(file_path):
            print(f"PDF file not found: {file_path}")
            return None
            
        with open(file_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            text = ""
            for page in pdf_reader.pages:
                text += page.extract_text() + "\n"
            return text
    except Exception as e:
        print(f"Error extracting PDF text: {e}")
        return None

@router.post("/chat")
async def chat_with_doctor_ai(request: ChatRequest, db: Session = Depends(get_db)):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {
            "response": "I'm sorry, but my brain (API Key) is missing. Please contact the administrator to set up the Gemini API Key."
        }
    
    try:
        client = genai.Client(api_key=api_key)
        
        # System prompt for medical assistant with RAG - STRICT PDF ONLY
        system_prompt = """You are a helpful and empathetic AI medical assistant with access to patient's medical reports.

CRITICAL INSTRUCTIONS - READ CAREFULLY:
1. You can ONLY use information from the PDF content provided below
2. DO NOT use any external knowledge or assumptions
3. DO NOT make up or infer values that are not explicitly in the PDF
4. If information is not in the PDF, clearly state "This information is not available in your medical reports"
5. ONLY reference specific values, findings, and text that appear in the PDF content
6. Quote directly from the PDF when providing analysis
7. If asked about something not in the PDF, politely explain you can only analyze what's in the uploaded reports

When analyzing the PDF content:
- Read the PDF text carefully and extract relevant information
- Assess if values are normal, borderline, or concerning based on reference ranges IN THE PDF
- Provide health recommendations based ONLY on what you find in the PDF
- Reference specific sections, values, and findings from the PDF
- Always remind to consult healthcare professionals for proper diagnosis

You are not a replacement for a real doctor, but you help patients understand their medical reports better by analyzing ONLY what is written in their PDF files."""
        
        # Check if user is asking about their reports/test results
        report_keywords = [
            'report', 'test result', 'analysis', 'analyze', 'my results', 
            'vitals', 'blood pressure', 'sugar', 'cholesterol', 'blood test',
            'my blood', 'my test', 'check my', 'what does', 'explain',
            'my report', 'pdf', 'document', 'findings', 'diagnosis'
        ]
        asking_about_reports = any(keyword in request.message.lower() for keyword in report_keywords)
        
        # Fetch patient's medical data if patient_id is provided
        medical_context = ""
        if request.patient_id:
            try:
                # Get patient info
                patient = db.query(sql_models.User).filter(
                    sql_models.User.id == request.patient_id
                ).first()
                
                # Get recent reports - ONLY PDF FILES (no database vitals)
                recent_reports = db.query(sql_models.Report).filter(
                    sql_models.Report.patient_id == request.patient_id
                ).order_by(sql_models.Report.created_at.desc()).limit(5).all()
                
                if recent_reports:
                    medical_context = f"\n\n{'='*80}\n"
                    medical_context += f"PATIENT MEDICAL DATA (ONLY FROM PDF FILES)\n"
                    medical_context += f"{'='*80}\n"
                    
                    if patient:
                        medical_context += f"\nPatient: {patient.full_name}\n"
                        if patient.age:
                            medical_context += f"Age: {patient.age} years\n"
                    
                    # Add reports with FULL PDF CONTENT ONLY
                    medical_context += f"\n\n📄 MEDICAL REPORTS (PDF CONTENT ONLY):\n"
                    medical_context += "=" * 80 + "\n"
                    
                    for idx, report in enumerate(recent_reports, 1):
                        medical_context += f"\n{'─'*80}\n"
                        medical_context += f"REPORT #{idx}: {report.title}\n"
                        medical_context += f"{'─'*80}\n"
                        medical_context += f"Department: {report.department}\n"
                        medical_context += f"Date: {report.created_at.strftime('%Y-%m-%d')}\n"
                        
                        # READ PDF DIRECTLY FROM UPLOADS FOLDER - THIS IS THE ONLY SOURCE
                        if report.file_url and os.path.exists(report.file_url):
                            print(f"🔍 RAG: Reading PDF from file: {report.file_url}")
                            pdf_text = extract_text_from_pdf(report.file_url)
                            
                            if pdf_text:
                                print(f"✅ RAG: Extracted {len(pdf_text)} characters from PDF file")
                                medical_context += f"\n📄 FULL PDF CONTENT (Read from: {os.path.basename(report.file_url)}):\n"
                                medical_context += "┌" + "─" * 78 + "┐\n"
                                # Include ALL content from PDF (up to 10000 chars per report for better analysis)
                                pdf_content = pdf_text[:10000]
                                # Format the PDF text nicely
                                for line in pdf_content.split('\n'):
                                    if line.strip():
                                        medical_context += f"│ {line[:76]:<76} │\n"
                                medical_context += "└" + "─" * 78 + "┘\n"
                                
                                if len(pdf_text) > 10000:
                                    remaining = len(pdf_text) - 10000
                                    medical_context += f"\n[Note: PDF has {remaining} more characters of content]\n"
                            else:
                                print(f"❌ RAG: Could not extract text from PDF file")
                                medical_context += f"\n⚠️  Could not extract text from PDF file\n"
                        else:
                            print(f"❌ RAG: PDF file not found: {report.file_url}")
                            medical_context += f"\n⚠️  PDF file not found in uploads folder: {report.file_url}\n"
                    
                    medical_context += f"\n{'='*80}\n"
                    medical_context += "END OF MEDICAL DATA\n"
                    medical_context += f"{'='*80}\n\n"
                    
                    medical_context += "🤖 AI INSTRUCTIONS:\n"
                    medical_context += "- The above data is ONLY from PDF files in uploads folder\n"
                    medical_context += "- DO NOT use any other data source\n"
                    medical_context += "- DO NOT make up or assume any values\n"
                    medical_context += "- ONLY analyze what is written in the PDF content above\n"
                    medical_context += "- If information is not in the PDF, say you don't have that information\n"
                    medical_context += "- Reference specific findings from the PDF content\n"
                    medical_context += "- Provide detailed analysis based ONLY on PDF content\n\n"
                else:
                    medical_context = f"\n\n{'='*80}\n"
                    medical_context += "NO MEDICAL DATA AVAILABLE\n"
                    medical_context += f"{'='*80}\n"
                    medical_context += "\nThe patient doesn't have any medical reports uploaded yet.\n\n"
                    medical_context += "Please inform them:\n"
                    medical_context += "1. Ask their doctor/admin to upload medical reports (PDF files)\n"
                    medical_context += "2. Go to 'Reports' section to view uploaded reports\n"
                    medical_context += "3. Once uploaded, I can analyze them automatically\n"
                    medical_context += f"{'='*80}\n\n"
            except Exception as e:
                print(f"Error fetching medical data: {e}")
                medical_context = f"\n\n⚠️  Error retrieving medical data: {str(e)}\n\n"
        
        # Create the full prompt with RAG context
        full_prompt = f"{system_prompt}\n{medical_context}\nPatient Question: {request.message}\n\nYour Response:"
        
        # Print the full prompt being sent to AI
        print("\n" + "="*80)
        print("📤 SENDING TO AI")
        print("="*80)
        print(f"Patient ID: {request.patient_id}")
        print(f"Question: {request.message}")
        print(f"Prompt Length: {len(full_prompt)} characters")
        print("-"*80)
        print("Full Prompt Preview (first 1000 chars):")
        print(full_prompt[:1000])
        print("..." if len(full_prompt) > 1000 else "")
        print("="*80 + "\n")
        
        # Use Gemini 2.5 Flash (new API)
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=full_prompt
        )
        
        # Print AI output to console
        print("\n" + "="*80)
        print("🤖 AI RESPONSE OUTPUT")
        print("="*80)
        print(f"Patient ID: {request.patient_id}")
        print(f"Question: {request.message}")
        print("-"*80)
        print(f"AI Response:\n{response.text}")
        print("="*80 + "\n")
        
        return {"response": response.text}
            
    except Exception as e:
        print(f"Gemini Error: {e}")
        error_msg = str(e)
        
        # Provide helpful error messages
        if "API_KEY" in error_msg.upper():
            return {
                "response": "⚠️  API Key issue detected. Please contact the administrator to verify the Gemini API Key configuration."
            }
        elif "QUOTA" in error_msg.upper() or "RATE" in error_msg.upper():
            return {
                "response": "⚠️  API quota exceeded. Please try again in a few moments or contact the administrator."
            }
        else:
            return {
                "response": f"I'm here to help with health questions! However, I'm experiencing a technical issue: {error_msg}\n\nPlease try again or consult with a healthcare professional for medical advice."
            }

@router.post("/patient-summary")
async def generate_patient_summary(request: ChatRequest, db: Session = Depends(get_db)):
    """
    Generate comprehensive AI summary of patient's medical history from all PDF reports
    For doctor dashboard use
    """
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {
            "summary": "API Key not configured",
            "critical_findings": [],
            "allergies": "Unknown",
            "medications": "Unknown"
        }
    
    try:
        client = genai.Client(api_key=api_key)
        
        # Get patient info
        patient = db.query(sql_models.User).filter(
            sql_models.User.id == request.patient_id
        ).first()
        
        if not patient:
            return {"error": "Patient not found"}
        
        # Get ALL patient reports
        all_reports = db.query(sql_models.Report).filter(
            sql_models.Report.patient_id == request.patient_id
        ).order_by(sql_models.Report.created_at.desc()).all()
        
        # Build comprehensive medical context from ALL PDFs
        medical_data = f"Patient: {patient.full_name}\nAge: {patient.age} years\n\n"
        medical_data += "="*80 + "\n"
        medical_data += "ALL MEDICAL REPORTS:\n"
        medical_data += "="*80 + "\n\n"
        
        for idx, report in enumerate(all_reports, 1):
            medical_data += f"Report #{idx}: {report.title} ({report.created_at.strftime('%Y-%m-%d')})\n"
            medical_data += f"Department: {report.department}\n"
            
            if report.file_url and os.path.exists(report.file_url):
                pdf_text = extract_text_from_pdf(report.file_url)
                if pdf_text:
                    medical_data += f"Content:\n{pdf_text[:5000]}\n"
            medical_data += "\n" + "-"*80 + "\n\n"
        
        # AI prompt for comprehensive summary
        prompt = f"""You are a medical AI assistant helping a doctor review a patient's complete medical history.

{medical_data}

Please provide a comprehensive medical summary in the following format:

1. PATIENT OVERVIEW:
   - Key demographics and basic info

2. MEDICAL HISTORY TIMELINE:
   - Chronological summary of all reports and findings
   - When conditions started
   - Progression over time

3. CRITICAL FINDINGS:
   - Any abnormal values or concerning results
   - Urgent issues that need attention

4. ALLERGIES:
   - List any allergies mentioned in reports
   - If none found, state "No allergies documented"

5. MEDICATIONS:
   - List any medications mentioned
   - If none found, state "No medications documented"

6. RECOMMENDATIONS:
   - Suggested follow-up actions
   - Areas needing further investigation

Be thorough but concise. Focus on clinically relevant information."""
        
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        
        return {"summary": response.text}
            
    except Exception as e:
        print(f"Error generating patient summary: {e}")
        return {
            "summary": f"Error generating summary: {str(e)}",
            "critical_findings": [],
            "allergies": "Unknown",
            "medications": "Unknown"
        }
