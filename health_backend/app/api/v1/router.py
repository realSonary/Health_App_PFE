from fastapi import APIRouter
from .auth import router as auth_router
from .profile import router as profile_router
from .symptoms import router as symptoms_router
from .water import router as water_router
from .sleep import router as sleep_router
from .medications import router as medications_router
from .analytics import router as analytics_router
from .predict import router as predict_router

api_router = APIRouter()

api_router.include_router(auth_router)
api_router.include_router(profile_router)
api_router.include_router(symptoms_router)
api_router.include_router(water_router)
api_router.include_router(sleep_router)
api_router.include_router(medications_router)
api_router.include_router(analytics_router)
api_router.include_router(predict_router)
