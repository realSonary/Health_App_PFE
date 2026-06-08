from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import List
import json


class Settings(BaseSettings):
    # App
    APP_NAME: str = "HealthAI"
    DEBUG: bool = False
    API_V1_PREFIX: str = "/api/v1"

    # Database
    DATABASE_URL: str = "mysql+aiomysql://root:password@localhost:3306/healthai_db"

    # JWT
    SECRET_KEY: str = "change-this-super-secret-key-in-production-min-32"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS
    ALLOWED_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8080"]

    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = "./firebase-credentials.json"

    # Email
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
