import requests
import json

# Test AI endpoint with patient_id
url = "http://127.0.0.1:8000/api/ai/chat"
data = {
    "message": "What is my blood pressure?",
    "history": [],
    "patient_id": 4
}

print("Testing AI endpoint...")
print(f"Request: {json.dumps(data, indent=2)}")

response = requests.post(url, json=data)
print(f"\nStatus Code: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}")
