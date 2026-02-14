"""
List all users in database
"""
import sqlite3

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

print("\n" + "="*60)
print("ALL USERS IN DATABASE")
print("="*60)

cursor.execute('SELECT id, email, full_name, role FROM users ORDER BY role, id')
users = cursor.fetchall()

if users:
    for user in users:
        user_id, email, full_name, role = user
        print(f"\n{role.upper()}: {full_name}")
        print(f"  ID: {user_id}")
        print(f"  Email: {email}")
        
        # Check RFID card if patient
        if role == 'patient':
            cursor.execute('SELECT card_uid FROM rfid_cards WHERE patient_id=? AND is_active=1', (user_id,))
            card = cursor.fetchone()
            if card:
                print(f"  RFID Card: {card[0]}")
            else:
                print(f"  RFID Card: None")
else:
    print("\n❌ No users found!")

print("\n" + "="*60)
print("TOTAL USERS:", len(users))
print("="*60 + "\n")

conn.close()
