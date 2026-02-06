from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from models import Appointment
import sql_models
from database import get_db
from routers.auth import get_current_user
from datetime import datetime

router = APIRouter()

@router.post("/create")
def create_appointment(appointment: Appointment, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    # Get patient and doctor
    patient = db.query(sql_models.User).filter(sql_models.User.id == int(appointment.patient_id)).first()
    doctor = db.query(sql_models.User).filter(sql_models.User.id == int(appointment.doctor_id)).first()
    
    if not patient or not doctor:
        raise HTTPException(status_code=404, detail="Patient or Doctor not found")
    
    db_appointment = sql_models.Appointment(
        patient_id=int(appointment.patient_id),
        doctor_id=int(appointment.doctor_id),
        date_time=appointment.date_time,
        status=appointment.status,
        notes=appointment.notes
    )
    
    db.add(db_appointment)
    db.commit()
    db.refresh(db_appointment)
    
    return {"message": "Appointment created", "appointment_id": db_appointment.id}

@router.get("/patient/{patient_id}")
def get_patient_appointments(patient_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    appointments = db.query(sql_models.Appointment).filter(
        sql_models.Appointment.patient_id == int(patient_id)
    ).order_by(sql_models.Appointment.date_time.desc()).all()
    
    result = []
    for apt in appointments:
        doctor = db.query(sql_models.User).filter(sql_models.User.id == apt.doctor_id).first()
        patient = db.query(sql_models.User).filter(sql_models.User.id == apt.patient_id).first()
        result.append({
            "id": str(apt.id),
            "patient_id": str(apt.patient_id),
            "doctor_id": str(apt.doctor_id),
            "patient_name": patient.full_name if patient else "",
            "doctor_name": doctor.full_name if doctor else "",
            "date_time": apt.date_time.isoformat(),
            "status": apt.status,
            "notes": apt.notes,
            "created_at": apt.created_at.isoformat()
        })
    
    return result

@router.get("/doctor/{doctor_id}")
def get_doctor_appointments(doctor_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    appointments = db.query(sql_models.Appointment).filter(
        sql_models.Appointment.doctor_id == int(doctor_id)
    ).order_by(sql_models.Appointment.date_time.desc()).all()
    
    result = []
    for apt in appointments:
        doctor = db.query(sql_models.User).filter(sql_models.User.id == apt.doctor_id).first()
        patient = db.query(sql_models.User).filter(sql_models.User.id == apt.patient_id).first()
        result.append({
            "id": str(apt.id),
            "patient_id": str(apt.patient_id),
            "doctor_id": str(apt.doctor_id),
            "patient_name": patient.full_name if patient else "",
            "doctor_name": doctor.full_name if doctor else "",
            "date_time": apt.date_time.isoformat(),
            "status": apt.status,
            "notes": apt.notes,
            "created_at": apt.created_at.isoformat()
        })
    
    return result

@router.put("/{appointment_id}/status")
def update_appointment_status(
    appointment_id: str, 
    status: str, 
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    if status not in ["pending", "approved", "rejected", "completed"]:
        raise HTTPException(status_code=400, detail="Invalid status")
    
    appointment = db.query(sql_models.Appointment).filter(
        sql_models.Appointment.id == int(appointment_id)
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    appointment.status = status
    db.commit()
    
    return {"message": "Appointment status updated"}

@router.get("/all")
def get_all_appointments(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    appointments = db.query(sql_models.Appointment).order_by(sql_models.Appointment.date_time.desc()).all()
    
    result = []
    for apt in appointments:
        doctor = db.query(sql_models.User).filter(sql_models.User.id == apt.doctor_id).first()
        patient = db.query(sql_models.User).filter(sql_models.User.id == apt.patient_id).first()
        result.append({
            "id": str(apt.id),
            "patient_id": str(apt.patient_id),
            "doctor_id": str(apt.doctor_id),
            "patient_name": patient.full_name if patient else "",
            "doctor_name": doctor.full_name if doctor else "",
            "date_time": apt.date_time.isoformat(),
            "status": apt.status,
            "notes": apt.notes,
            "created_at": apt.created_at.isoformat()
        })
    
    return result
