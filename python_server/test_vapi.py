"""Quick test to check VAPI account and assistant status"""
import requests
from key import VapiPrivateKey, VapiPublicKey

headers = {
    "Authorization": f"Bearer {VapiPrivateKey}",
    "Content-Type": "application/json"
}

print("=== VAPI Account Check ===")
print(f"Public Key: {VapiPublicKey[:10]}...")
print(f"Private Key: {VapiPrivateKey[:10]}...")

# List assistants
print("\n--- Listing Assistants ---")
r = requests.get("https://api.vapi.ai/assistant", headers=headers)
print(f"Status: {r.status_code}")

if r.status_code == 200:
    data = r.json()
    if isinstance(data, list):
        print(f"Total assistants: {len(data)}")
        for a in data[:5]:
            print(f"  - ID: {a.get('id')}")
            print(f"    Name: {a.get('name')}")
            print(f"    Model: {a.get('model', {}).get('model', 'N/A')}")
            print(f"    Voice: {a.get('voice', {}).get('provider', 'N/A')}")
    else:
        print(f"Response: {data}")
else:
    print(f"Error: {r.text[:500]}")

# Check account/org
print("\n--- Checking Calls ---")
r2 = requests.get("https://api.vapi.ai/call?limit=3", headers=headers)
print(f"Calls Status: {r2.status_code}")
if r2.status_code == 200:
    calls = r2.json()
    if isinstance(calls, list):
        print(f"Recent calls: {len(calls)}")
        for c in calls[:3]:
            print(f"  - Call ID: {c.get('id')}")
            print(f"    Status: {c.get('status')}")
            print(f"    EndedReason: {c.get('endedReason', 'N/A')}")
            print(f"    Duration: {c.get('duration', 'N/A')}s")
    else:
        print(f"Response: {calls}")
else:
    print(f"Error: {r2.text[:500]}")
