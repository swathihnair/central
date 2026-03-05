# Health App System Documentation

## Overview
A comprehensive healthcare management system with patient records, appointment booking, RFID authentication, and AI-powered medical report analysis.

## System Architecture

### Backend (FastAPI + Python)
- **Framework**: FastAPI
- **Database**: Supabase PostgreSQL
- **AI**: Google Gemini 2.5 Flash
- **Authentication**: JWT tokens with bcrypt password hashing
- **File Storage**: Local filesystem (uploads/)

### Frontend (Flutter)
- **Framework**: Flutter Web
- **State Management**: StatefulWidget
- **Charts**: fl_chart package
- **HTTP Client**: http package

## Database Configuration

**Connection String:**
```
postgresql://postgres:ed333#yhithe@db.ohvzatnkgxniswnpmtfx.supabase.co:5432/postgres
```

**Project:** ohvzatnkgxniswnpmtfx

## User Roles & Credentials

### Medical Center Hospital

**Admin:**
- Email: admin@health.com
- Password: admin123

**Doctors:**
- doctor@health.com / doctor123
- manu@gmail.com / manu123
- karthik@gmail.com / karthik123
- johnadams@gmail.com / john123

### Welcare Hospital

**Admin:**
- Email: admin.welcare@health.com
- Password: welcare123

**Doctors:**
- dr.sarah@welcare.com / sarah123 (Pediatrician)
- dr.michael@welcare.com / michael123 (Orthopedic Surgeon)

### Patients

- patient@health.com / patient123 (John Doe - has 3 reports)
- swathi.h.2005@gmail.com / swathi123 (Swathi H - has RFID card)
- arun@gmail.com / arun123 (Arun Sivaram Pillai)
- ziyan@gmail.com / ziyan123 (Mohammed Ziyan)
- doe@gmail.com / (Jane Doe - has 3 reports, phone: 9567186162)

## Key Features

### 1. Patient Dashboard
- Health vitals comparison graphs (BP, Sugar, Cholesterol)
- Normal range vs patient value visualization
- Appointment booking
- Medical reports access
- AI-powered health insights

### 2. Doctor Dashboard
- Patient list with search
- Appointment management with approval workflow
- Patient medical history and reports
- AI medical summary from PDF reports
- Availability schedule management

### 3. Admin Dashboard
- Hospital-specific statistics
- Patient and doctor management
- Report upload with AI vitals extraction
- RFID card management
- Appointment oversight

### 4. RFID Authentication
- Arduino-based RFID reader integration
- WebSocket real-time communication
- Patient quick login via RFID card
- Card registration and management

### 5. AI Features
- Automatic vitals extraction from PDF reports
- Medical summary generation
- RAG (Retrieval Augmented Generation) for report analysis
- Natural language health insights

## Appointment Workflow

1. Patient books appointment with doctor
2. Either doctor OR admin can approve (single approval system)
3. Once approved, appointment status changes to "approved"
4. Hospital validation ensures admin can only approve for their hospital's doctors

## Running the System

### Backend
```bash
cd health_app/backend
python -m uvicorn main:app --reload --port 8000
```

### Frontend
```bash
cd health_app/frontend
flutter run -d chrome
```

### RFID System (Optional)
```bash
cd health_app/backend
python rfid_websocket_bridge.py
```

Upload Arduino sketch: `arduino_keyboard_rfid.ino`

## API Endpoints

### Authentication
- POST `/api/auth/login` - User login
- POST `/api/auth/signup` - User registration
- GET `/api/auth/me` - Get current user

### Users
- GET `/api/users/doctors` - List doctors (filtered by hospital for admins)
- GET `/api/users/patients` - List patients
- GET `/api/users/hospital/statistics` - Hospital statistics (admin only)

