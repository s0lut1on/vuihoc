from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from db import get_db
from schemas import ValidateRequest, ValidateResult, ApiResponse
from auth import require_user
from services.text_check import validate_text
from models import LanguageExercise
from sqlalchemy import select

router = APIRouter()

@router.post("/validate", response_model=ApiResponse)
async def validate(
    body: ValidateRequest,
    user_id: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LanguageExercise).where(LanguageExercise.id == body.exercise_id)
    )
    exercise = result.scalar_one_or_none()
    if not exercise:
        raise HTTPException(status_code=404, detail="Exercise not found")
    if not exercise.expected_text:
        raise HTTPException(status_code=400, detail="Exercise has no expected text")

    result = validate_text(
        user_input=body.user_text,
        expected=exercise.expected_text,
        mode=exercise.validation_mode or "exact",
        case_sensitive=exercise.case_sensitive or False,
        diacritic_sensitive=exercise.diacritic_sensitive if exercise.diacritic_sensitive is not None else True,
        max_distance=exercise.max_edit_distance or 0,
    )
    return ApiResponse(data=result)
