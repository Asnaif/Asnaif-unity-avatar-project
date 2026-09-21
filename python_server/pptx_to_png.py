import os
import comtypes.client
from firebase_admin import firestore
import shutil
from firebase_admin_instance import get_firestore_instance, get_storage_bucket
import pythoncom

db = get_firestore_instance()
bucket = get_storage_bucket()

def upload_to_firebase_storage(local_file_path, remote_file_path):
    """Upload file to Firebase Storage and return public URL"""
    try:
        blob = bucket.blob(remote_file_path)
        blob.upload_from_filename(local_file_path)
        blob.make_public()
        url = blob.public_url
        print(f"✅ Uploaded to Firebase: {url}")
        return url
    except Exception as e:
        print(f"❌ Failed to upload to Firebase: {str(e)}")
        raise

def update_firestore(user_id, image_urls):
    """Update Firestore with slide image URLs"""
    try:
        print(f"📝 Updating Firestore for user: {user_id}")
        print(f"📝 Total image URLs to save: {len(image_urls)}")
        doc_ref = db.collection("slideImages").document(user_id)
        doc_ref.set({"imageLinks": image_urls}, merge=False)
        print(f"✅ Firestore updated successfully in 'slideImages' collection")
        print(f"✅ Document ID: {user_id}, Field: imageLinks, Count: {len(image_urls)}")
    except Exception as e:
        print(f"❌ Failed to update Firestore: {str(e)}")
        import traceback
        traceback.print_exc()
        raise

def pptx_to_pngs_and_upload(pptx_path, output_dir, user_id):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    pythoncom.CoInitialize()

    powerpoint = comtypes.client.CreateObject("Powerpoint.Application")
    powerpoint.Visible = 1
    try:
        ppt = powerpoint.Presentations.Open(pptx_path)
        filename = os.path.basename(pptx_path).split('.')[0]
        # Sanitize filename: remove/replace spaces and special characters
        sanitized_filename = filename.replace(' ', '_').replace('%', '_').replace('#', '_').replace('?', '_').replace('&', '_')
        image_urls = []

        for i, slide in enumerate(ppt.Slides):
            image_path = os.path.join(output_dir, f"slide_{i+1}.png")
            slide.Export(image_path, "PNG")

            # Define remote path with sanitized filename directory
            remote_path = f"images/{sanitized_filename}/slide_{i+1}.png"
            image_url = upload_to_firebase_storage(image_path, remote_path)
            image_urls.append(image_url)

            os.remove(image_path)

        ppt.Close()
        powerpoint.Quit()

        # Update Firestore with all slide URLs
        if image_urls:
            print(f"📤 Saving {len(image_urls)} slide URLs to Firestore...")
            update_firestore(user_id, image_urls)
            print(f"✅ All slides saved to Firestore successfully")
        else:
            print("⚠️ Warning: No image URLs to save to Firestore")
    finally:
        pythoncom.CoUninitialize()
        shutil.rmtree(output_dir)

# Example usage:
# pptx_path = "D:\projects\FYP\prepvrse\python_server\Lec.pptx"
# output_dir = "D:\projects\FYP\prepvrse\python_server\\temp"
# user_id = "LZgH1ZyEn3Q3yy8mEzAINQrNwTN2"
# pptx_to_pngs_and_upload(pptx_path, output_dir, user_id)
