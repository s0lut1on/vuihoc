from fastapi import APIRouter, HTTPException, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, insert, update, func
from typing import Optional
from uuid import UUID
from db import get_db
from schemas import (
    ProgressUpdate, LanguageProgressOut, ApiResponse,
    SubSubjectProgress, SubjectProgress
)
from auth import require_user
from models import LanguageProgress, LanguageSubSubject, LanguageLesson, LanguageSubject

router = APIRouter()

# ── Existing endpoints ──────────────────────────────────────────────────────

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


# ── NEW: Detailed sub-subject progress ────────────────────────────────────────

_UNLOCK_THRESHOLD = 0.80  # 80 % completion required to unlock next sub-subject


@router.get("/progress/detailed/{user_id}", response_model=ApiResponse)
async def get_detailed_progress(
    user_id: str,
    subject_id: Optional[str] = Query(None),
    _current_user: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    uid = UUID(user_id)

    # 1. Fetch sub-subjects (optionally filtered by subject_id)
    sub_q = (
        select(
            LanguageSubSubject.id,
            LanguageSubSubject.subject_id,
            LanguageSubSubject.name_vi,
            LanguageSubSubject.name_en,
            LanguageSubSubject.icon,
            LanguageSubSubject.color,
            LanguageSubSubject.display_order,
            func.count(LanguageLesson.id).label("total_lessons"),
        )
        .outerjoin(
            LanguageLesson,
            (LanguageLesson.sub_subject_id == LanguageSubSubject.id),
        )
        .group_by(LanguageSubSubject.id)
        .order_by(LanguageSubSubject.display_order)
    )
    if subject_id:
        sub_q = sub_q.where(LanguageSubSubject.subject_id == subject_id)

    sub_result = await db.execute(sub_q)
    sub_rows = sub_result.all()

    # 2. Fetch user progress
    prog_result = await db.execute(
        select(
            LanguageProgress.lesson_id,
            LanguageProgress.completed,
            LanguageProgress.stars,
        ).where(LanguageProgress.user_id == uid)
    )
    prog_map = {r.lesson_id: r for r in prog_result.all()}

    # 3. Map lessons to sub-subjects
    lessons_result = await db.execute(
        select(LanguageLesson.id, LanguageLesson.sub_subject_id)
        .where(LanguageLesson.sub_subject_id.isnot(None))
    )
    lessons_by_sub: dict = {}
    for lid, sid in lessons_result.all():
        lessons_by_sub.setdefault(sid, []).append(lid)

    # 4. Build per-sub-subject stats
    sub_stats = []
    for row in sub_rows:
        total = row.total_lessons or 0
        completed = 0
        stars = 0
        for lid in lessons_by_sub.get(row.id, []):
            prog = prog_map.get(lid)
            if prog and prog.completed:
                completed += 1
                stars += prog.stars
        sub_stats.append({
            "id": row.id,
            "subject_id": row.subject_id,
            "name_vi": row.name_vi,
            "name_en": row.name_en,
            "icon": row.icon,
            "color": row.color,
            "display_order": row.display_order,
            "total_lessons": total,
            "completed_lessons": completed,
            "stars_earned": stars,
            "max_stars": total * 3,
            "completion_pct": round(completed / total, 2) if total else 0.0,
        })

    # 5. Compute unlock status per subject
    subjects_map: dict = {}
    for stat in sub_stats:
        sid = stat["subject_id"]
        subjects_map.setdefault(sid, []).append(stat)

    for sid, subs in subjects_map.items():
        for i, sub in enumerate(subs):
            if i == 0:
                sub["is_unlocked"] = True
            else:
                prev = subs[i - 1]
                sub["is_unlocked"] = prev["completion_pct"] >= _UNLOCK_THRESHOLD

    # 6. Fetch subject metadata
    subject_ids = list(subjects_map.keys())
    subj_result = await db.execute(
        select(LanguageSubject).where(LanguageSubject.id.in_(subject_ids))
    )
    subject_meta = {s.id: s for s in subj_result.scalars().all()}

    # 7. Build final response
    response_subjects = []
    for sid, subs in subjects_map.items():
        meta = subject_meta.get(sid)
        total_lessons = sum(s["total_lessons"] for s in subs)
        completed_lessons = sum(s["completed_lessons"] for s in subs)
        stars_earned = sum(s["stars_earned"] for s in subs)
        max_stars = total_lessons * 3

        response_subjects.append({
            "subject_id": sid,
            "subject_vi": meta.name_vi if meta else sid,
            "subject_en": meta.name_en if meta else sid,
            "icon": meta.icon if meta else "📚",
            "color": meta.color if meta else "#FFEBEE",
            "total_lessons": total_lessons,
            "completed_lessons": completed_lessons,
            "stars_earned": stars_earned,
            "max_stars": max_stars,
            "completion_pct": round(completed_lessons / total_lessons, 2) if total_lessons else 0.0,
            "sub_subjects": [
                {
                    "id": s["id"],
                    "name_vi": s["name_vi"],
                    "name_en": s["name_en"],
                    "color": s["color"],
                    "icon": s["icon"],
                    "total_lessons": s["total_lessons"],
                    "completed_lessons": s["completed_lessons"],
                    "stars_earned": s["stars_earned"],
                    "max_stars": s["max_stars"],
                    "completion_pct": s["completion_pct"],
                    "is_unlocked": s["is_unlocked"],
                }
                for s in subs
            ],
        })

    return ApiResponse(data={"subjects": response_subjects})