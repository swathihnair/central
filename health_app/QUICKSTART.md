# Quick Start Guide

Get your Health App running in 5 minutes!

## Prerequisites Check

Before starting, ensure you have:
- [ ] Python 3.8+ installed (`python --version`)
- [ ] Flutter 3.9+ installed (`flutter --version`)
- [ ] MongoDB running (local or Atlas)
- [ ] Gemini API Key from [Google AI Studio](https://makersuite.google.com/app/apikey)

## Option 1: Automated Setup (Recommended)

```bash
cd health_app
python setup.py
```

Follow the prompts and you're done!

## Option 2: Manual Setup

### Step 1: Backend Setup (2 minutes)

```bash
cd health_app/backend

# Create and activate virtual environment
python -m venv venv

# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Edit .env file and add your GEMINI_API_KEY
```

### Step 2: Frontend Setup (1 minute)

```bash
cd health_app/frontend
flutter pub get
```

### Step 3: Start MongoDB

**Local MongoDB:**
```bash
mongod
```

**Or use MongoDB Atlas** (cloud) and update MONGODB_URL in .env

### Step 4: Run the App (1 minute)

**Terminal 1 - Backend:**
```bash
cd health_app/backend
python main.py
```

**Terminal 2 - Frontend:**
```bash
cd health_app/frontend
flutter run -d chrome
```

### Step 5: Create Test Users (1 minute)

**Admin:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@health.com","password":"admin123","full_name":"Admin User","role":"admin"}'
```

**Doctor:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@health.com","password":"doctor123","full_name":"Dr. Smith","role":"doctor","specialization":"Cardiology"}'
```

**Patient:**
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"patient@health.com","password":"patient123","full_name":"John Doe","role":"patient"}'
```

## Login Credentials

After creating test users:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@health.com | admin123 |
| Doctor | doctor@health.com | doctor123 |
| Patient | patient@health.com | patient123 |

## Test the Features

### As Patient:
1. Login with patient credentials
2. View dashboard (vitals will be empty initially)
3. Book an appointment with a doctor
4. Chat with AI Doctor
5. View reports (after admin uploads)

### As Doctor:
1. Login with doctor credentials
2. View dashboard with statistics
3. Approve/reject patient appointments
4. View patient list

### As Admin:
1. Login with admin credentials
2. View all patients and doctors
3. Upload a patient report (select patient, add title, choose department, upload file)
4. Reports will automatically extract vitals

## Troubleshooting

### Backend won't start
- Check if MongoDB is running
- Verify .env file exists with correct values
- Check if port 8000 is available

### Frontend won't connect
- Ensure backend is running on http://localhost:8000
- Check browser console for errors
- Try `flutter clean` and `flutter pub get`

### MongoDB connection error
- Start MongoDB: `mongod`
- Or use MongoDB Atlas and update MONGODB_URL
- Check if port 27017 is available

### Gemini API not working
- Verify GEMINI_API_KEY in .env
- Get key from https://makersuite.google.com/app/apikey
- Check API quota limits

## Next Steps

- Explore the API docs at http://localhost:8000/docs
- Customize the UI in `frontend/lib/screens/`
- Add new features in `backend/routers/`
- Read the full README.md for detailed documentation

## Need Help?

- Check the full README.md
- Review API documentation at /docs
- Check backend logs in terminal
- Verify all prerequisites are installed

---

Happy coding! 🚀
