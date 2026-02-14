from database import SessionLocal
from sql_models import Vital, Report
import json

db = SessionLocal()

print("=" * 60)
print("DATABASE CHECK - Patient ID 4")
print("=" * 60)

# Check vitals
vitals = db.query(Vital).filter(Vital.patient_id == 4).order_by(Vital.recorded_at.desc()).all()
print(f"\n✅ Found {len(vitals)} vitals for patient 4:")
for v in vitals:
    print(f"   - ID: {v.id}, BP: {v.bp_systolic}/{v.bp_diastolic}, Sugar: {v.sugar_level}, Cholesterol: {v.cholesterol}, Date: {v.recorded_at}")

# Check reports
reports = db.query(Report).filter(Report.patient_id == 4).order_by(Report.created_at.desc()).all()
print(f"\n✅ Found {len(reports)} reports for patient 4:")
for r in reports:
    print(f"   - ID: {r.id}, Title: {r.title}, Department: {r.department}, Date: {r.created_at}")
    print(f"     PDF Text Length: {len(r.pdf_text) if r.pdf_text else 0} characters")
    
    # Find vitals for this report
    report_vitals = db.query(Vital).filter(Vital.report_id == r.id).first()
    if report_vitals:
        print(f"     Vitals: BP {report_vitals.bp_systolic}/{report_vitals.bp_diastolic}, Sugar {report_vitals.sugar_level}, Cholesterol {report_vitals.cholesterol}")

print("\n" + "=" * 60)
print("EXPECTED BEHAVIOR")
print("=" * 60)
print("\n1. Dashboard should show LATEST vitals:")
latest = vitals[0] if vitals else None
if latest:
    print(f"   BP: {latest.bp_systolic}/{latest.bp_diastolic}")
    print(f"   Sugar: {latest.sugar_level} mg/dL")
    print(f"   Cholesterol: {latest.cholesterol} mg/dL")

print("\n2. AI should show SAME vitals when asked")
print("   (AI fetches from same database)")

print("\n3. Both should match because they use same data source!")

db.close()
