from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...core.security import hash_password, verify_password, create_access_token
from ...models.user import User
from ...models.health_logs import Profile
from ...schemas.auth import (
    UserRegister,
    UserLogin,
    TokenResponse,
    UserOut,
    ProfileCreate,
    ProfileOut,
    ProfileUpdate,
)
from .deps import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(payload: UserRegister, db: AsyncSession = Depends(get_db)):
    # Check duplicate email
    result = await db.execute(select(User).where(User.email == payload.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = User(
        email=payload.email,
        hashed_password=hash_password(payload.password),
    )
    db.add(user)
    await db.flush()  # get user.id before commit

    # Create blank profile
    profile = Profile(
        user_id=user.id,
        full_name=payload.full_name,
    )
    db.add(profile)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user=UserOut(
            id=user.id,
            email=user.email,
            is_active=user.is_active,
            full_name=payload.full_name,
        ),
    )


@router.post("/login", response_model=TokenResponse)
async def login(payload: UserLogin, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if not user or not verify_password(payload.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is disabled",
        )

    # Load profile for full_name
    profile_result = await db.execute(
        select(Profile).where(Profile.user_id == user.id)
    )
    profile = profile_result.scalar_one_or_none()

    token = create_access_token(user.id)
    return TokenResponse(
        access_token=token,
        user=UserOut(
            id=user.id,
            email=user.email,
            is_active=user.is_active,
            full_name=profile.full_name if profile else None,
            avatar_url=profile.avatar_url if profile else None,
        ),
    )


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return UserOut(
        id=current_user.id,
        email=current_user.email,
        is_active=current_user.is_active,
    )
