"""
Authentication endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.schemas.schemas import LoginRequest, AuthResponse, UserCreate
from app.crud import crud
from app.core.security import create_access_token

router = APIRouter()


@router.post("/login", response_model=AuthResponse)
async def login(request: LoginRequest, db: Session = Depends(get_db)):
    """
    Login or register user with username
    """
    # Check if user exists
    user = crud.get_user_by_username(db, request.username)
    
    if not user:
        # Create new user
        user = crud.create_user(
            db, 
            UserCreate(username=request.username)
        )
        message = "User created successfully"
    else:
        # Update last login
        user = crud.update_user_last_login(db, user)
        message = "Login successful"
    
    # Create access token for technicians
    token = None
    if user.role == "Técnico":
        token = create_access_token(
            data={"sub": str(user.id), "role": user.role}
        )
    
    return AuthResponse(
        user_id=user.id,
        token=token,
        role=user.role,
        message=message
    )


@router.post("/register", response_model=AuthResponse)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user
    """
    # Check if user already exists
    existing_user = crud.get_user_by_username(db, user_data.username)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User with this username already exists"
        )
    
    # Create user
    user = crud.create_user(db, user_data)
    
    # Create access token for technicians
    token = None
    if user.role == "Técnico":
        token = create_access_token(
            data={"sub": str(user.id), "role": user.role}
        )
    
    return AuthResponse(
        user_id=user.id,
        token=token,
        role=user.role,
        message="Registration successful"
    )
