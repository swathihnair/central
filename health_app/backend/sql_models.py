"""
PostgreSQL/Supabase Compatible SQL Models
"""
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # admin, doctor, patient
    hashed_password = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    age = Column(Integer, nullable=True)  # Patient age
    specialization = Column(String(255), nullable=True)  # For doctors
    hospital_name = Column(String(255), nullable=True)  # For doctors and admins
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    appointments_as_patient = relationship("Appointment", foreign_keys="Appointment.patient_id", back_populates="patient")
    appointments_as_doctor = relationship("Appointment", foreign_keys="Appointment.doctor_id", back_populates="doctor")
    reports = relationship("Report", back_populates="patient")

class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date_time = Column(DateTime, nullable=False)
    status = Column(String(50), default="pending")  # pending, approved, rejected, completed
    doctor_approved = Column(String(50), default="pending")  # pending, approved, rejected
    admin_approved = Column(String(50), default="pending")  # pending, approved, rejected
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    patient = relationship("User", foreign_keys=[patient_id], back_populates="appointments_as_patient")
    doctor = relationship("User", foreign_keys=[doctor_id], back_populates="appointments_as_doctor")

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), nullable=False)
    department = Column(String(100), nullable=False)
    file_url = Column(String(500), nullable=True)
    pdf_text = Column(Text, nullable=True)  # Store extracted PDF text for RAG
    uploaded_by = Column(Integer, nullable=False)  # admin user id
    hospital_name = Column(String(255), nullable=True)  # Hospital name from admin
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    patient = relationship("User", back_populates="reports")
    vitals = relationship("Vital", back_populates="report", cascade="all, delete-orphan")

class Vital(Base):
    __tablename__ = "vitals"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    report_id = Column(Integer, ForeignKey("reports.id", ondelete="CASCADE"), nullable=False)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    bp_systolic = Column(Integer, nullable=False)
    bp_diastolic = Column(Integer, nullable=False)
    sugar_level = Column(Integer, nullable=False)
    cholesterol = Column(Integer, nullable=False)
    recorded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    report = relationship("Report", back_populates="vitals")

class RFIDCard(Base):
    __tablename__ = "rfid_cards"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    card_uid = Column(String(255), unique=True, index=True, nullable=False)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    assigned_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)  # PostgreSQL Boolean instead of Integer
    created_at = Column(DateTime, default=datetime.utcnow)

class DoctorAvailability(Base):
    __tablename__ = "doctor_availability"
    
    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    doctor_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    day_of_week = Column(String(20), nullable=False)  # Monday, Tuesday, etc.
    start_time = Column(String(10), nullable=False)  # HH:MM format (e.g., "09:00")
    end_time = Column(String(10), nullable=False)  # HH:MM format (e.g., "17:00")
    is_available = Column(Boolean, default=True)  # PostgreSQL Boolean
    created_at = Column(DateTime, default=datetime.utcnow)
