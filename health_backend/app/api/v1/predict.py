from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import Profile, Prediction
from ...schemas.health import PredictRequest, PredictResponse
from ...ml.predict import predict_diseases
from .deps import get_current_user

router = APIRouter(prefix="/predict", tags=["ML Prediction"])


@router.post("", response_model=PredictResponse)
async def predict(
    payload: PredictRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Load profile for age/gender/history if not provided
    profile_result = await db.execute(
        select(Profile).where(Profile.user_id == current_user.id)
    )
    profile = profile_result.scalar_one_or_none()

    age = payload.age
    gender = payload.gender
    medical_history = payload.medical_history or []

    if profile:
        if age is None and profile.date_of_birth:
            from datetime import date
            today = date.today()
            dob = profile.date_of_birth
            age = today.year - dob.year - (
                (today.month, today.day) < (dob.month, dob.day)
            )
        if gender is None and profile.gender:
            gender = profile.gender
        if not medical_history and profile.medical_conditions:
            medical_history = profile.medical_conditions or []

    # Run ML prediction
    result = predict_diseases(
        symptoms=[s.model_dump() for s in payload.symptoms],
        age=age,
        gender=gender,
        medical_history=medical_history,
    )

    # Persist prediction
    prediction = Prediction(
        user_id=current_user.id,
        results=result,
        model_version="v1.0",
    )
    db.add(prediction)
    await db.commit()

    return PredictResponse(
        predictions=result["predictions"],
        health_tips=result["health_tips"],
        model_version="v1.0",
    )


@router.get("/history", response_model=list[dict])
async def get_prediction_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import desc
    result = await db.execute(
        select(Prediction)
        .where(Prediction.user_id == current_user.id)
        .order_by(desc(Prediction.predicted_at))
        .limit(10)
    )
    preds = result.scalars().all()
    return [
        {
            "id": p.id,
            "predicted_at": p.predicted_at.isoformat(),
            "model_version": p.model_version,
            "top_disease": p.results["predictions"][0]["disease"]
            if p.results.get("predictions")
            else None,
        }
        for p in preds
    ]
