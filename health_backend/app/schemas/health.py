from pydantic import BaseModel, field_validator
from typing import Optional, Any
from datetime import datetime


# ── Symptoms ──────────────────────────────────────────────
class SymptomItem(BaseModel):
    name: str
    severity: int  # 1–10

    @field_validator("severity")
    @classmethod
    def validate_severity(cls, v: int) -> int:
        if not 1 <= v <= 10:
            raise ValueError("Severity must be between 1 and 10")
        return v


class SymptomLogCreate(BaseModel):
    symptoms: list[SymptomItem]
    notes: Optional[str] = None
    duration_hours: Optional[float] = None
    body_temp_c: Optional[float] = None


class SymptomLogOut(BaseModel):
    id: int
    logged_at: datetime
    symptoms: list[dict]
    notes: Optional[str] = None
    body_temp_c: Optional[float] = None

    model_config = {"from_attributes": True}


# ── Water ──────────────────────────────────────────────────
class WaterLogCreate(BaseModel):
    amount_ml: int

    @field_validator("amount_ml")
    @classmethod
    def validate_amount(cls, v: int) -> int:
        if v <= 0 or v > 5000:
            raise ValueError("Amount must be between 1 and 5000 ml")
        return v


class WaterLogOut(BaseModel):
    id: int
    logged_at: datetime
    amount_ml: int

    model_config = {"from_attributes": True}


class WaterDaySummary(BaseModel):
    date: str
    total_ml: int
    logs: list[WaterLogOut]


# ── Sleep ──────────────────────────────────────────────────
class SleepLogCreate(BaseModel):
    sleep_start: datetime
    sleep_end: datetime
    quality: int  # 1–5
    notes: Optional[str] = None

    @field_validator("quality")
    @classmethod
    def validate_quality(cls, v: int) -> int:
        if not 1 <= v <= 5:
            raise ValueError("Quality must be between 1 and 5")
        return v

    @field_validator("sleep_end")
    @classmethod
    def validate_end_after_start(cls, v: datetime, info: Any) -> datetime:
        if "sleep_start" in info.data and v <= info.data["sleep_start"]:
            raise ValueError("sleep_end must be after sleep_start")
        return v


class SleepLogOut(BaseModel):
    id: int
    sleep_start: datetime
    sleep_end: datetime
    duration_hours: float
    quality: int
    notes: Optional[str] = None

    model_config = {"from_attributes": True}


# ── Medications ───────────────────────────────────────────
class MedicationCreate(BaseModel):
    name: str
    dosage: str
    frequency: str
    schedule_times: Optional[list[str]] = []
    start_date: str  # YYYY-MM-DD
    end_date: Optional[str] = None
    notes: Optional[str] = None


class MedicationOut(BaseModel):
    id: int
    name: str
    dosage: str
    frequency: str
    schedule_times: list[str] = []
    start_date: str
    end_date: Optional[str] = None
    notes: Optional[str] = None
    is_active: bool

    model_config = {"from_attributes": True}


class MedicationLogCreate(BaseModel):
    scheduled_time: datetime
    status: str  # taken | missed | skipped
    taken_at: Optional[datetime] = None
    notes: Optional[str] = None


# ── Calories ──────────────────────────────────────────────
class CaloriesLogCreate(BaseModel):
    meal_type: str
    food_name: str
    calories: int
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None


class CaloriesLogOut(BaseModel):
    id: int
    logged_at: datetime
    meal_type: str
    food_name: str
    calories: int
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None

    model_config = {"from_attributes": True}


# ── Prediction ───────────────────────────────────────────
class PredictRequest(BaseModel):
    symptoms: list[SymptomItem]
    age: Optional[int] = None
    gender: Optional[str] = None
    medical_history: Optional[list[str]] = []


class PredictionResult(BaseModel):
    disease: str
    confidence: float
    actions: list[str]


class PredictResponse(BaseModel):
    predictions: list[PredictionResult]
    health_tips: list[str]
    model_version: str
