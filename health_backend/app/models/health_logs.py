from datetime import datetime, date
from typing import Optional, Any
from sqlalchemy import (
    String, Integer, Boolean, DateTime, Date, Text, JSON,
    ForeignKey, Enum, Numeric, SmallInteger, func
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..core.database import Base


class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    full_name: Mapped[Optional[str]] = mapped_column(String(100))
    date_of_birth: Mapped[Optional[date]] = mapped_column(Date)
    gender: Mapped[Optional[str]] = mapped_column(Enum("male", "female", "other"))
    weight_kg: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    height_cm: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    blood_type: Mapped[Optional[str]] = mapped_column(String(5))
    medical_conditions: Mapped[Optional[Any]] = mapped_column(JSON, default=list)
    allergies: Mapped[Optional[Any]] = mapped_column(JSON, default=list)
    avatar_url: Mapped[Optional[str]] = mapped_column(String(500))
    fcm_token: Mapped[Optional[str]] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship("User", back_populates="profile")  # noqa: F821


class SymptomLog(Base):
    __tablename__ = "symptoms_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    symptoms: Mapped[Any] = mapped_column(JSON, nullable=False)  # [{name, severity}]
    notes: Mapped[Optional[str]] = mapped_column(Text)
    duration_hours: Mapped[Optional[float]] = mapped_column(Numeric(5, 1))
    body_temp_c: Mapped[Optional[float]] = mapped_column(Numeric(4, 1))
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())

    user: Mapped["User"] = relationship("User", back_populates="symptom_logs")  # noqa: F821


class Medication(Base):
    __tablename__ = "medications"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    dosage: Mapped[str] = mapped_column(String(100), nullable=False)
    frequency: Mapped[str] = mapped_column(
        Enum("once_daily", "twice_daily", "three_times_daily", "four_times_daily", "as_needed", "weekly"),
        nullable=False,
    )
    schedule_times: Mapped[Optional[Any]] = mapped_column(JSON, default=list)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[Optional[date]] = mapped_column(Date)
    notes: Mapped[Optional[str]] = mapped_column(Text)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now())

    user: Mapped["User"] = relationship("User", back_populates="medications")  # noqa: F821
    logs: Mapped[list["MedicationLog"]] = relationship(
        "MedicationLog", back_populates="medication", cascade="all, delete-orphan"
    )


class MedicationLog(Base):
    __tablename__ = "medication_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    medication_id: Mapped[int] = mapped_column(Integer, ForeignKey("medications.id", ondelete="CASCADE"), nullable=False)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    scheduled_time: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    taken_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    status: Mapped[str] = mapped_column(
        Enum("taken", "missed", "skipped"), default="missed", nullable=False
    )
    notes: Mapped[Optional[str]] = mapped_column(Text)

    medication: Mapped["Medication"] = relationship("Medication", back_populates="logs")


class WaterLog(Base):
    __tablename__ = "water_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    amount_ml: Mapped[int] = mapped_column(Integer, nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="water_logs")  # noqa: F821


class SleepLog(Base):
    __tablename__ = "sleep_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    sleep_start: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    sleep_end: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    quality: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 1-5
    notes: Mapped[Optional[str]] = mapped_column(Text)

    user: Mapped["User"] = relationship("User", back_populates="sleep_logs")  # noqa: F821

    @property
    def duration_hours(self) -> float:
        return (self.sleep_end - self.sleep_start).total_seconds() / 3600


class CaloriesLog(Base):
    __tablename__ = "calories_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    logged_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    meal_type: Mapped[str] = mapped_column(
        Enum("breakfast", "lunch", "dinner", "snack"), nullable=False
    )
    food_name: Mapped[str] = mapped_column(String(200), nullable=False)
    calories: Mapped[int] = mapped_column(Integer, nullable=False)
    protein_g: Mapped[Optional[float]] = mapped_column(Numeric(6, 2))
    carbs_g: Mapped[Optional[float]] = mapped_column(Numeric(6, 2))
    fat_g: Mapped[Optional[float]] = mapped_column(Numeric(6, 2))

    user: Mapped["User"] = relationship("User", back_populates="calories_logs")  # noqa: F821


class HealthScore(Base):
    __tablename__ = "health_scores"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    scored_at: Mapped[date] = mapped_column(Date, nullable=False)
    overall_score: Mapped[float] = mapped_column(Numeric(5, 2), nullable=False)
    sleep_score: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    water_score: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    medication_score: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))
    symptom_score: Mapped[Optional[float]] = mapped_column(Numeric(5, 2))

    user: Mapped["User"] = relationship("User", back_populates="health_scores")  # noqa: F821


class Prediction(Base):
    __tablename__ = "predictions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    symptom_log_id: Mapped[Optional[int]] = mapped_column(
        Integer, ForeignKey("symptoms_logs.id", ondelete="SET NULL")
    )
    predicted_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    results: Mapped[Any] = mapped_column(JSON, nullable=False)
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)

    user: Mapped["User"] = relationship("User", back_populates="predictions")  # noqa: F821
