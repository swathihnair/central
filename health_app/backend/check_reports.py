import requests

# Login as patient ID 3
response = requests.post(
    'http://127.0.0.1:8000/api/auth/login',
    json={'email': 'patient@health.com', 'password': 'patient123', 'role': 'patient'}
)
token = response.json()['access_token']

# Get reports for patient 3
response = requests.get(
    'http://127.0.0.1:8000/api/reports/patient/3',
    headers={'Authorization': f'Bearer {token}'}
)
reports = response.json()
print(f"Patient 3 has {len(reports)} reports:")
for report in reports:
    print(f"  - Report ID: {report['id']}, Patient ID: {report['patient_id']}, Title: {report['title']}")

# Login as patient ID 4 (swathi)
response = requests.post(
    'http://127.0.0.1:8000/api/auth/login',
    json={'email': 'swathi.h.2005@gmail.com', 'password': 'patient123', 'role': 'patient'}
)
token = response.json()['access_token']

# Get reports for patient 4
response = requests.get(
    'http://127.0.0.1:8000/api/reports/patient/4',
    headers={'Authorization': f'Bearer {token}'}
)
reports = response.json()
print(f"\nPatient 4 has {len(reports)} reports:")
for report in reports:
    print(f"  - Report ID: {report['id']}, Patient ID: {report['patient_id']}, Title: {report['title']}")
