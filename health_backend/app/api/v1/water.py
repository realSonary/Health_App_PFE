from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, desc
from datetime import datetime, date

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import WaterLog
from ...schemas.health import WaterLogCreate, WaterLogOut, WaterDaySummary
from .deps import get_current_user

router = APIRouter(prefix="/water", tags=["Water"])


@router.post("", response_model=WaterLogOut, status_code=201)
async def add_water(
    payload: WaterLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    log = WaterLog(user_id=current_user.id, amount_ml=payload.amount_ml)
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return WaterLogOut(id=log.id, logged_at=log.logged_at, amount_ml=log.amount_ml)


@router.get("", response_model=WaterDaySummary)
async def get_water_today(
    date_str: str = Query(default=None, alias="date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = date.fromisoformat(date_str) if date_str else date.today()

    result = await db.execute(
        select(WaterLog).where(
            WaterLog.user_id == current_user.id,
            func.date(WaterLog.logged_at) == target_date,
        ).order_by(desc(WaterLog.logged_at))
    )
    logs = result.scalars().all()
    total = sum(l.amount_ml for l in logs)

    return WaterDaySummary(
        date=str(target_date),
        total_ml=total,
        logs=[WaterLogOut(id=l.id, logged_at=l.logged_at, amount_ml=l.amount_ml) for l in logs],
    )


@router.get("/history", response_model=list[dict])
async def get_water_history(
    days: int = Query(default=7, le=30),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(
            func.date(WaterLog.logged_at).label("day"),
            func.sum(WaterLog.amount_ml).label("total"),
        )
        .where(WaterLog.user_id == current_user.id)
        .group_by(func.date(WaterLog.logged_at))
        .order_by(desc("day"))
        .limit(days)
    )
    rows = result.all()
    return [{"date": str(r.day), "total_ml": int(r.total)} for r in rows]
