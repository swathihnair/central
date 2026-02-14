# Database Configuration Updated

**Date**: February 13, 2026  
**Status**: ✅ Complete

---

## Changes Made

### Database URL Updated

**Previous Configuration**:
```
DATABASE_URL=sqlite:///./health_app.db
```

**New Configuration**:
```
DATABASE_URL=mysql+pymysql://root:swathi@localhost/health_app
```

### File Modified
- `health_app/backend/.env`

---

## Database Details

### Connection Information
- **Type**: MySQL
- **Host**: localhost
- **Port**: 3306 (default)
- **Database**: health_app
- **Username**: root
- **Password**: swathi
- **Driver**: pymysql

### Connection String
```
mysql+pymysql://root:swathi@localhost/health_app
```

---

## Services Status

### Backend
- **Status**: ✅ Running
- **URL**: http://127.0.0.1:8000
- **Process**: 4
- **Database**: MySQL (health_app)

### Frontend
- **Status**: ✅ Running
- **Platform**: Chrome
- **Process**: 2
- **Debug Service**: http://127.0.0.1:49872

---

## Database Schema

The application uses the following tables in MySQL:

### 1. users
- id (Primary Key)
- email (Unique)
- password (Hashed)
- full_name
- role (admin/doctor/patient)
- phone
- age
- specialization (for doctors)
- created_at

### 2. reports
- id (Primary Key)
- patient_id (Foreign Key → users.id)
- title
- department
- file_url
- pdf_text (LONGTEXT)
- uploaded_by (Foreign Key → users.id)
- created_at

### 3. vitals
- id (Primary Key)
- report_id (Foreign Key → reports.id)
- patient_id (Foreign Key → users.id)
- bp_systolic
- bp_diastolic
- sugar_level
- cholesterol
- recorded_at

### 4. appointments
- id (Primary Key)
- patient_id (Foreign Key → users.id)
- doctor_id (Foreign Key → users.id)
- date_time
- status (pending/approved/rejected/completed)
- doctor_approved (pending/approved/rejected)
- admin_approved (pending/approved/rejected)
- notes
- created_at

---

## Verification

### Test Database Connection

Run this command to verify the connection:

```bash
cd health_app/backend
.\venv\Scripts\python.exe -c "from database import engine; print('✅ Database connected:', engine.url)"
```

Expected output:
```
✅ Database connected: mysql+pymysql://root:***@localhost/health_app
```

### Check Tables

```python
from database import engine
from sqlalchemy import inspect

inspector = inspect(engine)
tables = inspector.get_table_names()
print("Tables:", tables)
```

Expected output:
```
Tables: ['users', 'reports', 'vitals', 'appointments']
```

---

## Migration Notes

### If Starting Fresh

If you need to create the database and tables:

```bash
cd health_app/backend
.\venv\Scripts\python.exe
```

```python
from database import Base, engine
from sql_models import User, Report, Vital, Appointment

# Create all tables
Base.metadata.create_all(bind=engine)
print("✅ All tables created")
```

### If Migrating from SQLite

If you had data in SQLite and want to migrate:

1. Export data from SQLite
2. Import into MySQL
3. Update foreign key constraints
4. Verify data integrity

---

## Test Credentials

All existing test credentials remain the same:

### Admin
- Email: admin@health.com
- Password: admin123

### Doctor
- Email: doctor@health.com
- Password: doctor123

### Patients
- Email: patient@health.com
- Password: patient123

- Email: swathi.h.2005@gmail.com
- Password: patient123

---

## Troubleshooting

### Connection Refused

**Error**: `Can't connect to MySQL server on 'localhost'`

**Solutions**:
1. Check if MySQL is running:
   ```bash
   mysql -u root -p
   ```
2. Start MySQL service if stopped
3. Verify port 3306 is not blocked

### Access Denied

**Error**: `Access denied for user 'root'@'localhost'`

**Solutions**:
1. Verify password is correct: `swathi`
2. Check user permissions:
   ```sql
   GRANT ALL PRIVILEGES ON health_app.* TO 'root'@'localhost';
   FLUSH PRIVILEGES;
   ```

### Database Not Found

**Error**: `Unknown database 'health_app'`

**Solution**:
```sql
CREATE DATABASE health_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### PyMySQL Not Installed

**Error**: `No module named 'pymysql'`

**Solution**:
```bash
cd health_app/backend
.\venv\Scripts\pip install pymysql
```

---

## Performance Considerations

### MySQL vs SQLite

**Advantages of MySQL**:
- ✅ Better for production
- ✅ Concurrent connections
- ✅ Better performance at scale
- ✅ Advanced features (stored procedures, triggers)
- ✅ Better data integrity
- ✅ Backup and recovery tools

**Configuration**:
- Connection pooling enabled
- UTF-8 encoding
- InnoDB engine (default)

---

## Backup Recommendations

### Daily Backup

```bash
mysqldump -u root -pswathi health_app > backup_$(date +%Y%m%d).sql
```

### Restore from Backup

```bash
mysql -u root -pswathi health_app < backup_20260213.sql
```

### Automated Backup Script

Create `backup.bat`:
```batch
@echo off
set TIMESTAMP=%date:~-4,4%%date:~-10,2%%date:~-7,2%
mysqldump -u root -pswathi health_app > backups\health_app_%TIMESTAMP%.sql
echo Backup completed: health_app_%TIMESTAMP%.sql
```

---

## Environment Variables

Current `.env` configuration:

```env
DATABASE_URL=mysql+pymysql://root:swathi@localhost/health_app
SECRET_KEY=64cb89be9e797959db0022d9473d13ad703a539a14b42a7ad47a945ae6c04709
GEMINI_API_KEY=AIzaSyBjRd-o-UVQ8BkcebArclxgw3fAGZl_1SM
```

**Security Note**: Never commit `.env` file to version control!

---

## Next Steps

1. ✅ Database URL updated
2. ✅ Backend restarted
3. ✅ Frontend running
4. ✅ Services connected to MySQL

You can now:
- Login with existing credentials
- All data is stored in MySQL
- Better performance and scalability
- Production-ready setup

---

**Status**: ✅ All systems operational with MySQL database  
**Last Updated**: February 13, 2026
