import os
import logging
from backend.config import settings

logger = logging.getLogger("PortfolioAI.Firebase")

HAS_FIREBASE = False
try:
    import firebase_admin
    from firebase_admin import credentials, storage
    HAS_FIREBASE = True
except ImportError:
    pass

class FirebaseService:
    def __init__(self):
        self.mock = settings.FIREBASE_MOCK or not HAS_FIREBASE
        self.bucket = None
        
        if not self.mock and settings.FIREBASE_CREDENTIALS_PATH:
            try:
                cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
                firebase_admin.initialize_app(cred, {
                    'storageBucket': f"{settings.PROJECT_NAME.lower().replace(' ', '-')}.appspot.com"
                })
                self.bucket = storage.bucket()
                logger.info("Real Firebase Storage initialized successfully.")
            except Exception as e:
                logger.error(f"Failed to initialize Firebase Storage: {e}. Using local storage.")
                self.mock = True

    def upload_file(self, folder: str, filename: str, file_bytes: bytes) -> str:
        """
        Uploads file bytes to Firebase Storage or local filesystem folder.
        Returns a download link / path.
        """
        # Compress image if it's an image file
        lower_filename = filename.lower()
        if any(lower_filename.endswith(ext) for ext in [".png", ".jpg", ".jpeg", ".webp"]):
            try:
                from PIL import Image, ImageOps
                import io
                img = Image.open(io.BytesIO(file_bytes))
                
                # Check target folder for photo vs screenshots
                if folder in ["profiles", "avatars", "profile_photos"]:
                    # Crop to exactly square for avatars
                    img = ImageOps.fit(img, (512, 512), Image.Resampling.LANCZOS)
                else:
                    # Fits screenshot to reasonable dimensions
                    img.thumbnail((1200, 1200), Image.Resampling.LANCZOS)
                
                # Convert to RGB if transparency exists
                if img.mode in ("RGBA", "P"):
                    background = Image.new("RGB", img.size, (255, 255, 255))
                    background.paste(img, mask=img.split()[3] if img.mode == "RGBA" else None)
                    img = background
                
                out_buf = io.BytesIO()
                img.save(out_buf, format="JPEG", quality=75, optimize=True)
                file_bytes = out_buf.getvalue()
                
                # Replace extension with .jpg
                base_name = os.path.splitext(filename)[0]
                filename = f"{base_name}.jpg"
            except Exception as e:
                logger.error(f"Image processing compression failed: {e}")

        if self.mock:
            dest_dir = os.path.join(settings.LOCAL_STORAGE_DIR, folder)
            os.makedirs(dest_dir, exist_ok=True)
            dest_path = os.path.join(dest_dir, filename)
            with open(dest_path, "wb") as f:
                f.write(file_bytes)
            # URL route served statically by FastAPI main app
            return f"/api/v1/static/{folder}/{filename}"
        else:
            try:
                blob = self.bucket.blob(f"{folder}/{filename}")
                blob.upload_from_string(file_bytes)
                blob.make_public()
                return blob.public_url
            except Exception as e:
                logger.error(f"Failed real Firebase upload: {e}. Falling back to local storage.")
                # Fallback locally
                dest_dir = os.path.join(settings.LOCAL_STORAGE_DIR, folder)
                os.makedirs(dest_dir, exist_ok=True)
                dest_path = os.path.join(dest_dir, filename)
                with open(dest_path, "wb") as f:
                    f.write(file_bytes)
                return f"/api/v1/static/{folder}/{filename}"

firebase_service = FirebaseService()
