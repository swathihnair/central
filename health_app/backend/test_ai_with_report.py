import requests
import json

# Test AI endpoint asking about report analysis
url = "http://127.0.0.1:8000/api/ai/chat"
data = {
    "message": "Analyze my blood test report",
    "history": [],
    "patient_id": 4
}

print("Testing AI with report analysis request...")
print(f"Request: {json.dumps(data, indent=2)}")

response = requests.post(url, json=data)
print(f"\nStatus Code: {response.status_code}")
result = response.json()
print(f"\nAI Response:")
print("=" * 60)
print(result['response'])
print("=" * 60)
