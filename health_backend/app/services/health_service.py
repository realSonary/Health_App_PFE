"""
Health score calculation and personalized tips engine.
Called periodically (e.g., daily via Celery) or on-demand.
"""
from datetime import date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from ..models.health_logs import (
    WaterLog, SleepLog, MedicationLog, SymptomLog, HealthScore
)

DAILY_WATER_GOAL_ML = 2500
RECOMMENDED_SLEEP_HOURS = 8.0


async def calculate_and_save_health_score(
    user_id: int,
    db: AsyncSession,
    target_date: date | None = None,
) -> HealthScore:
    """
    Calculates a composite health score for the given user and date.
    Score components: water (25%), sleep (25%), medication (25%), symptoms (25%)
    """
    target_date = target_date or date.today()

    water_score = await _water_score(user_id, target_date, db)
    sleep_score = await _sleep_score(user_id, target_date, db)
    medication_score = await _medication_score(user_id, target_date, db)
    symptom_score = await _symptom_score(user_id, target_date, db)

    overall = (
        water_score * 0.25
        + sleep_score * 0.25
        + medication_score * 0.25
        + symptom_score * 0.25
    )

    # Upsert health score
    result = await db.execute(
        select(HealthScore).where(
            HealthScore.user_id == user_id,
            HealthScore.scored_at == target_date,
        )
    )
    hs = result.scalar_one_or_none()
    if hs:
        hs.overall_score = round(overall, 2)
        hs.sleep_score = round(sleep_score, 2)
        hs.water_score = round(water_score, 2)
        hs.medication_score = round(medication_score, 2)
        hs.symptom_score = round(symptom_score, 2)
    else:
        hs = HealthScore(
            user_id=user_id,
            scored_at=target_date,
            overall_score=round(overall, 2),
            sleep_score=round(sleep_score, 2),
            water_score=round(water_score, 2),
            medication_score=round(medication_score, 2),
            symptom_score=round(symptom_score, 2),
        )
        db.add(hs)

    await db.commit()
    await db.refresh(hs)
    return hs


async def _water_score(user_id: int, target_date: date, db: AsyncSession) -> float:
    result = await db.execute(
        select(func.sum(WaterLog.amount_ml)).where(
            WaterLog.user_id == user_id,
            func.date(WaterLog.logged_at) == target_date,
        )
    )
    total = result.scalar_one_or_none() or 0
    return min(float(total) / DAILY_WATER_GOAL_ML, 1.0) * 100


async def _sleep_score(user_id: int, target_date: date, db: AsyncSession) -> float:
    result = await db.execute(
        select(SleepLog).where(
            SleepLog.user_id == user_id,
            func.date(SleepLog.sleep_end) == target_date,
        )
    )
    log = result.scalar_one_or_none()
    if not log:
        return 50.0  # no data = neutral score
    hours = log.duration_hours
    quality = log.quality  # 1-5
    duration_score = min(hours / RECOMMENDED_SLEEP_HOURS, 1.0) * 70
    quality_score = (quality / 5.0) * 30
    return duration_score + quality_score


async def _medication_score(user_id: int, target_date: date, db: AsyncSession) -> float:
    result = await db.execute(
        select(MedicationLog).where(
            MedicationLog.user_id == user_id,
            func.date(MedicationLog.scheduled_time) == target_date,
        )
    )
    logs = result.scalars().all()
    if not logs:
        return 100.0  # no medications = full score
    taken = sum(1 for l in logs if l.status == "taken")
    return (taken / len(logs)) * 100


async def _symptom_score(user_id: int, target_date: date, db: AsyncSession) -> float:
    result = await db.execute(
        select(SymptomLog).where(
            SymptomLog.user_id == user_id,
            func.date(SymptomLog.logged_at) == target_date,
        )
    )
    logs = result.scalars().all()
    if not logs:
        return 100.0  # no symptoms logged = good

    # Average severity across all symptoms in all logs
    all_severities: list[int] = []
    for log in logs:
        for s in (log.symptoms or []):
            all_severities.append(s.get("severity", 5))

    if not all_severities:
        return 100.0

    avg_severity = sum(all_severities) / len(all_severities)
    # Severity 1 = score 100, severity 10 = score 0
    return max(0.0, (10 - avg_severity) / 9.0 * 100)


def generate_health_alerts(
    water_ml: int,
    sleep_hours: float,
    missed_medications: int,
) -> list[dict]:
    """
    Returns a list of alerts to push as notifications.
    """
    alerts = []

    if water_ml < 1000:
        alerts.append({
            "type": "dehydration",
            "title": "Stay Hydrated!",
            "body": f"You've only had {water_ml}ml today. Aim for 2500ml.",
            "priority": "high",
        })
    elif water_ml < 1500:
        alerts.append({
            "type": "dehydration",
            "title": "Drink More Water",
            "body": f"You're at {water_ml}ml. Halfway to your daily goal!",
            "priority": "normal",
        })

    if sleep_hours < 6:
        alerts.append({
            "type": "poor_sleep",
            "title": "Poor Sleep Detected",
            "body": f"You slept {sleep_hours:.1f} hours. Try to get at least 7–8 hours.",
            "priority": "high",
        })

    if missed_medications > 0:
        alerts.append({
            "type": "missed_medication",
            "title": "Missed Medication",
            "body": f"You missed {missed_medications} medication dose(s) today.",
            "priority": "high",
        })

    return alerts
