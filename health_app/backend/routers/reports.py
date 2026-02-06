from fastapi import APIRouter, File, UploadFile, HTTPException, Depends, Form
from sqlalchemy.orm import Session
from models import VitalStats
import sql_models
from database import get_db
from routers.auth import get_current_user
from datetime import datetime
import random
import os

router = APIRouter()

# Create uploads directory if it doesn't exist
UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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
    
    # Create report
    db_report = sql_models.Report(
        patient_id=int(patient_id),
        title=title,
        department=department,
        file_url=file_path,
        uploaded_by=current_user.id
    )
    
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    
    # Mock vital extraction (in production, use OCR)
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
    
    return {"message": "Report uploaded successfully", "report_id": db_report.id}

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
    vitals = db.query(sql_models.Vital).filter(
        sql_models.Vital.patient_id == int(patient_id)
    ).order_by(sql_models.Vital.recorded_at.desc()).limit(10).all()
    
    result = []
    for vital in vitals:
        result.append({
            "id": str(vital.id),
            "report_id": str(vital.report_id),
            "patient_id": str(vital.patient_id),
            "bp_systolic": vital.bp_systolic,
            "bp_diastolic": vital.bp_diastolic,
            "sugar_level": vital.sugar_level,
            "cholesterol": vital.cholesterol,
            "recorded_at": vital.recorded_at.isoformat()
        })
    
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
