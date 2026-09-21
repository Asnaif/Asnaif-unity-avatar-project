import os
import sys
sys.path.append(r'c:\Flutter\InterPrep\python_server')
from firebase_admin_instance import get_firestore_instance

db = get_firestore_instance()

user_id = "uizXxsgpVUduBtmirxM2bHwmFi03"
print(f"--- Detail Scan for User {user_id} ---")
sessions_doc = db.collection("sessions").document(user_id).get()
if sessions_doc.exists:
    sd = sessions_doc.to_dict()
    sessions = sd.get('sessions', [])
    vapi = sd.get('vapiInterviews', [])
    
    completed_regs = [s for s in sessions if s.get('status') == 'completed']
    print(f"Completed regular sessions: {len(completed_regs)}")
    for i, s in enumerate(completed_regs):
        print(f"Completed Reg Session {i}: {s}")
        
    print(f"\nTotal vapiInterviews: {len(vapi)}")
    if vapi:
        first_vapi = vapi[0]
        vapi_id = first_vapi.get('sessionId')
        print(f"Looking up vapi_interviews doc with ID: {vapi_id}")
        vapi_doc = db.collection("vapi_interviews").document(vapi_id).get()
        if vapi_doc.exists:
            print(f"Vapi Interview Doc Content: {vapi_doc.to_dict()}")
        else:
            print("Vapi Interview Doc NOT found in collection 'vapi_interviews'!")
            # Let's list a few document IDs in vapi_interviews to see what is there
            print("Listing first 5 doc IDs in vapi_interviews collection:")
            for doc in db.collection("vapi_interviews").limit(5).stream():
                print(f"  Doc ID: {doc.id}")
else:
    print("No sessions document found.")



