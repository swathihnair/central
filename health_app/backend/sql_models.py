from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base
from datetime import datetime

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    full_name = Column(String(255), nullable=False)
    role = Column(String(50), nullable=False)  # admin, doctor, patient
    hashed_password = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    specialization = Column(String(255), nullable=True)  # For doctors
    created_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    appointments_as_patient = relationship("Appointment", foreign_keys="Appointment.patient_id", back_populates="patient")
    appointments_as_doctor = relationship("Appointment", foreign_keys="Appointment.doctor_id", back_populates="doctor")
    reports = relationship("Report", back_populates="patient")

class Appointment(Base):
    __tablename__ = "appointments"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    doctor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    date_time = Column(DateTime, nullable=False)
    status = Column(String(50), default="pending")  # pending, approved, rejected, completed
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    patient = relationship("User", foreign_keys=[patient_id], back_populates="appointments_as_patient")
    doctor = relationship("User", foreign_keys=[doctor_id], back_populates="appointments_as_doctor")

class Report(Base):
    __tablename__ = "reports"
    
    id = Column(Integer, primary_key=True, index=True)
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    title = Column(String(255), nullable=False)
    department = Column(String(100), nullable=False)
    file_url = Column(String(500), nullable=True)
    uploaded_by = Column(Integer, nullable=False)  # admin user id
    created_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    patient = relationship("User", back_populates="reports")
    vitals = relationship("Vital", back_populates="report", cascade="all, delete-orphan")

class Vital(Base):
    __tablename__ = "vitals"
    
    id = Column(Integer, primary_key=True, index=True)
    report_id = Column(Integer, ForeignKey("reports.id"), nullable=False)
    patient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    bp_systolic = Column(Integer, nullable=False)
    bp_diastolic = Column(Integer, nullable=False)
    sugar_level = Column(Integer, nullable=False)
    cholesterol = Column(Integer, nullable=False)
    recorded_at = Column(DateTime, default=datetime.now)
    
    # Relationships
    report = relationship("Report", back_populates="vitals")
