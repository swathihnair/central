"""
Test login functionality
"""
from database import SessionLocal
from sql_models import User
import bcrypt

db = SessionLocal()

print("=" * 60)
print("LOGIN CREDENTIALS TEST")
print("=" * 60)

# Get all users
users = db.query(User).all()

print(f"\n✅ Found {len(users)} users in database:\n")

for user in users:
    print(f"📧 Email: {user.email}")
    print(f"   Role: {user.role}")
    print(f"   Name: {user.full_name}")
    print(f"   ID: {user.id}")
    print(f"   Password Hash: {user.hashed_password[:20]}...")
    print()

print("=" * 60)
print("TEST LOGIN CREDENTIALS")
print("=" * 60)

# Test credentials
test_logins = [
    ("admin@health.com", "admin123", "admin"),
    ("doctor@health.com", "doctor123", "doctor"),
    ("patient@health.com", "patient123", "patient"),
]

for email, password, expected_role in test_logins:
    print(f"\n🔐 Testing: {email} / {password}")
    
    user = db.query(User).filter(User.email == email).first()
    
    if not user:
        print(f"   ❌ User not found!")
        continue
    
    # Check password
    try:
        if bcrypt.checkpw(password.encode('utf-8'), user.hashed_password.encode('utf-8')):
            print(f"   ✅ Password correct!")
            print(f"   ✅ Role: {user.role}")
            print(f"   ✅ User ID: {user.id}")
        else:
            print(f"   ❌ Password incorrect!")
    except Exception as e:
        print(f"   ❌ Error checking password: {e}")

print("\n" + "=" * 60)
print("RECOMMENDED LOGIN CREDENTIALS")
print("=" * 60)
print("\n🔑 PATIENT LOGIN:")
print("   Email: patient@health.com")
print("   Password: patient123")
print("   Role: Patient")

print("\n🔑 DOCTOR LOGIN:")
print("   Email: doctor@health.com")
print("   Password: doctor123")
print("   Role: Doctor")

print("\n🔑 ADMIN LOGIN:")
print("   Email: admin@health.com")
print("   Password: admin123")
print("   Role: Admin")

db.close()
