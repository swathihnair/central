# 🔐 Health App - Login Credentials

## Admin Account

**Email:** admin@health.com  
**Password:** admin123  
**Role:** Admin

**Access:**
- Patient Management
- Doctor Management
- Appointment Management
- Report Upload/Delete
- RFID Scanner
- Full system access

---

## Patient Accounts

### Patient 1: John Doe
**Email:** patient@health.com  
**Password:** password123  
**Role:** Patient  
**Patient ID:** 3  
**RFID Card:** CARD001

**Access:**
- View own reports (4 reports)
- Download reports
- View vitals
- Book appointments
- AI Health Assistant

**Reports:**
- Kidney Function Test (with vitals)
- Lipid Profile Test (with vitals)
- Chest X-Ray Report
- ECG Report (with vitals)

---

### Patient 2: Swathi H
**Email:** swathi.h.2005@gmail.com  
**Password:** password123  
**Role:** Patient  
**Patient ID:** 4  
**RFID Card:** 51E4B217 (51 E4 B2 17)

**Access:**
- View own reports (6 reports)
- Download reports
- View vitals
- Book appointments
- AI Health Assistant

**Reports:**
- Sterling Accuris Pathology Sample Report (real PDF)
- Kidney Function Test (with vitals)
- Chest X-Ray Report
- Thyroid Function Test (with vitals)
- Complete Blood Count (CBC) (with vitals)
- Lipid Profile Test (with vitals)

---

## Doctor Accounts

### Doctor 1: Dr. Smith
**Email:** doctor@health.com  
**Password:** password123  
**Role:** Doctor  
**Specialization:** Cardiology

**Access:**
- View appointments
- Approve/Reject appointments
- View patient records
- Access patient reports

---

## Test Accounts Summary

| Role | Email | Password | ID | RFID Card |
|------|-------|----------|-----|-----------|
| Admin | admin@health.com | admin123 | 1 | - |
| Patient | patient@health.com | password123 | 3 | CARD001 |
| Patient | swathi.h.2005@gmail.com | password123 | 4 | 51E4B217 |
| Doctor | doctor@health.com | password123 | 2 | - |

---

## RFID Cards

### Registered Cards:

**Card 1:**
- **UID:** CARD001
- **Patient:** John Doe (ID: 3)
- **Status:** Active
- **Email:** patient@health.com

**Card 2:**
- **UID:** 51E4B217 (or 51 E4 B2 17)
- **Patient:** Swathi H (ID: 4)
- **Status:** Active
- **Email:** swathi.h.2005@gmail.com

---

## Quick Login Guide

### For Admin:
1. Go to login page
2. Select "Admin" role
3. Email: `admin@health.com`
4. Password: `admin123`
5. Click Login

### For Patient:
1. Go to login page
2. Select "Patient" role
3. Email: `patient@health.com` or `swathi.h.2005@gmail.com`
4. Password: `password123`
5. Click Login

### For Doctor:
1. Go to login page
2. Select "Doctor" role
3. Email: `doctor@health.com`
4. Password: `password123`
5. Click Login

---

## RFID Scanner Login

### Method 1: Manual Login
1. Login as admin (admin@health.com / admin123)
2. Go to RFID Scanner (6th menu item)
3. Scan card or type UID manually

### Method 2: Python Bridge Auto-Login
The `rfid_reader.py` script automatically logs in as admin:
```python
email: 'admin@health.com'
password: 'admin123'
```

### Method 3: WebSocket Bridge
The `rfid_websocket_bridge.py` doesn't require login - it just broadcasts card UIDs to connected browsers.

---

## Database Access

### SQLite Database:
**File:** `health_app/backend/health_app.db`

**Direct Access:**
```bash
cd health_app/backend
sqlite3 health_app.db
```

**View Users:**
```sql
SELECT id, full_name, email, role FROM users;
```

**View RFID Cards:**
```sql
SELECT card_uid, patient_id, is_active FROM rfid_cards;
```

---

## API Authentication

### Get Token:
```bash
curl -X POST http://127.0.0.1:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@health.com",
    "password": "admin123",
    "role": "admin"
  }'
```

### Use Token:
```bash
curl -X GET http://127.0.0.1:8000/api/users/patients \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

## Password Reset (If Needed)

### Reset Admin Password:
```python
# In Python console
from database import get_db
from passlib.context import CryptContext
import sql_models

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
db = next(get_db())

admin = db.query(sql_models.User).filter(sql_models.User.email == "admin@health.com").first()
admin.password = pwd_context.hash("admin123")
db.commit()
print("Admin password reset to: admin123")
```

### Reset Patient Password:
```python
patient = db.query(sql_models.User).filter(sql_models.User.email == "patient@health.com").first()
patient.password = pwd_context.hash("password123")
db.commit()
print("Patient password reset to: password123")
```

---

## Security Notes

### Development Environment:
- ⚠️ These are **test credentials** for development only
- ⚠️ Passwords are simple for easy testing
- ⚠️ CORS is set to allow all origins

### Production Deployment:
- ✅ Change all passwords to strong, unique passwords
- ✅ Enable HTTPS/SSL
- ✅ Restrict CORS to specific domains
- ✅ Add rate limiting
- ✅ Enable 2FA for admin accounts
- ✅ Use environment variables for secrets
- ✅ Regular password rotation policy
- ✅ Audit logging for all access

---

## Creating New Users

### Via API:
```bash
curl -X POST http://127.0.0.1:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "newuser@example.com",
    "password": "password123",
    "full_name": "New User",
    "role": "patient",
    "phone": "1234567890",
    "age": 30
  }'
```

### Via Admin Dashboard:
1. Login as admin
2. Go to Patient Management or Doctor Management
3. Click "Add New" button
4. Fill in details
5. Click Save

---

## Assigning RFID Cards

### Via API:
```bash
curl -X POST http://127.0.0.1:8000/api/rfid/assign \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "card_uid": "NEWCARD123",
    "patient_id": 3
  }'
```

### Via Python Script:
```python
import sqlite3

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

cursor.execute('''
    INSERT INTO rfid_cards (card_uid, patient_id, is_active)
    VALUES (?, ?, 1)
''', ('NEWCARD123', 3))

conn.commit()
conn.close()
```

---

## Troubleshooting Login Issues

### "Invalid credentials"
- Check email spelling
- Check password (case-sensitive)
- Verify role selection matches account type

### "User not found"
- Check if user exists in database
- Run: `python check_reports.py` to see all users

### "Token expired"
- Logout and login again
- Tokens expire after 24 hours

### "Access denied"
- Check user role matches required permission
- Admin access required for RFID scanner

---

## Quick Reference

**Admin Login:**
```
admin@health.com / admin123
```

**Patient Login:**
```
patient@health.com / password123
swathi.h.2005@gmail.com / password123
```

**Doctor Login:**
```
doctor@health.com / password123
```

**RFID Cards:**
```
CARD001 → John Doe
51E4B217 → Swathi H
```

---

**Last Updated:** Now  
**Environment:** Development  
**Security Level:** Test/Development Only  

⚠️ **IMPORTANT:** Change all passwords before production deployment!
