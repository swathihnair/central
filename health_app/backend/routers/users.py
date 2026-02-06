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
    doctors = db.query(sql_models.User).filter(sql_models.User.role == "doctor").all()
    
    result = []
    for doctor in doctors:
        result.append({
            "id": str(doctor.id),
            "email": doctor.email,
            "full_name": doctor.full_name,
            "role": doctor.role,
            "specialization": doctor.specialization,
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
