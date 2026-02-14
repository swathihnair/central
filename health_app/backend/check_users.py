"""
Check all users in database
"""
import sqlite3
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

print("\n" + "="*60)
print("ALL USERS IN DATABASE")
print("="*60)

cursor.execute('SELECT id, email, full_name, role, hashed_password FROM users')
users = cursor.fetchall()

if users:
    for user in users:
        user_id, email, full_name, role, password_hash = user
        print(f"\n{'='*60}")
        print(f"ID: {user_id}")
        print(f"Name: {full_name}")
        print(f"Email: {email}")
        print(f"Role: {role}")
        print(f"Password Hash: {password_hash[:50]}...")
        
        # Test common passwords
        test_passwords = ['admin123', 'password123', 'doctor123']
        for test_pwd in test_passwords:
            if pwd_context.verify(test_pwd, password_hash):
                print(f"✅ Password: {test_pwd}")
                break
        else:
            print("❌ Password: Unknown (not in test list)")
else:
    print("\n❌ No users found!")

print("\n" + "="*60)

conn.close()
