"""
Fix missing reports - Add existing PDF files to database
"""
import os
import sqlite3
from datetime import datetime

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

print("\n" + "="*60)
print("FIXING MISSING REPORTS")
print("="*60)

# Check uploads folder
uploads_dir = 'uploads'
if os.path.exists(uploads_dir):
    files = [f for f in os.listdir(uploads_dir) if f.endswith('.pdf')]
    
    print(f"\nFound {len(files)} PDF file(s) in uploads folder:")
    
    for filename in files:
        print(f"\n📄 Processing: {filename}")
        
        # Parse filename: patient_id_timestamp_title.pdf
        parts = filename.split('_', 2)
        if len(parts) >= 2:
            patient_id = int(parts[0])
            
            # Check if patient exists
            cursor.execute('SELECT full_name FROM users WHERE id=? AND role="patient"', (patient_id,))
            patient = cursor.fetchone()
            
            if patient:
                patient_name = patient[0]
                print(f"   Patient: {patient_name} (ID: {patient_id})")
                
                # Check if report already exists
                file_url = f"/uploads/{filename}"
                cursor.execute('SELECT id FROM reports WHERE file_url=?', (file_url,))
                existing = cursor.fetchone()
                
                if existing:
                    print(f"   ✅ Report already in database (ID: {existing[0]})")
                else:
                    # Extract title from filename
                    title_part = parts[2].replace('.pdf', '').replace('-', ' ').replace('_', ' ')
                    title = title_part.title()
                    
                    # Get admin user ID
                    cursor.execute('SELECT id FROM users WHERE role="admin" LIMIT 1')
                    admin = cursor.fetchone()
                    admin_id = admin[0] if admin else 1
                    
                    # Insert report
                    cursor.execute('''
                        INSERT INTO reports (patient_id, title, department, file_url, uploaded_by, created_at)
                        VALUES (?, ?, ?, ?, ?, ?)
                    ''', (
                        patient_id,
                        title,
                        'Pathology',  # Default department
                        file_url,
                        admin_id,
                        datetime.now().isoformat()
                    ))
                    
                    report_id = cursor.lastrowid
                    print(f"   ✅ Added to database (Report ID: {report_id})")
                    print(f"   Title: {title}")
                    print(f"   Department: Pathology")
            else:
                print(f"   ❌ Patient ID {patient_id} not found in database")
        else:
            print(f"   ⚠️  Skipping - invalid filename format")
    
    conn.commit()
    print("\n" + "="*60)
    print("✅ Database updated!")
    print("="*60)
else:
    print("\n❌ Uploads folder not found!")

# Show final report count
cursor.execute('SELECT COUNT(*) FROM reports')
total_reports = cursor.fetchone()[0]
print(f"\nTotal reports in database: {total_reports}")

# Show reports per patient
print("\nReports per patient:")
cursor.execute('''
    SELECT u.id, u.full_name, COUNT(r.id) as report_count
    FROM users u
    LEFT JOIN reports r ON u.id = r.patient_id
    WHERE u.role = "patient"
    GROUP BY u.id
''')

for row in cursor.fetchall():
    print(f"  {row[1]} (ID: {row[0]}): {row[2]} report(s)")

conn.close()
print("\n" + "="*60)