### Appointments
- POST `/api/appointments/book` - Book appointment
- GET `/api/appointments/patient/{id}` - Patient appointments
- GET `/api/appointments/doctor/{id}` - Doctor appointments
- PUT `/api/appointments/{id}/approve-doctor` - Doctor approval
- PUT `/api/appointments/{id}/approve-admin` - Admin approval

### Reports
- POST `/api/reports/upload` - Upload report (admin only)
- GET `/api/reports/patient/{id}` - Get patient reports
- GET `/api/reports/patient/{id}/vitals` - Get patient vitals
- GET `/api/reports/download/{id}` - Download report PDF
- GET `/api/reports/view/{id}` - View report PDF
- DELETE `/api/reports/delete/{id}` - Delete report (admin only)

### RFID
- POST `/api/rfid/register` - Register RFID card
- POST `/api/rfid/login` - Login with RFID
- GET `/api/rfid/cards` - List all cards

### AI
- POST `/api/ai/chat` - Chat with AI about medical reports

## Database Schema

### users
- id, email, full_name, role, hashed_password
- phone, age, specialization, hospital_name
- created_at

### appointments
- id, patient_id, doctor_id, date_time
- status, doctor_approved, admin_approved
- notes, created_at

### reports
- id, patient_id, title, department
- file_url, pdf_text, uploaded_by
- hospital_name, created_at

### vitals
- id, report_id, patient_id
- bp_systolic, bp_diastolic
- sugar_level, cholesterol
- recorded_at

### rfid_cards
- id, card_uid, patient_id
- assigned_at, is_active, created_at

### doctor_availability
- id, doctor_id, day_of_week
- start_time, end_time, is_available
- created_at

## Environment Variables

Create `.env` file in `backend/` directory:

```env
DATABASE_URL=postgresql://postgres:ed333#yhithe@db.ohvzatnkgxniswnpmtfx.supabase.co:5432/postgres
SECRET_KEY=your-secret-key-here
GEMINI_API_KEY=your-gemini-api-key-here
```

## File Structure

```
health_app/
├── backend/
│   ├── main.py                 # FastAPI application
│   ├── sql_models.py           # Database models
│   ├── database_supabase.py    # Database connection
│   ├── routers/
│   │   ├── auth.py            # Authentication
│   │   ├── users.py           # User management
│   │   ├── appointments.py    # Appointments
│   │   ├── reports.py         # Medical reports
│   │   ├── rfid.py            # RFID system
│   │   ├── ai.py              # AI features
│   │   └── availability.py    # Doctor availability
│   ├── rfid_reader.py         # RFID hardware interface
│   ├── rfid_websocket_bridge.py # WebSocket server
│   ├── uploads/               # PDF storage
│   └── requirements.txt
├── frontend/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── auth/          # Login/Signup
│   │   │   ├── patient/       # Patient screens
│   │   │   ├── doctor/        # Doctor screens
│   │   │   └── admin/         # Admin screens
│   │   └── services/
│   │       ├── api_service.dart
│   │       └── rfid_websocket_service.dart
│   └── pubspec.yaml
├── arduino_keyboard_rfid.ino  # Arduino RFID sketch
├── README.md
├── QUICKSTART.md
└── COMPLETE_GUIDE.md

## Troubleshooting

### Backend won't start
- Check if port 8000 is available
- Verify DATABASE_URL in .env
- Install dependencies: `pip install -r requirements.txt`

### Frontend build errors
- Run `flutter pub get`
- Clear build: `flutter clean`
- Check Flutter version: `flutter --version`

### RFID not working
- Check Arduino COM port
- Verify WebSocket connection on port 8765
- Test RFID reader with Arduino Serial Monitor

### Reports not showing
- Check if PDF files exist in uploads/
- Verify patient_id matches in database
- Check backend logs for errors

## Support

For issues or questions, check the logs:
- Backend: Console output from uvicorn
- Frontend: Browser console (F12)
- Database: Supabase dashboard

## Version
Current Version: 1.0.0
Last Updated: 2026-03-05
