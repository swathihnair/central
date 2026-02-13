from database import SessionLocal
import sql_models
from datetime import datetime

db = SessionLocal()

# Get patient with ID 4
patient = db.query(sql_models.User).filter(sql_models.User.id == 4).first()

if patient:
    print(f"Adding test report for patient: {patient.full_name}")
    
    # Create a test report
    report = sql_models.Report(
        patient_id=4,
        title="Blood Test Results - Complete Panel",
        department="Pathology",
        file_url="/uploads/test_report.pdf",
        uploaded_by=4,  # admin id
        created_at=datetime.now()
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    
    print(f"Report created with ID: {report.id}")
    
    # Add vitals for this report
    vital = sql_models.Vital(
        report_id=report.id,
        patient_id=4,
        bp_systolic=130,
        bp_diastolic=85,
        sugar_level=110,
        cholesterol=200,
        recorded_at=datetime.now()
    )
    db.add(vital)
    db.commit()
    
    print("✅ Test report and vitals added successfully!")
    print(f"Blood Pressure: 130/85 mmHg")
    print(f"Sugar Level: 110 mg/dL")
    print(f"Cholesterol: 200 mg/dL")
else:
    print("Patient not found!")

db.close()
