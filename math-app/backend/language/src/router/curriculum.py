from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from typing import List, Optional
from db import get_db
from models import LanguageSubject, LanguageLesson, LanguageExercise, LanguageSubSubject
from schemas import (
    ApiResponse, CurriculumSubject, ApiLesson, ApiExercise, SubjectSummary,
    SubSubjectSummary, CurriculumSubSubject
)
from auth import require_user

router = APIRouter()

@router.get("/subjects", response_model=ApiResponse)
async def get_subjects(grade: Optional[int] = Query(default=1), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(
            LanguageSubject.id,
            LanguageSubject.name_vi,
            LanguageSubject.name_en,
            LanguageSubject.icon,
            LanguageSubject.color,
            func.count(LanguageLesson.id).label("lesson_count"),
        )
        .outerjoin(LanguageLesson, 
            (LanguageLesson.subject_id == LanguageSubject.id) & 
            (LanguageLesson.grade == grade)
        )
        .where(
            (LanguageSubject.grade_min <= grade) &
            (LanguageSubject.grade_max >= grade)
        )
        .group_by(LanguageSubject.id)
        .order_by(LanguageSubject.display_order)
    )
    rows = result.all()
    data = [
        SubjectSummary(
            id=r.id,
            name_vi=r.name_vi,
            name_en=r.name_en,
            icon=r.icon,
            color=r.color,
            lesson_count=r.lesson_count or 0,
        ).model_dump()
        for r in rows
    ]
    return ApiResponse(data={"subjects": data})

@router.get("/sub-subjects", response_model=ApiResponse)
async def get_sub_subjects(
    subject_id: str = Query(...),
    grade: Optional[int] = Query(default=1),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(
            LanguageSubSubject.id,
            LanguageSubSubject.subject_id,
            LanguageSubSubject.name_vi,
            LanguageSubSubject.name_en,
            LanguageSubSubject.icon,
            LanguageSubSubject.color,
            LanguageSubSubject.display_order,
            func.count(LanguageLesson.id).label("lesson_count"),
        )
        .outerjoin(LanguageLesson, 
            (LanguageLesson.sub_subject_id == LanguageSubSubject.id) &
            (LanguageLesson.grade == grade)
        )
        .where(
            (LanguageSubSubject.subject_id == subject_id)
        )
        .group_by(LanguageSubSubject.id)
        .order_by(LanguageSubSubject.display_order)
    )
    rows = result.all()
    data = [
        SubSubjectSummary(
            id=r.id,
            subject_id=r.subject_id,
            name_vi=r.name_vi,
            name_en=r.name_en,
            icon=r.icon,
            color=r.color,
            display_order=r.display_order,
            lesson_count=r.lesson_count or 0,
        ).model_dump()
        for r in rows
    ]
    return ApiResponse(data={"sub_subjects": data})

