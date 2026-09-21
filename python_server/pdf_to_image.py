import os
from pdf2image import convert_from_path
from firebase_admin_instance import get_firestore_instance, get_storage_bucket
from firebase_admin import firestore

db = get_firestore_instance()
bucket = get_storage_bucket()

def upload_to_firebase_storage(local_file_path, remote_file_path):
    """Upload file to Firebase Storage and return public URL"""
    blob = bucket.blob(remote_file_path)
    blob.upload_from_filename(local_file_path)
    blob.make_public()
    return blob.public_url

def update_firestore_slides(user_id, image_urls):
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

def pdf_first_page_to_image(pdf_path, output_dir, user_id):
    """
    Convert first page of PDF to PNG image and upload to Firebase.
    For presentation mode, this provides a visual reference.
    """
    try:
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        filename = os.path.basename(pdf_path).split('.')[0]
        # Sanitize filename: remove/replace spaces and special characters
        sanitized_filename = filename.replace(' ', '_').replace('%', '_').replace('#', '_').replace('?', '_').replace('&', '_')
        
        # Convert first page of PDF to image
        # DPI 200 for good quality
        images = convert_from_path(pdf_path, first_page=1, last_page=1, dpi=200)
        
        if not images:
            print("⚠️ No pages found in PDF")
            return None
        
        # Save first page as PNG
        image_path = os.path.join(output_dir, f"{sanitized_filename}_page1.png")
        images[0].save(image_path, 'PNG')
        
        # Upload to Firebase Storage
        remote_path = f"images/{sanitized_filename}/page1.png"
        image_url = upload_to_firebase_storage(image_path, remote_path)
        
        # Update Firestore with single image URL
        update_firestore_slides(user_id, [image_url])
        
        # Cleanup
        os.remove(image_path)
        
        print(f"✅ PDF first page converted and uploaded: {image_url}")
        return image_url
        
    except Exception as e:
        print(f"❌ Error converting PDF to image: {str(e)}")
        # If pdf2image fails, return None (slides won't be available)
        return None


def pdf_all_pages_to_images(pdf_path, output_dir, user_id):
    """
    Convert ALL pages of PDF to PNG images and upload to Firebase.
    Similar to PPTX conversion which creates images for all slides.
    """
    try:
        if not os.path.exists(output_dir):
            os.makedirs(output_dir)

        filename = os.path.basename(pdf_path).split('.')[0]
        sanitized_filename = filename.replace(' ', '_').replace('%', '_').replace('#', '_').replace('?', '_').replace('&', '_')
        
        # Convert ALL pages of PDF to images
        images = convert_from_path(pdf_path, dpi=200)
        
        if not images:
            print("⚠️ No pages found in PDF")
            return None
        
        image_urls = []
        for idx, image in enumerate(images, start=1):
            # Save each page as PNG
            image_path = os.path.join(output_dir, f"{sanitized_filename}_page{idx}.png")
            image.save(image_path, 'PNG')
            
            # Upload to Firebase Storage
            remote_path = f"images/{sanitized_filename}/page{idx}.png"
            image_url = upload_to_firebase_storage(image_path, remote_path)
            image_urls.append(image_url)
            
            # Cleanup local file
            os.remove(image_path)
        
        # Update Firestore with all image URLs
        update_firestore_slides(user_id, image_urls)
        
        print(f"✅ PDF {len(images)} pages converted and uploaded: {len(image_urls)} images")
        return image_urls
        
    except Exception as e:
        print(f"❌ Error converting PDF to images: {str(e)}")
        return None