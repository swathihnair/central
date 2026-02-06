# Health App - Complete Healthcare Management System

A comprehensive healthcare management system with Flutter frontend and FastAPI backend, featuring role-based access for Admin, Doctor, and Patient users.

## Features

### Patient Features
- **Dashboard**: View vitals (BP, Sugar, Cholesterol) with trend charts
- **Appointments**: Book appointments with doctors and track status
- **Doctor AI**: Chat with AI health assistant powered by Gemini
- **Reports**: View medical reports organized by department
- **Settings**: Manage profile and preferences

### Doctor Features
- **Dashboard**: Overview of patients, appointments, and statistics
- **Patient Management**: View patient details and history
- **Appointment Management**: Approve/reject appointment requests
- **Patient Reviews**: View patient feedback

### Admin Features
- **Dashboard**: System overview with statistics
- **User Management**: View all patients and doctors
- **Report Upload**: Upload patient reports with automatic vital extraction
- **System Management**: Manage all system data

## Tech Stack

### Frontend
- Flutter 3.9+
- Material Design 3
- Provider for state management
- FL Chart for data visualization
- Dash Chat for AI interface

### Backend
- FastAPI (Python)
- MongoDB for database
- JWT authentication
- Gemini AI integration
- Async/await architecture

## Prerequisites

- Python 3.8+
- Flutter 3.9+
- MongoDB (local or cloud)
- Gemini API Key (for AI features)

## Installation

### 1. Backend Setup

```bash
cd health_app/backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
# Edit .env file and add:
# - MONGODB_URL (default: mongodb://localhost:27017)
# - GEMINI_API_KEY (get from https://makersuite.google.com/app/apikey)
# - SECRET_KEY (generate with: openssl rand -hex 32)
```

### 2. MongoDB Setup

**Option A: Local MongoDB**
```bash
# Install MongoDB from https://www.mongodb.com/try/download/community
# Start MongoDB service
mongod
```

**Option B: MongoDB Atlas (Cloud)**
1. Create account at https://www.mongodb.com/cloud/atlas
2. Create a free cluster
3. Get connection string and update MONGODB_URL in .env

### 3. Frontend Setup

```bash
cd health_app/frontend

# Install dependencies
flutter pub get

# Run the app
flutter run -d chrome  # For web
flutter run            # For mobile/desktop
```

### 4. Start Backend Server

```bash
cd health_app/backend
python main.py
```

The API will be available at http://localhost:8000

## Initial Setup

### Create Test Users

You can register users through the API or use the following curl commands:

**Create Admin:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@health.com",
    "password": "admin123",
    "full_name": "Admin User",
    "role": "admin"
  }'
```

**Create Doctor:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@health.com",
    "password": "doctor123",
    "full_name": "Dr. Smith",
    "role": "doctor",
    "specialization": "Cardiology"
  }'
```

**Create Patient:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "patient@health.com",
    "password": "patient123",
    "full_name": "John Doe",
    "role": "patient",
    "phone": "1234567890"
  }'
```

## Usage

### Login Credentials (After creating test users)

**Admin:**
- Email: admin@health.com
- Password: admin123
- Role: Admin

**Doctor:**
- Email: doctor@health.com
- Password: doctor123
- Role: Doctor

**Patient:**
- Email: patient@health.com
- Password: patient123
- Role: Patient

### Workflow

1. **Admin** uploads patient reports
2. System automatically extracts vitals from reports
3. **Patient** views vitals and reports in dashboard
4. **Patient** books appointment with doctor
5. **Doctor** approves/rejects appointment
6. **Patient** can chat with AI doctor for health queries

## API Documentation

Once the backend is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
health_app/
├── backend/
│   ├── routers/
│   │   ├── auth.py          # Authentication endpoints
│   │   ├── appointments.py  # Appointment management
│   │   ├── reports.py       # Report upload & retrieval
│   │   ├── users.py         # User management
│   │   └── ai.py            # AI chat integration
│   ├── models.py            # Pydantic models
│   ├── database.py          # MongoDB connection
│   ├── main.py              # FastAPI app
│   └── .env                 # Environment variables
│
└── frontend/
    ├── lib/
    │   ├── screens/
    │   │   ├── auth/        # Login screen
    │   │   ├── patient/     # Patient screens
    │   │   ├── doctor/      # Doctor screens
    │   │   └── admin/       # Admin screens
    │   ├── services/
    │   │   └── api_service.dart  # API integration
    │   └── main.dart
    └── pubspec.yaml
```

## Features in Detail

### Vitals Tracking
- Automatic extraction from uploaded reports
- Historical trend visualization
- Real-time updates

### AI Doctor Chat
- Powered by Google Gemini
- Context-aware health advice
- Natural conversation interface

### Report Management
- Automatic department categorization
- Secure file storage
- Easy download and viewing

### Appointment System
- Real-time status updates
- Doctor approval workflow
- Calendar integration

## Troubleshooting

### Backend Issues

**MongoDB Connection Error:**
- Ensure MongoDB is running
- Check MONGODB_URL in .env
- Verify network connectivity

**Gemini API Error:**
- Verify GEMINI_API_KEY in .env
- Check API quota at Google AI Studio
- Ensure internet connectivity

### Frontend Issues

**API Connection Error:**
- Ensure backend is running on port 8000
- Check baseUrl in api_service.dart
- Verify CORS settings

**Build Errors:**
- Run `flutter clean`
- Run `flutter pub get`
- Update Flutter: `flutter upgrade`

## Development

### Adding New Features

1. **Backend**: Add new router in `routers/` directory
2. **Frontend**: Create new screen in `lib/screens/`
3. **API Integration**: Update `api_service.dart`

### Database Schema

The app uses MongoDB with the following collections:
- `users`: User accounts (admin, doctor, patient)
- `appointments`: Appointment records
- `reports`: Medical reports
- `vitals`: Extracted vital statistics

## Security Notes

- Change SECRET_KEY in production
- Use HTTPS in production
- Implement rate limiting
- Add input validation
- Use environment-specific configs

## Future Enhancements

- [ ] Video consultation
- [ ] Prescription management
- [ ] Lab test integration
- [ ] Payment gateway
- [ ] Mobile notifications
- [ ] Advanced OCR for report parsing
- [ ] Multi-language support

## License

MIT License - feel free to use for personal or commercial projects

## Support

For issues and questions:
- Create an issue on GitHub
- Check API documentation at /docs
- Review error logs in backend console

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

---

Built with ❤️ using Flutter and FastAPI