@router.get("/curriculum", response_model=ApiResponse)
async def get_curriculum(
    subject_id: Optional[str] = Query(default=None),
    grade: Optional[int] = Query(default=1),
    db: AsyncSession = Depends(get_db)
):
    # Build base query
    query = (
        select(LanguageSubject, LanguageLesson, LanguageExercise, LanguageSubSubject)
        .outerjoin(LanguageLesson, 
            (LanguageLesson.subject_id == LanguageSubject.id) & 
            (LanguageLesson.grade == grade)
        )
        .outerjoin(LanguageSubSubject, LanguageSubSubject.id == LanguageLesson.sub_subject_id)
        .outerjoin(LanguageExercise, LanguageExercise.lesson_id == LanguageLesson.id)
        .where(
            (LanguageSubject.grade_min <= grade) &
            (LanguageSubject.grade_max >= grade)
        )
    )
    
    if subject_id:
        query = query.where(LanguageSubject.id == subject_id)
    
    query = query.order_by(
        LanguageSubject.display_order, 
        LanguageSubSubject.display_order.nulls_last(),
        LanguageLesson.lesson_order, 
        LanguageExercise.exercise_order
    )
    
    result = await db.execute(query)
    rows = result.all()

    subjects_map = {}
    lessons_map = {}
    sub_subjects_map = {}

    for subject, lesson, exercise, sub_subject in rows:
        sid = subject.id
        if sid not in subjects_map:
            subjects_map[sid] = {
                "subject_id": sid,
                "subject_vi": subject.name_vi,
                "subject_en": subject.name_en,
                "subject_icon": subject.icon,
                "subject_color": subject.color,
                "sub_subjects": {},
                "lessons": {},
            }
        if lesson is None:
            continue
        
        # Handle sub-subjects grouping
        if sub_subject is not None:
            ssid = sub_subject.id
            if ssid not in subjects_map[sid]["sub_subjects"]:
                subjects_map[sid]["sub_subjects"][ssid] = {
                    "sub_subject_id": ssid,
                    "sub_subject_vi": sub_subject.name_vi,
                    "sub_subject_en": sub_subject.name_en,
                    "sub_subject_icon": sub_subject.icon,
                    "sub_subject_color": sub_subject.color,
                    "display_order": sub_subject.display_order,
                    "lessons": {},
                }
            target = subjects_map[sid]["sub_subjects"][ssid]["lessons"]
        else:
            target = subjects_map[sid]["lessons"]
        
        lid = lesson.id
        if lid not in lessons_map:
            lessons_map[lid] = {
                "id": lid,
                "title_vi": lesson.title_vi,
                "title_en": lesson.title_en,
                "description_vi": lesson.description_vi,
                "description_en": lesson.description_en,
                "lesson_order": lesson.lesson_order,
                "difficulty": lesson.difficulty,
                "is_premium": lesson.is_premium,
                "exercises": [],
            }
            target[lid] = lessons_map[lid]
        
        if exercise is not None:
            lessons_map[lid]["exercises"].append(ApiExercise(
                id=exercise.id,
                exercise_type=exercise.exercise_type,
                question_vi=exercise.question_vi,
                question_en=exercise.question_en,
                options=list(exercise.options) if exercise.options else [],
                correct_index=exercise.correct_index,
                expected_text=exercise.expected_text,
                validation_mode=exercise.validation_mode,
                max_edit_distance=exercise.max_edit_distance,
                case_sensitive=exercise.case_sensitive,
                diacritic_sensitive=exercise.diacritic_sensitive,
                audio_url=exercise.audio_url,
                reference_audio_url=exercise.reference_audio_url,
                visual_asset=exercise.visual_asset or "",
                hint_vi=exercise.hint_vi,
                hint_en=exercise.hint_en,
                exercise_order=exercise.exercise_order,
            ).model_dump())

    curriculum = []
    for sid in sorted(subjects_map.keys(), key=lambda x: subjects_map[x]["subject_id"]):
        s = subjects_map[sid]
        
        # Sort sub-subjects by display_order
        sub_subjects_data = []
        for ssid in sorted(s["sub_subjects"].keys(), key=lambda x: s["sub_subjects"][x]["display_order"]):
            ss = s["sub_subjects"][ssid]
            sorted_lessons = sorted(ss["lessons"].values(), key=lambda l: l["lesson_order"])
            for l in sorted_lessons:
                l["exercises"] = sorted(l["exercises"], key=lambda e: e["exercise_order"])
            sub_subjects_data.append(CurriculumSubSubject(
                sub_subject_id=ss["sub_subject_id"],
                sub_subject_vi=ss["sub_subject_vi"],
                sub_subject_en=ss["sub_subject_en"],
                sub_subject_icon=ss["sub_subject_icon"],
                sub_subject_color=ss["sub_subject_color"],
                lessons=[ApiLesson(**l) for l in sorted_lessons],
            ).model_dump())
        
        # Also include lessons not in any sub-subject (backward compat)
        loose_lessons = sorted(s["lessons"].values(), key=lambda l: l["lesson_order"])
        for l in loose_lessons:
            l["exercises"] = sorted(l["exercises"], key=lambda e: e["exercise_order"])
        
        curriculum.append(CurriculumSubject(
            subject_id=s["subject_id"],
            subject_vi=s["subject_vi"],
            subject_en=s["subject_en"],
            subject_icon=s["subject_icon"],
            subject_color=s["subject_color"],
            sub_subjects=sub_subjects_data,
            lessons=[ApiLesson(**l) for l in loose_lessons],
        ).model_dump())

    return ApiResponse(data={"curriculum": curriculum})

@router.get("/lesson/{lesson_id}", response_model=ApiResponse)
async def get_lesson(lesson_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(LanguageLesson, LanguageExercise)
        .outerjoin(LanguageExercise, LanguageExercise.lesson_id == LanguageLesson.id)
        .where(LanguageLesson.id == lesson_id)
        .order_by(LanguageExercise.exercise_order)
    )
    rows = result.all()
    if not rows:
        raise HTTPException(status_code=404, detail="Lesson not found")
    lesson = rows[0][0]
    exercises = []
    for _, ex in rows:
        if ex is not None:
            exercises.append(ApiExercise(
                id=ex.id,
                exercise_type=ex.exercise_type,
                question_vi=ex.question_vi,
                question_en=ex.question_en,
                options=list(ex.options) if ex.options else [],
                correct_index=ex.correct_index,
                expected_text=ex.expected_text,
                validation_mode=ex.validation_mode,
                max_edit_distance=ex.max_edit_distance,
                case_sensitive=ex.case_sensitive,
                diacritic_sensitive=ex.diacritic_sensitive,
                audio_url=ex.audio_url,
                reference_audio_url=ex.reference_audio_url,
                visual_asset=ex.visual_asset or "",
                hint_vi=ex.hint_vi,
                hint_en=ex.hint_en,
                exercise_order=ex.exercise_order,
            ).model_dump())
    return ApiResponse(data=ApiLesson(
        id=lesson.id,
        title_vi=lesson.title_vi,
        title_en=lesson.title_en,
        description_vi=lesson.description_vi,
        description_en=lesson.description_en,
        lesson_order=lesson.lesson_order,
        difficulty=lesson.difficulty,
        is_premium=lesson.is_premium,
        exercises=exercises,
    ).model_dump())
