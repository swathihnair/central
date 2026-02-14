import requests

# Login as admin
print("Logging in...")
login_response = requests.post(
    'http://127.0.0.1:8000/api/auth/login',
    json={
        'email': 'admin@health.com',
        'password': 'admin123',
        'role': 'admin'
    }
)

if login_response.status_code != 200:
    print(f"Login failed: {login_response.text}")
    exit(1)

token = login_response.json()['access_token']
print(f"✅ Login successful! Token: {token[:20]}...")

# Test scanning Swathi's card
print("\nTesting card: 51E4B217 (Swathi H)")
scan_response = requests.post(
    'http://127.0.0.1:8000/api/rfid/scan',
    json={'card_uid': '51E4B217'},
    headers={'Authorization': f'Bearer {token}'}
)

print(f"Status Code: {scan_response.status_code}")
print(f"Response: {scan_response.json()}")

if scan_response.status_code == 200:
    patient = scan_response.json()
    print("\n✅ SUCCESS!")
    print(f"Patient: {patient['full_name']}")
    print(f"ID: {patient['patient_id']}")
    print(f"Email: {patient['email']}")
else:
    print(f"\n❌ FAILED: {scan_response.json()}")
