import requests
import json

print("=" * 60)
print("TESTING API LOGIN")
print("=" * 60)

# Test admin login
url = "http://127.0.0.1:8000/api/auth/login"

test_credentials = [
    ("admin@health.com", "admin123", "admin"),
    ("doctor@health.com", "doctor123", "doctor"),
    ("patient@health.com", "patient123", "patient"),
]

for email, password, role in test_credentials:
    print(f"\n🔐 Testing: {email} / {password} / {role}")
    
    data = {
        "email": email,
        "password": password,
        "role": role
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ SUCCESS!")
            print(f"   Token: {result.get('access_token', 'N/A')[:20]}...")
        else:
            print(f"   ❌ FAILED!")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"   ❌ ERROR: {e}")

print("\n" + "=" * 60)
print("SUMMARY")
print("=" * 60)
print("\nIf all three show ✅ SUCCESS, login is working!")
print("If any show ❌ FAILED, there's an issue with that account.")
