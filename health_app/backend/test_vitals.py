import requests
import json

# Test vitals endpoint
url = "http://127.0.0.1:8000/api/reports/patient/4/vitals"

print("Testing vitals endpoint...")
response = requests.get(url)
print(f"Status Code: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
