import sqlite3

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

print("\n" + "="*60)
print("REPORTS IN DATABASE")
print("="*60)

cursor.execute('SELECT id, patient_id, title, department, file_url FROM reports')
reports = cursor.fetchall()

if reports:
    for row in reports:
        print(f"\nReport ID: {row[0]}")
        print(f"  Patient ID: {row[1]}")
        print(f"  Title: {row[2]}")
        print(f"  Department: {row[3]}")
        print(f"  File: {row[4]}")
else:
    print("\n❌ No reports found in database!")

print("\n" + "="*60)
print("PATIENTS IN DATABASE")
print("="*60)

cursor.execute('SELECT id, full_name, email, role FROM users WHERE role="patient"')
patients = cursor.fetchall()

if patients:
    for row in patients:
        print(f"\nPatient ID: {row[0]}")
        print(f"  Name: {row[1]}")
        print(f"  Email: {row[2]}")
        
        # Count reports for this patient
        cursor.execute('SELECT COUNT(*) FROM reports WHERE patient_id=?', (row[0],))
        count = cursor.fetchone()[0]
        print(f"  Reports: {count}")
else:
    print("\n❌ No patients found in database!")

print("\n" + "="*60)

conn.close()
