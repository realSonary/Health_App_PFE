from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import Profile
from ...schemas.auth import ProfileCreate, ProfileUpdate, ProfileOut
from .deps import get_current_user

router = APIRouter(prefix="/profile", tags=["Profile"])


async def _get_or_create_profile(user: User, db: AsyncSession) -> Profile:
    result = await db.execute(select(Profile).where(Profile.user_id == user.id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = Profile(user_id=user.id)
        db.add(profile)
        await db.flush()
    return profile


def _build_profile_out(profile: Profile) -> ProfileOut:
    return ProfileOut(
        user_id=profile.user_id,
        full_name=profile.full_name,
        date_of_birth=(
            str(profile.date_of_birth) if profile.date_of_birth else None
        ),
        gender=profile.gender,
        weight_kg=float(profile.weight_kg) if profile.weight_kg else None,
        height_cm=float(profile.height_cm) if profile.height_cm else None,
        blood_type=profile.blood_type,
        medical_conditions=profile.medical_conditions or [],
        allergies=profile.allergies or [],
        avatar_url=profile.avatar_url,
    )


@router.get("", response_model=ProfileOut)
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_or_create_profile(current_user, db)
    return _build_profile_out(profile)


@router.post("", response_model=ProfileOut, status_code=status.HTTP_201_CREATED)
async def create_profile(
    payload: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_or_create_profile(current_user, db)
    _apply_profile_fields(profile, payload)
    await db.commit()
    await db.refresh(profile)
    return _build_profile_out(profile)


@router.put("", response_model=ProfileOut)
async def update_profile(
    payload: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await _get_or_create_profile(current_user, db)
    _apply_profile_fields(profile, payload)
    await db.commit()
    await db.refresh(profile)
    return _build_profile_out(profile)


def _apply_profile_fields(profile: Profile, payload: ProfileCreate) -> None:
    from datetime import date as date_type

    if payload.full_name is not None:
        profile.full_name = payload.full_name
    if payload.date_of_birth is not None:
        try:
            profile.date_of_birth = date_type.fromisoformat(payload.date_of_birth)
        except ValueError:
            pass
    if payload.gender is not None:
        profile.gender = payload.gender
    if payload.weight_kg is not None:
        profile.weight_kg = payload.weight_kg
    if payload.height_cm is not None:
        profile.height_cm = payload.height_cm
    if payload.blood_type is not None:
        profile.blood_type = payload.blood_type
    if payload.medical_conditions is not None:
        profile.medical_conditions = payload.medical_conditions
    if payload.allergies is not None:
        profile.allergies = payload.allergies
    if payload.fcm_token is not None:
        profile.fcm_token = payload.fcm_token
