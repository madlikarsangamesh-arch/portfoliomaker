import hmac
import hashlib
import time
import base64
import json
from typing import Optional
from backend.config import settings

def hash_password(password: str) -> str:
    """
    Returns a secure salt-hashed password using PBKDF2-HMAC-SHA256.
    """
    salt = b"portfolio_ai_secure_salt_value"
    pwd_bytes = password.encode('utf-8')
    key = hashlib.pbkdf2_hmac('sha256', pwd_bytes, salt, 100000)
    return base64.b64encode(key).decode('utf-8')

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return hash_password(plain_password) == hashed_password

def create_access_token(user_id: str, email: str, role: str = "user") -> str:
    """
    Generates a secure, signed JWT-like access token using HMAC-SHA256.
    """
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": user_id,
        "email": email,
        "role": role,
        "exp": int(time.time()) + (settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    }
    
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode('utf-8')).decode('utf-8').rstrip('=')
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode('utf-8')).decode('utf-8').rstrip('=')
    
    signature_base = f"{header_b64}.{payload_b64}".encode('utf-8')
    signature = hmac.new(settings.SECRET_KEY.encode('utf-8'), signature_base, hashlib.sha256).digest()
    signature_b64 = base64.urlsafe_b64encode(signature).decode('utf-8').rstrip('=')
    
    return f"{header_b64}.{payload_b64}.{signature_b64}"

def verify_access_token(token: str) -> Optional[dict]:
    """
    Verifies the HMAC-SHA256 token and returns the payload if valid.
    """
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return None
            
        header_b64, payload_b64, signature_b64 = parts
        
        # Verify signature
        signature_base = f"{header_b64}.{payload_b64}".encode('utf-8')
        expected_signature = hmac.new(settings.SECRET_KEY.encode('utf-8'), signature_base, hashlib.sha256).digest()
        expected_signature_b64 = base64.urlsafe_b64encode(expected_signature).decode('utf-8').rstrip('=')
        
        if not hmac.compare_digest(signature_b64, expected_signature_b64):
            return None
            
        # Decode payload
        # Pad base64 payload if needed
        padding = 4 - (len(payload_b64) % 4)
        if padding != 4:
            payload_b64 += "=" * padding
            
        payload_bytes = base64.urlsafe_b64decode(payload_b64)
        payload = json.loads(payload_bytes.decode('utf-8'))
        
        # Check expiration
        if int(time.time()) > payload.get("exp", 0):
            return None
            
        return payload
    except Exception:
        return None
