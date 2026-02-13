"""
Test script for delete report endpoint
"""
import requests

BASE_URL = "http://127.0.0.1:8000/api"

# Login as admin
print("=" * 60)
print("Testing Delete Report Endpoint")
print("=" * 60)

response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"email": "admin@health.com", "password": "admin123", "role": "admin"}
)

if response.status_code != 200:
    print("❌ Admin login failed")
    exit(1)

token = response.json()["access_token"]
print("✅ Admin login successful")

# Get patient 3's reports
response = requests.get(
    f"{BASE_URL}/reports/patient/3",
    headers={"Authorization": f"Bearer {token}"}
)

reports = response.json()
print(f"\n📋 Patient 3 has {len(reports)} reports:")
for report in reports:
    print(f"  - Report ID: {report['id']}, Title: {report['title']}")

if not reports:
    print("\n⚠️  No reports to delete")
    exit(0)

# Test delete with non-admin user (should fail)
print("\n🔒 Testing authorization (patient trying to delete)...")
response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"email": "patient@health.com", "password": "patient123", "role": "patient"}
)
patient_token = response.json()["access_token"]

report_id = reports[0]['id']
response = requests.delete(
    f"{BASE_URL}/reports/delete/{report_id}",
    headers={"Authorization": f"Bearer {patient_token}"}
)

if response.status_code == 403:
    print("✅ Authorization check working (patient cannot delete)")
else:
    print(f"❌ Authorization check failed: {response.status_code}")

# Test delete as admin
print(f"\n🗑️  Testing delete as admin...")
print(f"Deleting Report ID: {report_id}, Title: {reports[0]['title']}")

response = requests.delete(
    f"{BASE_URL}/reports/delete/{report_id}",
    headers={"Authorization": f"Bearer {token}"}
)

if response.status_code == 200:
    print("✅ Report deleted successfully")
    print(f"   Response: {response.json()}")
    
    # Verify deletion
    response = requests.get(
        f"{BASE_URL}/reports/patient/3",
        headers={"Authorization": f"Bearer {token}"}
    )
    new_reports = response.json()
    print(f"\n✅ Verification: Patient 3 now has {len(new_reports)} reports")
    
    if len(new_reports) == len(reports) - 1:
        print("✅ Report count decreased by 1")
    else:
        print("⚠️  Report count mismatch")
else:
    print(f"❌ Delete failed: {response.status_code}")
    print(f"   Response: {response.text}")

print("\n" + "=" * 60)
print("✅ Test completed!")
print("=" * 60)
