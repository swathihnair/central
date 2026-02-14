"""
Script to extract text from existing PDF files and update database
"""
from database import SessionLocal
from sql_models import Report, Vital
import PyPDF2
import os
from google import genai
from dotenv import load_dotenv

load_dotenv()

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
        if not api_key or not pdf_text:
            return None
        
        client = genai.Client(api_key=api_key)
        
        prompt = f"""Analyze this medical report and extract ONLY the following vital signs. Return ONLY numbers, no units or text.

Medical Report Text:
{pdf_text[:3000]}

Extract these values (return 0 if not found):
1. Blood Pressure Systolic (top number, e.g., 120 from 120/80)
2. Blood Pressure Diastolic (bottom number, e.g., 80 from 120/80)
3. Blood Sugar/Glucose Level (in mg/dL)
4. Cholesterol Level (total cholesterol in mg/dL)

Return ONLY in this exact format (numbers only, one per line):
[systolic]
[diastolic]
[sugar]
[cholesterol]

Example:
130
85
110
200"""

        response = client.models.generate_content(
            model='gemini-2.5-flash',
            contents=prompt
        )
        
        # Parse response
        lines = response.text.strip().split('\n')
        if len(lines) >= 4:
            try:
                systolic = int(lines[0].strip())
                diastolic = int(lines[1].strip())
                sugar = int(lines[2].strip())
                cholesterol = int(lines[3].strip())
                
                # Validate ranges
                if 80 <= systolic <= 200 and 50 <= diastolic <= 120:
                    if 50 <= sugar <= 300 and 100 <= cholesterol <= 400:
                        return {
                            'bp_systolic': systolic,
                            'bp_diastolic': diastolic,
                            'sugar_level': sugar,
                            'cholesterol': cholesterol
                        }
            except:
                pass
        
        return None
    except Exception as e:
        print(f"Error extracting vitals with AI: {e}")
        return None

def main():
    db = SessionLocal()
    
    print("=" * 60)
    print("EXTRACTING TEXT FROM EXISTING PDFs")
    print("=" * 60)
    
    # Get all reports without pdf_text
    reports = db.query(Report).filter(
        (Report.pdf_text == None) | (Report.pdf_text == "")
    ).all()
    
    print(f"\nFound {len(reports)} reports without PDF text")
    
    for report in reports:
        print(f"\n📄 Processing Report ID {report.id}: {report.title}")
        print(f"   File: {report.file_url}")
        
        if not os.path.exists(report.file_url):
            print(f"   ❌ File not found!")
            continue
        
        # Extract text
        pdf_text = extract_text_from_pdf(report.file_url)
        if pdf_text:
            print(f"   ✅ Extracted {len(pdf_text)} characters")
            report.pdf_text = pdf_text
            
            # Try to extract vitals with AI
            extracted_vitals = extract_vitals_from_pdf_text(pdf_text)
            if extracted_vitals:
                print(f"   ✅ AI extracted vitals: {extracted_vitals}")
                
                # Update existing vitals
                vital = db.query(Vital).filter(Vital.report_id == report.id).first()
                if vital:
                    vital.bp_systolic = extracted_vitals['bp_systolic']
                    vital.bp_diastolic = extracted_vitals['bp_diastolic']
                    vital.sugar_level = extracted_vitals['sugar_level']
                    vital.cholesterol = extracted_vitals['cholesterol']
                    print(f"   ✅ Updated vitals in database")
            else:
                print(f"   ⚠️  Could not extract vitals with AI (keeping existing values)")
        else:
            print(f"   ❌ Could not extract text")
    
    db.commit()
    print("\n" + "=" * 60)
    print("✅ DONE! All PDFs processed")
    print("=" * 60)
    db.close()

if __name__ == "__main__":
    main()
