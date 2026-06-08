from datetime import datetime
from typing import Optional
from sqlalchemy import String, Boolean, DateTime, func, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    # Relationships
    profile: Mapped[Optional["Profile"]] = relationship(  # noqa: F821
        "Profile", back_populates="user", uselist=False, cascade="all, delete-orphan"
    )
    symptom_logs: Mapped[list["SymptomLog"]] = relationship(  # noqa: F821
        "SymptomLog", back_populates="user", cascade="all, delete-orphan"
    )
    medications: Mapped[list["Medication"]] = relationship(  # noqa: F821
        "Medication", back_populates="user", cascade="all, delete-orphan"
    )
    water_logs: Mapped[list["WaterLog"]] = relationship(  # noqa: F821
        "WaterLog", back_populates="user", cascade="all, delete-orphan"
    )
    sleep_logs: Mapped[list["SleepLog"]] = relationship(  # noqa: F821
        "SleepLog", back_populates="user", cascade="all, delete-orphan"
    )
    calories_logs: Mapped[list["CaloriesLog"]] = relationship(  # noqa: F821
        "CaloriesLog", back_populates="user", cascade="all, delete-orphan"
    )
    health_scores: Mapped[list["HealthScore"]] = relationship(  # noqa: F821
        "HealthScore", back_populates="user", cascade="all, delete-orphan"
    )
    predictions: Mapped[list["Prediction"]] = relationship(  # noqa: F821
        "Prediction", back_populates="user", cascade="all, delete-orphan"
    )
