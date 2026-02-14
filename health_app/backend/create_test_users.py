import bcrypt
from database import SessionLocal, engine, Base
import sql_models

# Create tables
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# Check if users exist
existing = db.query(sql_models.User).filter(sql_models.User.email == 'admin@health.com').first()
if not existing:
    # Create admin
    admin = sql_models.User(
        email='admin@health.com',
        full_name='Admin User',
        role='admin',
        hashed_password=bcrypt.hashpw('admin123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        phone='1234567890'
    )
    db.add(admin)
    
    # Create doctor
    doctor = sql_models.User(
        email='doctor@health.com',
        full_name='Dr. Smith',
        role='doctor',
        hashed_password=bcrypt.hashpw('doctor123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        phone='9876543210',
        specialization='General Medicine'
    )
    db.add(doctor)
    
    # Create patient
    patient = sql_models.User(
        email='patient@health.com',
        full_name='John Doe',
        role='patient',
        hashed_password=bcrypt.hashpw('patient123'.encode('utf-8'), bcrypt.gensalt()).decode('utf-8'),
        phone='5555555555'
    )
    db.add(patient)
    
    db.commit()
    print('Test users created successfully!')
else:
    print('Users already exist')

db.close()
