"""
Test login for all users
"""
import requests

API_URL = 'http://127.0.0.1:8000/api/auth/login'

print("\n" + "="*60)
print("TESTING LOGIN FOR ALL USERS")
print("="*60)

# Test credentials
test_users = [
    {'email': 'admin@health.com', 'password': 'admin123', 'role': 'admin'},
    {'email': 'doctor@health.com', 'password': 'password123', 'role': 'doctor'},
    {'email': 'patient@health.com', 'password': 'password123', 'role': 'patient'},
    {'email': 'swathi.h.2005@gmail.com', 'password': 'password123', 'role': 'patient'},
]

for user in test_users:
    print(f"\n{'='*60}")
    print(f"Testing: {user['role'].upper()} - {user['email']}")
    print(f"Password: {user['password']}")
    print("-" * 60)
    
    try:
        response = requests.post(
            API_URL,
            json=user,
            timeout=5
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ LOGIN SUCCESSFUL!")
            print(f"   Token: {data['access_token'][:50]}...")
            print(f"   Token Type: {data['token_type']}")
        else:
            print(f"❌ LOGIN FAILED!")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.json().get('detail', 'Unknown error')}")
    except requests.exceptions.ConnectionError:
        print(f"❌ CONNECTION ERROR!")
        print(f"   Backend not running on {API_URL}")
        print(f"   Start backend: python main.py")
        break
    except Exception as e:
        print(f"❌ ERROR: {e}")

print("\n" + "="*60)
print("TEST COMPLETE")
print("="*60 + "\n")
