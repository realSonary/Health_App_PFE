from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from datetime import date, timedelta

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import WaterLog, SleepLog, SymptomLog, MedicationLog, HealthScore
from .deps import get_current_user

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("")
async def get_analytics(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    week_ago = today - timedelta(days=7)

    # Water last 7 days
    water_result = await db.execute(
        select(
            func.date(WaterLog.logged_at).label("day"),
            func.sum(WaterLog.amount_ml).label("total"),
        )
        .where(WaterLog.user_id == current_user.id, func.date(WaterLog.logged_at) >= week_ago)
        .group_by(func.date(WaterLog.logged_at))
        .order_by("day")
    )
    water_rows = {str(r.day): int(r.total) for r in water_result.all()}

    # Sleep last 7 days
    sleep_result = await db.execute(
        select(SleepLog)
        .where(SleepLog.user_id == current_user.id, func.date(SleepLog.sleep_start) >= week_ago)
        .order_by(SleepLog.sleep_start)
    )
    sleep_logs = sleep_result.scalars().all()
    sleep_by_day = {
        str(l.sleep_start.date()): round(l.duration_hours, 1)
        for l in sleep_logs
    }

    # Build 7-day series
    days = [(today - timedelta(days=i)) for i in range(6, -1, -1)]
    water_7d = [water_rows.get(str(d), 0) for d in days]
    sleep_7d = [sleep_by_day.get(str(d), 0) for d in days]

    # Health scores last 7 days
    score_result = await db.execute(
        select(HealthScore)
        .where(HealthScore.user_id == current_user.id, HealthScore.scored_at >= week_ago)
        .order_by(HealthScore.scored_at)
    )
    scores_by_day = {
        str(s.scored_at): float(s.overall_score)
        for s in score_result.scalars().all()
    }
    health_scores_7d = [scores_by_day.get(str(d), 60.0) for d in days]

    # Symptom frequency
    symptom_result = await db.execute(
        select(SymptomLog)
        .where(
            SymptomLog.user_id == current_user.id,
            func.date(SymptomLog.logged_at) >= (today - timedelta(days=30)),
        )
    )
    symptom_logs = symptom_result.scalars().all()
    freq: dict[str, int] = {}
    for log in symptom_logs:
        for s in (log.symptoms or []):
            name = s.get("name", "Unknown")
            freq[name] = freq.get(name, 0) + 1

    top_symptoms = dict(
        sorted(freq.items(), key=lambda x: x[1], reverse=True)[:5]
    )

    # Medication adherence
    med_result = await db.execute(
        select(MedicationLog).where(MedicationLog.user_id == current_user.id)
    )
    med_logs = med_result.scalars().all()
    adherence = 100.0
    if med_logs:
        taken = sum(1 for l in med_logs if l.status == "taken")
        adherence = round(taken / len(med_logs) * 100, 1)

    return {
        "water_7d": water_7d,
        "sleep_7d": sleep_7d,
        "health_scores_7d": health_scores_7d,
        "symptom_frequency": top_symptoms,
        "medication_adherence": adherence,
        "days": [str(d) for d in days],
    }
