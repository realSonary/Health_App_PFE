from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from datetime import date

from ...core.database import get_db
from ...models.user import User
from ...models.health_logs import Medication, MedicationLog
from ...schemas.health import MedicationCreate, MedicationOut, MedicationLogCreate
from .deps import get_current_user

router = APIRouter(prefix="/medications", tags=["Medications"])


@router.get("", response_model=dict)
async def list_medications(
    active_only: bool = Query(default=False),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Medication).where(Medication.user_id == current_user.id)
    if active_only:
        query = query.where(Medication.is_active == True)
    result = await db.execute(query.order_by(desc(Medication.created_at)))
    meds = result.scalars().all()
    return {"medications": [_to_out(m) for m in meds]}


@router.post("", response_model=MedicationOut, status_code=201)
async def create_medication(
    payload: MedicationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    med = Medication(
        user_id=current_user.id,
        name=payload.name,
        dosage=payload.dosage,
        frequency=payload.frequency,
        schedule_times=payload.schedule_times or [],
        start_date=date.fromisoformat(payload.start_date),
        end_date=date.fromisoformat(payload.end_date) if payload.end_date else None,
        notes=payload.notes,
    )
    db.add(med)
    await db.commit()
    await db.refresh(med)
    return _to_out(med)


@router.get("/{med_id}", response_model=MedicationOut)
async def get_medication(
    med_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    med = await _get_med_or_404(med_id, current_user.id, db)
    return _to_out(med)


@router.delete("/{med_id}", status_code=204)
async def delete_medication(
    med_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    med = await _get_med_or_404(med_id, current_user.id, db)
    await db.delete(med)
    await db.commit()


@router.post("/{med_id}/log", status_code=201)
async def log_medication(
    med_id: int,
    payload: MedicationLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _get_med_or_404(med_id, current_user.id, db)
    log = MedicationLog(
        medication_id=med_id,
        user_id=current_user.id,
        scheduled_time=payload.scheduled_time,
        taken_at=payload.taken_at,
        status=payload.status,
        notes=payload.notes,
    )
    db.add(log)
    await db.commit()
    return {"message": "Logged"}


@router.get("/adherence/summary", response_model=dict)
async def get_adherence_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MedicationLog).where(MedicationLog.user_id == current_user.id)
    )
    logs = result.scalars().all()
    if not logs:
        return {"adherence_percent": 100.0, "taken": 0, "missed": 0, "total": 0}

    taken = sum(1 for l in logs if l.status == "taken")
    total = len(logs)
    return {
        "adherence_percent": round(taken / total * 100, 1),
        "taken": taken,
        "missed": total - taken,
        "total": total,
    }


async def _get_med_or_404(med_id: int, user_id: int, db: AsyncSession) -> Medication:
    result = await db.execute(
        select(Medication).where(
            Medication.id == med_id,
            Medication.user_id == user_id,
        )
    )
    med = result.scalar_one_or_none()
    if not med:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found")
    return med


def _to_out(m: Medication) -> MedicationOut:
    return MedicationOut(
        id=m.id,
        name=m.name,
        dosage=m.dosage,
        frequency=m.frequency,
        schedule_times=m.schedule_times or [],
        start_date=str(m.start_date),
        end_date=str(m.end_date) if m.end_date else None,
        notes=m.notes,
        is_active=m.is_active,
    )
