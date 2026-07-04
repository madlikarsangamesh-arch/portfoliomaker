from fastapi import APIRouter, HTTPException, Depends
from backend.models.schemas import UserLogin, UserRegister, UserResponse
from backend.repositories.user_repository import user_repository
from backend.auth.security import hash_password, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=UserResponse)
def register(user_data: UserRegister):
    try:
        # Check if user already exists
        existing = user_repository.get_by_email(user_data.email)
        if existing:
            raise HTTPException(status_code=400, detail="Email already registered")
            
        hashed = hash_password(user_data.password)
        import uuid
        user_id = f"usr_{uuid.uuid4().hex[:12]}"
        
        user = user_repository.create(
            user_id=user_id,
            email=user_data.email,
            password_hash=hashed,
            full_name=user_data.full_name
        )
        
        token = create_access_token(user["id"], user["email"], user["role"])
        return UserResponse(
            id=user["id"],
            email=user["email"],
            full_name=user["full_name"],
            role=user["role"],
            token=token
        )
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.post("/login", response_model=UserResponse)
def login(user_data: UserLogin):
    user = user_repository.get_by_email(user_data.email)
    if not user or not verify_password(user_data.password, user["password_hash"]):
        raise HTTPException(status_code=400, detail="Invalid email or password")
        
    token = create_access_token(user["id"], user["email"], user["role"])
    return UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        role=user["role"],
        token=token
    )

@router.post("/google", response_model=UserResponse)
def google_sign_in(payload: dict):
    """
    Mock Google sign-in endpoint. Automatically registers or logins user.
    """
    email = payload.get("email")
    full_name = payload.get("full_name", "Google User")
    
    if not email:
        raise HTTPException(status_code=400, detail="Invalid email payload")
        
    user = user_repository.get_by_email(email)
    if not user:
        import uuid
        user_id = f"usr_{uuid.uuid4().hex[:12]}"
        # Store dummy password hash for oauth users
        dummy_hash = hash_password(uuid.uuid4().hex)
        user = user_repository.create(
            user_id=user_id,
            email=email,
            password_hash=dummy_hash,
            full_name=full_name
        )
        
    token = create_access_token(user["id"], user["email"], user["role"])
    return UserResponse(
        id=user["id"],
        email=user["email"],
        full_name=user["full_name"],
        role=user["role"],
        token=token
    )
