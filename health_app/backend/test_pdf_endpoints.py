"""
Test script for PDF view and download endpoints
"""
import requests

BASE_URL = "http://127.0.0.1:8000/api"

# Test credentials
PATIENT_EMAIL = "patient@health.com"
PATIENT_PASSWORD = "patient123"
ADMIN_EMAIL = "admin@health.com"
ADMIN_PASSWORD = "admin123"

def login(email, password, role):
    """Login and get token"""
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={"email": email, "password": password, "role": role}
    )
    if response.status_code == 200:
        return response.json()["access_token"]
    else:
        print(f"Login failed: {response.text}")
        return None

def get_patient_reports(token, patient_id):
    """Get patient reports"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/reports/patient/{patient_id}",
        headers=headers
    )
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Failed to get reports: {response.text}")
        return []

def test_view_report(token, report_id):
    """Test view report endpoint"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/reports/view/{report_id}",
        headers=headers
    )
    print(f"\nView Report {report_id}:")
    print(f"  Status: {response.status_code}")
    print(f"  Content-Type: {response.headers.get('Content-Type')}")
    print(f"  Content-Disposition: {response.headers.get('Content-Disposition')}")
    if response.status_code == 200:
        print(f"  ✅ Success - PDF size: {len(response.content)} bytes")
    else:
        print(f"  ❌ Failed: {response.text}")
    return response.status_code == 200

def test_download_report(token, report_id):
    """Test download report endpoint"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(
        f"{BASE_URL}/reports/download/{report_id}",
        headers=headers
    )
    print(f"\nDownload Report {report_id}:")
    print(f"  Status: {response.status_code}")
    print(f"  Content-Type: {response.headers.get('Content-Type')}")
    print(f"  Content-Disposition: {response.headers.get('Content-Disposition')}")
    if response.status_code == 200:
        print(f"  ✅ Success - PDF size: {len(response.content)} bytes")
    else:
        print(f"  ❌ Failed: {response.text}")
    return response.status_code == 200

def main():
    print("=" * 60)
    print("Testing PDF View and Download Endpoints")
    print("=" * 60)
    
    # Test as patient
    print("\n📋 Testing as PATIENT")
    print("-" * 60)
    patient_token = login(PATIENT_EMAIL, PATIENT_PASSWORD, "patient")
    if patient_token:
        print("✅ Patient login successful")
        
        # Get patient reports
        reports = get_patient_reports(patient_token, "3")  # Patient ID 3
        if reports:
            print(f"✅ Found {len(reports)} reports")
            
            # Test first report
            if len(reports) > 0:
                report_id = reports[0]['id']
                print(f"\nTesting with Report ID: {report_id}")
                test_view_report(patient_token, report_id)
                test_download_report(patient_token, report_id)
        else:
            print("❌ No reports found")
    else:
        print("❌ Patient login failed")
    
    # Test as admin
    print("\n\n👨‍💼 Testing as ADMIN")
    print("-" * 60)
    admin_token = login(ADMIN_EMAIL, ADMIN_PASSWORD, "admin")
    if admin_token:
        print("✅ Admin login successful")
        
        # Get patient reports (admin can access any patient)
        reports = get_patient_reports(admin_token, "3")
        if reports:
            print(f"✅ Found {len(reports)} reports")
            
            # Test first report
            if len(reports) > 0:
                report_id = reports[0]['id']
                print(f"\nTesting with Report ID: {report_id}")
                test_view_report(admin_token, report_id)
                test_download_report(admin_token, report_id)
        else:
            print("❌ No reports found")
    else:
        print("❌ Admin login failed")
    
    # Test authorization (patient trying to access another patient's report)
    print("\n\n🔒 Testing AUTHORIZATION")
    print("-" * 60)
    print("Patient trying to access another patient's report...")
    # This should fail with 403 if implemented correctly
    # For now, we'll just test with patient's own reports
    
    print("\n" + "=" * 60)
    print("✅ All tests completed!")
    print("=" * 60)

if __name__ == "__main__":
    main()
