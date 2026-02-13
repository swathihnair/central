"""
Test script to verify PDF download returns proper bytes
"""
import requests

BASE_URL = "http://127.0.0.1:8000/api"

# Login as patient
response = requests.post(
    f"{BASE_URL}/auth/login",
    json={"email": "patient@health.com", "password": "patient123", "role": "patient"}
)
token = response.json()["access_token"]

# Get reports
response = requests.get(
    f"{BASE_URL}/reports/patient/3",
    headers={"Authorization": f"Bearer {token}"}
)
reports = response.json()

if reports:
    report_id = reports[0]['id']
    report_title = reports[0]['title']
    
    print(f"Testing download for Report ID: {report_id}")
    print(f"Report Title: {report_title}")
    
    # Download PDF
    response = requests.get(
        f"{BASE_URL}/reports/download/{report_id}",
        headers={"Authorization": f"Bearer {token}"}
    )
    
    print(f"\nDownload Response:")
    print(f"  Status Code: {response.status_code}")
    print(f"  Content-Type: {response.headers.get('Content-Type')}")
    print(f"  Content-Disposition: {response.headers.get('Content-Disposition')}")
    print(f"  Content Length: {len(response.content)} bytes")
    
    if response.status_code == 200:
        # Save to file to verify it's a valid PDF
        filename = f"test_download_{report_id}.pdf"
        with open(filename, 'wb') as f:
            f.write(response.content)
        print(f"\n✅ PDF downloaded successfully!")
        print(f"  Saved as: {filename}")
        print(f"  You can open this file to verify it's a valid PDF")
    else:
        print(f"\n❌ Download failed: {response.text}")
else:
    print("No reports found")
