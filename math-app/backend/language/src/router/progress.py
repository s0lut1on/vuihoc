from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, insert, update
from uuid import UUID
from db import get_db
from schemas import ProgressUpdate, LanguageProgressOut, ApiResponse
from auth import require_user
from models import LanguageProgress

router = APIRouter()

@router.get("/progress/{user_id}", response_model=ApiResponse)
async def get_progress(
    user_id: str,
    _current_user: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LanguageProgress).where(LanguageProgress.user_id == UUID(user_id))
    )
    rows = result.scalars().all()
    data = [
        LanguageProgressOut(
            user_id=r.user_id,
            lesson_id=r.lesson_id,
            completed=r.completed,
            stars=r.stars,
            attempts=r.attempts,
        ).model_dump()
        for r in rows
    ]
    return ApiResponse(data={"progress": data})

@router.post("/progress", response_model=ApiResponse)
async def update_progress(
    body: ProgressUpdate,
    user_id: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    from uuid import UUID
    uid = UUID(body.user_id)

    result = await db.execute(
        select(LanguageProgress).where(
            LanguageProgress.user_id == uid,
            LanguageProgress.lesson_id == body.lesson_id,
        )
    )
    existing = result.scalar_one_or_none()

    if existing:
        await db.execute(
            update(LanguageProgress)
            .where(
                LanguageProgress.user_id == uid,
                LanguageProgress.lesson_id == body.lesson_id,
            )
            .values(
                completed=body.completed,
                stars=max(existing.stars, body.stars),
                attempts=existing.attempts + 1,
            )
        )
    else:
        await db.execute(
            insert(LanguageProgress).values(
                user_id=uid,
                lesson_id=body.lesson_id,
                completed=body.completed,
                stars=body.stars,
                attempts=1,
            )
        )
    await db.commit()
    return ApiResponse(data={"updated": True})
