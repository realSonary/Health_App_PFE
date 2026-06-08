from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import SleepLog
from ...schemas.health import SleepLogCreate, SleepLogOut
from .deps import get_current_user

router = APIRouter(prefix="/sleep", tags=["Sleep"])


@router.post("", response_model=SleepLogOut, status_code=201)
async def log_sleep(
    payload: SleepLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    log = SleepLog(
        user_id=current_user.id,
        sleep_start=payload.sleep_start,
        sleep_end=payload.sleep_end,
        quality=payload.quality,
        notes=payload.notes,
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return _to_out(log)


@router.get("", response_model=dict)
async def get_sleep_logs(
    limit: int = Query(default=7, le=30),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SleepLog)
        .where(SleepLog.user_id == current_user.id)
        .order_by(desc(SleepLog.sleep_start))
        .limit(limit)
    )
    logs = result.scalars().all()
    return {
        "logs": [_to_out(l) for l in logs],
        "average_hours": round(
            sum(l.duration_hours for l in logs) / len(logs), 2
        ) if logs else 0,
    }


def _to_out(log: SleepLog) -> SleepLogOut:
    return SleepLogOut(
        id=log.id,
        sleep_start=log.sleep_start,
        sleep_end=log.sleep_end,
        duration_hours=round(log.duration_hours, 2),
        quality=log.quality,
        notes=log.notes,
    )
