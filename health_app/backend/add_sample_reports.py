"""
Add sample reports for testing
"""
import sqlite3
from datetime import datetime, timedelta
import random

conn = sqlite3.connect('health_app.db')
cursor = conn.cursor()

print("\n" + "="*60)
print("ADDING SAMPLE REPORTS")
print("="*60)

# Get admin user
cursor.execute('SELECT id FROM users WHERE role="admin" LIMIT 1')
admin = cursor.fetchone()
admin_id = admin[0] if admin else 1

# Get patients
cursor.execute('SELECT id, full_name FROM users WHERE role="patient"')
patients = cursor.fetchall()

if not patients:
    print("\n❌ No patients found!")
    conn.close()
    exit()

# Sample report data
sample_reports = [
    {
        'title': 'Complete Blood Count (CBC)',
        'department': 'Pathology',
        'vitals': {'bp_sys': 120, 'bp_dia': 80, 'sugar': 95, 'cholesterol': 180}
    },
    {
        'title': 'Lipid Profile Test',
        'department': 'Pathology',
        'vitals': {'bp_sys': 118, 'bp_dia': 78, 'sugar': 92, 'cholesterol': 175}
    },
    {
        'title': 'Thyroid Function Test',
        'department': 'Pathology',
        'vitals': {'bp_sys': 122, 'bp_dia': 82, 'sugar': 98, 'cholesterol': 185}
    },
    {
        'title': 'Chest X-Ray Report',
        'department': 'Radiology',
        'vitals': None
    },
    {
        'title': 'ECG Report',
        'department': 'Cardiology',
        'vitals': {'bp_sys': 115, 'bp_dia': 75, 'sugar': 90, 'cholesterol': 170}
    },
    {
        'title': 'Kidney Function Test',
        'department': 'Pathology',
        'vitals': {'bp_sys': 125, 'bp_dia': 85, 'sugar': 100, 'cholesterol': 190}
    },
    {
        'title': 'Liver Function Test',
        'department': 'Pathology',
        'vitals': {'bp_sys': 120, 'bp_dia': 80, 'sugar': 94, 'cholesterol': 182}
    },
]

reports_added = 0

for patient_id, patient_name in patients:
    print(f"\n👤 Adding reports for: {patient_name} (ID: {patient_id})")
    
    # Add 3-5 random reports per patient
    num_reports = random.randint(3, 5)
    selected_reports = random.sample(sample_reports, min(num_reports, len(sample_reports)))
    
    for i, report_data in enumerate(selected_reports):
        # Create report with date going back in time
        days_ago = i * 30  # 30 days apart
        created_date = (datetime.now() - timedelta(days=days_ago)).isoformat()
        
        # Insert report
        cursor.execute('''
            INSERT INTO reports (patient_id, title, department, file_url, uploaded_by, created_at)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', (
            patient_id,
            report_data['title'],
            report_data['department'],
            f'/uploads/{patient_id}_sample_{i}.pdf',  # Dummy file path
            admin_id,
            created_date
        ))
        
        report_id = cursor.lastrowid
        reports_added += 1
        
        print(f"   ✅ {report_data['title']} (Report ID: {report_id})")
        
        # Add vitals if present
        if report_data['vitals']:
            cursor.execute('''
                INSERT INTO vitals (report_id, patient_id, bp_systolic, bp_diastolic, sugar_level, cholesterol)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (
                report_id,
                patient_id,
                report_data['vitals']['bp_sys'],
                report_data['vitals']['bp_dia'],
                report_data['vitals']['sugar'],
                report_data['vitals']['cholesterol']
            ))
            print(f"      📊 Vitals: BP {report_data['vitals']['bp_sys']}/{report_data['vitals']['bp_dia']}, "
                  f"Sugar {report_data['vitals']['sugar']}, Cholesterol {report_data['vitals']['cholesterol']}")

conn.commit()

print("\n" + "="*60)
print(f"✅ Added {reports_added} sample reports!")
print("="*60)

# Show final counts
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

cursor.execute('SELECT COUNT(*) FROM reports')
total = cursor.fetchone()[0]
print(f"\nTotal reports in database: {total}")

cursor.execute('SELECT COUNT(*) FROM vitals')
total_vitals = cursor.fetchone()[0]
print(f"Total vitals records: {total_vitals}")

conn.close()
print("\n" + "="*60)
print("✅ Done! Refresh the patient details page to see reports.")
print("="*60 + "\n")
