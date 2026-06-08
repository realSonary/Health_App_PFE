from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime


class UserRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None

    @field_validator("password")
    @classmethod
    def password_strength(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isdigit() for c in v):
            raise ValueError("Password must contain at least one digit")
        return v


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    email: str
    is_active: bool
    full_name: Optional[str] = None
    avatar_url: Optional[str] = None

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class RefreshRequest(BaseModel):
    refresh_token: str


class ProfileCreate(BaseModel):
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None  # ISO date YYYY-MM-DD
    gender: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    blood_type: Optional[str] = None
    medical_conditions: Optional[list[str]] = []
    allergies: Optional[list[str]] = []
    fcm_token: Optional[str] = None


class ProfileUpdate(ProfileCreate):
    pass


class ProfileOut(BaseModel):
    user_id: int
    full_name: Optional[str] = None
    date_of_birth: Optional[str] = None
    gender: Optional[str] = None
    weight_kg: Optional[float] = None
    height_cm: Optional[float] = None
    blood_type: Optional[str] = None
    medical_conditions: list[str] = []
    allergies: list[str] = []
    avatar_url: Optional[str] = None

    model_config = {"from_attributes": True}
