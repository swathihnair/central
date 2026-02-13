from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)

    @classmethod
    def __get_pydantic_json_schema__(cls, field_schema):
        field_schema.update(type="string")

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
    role: Optional[str] = None

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: str  # 'admin', 'doctor', 'patient'
    phone: Optional[str] = None
    age: Optional[int] = None  # For patients
    specialization: Optional[str] = None  # For doctors

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: str = Field(alias="_id")
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}

class LoginRequest(BaseModel):
    email: str
    password: str
    role: str

class VitalStats(BaseModel):
    bp_systolic: int
    bp_diastolic: int
    sugar_level: int
    cholesterol: int
    recorded_at: datetime = Field(default_factory=datetime.now)

class Report(BaseModel):
    id: Optional[str] = Field(alias="_id", default=None)
    patient_id: str
    patient_name: Optional[str] = None
    title: str
    department: str
    file_url: Optional[str] = None
    extracted_vitals: Optional[VitalStats] = None
    uploaded_by: str  # admin id
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}

class Appointment(BaseModel):
    id: Optional[str] = Field(alias="_id", default=None)
    patient_id: str
    doctor_id: str
    doctor_name: Optional[str] = None
    patient_name: Optional[str] = None
    date_time: datetime
    status: str = "pending"  # pending, approved, rejected, completed
    notes: Optional[str] = None
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}

class HealthTip(BaseModel):
    id: Optional[str] = Field(alias="_id", default=None)
    title: str
    content: str
    created_at: datetime = Field(default_factory=datetime.now)

    class Config:
        populate_by_name = True
        json_encoders = {ObjectId: str}
