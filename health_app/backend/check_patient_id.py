import requests

# Login as patient
response = requests.post(
    'http://127.0.0.1:8000/api/auth/login',
    json={'email': 'patient@health.com', 'password': 'patient123', 'role': 'patient'}
)
token = response.json()['access_token']

# Get user info
response = requests.get(
    'http://127.0.0.1:8000/api/auth/me',
    headers={'Authorization': f'Bearer {token}'}
)
user = response.json()
print(f"Patient ID: {user['id']}")
print(f"Patient Name: {user['full_name']}")
