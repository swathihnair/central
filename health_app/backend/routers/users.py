from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
import sql_models
from database import get_db
from routers.auth import get_current_user

router = APIRouter()

@router.get("/patients")
def get_all_patients(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    patients = db.query(sql_models.User).filter(sql_models.User.role == "patient").all()
    
    result = []
    for patient in patients:
        result.append({
            "id": str(patient.id),
            "email": patient.email,
            "full_name": patient.full_name,
            "role": patient.role,
            "phone": patient.phone,
            "created_at": patient.created_at.isoformat()
        })
    
    return result

@router.get("/doctors")
def get_all_doctors(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    # If admin, only show doctors from their hospital
    if current_user.role == "admin":
        if not current_user.hospital_name:
            raise HTTPException(status_code=400, detail="Admin has no hospital assigned")
        
        doctors = db.query(sql_models.User).filter(
            sql_models.User.role == "doctor",
            sql_models.User.hospital_name == current_user.hospital_name
        ).all()
    else:
        # For other roles, show all doctors
        doctors = db.query(sql_models.User).filter(sql_models.User.role == "doctor").all()
    
    result = []
    for doctor in doctors:
        result.append({
            "id": str(doctor.id),
            "email": doctor.email,
            "full_name": doctor.full_name,
            "role": doctor.role,
            "specialization": doctor.specialization,
            "hospital_name": doctor.hospital_name,
            "created_at": doctor.created_at.isoformat()
        })
    
    return result

@router.get("/{user_id}")
def get_user(user_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    user = db.query(sql_models.User).filter(sql_models.User.id == int(user_id)).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    return {
        "id": str(user.id),
        "email": user.email,
        "full_name": user.full_name,
        "role": user.role,
        "phone": user.phone,
        "specialization": user.specialization,
        "created_at": user.created_at.isoformat()
    }

@router.get("/hospital/statistics")
def get_hospital_statistics(db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    """Get statistics for the admin's hospital"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    if not current_user.hospital_name:
        raise HTTPException(status_code=400, detail="Admin has no hospital assigned")
    
    # Count doctors in this hospital
    doctors_count = db.query(sql_models.User).filter(
        sql_models.User.role == "doctor",
        sql_models.User.hospital_name == current_user.hospital_name
    ).count()
    
    # Count total patients (all patients can visit any hospital)
    patients_count = db.query(sql_models.User).filter(
        sql_models.User.role == "patient"
    ).count()
    
    # Count pending appointments for this hospital's doctors
    pending_appointments = db.query(sql_models.Appointment).join(
        sql_models.User, sql_models.Appointment.doctor_id == sql_models.User.id
    ).filter(
        sql_models.User.hospital_name == current_user.hospital_name,
        sql_models.Appointment.status == "pending"
    ).count()
    
    # Count total appointments for this hospital's doctors
    total_appointments = db.query(sql_models.Appointment).join(
        sql_models.User, sql_models.Appointment.doctor_id == sql_models.User.id
    ).filter(
        sql_models.User.hospital_name == current_user.hospital_name
    ).count()
    
    return {
        "hospital_name": current_user.hospital_name,
        "doctors_count": doctors_count,
        "patients_count": patients_count,
        "pending_appointments": pending_appointments,
        "total_appointments": total_appointments
    }

@router.delete("/{user_id}")
def delete_user(user_id: str, db: Session = Depends(get_db), current_user: sql_models.User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    user = db.query(sql_models.User).filter(sql_models.User.id == int(user_id)).first()
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    db.delete(user)
    db.commit()
    
    return {"message": "User deleted successfully"}
