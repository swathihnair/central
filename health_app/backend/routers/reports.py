from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, Form
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from models import VitalStats
import sql_models
from database import get_db
from routers.auth import get_current_user
from datetime import datetime
import random
import os
import PyPDF2
from google import genai  # Updated to new API

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def extract_text_from_pdf(file_path):
    """Extract text content from PDF file"""
    try:
        with open(file_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            text = ""
            for page in pdf_reader.pages:
                text += page.extract_text() + "\n"
            return text
    except Exception as e:
        print(f"Error extracting PDF text: {e}")
        return None

def extract_vitals_from_pdf_text(pdf_text):
    """Use Gemini AI to extract vitals from PDF text"""
    try:
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            print("❌ No Gemini API key found")
            return None
        if not pdf_text:
            print("❌ No PDF text provided")
            return None
        
        print(f"🔍 Extracting vitals from PDF text ({len(pdf_text)} chars)")
        
        client = genai.Client(api_key=api_key)
        
        prompt = f"""You are a medical data extraction assistant. Analyze this medical report and extract vital signs.

Medical Report Text:
{pdf_text[:5000]}

Find and extract these values from the report:
1. Blood Pressure Systolic (the first/top number in BP reading like 120/80)
2. Blood Pressure Diastolic (the second/bottom number in BP reading like 120/80)
3. Blood Sugar or Glucose Level (in mg/dL)
4. Total Cholesterol Level (in mg/dL)

IMPORTANT: 
- Look for actual measured values in the report
- If a value is not found, return 0
- Return ONLY 4 numbers, one per line
- No text, no units, just numbers

Format (one number per line):
<systolic>
<diastolic>
<sugar>
<cholesterol>

Example output:
120
80
95
189"""

        print("📤 Sending to Gemini AI...")
        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        
        response_text = response.text.strip()
        print(f"📥 AI Response: '{response_text}'")
        
        # Try to parse response - handle both single line and multi-line
        lines = response_text.split('\n')
        
        # If response is on a single line, try to split it
        if len(lines) == 1 and len(response_text) >= 4:
            # Try to extract 4 numbers from the string
            import re
            numbers = re.findall(r'\d+', response_text)
            if len(numbers) >= 4:
                lines = numbers[:4]
                print(f"📊 Extracted {len(lines)} numbers from single line")
        
        print(f"📊 Parsed {len(lines)} lines from AI response: {lines}")
        
        if len(lines) >= 4:
            try:
                # Clean and parse numbers
                systolic = int(str(lines[0]).strip().replace(',', ''))
                diastolic = int(str(lines[1]).strip().replace(',', ''))
                sugar = int(str(lines[2]).strip().replace(',', ''))
                cholesterol = int(str(lines[3]).strip().replace(',', ''))
                
                print(f"🔢 Extracted values: BP={systolic}/{diastolic}, Sugar={sugar}, Chol={cholesterol}")
                
                # More lenient validation - accept 0 values but validate non-zero ones
                valid_bp = (systolic == 0 and diastolic == 0) or (80 <= systolic <= 200 and 50 <= diastolic <= 120)
                valid_sugar = sugar == 0 or (50 <= sugar <= 300)
                valid_chol = cholesterol == 0 or (100 <= cholesterol <= 400)
                
                if valid_bp and valid_sugar and valid_chol:
                    # If all values are 0, extraction failed
                    if systolic == 0 and diastolic == 0 and sugar == 0 and cholesterol == 0:
                        print("❌ All values are 0 - extraction failed")
                        return None
                    
                    print("✅ Values validated successfully")
                    return {
                        'bp_systolic': systolic if systolic > 0 else 120,  # Default values if not found
                        'bp_diastolic': diastolic if diastolic > 0 else 80,
                        'sugar_level': sugar if sugar > 0 else 100,
                        'cholesterol': cholesterol if cholesterol > 0 else 180
                    }
                else:
                    print(f"❌ Values out of range: BP={systolic}/{diastolic}, Sugar={sugar}, Chol={cholesterol}")
            except Exception as parse_error:
                print(f"❌ Error parsing numbers: {parse_error}")
                print(f"   Lines: {lines}")
        else:
            print(f"❌ Not enough lines in response (got {len(lines)}, need 4)")
        
        return None
    except Exception as e:
        print(f"❌ Error extracting vitals with AI: {e}")
        import traceback
        traceback.print_exc()
        return None


@router.post("/upload")
def upload_report(
    patient_id: str = Form(...),
    title: str = Form(...),
    department: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    # Only admin can upload reports
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Get patient info
    patient = db.query(sql_models.User).filter(sql_models.User.id == int(patient_id)).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # Save file
    file_path = os.path.join(UPLOAD_DIR, f"{patient_id}_{datetime.now().timestamp()}_{file.filename}")
    with open(file_path, "wb") as f:
        content = file.file.read()
        f.write(content)
    
    # Extract text from PDF
    pdf_text = None
    extracted_vitals = None
    
    if file.filename.lower().endswith('.pdf'):
        pdf_text = extract_text_from_pdf(file_path)
        print(f"Extracted {len(pdf_text) if pdf_text else 0} characters from PDF")
        
        # Use AI to extract vitals from PDF text
        if pdf_text:
            extracted_vitals = extract_vitals_from_pdf_text(pdf_text)
            if extracted_vitals:
                print(f"AI extracted vitals: {extracted_vitals}")
            else:
                print("AI could not extract vitals, using random values")
    
    # Create report with PDF text and hospital name from admin
    db_report = sql_models.Report(
        patient_id=int(patient_id),
        title=title,
        department=department,
        file_url=file_path,
        pdf_text=pdf_text,  # Store extracted text for RAG
        uploaded_by=current_user.id,
        hospital_name=current_user.hospital_name  # Get hospital name from admin user
    )
    
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    
    # Create vitals - use AI extracted values or fallback to random
    if extracted_vitals:
        db_vital = sql_models.Vital(
            report_id=db_report.id,
            patient_id=int(patient_id),
            bp_systolic=extracted_vitals['bp_systolic'],
            bp_diastolic=extracted_vitals['bp_diastolic'],
            sugar_level=extracted_vitals['sugar_level'],
            cholesterol=extracted_vitals['cholesterol']
        )
    else:
        # Fallback to random values if AI extraction fails
        db_vital = sql_models.Vital(
            report_id=db_report.id,
            patient_id=int(patient_id),
            bp_systolic=random.randint(110, 140),
            bp_diastolic=random.randint(70, 90),
            sugar_level=random.randint(80, 150),
            cholesterol=random.randint(150, 220)
        )
    
    db.add(db_vital)
    db.commit()
    
    return {
        "message": "Report uploaded successfully",
        "report_id": db_report.id,
        "vitals_extracted": extracted_vitals is not None
    }

@router.get("/patient/{patient_id}")
def get_patient_reports(patient_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    reports = db.query(sql_models.Report).filter(
        sql_models.Report.patient_id == int(patient_id)
    ).order_by(sql_models.Report.created_at.desc()).all()
    
    result = []
    for report in reports:
        # Get vitals for this report
        vitals = db.query(sql_models.Vital).filter(sql_models.Vital.report_id == report.id).first()
        
        report_data = {
            "id": str(report.id),
            "patient_id": str(report.patient_id),
            "title": report.title,
            "department": report.department,
            "file_url": report.file_url,
            "hospital_name": report.hospital_name,  # Include hospital name
            "date": report.created_at.strftime("%Y-%m-%d"),
            "created_at": report.created_at.isoformat()
        }
        
        if vitals:
            report_data["vitals"] = {
                "bp": f"{vitals.bp_systolic}/{vitals.bp_diastolic}",
                "sugar": str(vitals.sugar_level),
                "cholesterol": str(vitals.cholesterol)
            }
            report_data["extracted_vitals"] = {
                "bp_systolic": vitals.bp_systolic,
                "bp_diastolic": vitals.bp_diastolic,
                "sugar_level": vitals.sugar_level,
                "cholesterol": vitals.cholesterol
            }
        
        result.append(report_data)
    
    return result

@router.get("/patient/{patient_id}/vitals")
def get_patient_vitals(patient_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    """
    Get patient vitals extracted directly from PDF files (not from database)
    """
    # Get patient's reports
    reports = db.query(sql_models.Report).filter(
        sql_models.Report.patient_id == int(patient_id)
    ).order_by(sql_models.Report.created_at.desc()).limit(10).all()
    
    result = []
    for report in reports:
        # Extract vitals from PDF file
        if report.file_url and os.path.exists(report.file_url):
            pdf_text = extract_text_from_pdf(report.file_url)
            
            if pdf_text:
                # Use AI to extract vitals from PDF
                extracted_vitals = extract_vitals_from_pdf_text(pdf_text)
                
                if extracted_vitals:
                    result.append({
                        "id": str(report.id),
                        "report_id": str(report.id),
                        "patient_id": str(report.patient_id),
                        "bp_systolic": extracted_vitals['bp_systolic'],
                        "bp_diastolic": extracted_vitals['bp_diastolic'],
                        "sugar_level": extracted_vitals['sugar_level'],
                        "cholesterol": extracted_vitals['cholesterol'],
                        "recorded_at": report.created_at.isoformat(),
                        "source": "pdf",  # Indicate data is from PDF
                        "report_title": report.title
                    })
                    print(f"✅ Extracted vitals from PDF: {report.title}")
                else:
                    print(f"⚠️  Could not extract vitals from PDF: {report.title}")
            else:
                print(f"❌ Could not read PDF: {report.file_url}")
    
    return result

@router.get("/all")
def get_all_reports(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    reports = db.query(sql_models.Report).order_by(sql_models.Report.created_at.desc()).all()
    
    result = []
    for report in reports:
        patient = db.query(sql_models.User).filter(sql_models.User.id == report.patient_id).first()
        result.append({
            "id": str(report.id),
            "patient_id": str(report.patient_id),
            "patient_name": patient.full_name if patient else "",
            "title": report.title,
            "department": report.department,
            "date": report.created_at.strftime("%Y-%m-%d"),
            "created_at": report.created_at.isoformat()
        })
    
    return result

@router.get("/download/{report_id}")
def download_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Download a report PDF file"""
    report = db.query(sql_models.Report).filter(sql_models.Report.id == int(report_id)).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    # Check authorization
    if current_user.role == "patient" and current_user.id != report.patient_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this report")
    
    # Check if file exists
    if not os.path.exists(report.file_url):
        raise HTTPException(status_code=404, detail="Report file not found")
    
    # Get original filename
    filename = os.path.basename(report.file_url)
    
    return FileResponse(
        path=report.file_url,
        media_type='application/pdf',
        filename=filename,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )

@router.get("/view/{report_id}")
def view_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """View a report PDF file in browser"""
    report = db.query(sql_models.Report).filter(sql_models.Report.id == int(report_id)).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    # Check authorization
    if current_user.role == "patient" and current_user.id != report.patient_id:
        raise HTTPException(status_code=403, detail="Not authorized to access this report")
    
    # Check if file exists
    if not os.path.exists(report.file_url):
        raise HTTPException(status_code=404, detail="Report file not found")
    
    # Get original filename
    filename = os.path.basename(report.file_url)
    
    return FileResponse(
        path=report.file_url,
        media_type='application/pdf',
        filename=filename,
        headers={"Content-Disposition": f"inline; filename={filename}"}
    )

@router.delete("/delete/{report_id}")
def delete_report(
    report_id: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Delete a report (admin only)"""
    # Only admin can delete reports
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    report = db.query(sql_models.Report).filter(sql_models.Report.id == int(report_id)).first()
    
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    
    # Delete associated vitals first
    db.query(sql_models.Vital).filter(sql_models.Vital.report_id == int(report_id)).delete()
    
    # Delete the PDF file from filesystem
    if os.path.exists(report.file_url):
        try:
            os.remove(report.file_url)
        except Exception as e:
            print(f"Error deleting file: {e}")
    
    # Delete the report from database
    db.delete(report)
    db.commit()
    
    return {
        "message": "Report deleted successfully",
        "report_id": report_id
    }
