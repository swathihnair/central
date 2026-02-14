from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
import sql_models
from routers.auth import get_current_user
from pydantic import BaseModel

router = APIRouter()

class RFIDCardAssign(BaseModel):
    card_uid: str
    patient_id: int

class RFIDCardScan(BaseModel):
    card_uid: str

@router.post("/assign")
async def assign_rfid_card(
    card_data: RFIDCardAssign,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Assign an RFID card to a patient (Admin only)"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Check if patient exists
    patient = db.query(sql_models.User).filter(
        sql_models.User.id == card_data.patient_id,
        sql_models.User.role == "patient"
    ).first()
    
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    # Check if card is already assigned
    existing_card = db.query(sql_models.RFIDCard).filter(
        sql_models.RFIDCard.card_uid == card_data.card_uid
    ).first()
    
    if existing_card:
        # Update existing card assignment
        existing_card.patient_id = card_data.patient_id
        existing_card.is_active = 1
    else:
        # Create new card assignment
        new_card = sql_models.RFIDCard(
            card_uid=card_data.card_uid,
            patient_id=card_data.patient_id
        )
        db.add(new_card)
    
    db.commit()
    
    return {
        "message": "RFID card assigned successfully",
        "card_uid": card_data.card_uid,
        "patient_id": card_data.patient_id,
        "patient_name": patient.full_name
    }

@router.post("/scan")
async def scan_rfid_card(
    scan_data: RFIDCardScan,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Scan an RFID card and return patient information"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    # Find the card
    card = db.query(sql_models.RFIDCard).filter(
        sql_models.RFIDCard.card_uid == scan_data.card_uid,
        sql_models.RFIDCard.is_active == 1
    ).first()
    
    if not card:
        raise HTTPException(status_code=404, detail="RFID card not registered or inactive")
    
    # Get patient details
    patient = db.query(sql_models.User).filter(
        sql_models.User.id == card.patient_id
    ).first()
    
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    
    return {
        "patient_id": patient.id,
        "full_name": patient.full_name,
        "email": patient.email,
        "phone": patient.phone,
        "age": patient.age
    }

@router.get("/patient/{patient_id}")
async def get_patient_rfid(
    patient_id: int,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Get RFID card assigned to a patient"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    card = db.query(sql_models.RFIDCard).filter(
        sql_models.RFIDCard.patient_id == patient_id,
        sql_models.RFIDCard.is_active == 1
    ).first()
    
    if not card:
        return {"card_uid": None, "message": "No RFID card assigned"}
    
    return {
        "card_uid": card.card_uid,
        "assigned_at": card.assigned_at.isoformat()
    }

@router.delete("/unassign/{card_uid}")
async def unassign_rfid_card(
    card_uid: str,
    db: Session = Depends(get_db),
    current_user: sql_models.User = Depends(get_current_user)
):
    """Deactivate an RFID card"""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    
    card = db.query(sql_models.RFIDCard).filter(
        sql_models.RFIDCard.card_uid == card_uid
    ).first()
    
    if not card:
        raise HTTPException(status_code=404, detail="RFID card not found")
    
    card.is_active = 0
    db.commit()
    
    return {"message": "RFID card deactivated successfully"}
