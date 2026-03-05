from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from database import get_db
import sql_models
from pydantic import BaseModel
from typing import List
from datetime import datetime, timedelta

router = APIRouter()

class AvailabilitySlot(BaseModel):
    day_of_week: str
    start_time: str
    end_time: str
    is_available: bool = True

class AvailabilityResponse(BaseModel):
    id: int
    day_of_week: str
    start_time: str
    end_time: str
    is_available: bool

@router.post("/doctor/{doctor_id}/availability")
async def set_doctor_availability(
    doctor_id: int,
    slots: List[AvailabilitySlot],
    db: Session = Depends(get_db)
):
    """Set or update doctor's availability schedule"""
    try:
        # Delete existing availability for this doctor
        db.query(sql_models.DoctorAvailability).filter(
            sql_models.DoctorAvailability.doctor_id == doctor_id
        ).delete()
        
        # Add new availability slots
        for slot in slots:
            availability = sql_models.DoctorAvailability(
                doctor_id=doctor_id,
                day_of_week=slot.day_of_week,
                start_time=slot.start_time,
                end_time=slot.end_time,
                is_available=1 if slot.is_available else 0
            )
            db.add(availability)
        
        db.commit()
        return {"message": "Availability updated successfully"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/doctor/{doctor_id}/availability")
async def get_doctor_availability(
    doctor_id: int,
    db: Session = Depends(get_db)
):
    """Get doctor's availability schedule"""
    availability = db.query(sql_models.DoctorAvailability).filter(
        sql_models.DoctorAvailability.doctor_id == doctor_id,
        sql_models.DoctorAvailability.is_available == 1
    ).all()
    
    return [
        {
            "id": slot.id,
            "day_of_week": slot.day_of_week,
            "start_time": slot.start_time,
            "end_time": slot.end_time,
            "is_available": bool(slot.is_available)
        }
        for slot in availability
    ]

@router.get("/doctor/{doctor_id}/available-slots/{date}")
async def get_available_time_slots(
    doctor_id: int,
    date: str,  # Format: YYYY-MM-DD
    db: Session = Depends(get_db)
):
    """Get available time slots for a specific date based on doctor's availability"""
    try:
        # Parse the date
        target_date = datetime.strptime(date, "%Y-%m-%d")
        day_name = target_date.strftime("%A")  # Get day name (Monday, Tuesday, etc.)
        
        # Get doctor's availability for this day
        availability = db.query(sql_models.DoctorAvailability).filter(
            sql_models.DoctorAvailability.doctor_id == doctor_id,
            sql_models.DoctorAvailability.day_of_week == day_name,
            sql_models.DoctorAvailability.is_available == 1
        ).all()
        
        if not availability:
            return {"available_slots": [], "message": "Doctor not available on this day"}
        
        # Get existing appointments for this doctor on this date
        existing_appointments = db.query(sql_models.Appointment).filter(
            sql_models.Appointment.doctor_id == doctor_id,
            sql_models.Appointment.date_time >= target_date,
            sql_models.Appointment.date_time < target_date + timedelta(days=1),
            sql_models.Appointment.status.in_(["pending", "approved"])
        ).all()
        
        booked_times = {appt.date_time.strftime("%H:%M") for appt in existing_appointments}
        
        # Generate time slots based on availability
        all_slots = []
        for slot in availability:
            start_hour, start_min = map(int, slot.start_time.split(":"))
            end_hour, end_min = map(int, slot.end_time.split(":"))
            
            current_time = datetime.strptime(slot.start_time, "%H:%M")
            end_time = datetime.strptime(slot.end_time, "%H:%M")
            
            while current_time < end_time:
                time_str = current_time.strftime("%H:%M")
                all_slots.append({
                    "time": time_str,
                    "available": time_str not in booked_times
                })
                current_time += timedelta(minutes=30)  # 30-minute slots
        
        return {
            "date": date,
            "day_of_week": day_name,
            "available_slots": all_slots
        }
        
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.delete("/doctor/{doctor_id}/availability/{slot_id}")
async def delete_availability_slot(
    doctor_id: int,
    slot_id: int,
    db: Session = Depends(get_db)
):
    """Delete a specific availability slot"""
    slot = db.query(sql_models.DoctorAvailability).filter(
        sql_models.DoctorAvailability.id == slot_id,
        sql_models.DoctorAvailability.doctor_id == doctor_id
    ).first()
    
    if not slot:
        raise HTTPException(status_code=404, detail="Availability slot not found")
    
    db.delete(slot)
    db.commit()
    return {"message": "Availability slot deleted successfully"}
