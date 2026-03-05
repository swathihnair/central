from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from models import Appointment
import sql_models
from database import get_db
from routers.auth import get_current_user
from datetime import datetime, timedelta
from typing import List

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
            "doctor_approved": apt.doctor_approved,
            "admin_approved": apt.admin_approved,
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
            "doctor_approved": apt.doctor_approved,
            "admin_approved": apt.admin_approved,
            "notes": apt.notes,
            "created_at": apt.created_at.isoformat()
        })
    
    return result

@router.put("/{appointment_id}/approve")
def approve_appointment(
    appointment_id: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    appointment = db.query(sql_models.Appointment).filter(
        sql_models.Appointment.id == int(appointment_id)
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Get doctor and admin info
    doctor = db.query(sql_models.User).filter(sql_models.User.id == appointment.doctor_id).first()
    
    # Doctor approval
    if current_user.role == "doctor" and current_user.id == appointment.doctor_id:
        appointment.doctor_approved = "approved"
        # If doctor approves, appointment is approved immediately
        appointment.status = "approved"
    # Admin approval - must be from same hospital as doctor
    elif current_user.role == "admin":
        if current_user.hospital_name and doctor.hospital_name:
            if current_user.hospital_name.lower().strip() == doctor.hospital_name.lower().strip():
                appointment.admin_approved = "approved"
                # If admin approves, appointment is approved immediately
                appointment.status = "approved"
            else:
                raise HTTPException(
                    status_code=403, 
                    detail=f"Admin can only approve appointments for doctors in their hospital ({current_user.hospital_name})"
                )
        else:
            # Fallback if hospital names not set
            appointment.admin_approved = "approved"
            appointment.status = "approved"
    else:
        raise HTTPException(status_code=403, detail="Not authorized to approve this appointment")
    
    db.commit()
    
    return {
        "message": "Appointment approved",
        "doctor_approved": appointment.doctor_approved,
        "admin_approved": appointment.admin_approved,
        "status": appointment.status
    }

@router.put("/{appointment_id}/reject")
def reject_appointment(
    appointment_id: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    appointment = db.query(sql_models.Appointment).filter(
        sql_models.Appointment.id == int(appointment_id)
    ).first()
    
    if not appointment:
        raise HTTPException(status_code=404, detail="Appointment not found")
    
    # Get doctor info
    doctor = db.query(sql_models.User).filter(sql_models.User.id == appointment.doctor_id).first()
    
    # Doctor rejection
    if current_user.role == "doctor" and current_user.id == appointment.doctor_id:
        appointment.doctor_approved = "rejected"
    # Admin rejection - must be from same hospital as doctor
    elif current_user.role == "admin":
        if current_user.hospital_name and doctor.hospital_name:
            if current_user.hospital_name.lower().strip() == doctor.hospital_name.lower().strip():
                appointment.admin_approved = "rejected"
            else:
                raise HTTPException(
                    status_code=403, 
                    detail=f"Admin can only reject appointments for doctors in their hospital ({current_user.hospital_name})"
                )
        else:
            # Fallback if hospital names not set
            appointment.admin_approved = "rejected"
    else:
        raise HTTPException(status_code=403, detail="Not authorized to reject this appointment")
    
    # If either rejects, appointment is rejected
    if appointment.doctor_approved == "rejected" or appointment.admin_approved == "rejected":
        appointment.status = "rejected"
    
    db.commit()
    
    return {
        "message": "Appointment rejected",
        "doctor_approved": appointment.doctor_approved,
        "admin_approved": appointment.admin_approved,
        "status": appointment.status
    }

@router.get("/all")
def get_all_appointments(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Get all appointments
    appointments = db.query(sql_models.Appointment).order_by(sql_models.Appointment.date_time.desc()).all()
    
    result = []
    for apt in appointments:
        doctor = db.query(sql_models.User).filter(sql_models.User.id == apt.doctor_id).first()
        patient = db.query(sql_models.User).filter(sql_models.User.id == apt.patient_id).first()
        
        # Filter by hospital - only show appointments for doctors in admin's hospital
        if current_user.hospital_name and doctor and doctor.hospital_name:
            if current_user.hospital_name.lower().strip() != doctor.hospital_name.lower().strip():
                continue  # Skip appointments from other hospitals
        
        result.append({
            "id": str(apt.id),
            "patient_id": str(apt.patient_id),
            "doctor_id": str(apt.doctor_id),
            "patient_name": patient.full_name if patient else "",
            "doctor_name": doctor.full_name if doctor else "",
            "doctor_hospital": doctor.hospital_name if doctor else "",
            "date_time": apt.date_time.isoformat(),
            "status": apt.status,
            "doctor_approved": apt.doctor_approved,
            "admin_approved": apt.admin_approved,
            "notes": apt.notes,
            "created_at": apt.created_at.isoformat()
        })
    
    return result

@router.get("/available-slots/{doctor_id}/{date}")
def get_available_slots(
    doctor_id: str,
    date: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """
    Get available time slots for a doctor on a specific date.
    Each appointment slot is 30 minutes.
    Working hours: 9:00 AM to 5:00 PM
    """
    try:
        # Parse the date
        target_date = datetime.fromisoformat(date.replace('Z', '+00:00'))
        
        # Get all appointments for this doctor on this date
        start_of_day = target_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_of_day = target_date.replace(hour=23, minute=59, second=59, microsecond=999999)
        
        booked_appointments = db.query(sql_models.Appointment).filter(
            sql_models.Appointment.doctor_id == int(doctor_id),
            sql_models.Appointment.date_time >= start_of_day,
            sql_models.Appointment.date_time <= end_of_day,
            sql_models.Appointment.status != "rejected"  # Don't count rejected appointments
        ).all()
        
        # Create list of booked time slots (each appointment blocks 30 minutes)
        booked_slots = set()
        for apt in booked_appointments:
            # Block the appointment time slot
            slot_time = apt.date_time.replace(second=0, microsecond=0)
            booked_slots.add(slot_time.strftime("%H:%M"))
        
        # Generate all possible time slots (9 AM to 5 PM, 30-minute intervals)
        available_slots = []
        current_time = target_date.replace(hour=9, minute=0, second=0, microsecond=0)
        end_time = target_date.replace(hour=17, minute=0, second=0, microsecond=0)
        
        while current_time <= end_time:
            time_str = current_time.strftime("%H:%M")
            
            # Check if this slot is available
            if time_str not in booked_slots:
                # If it's today, only show future slots
                now = datetime.now()
                if target_date.date() == now.date():
                    if current_time.time() > now.time():
                        available_slots.append({
                            "time": time_str,
                            "display": current_time.strftime("%I:%M %p"),
                            "datetime": current_time.isoformat()
                        })
                else:
                    available_slots.append({
                        "time": time_str,
                        "display": current_time.strftime("%I:%M %p"),
                        "datetime": current_time.isoformat()
                    })
            
            # Move to next 30-minute slot
            current_time += timedelta(minutes=30)
        
        return {
            "date": date,
            "doctor_id": doctor_id,
            "available_slots": available_slots,
            "booked_count": len(booked_slots)
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error fetching available slots: {str(e)}")
