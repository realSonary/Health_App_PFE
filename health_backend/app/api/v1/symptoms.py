from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from datetime import datetime

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import SymptomLog
from ...schemas.health import SymptomLogCreate, SymptomLogOut
from .deps import get_current_user

router = APIRouter(prefix="/symptoms", tags=["Symptoms"])


@router.post("", response_model=SymptomLogOut, status_code=201)
async def log_symptoms(
    payload: SymptomLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    log = SymptomLog(
        user_id=current_user.id,
        symptoms=[s.model_dump() for s in payload.symptoms],
        notes=payload.notes,
        duration_hours=payload.duration_hours,
        body_temp_c=payload.body_temp_c,
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)
    return _to_out(log)


@router.get("", response_model=dict)
async def get_symptoms(
    limit: int = Query(default=20, le=100),
    offset: int = Query(default=0),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SymptomLog)
        .where(SymptomLog.user_id == current_user.id)
        .order_by(desc(SymptomLog.logged_at))
        .limit(limit)
        .offset(offset)
    )
    logs = result.scalars().all()
    return {"logs": [_to_out(l) for l in logs], "total": len(logs)}


@router.get("/{log_id}", response_model=SymptomLogOut)
async def get_symptom_log(
    log_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from fastapi import HTTPException, status
    result = await db.execute(
        select(SymptomLog).where(
            SymptomLog.id == log_id,
            SymptomLog.user_id == current_user.id,
        )
    )
    log = result.scalar_one_or_none()
    if not log:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Log not found")
    return _to_out(log)


def _to_out(log: SymptomLog) -> SymptomLogOut:
    return SymptomLogOut(
        id=log.id,
        logged_at=log.logged_at,
        symptoms=log.symptoms,
        notes=log.notes,
        body_temp_c=float(log.body_temp_c) if log.body_temp_c else None,
    )
