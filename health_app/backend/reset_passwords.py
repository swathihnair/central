"""
Reset all user passwords to known values
"""
from database import get_db
import sql_models
import bcrypt

db = next(get_db())

print("\n" + "="*60)
print("RESETTING USER PASSWORDS")
print("="*60)

# Define password mappings
password_map = {
    'admin@health.com': 'admin123',
    'doctor@health.com': 'password123',
    'patient@health.com': 'password123',
    'swathi.h.2005@gmail.com': 'password123'
}

for email, password in password_map.items():
    user = db.query(sql_models.User).filter(sql_models.User.email == email).first()
    
    if user:
        # Hash the password using bcrypt directly
        hashed = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        user.hashed_password = hashed
        db.commit()
        
        print(f"\n✅ {user.role.upper()}: {user.full_name}")
        print(f"   Email: {email}")
        print(f"   Password: {password}")
    else:
        print(f"\n❌ User not found: {email}")

print("\n" + "="*60)
print("✅ ALL PASSWORDS RESET!")
print("="*60)

print("\nLogin Credentials:")
print("-" * 60)
print("ADMIN:")
print("  Email: admin@health.com")
print("  Password: admin123")
print()
print("DOCTOR:")
print("  Email: doctor@health.com")
print("  Password: password123")
print()
print("PATIENTS:")
print("  Email: patient@health.com")
print("  Password: password123")
print()
print("  Email: swathi.h.2005@gmail.com")
print("  Password: password123")
print("="*60 + "\n")
