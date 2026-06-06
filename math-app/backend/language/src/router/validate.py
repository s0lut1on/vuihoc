# validate.py — extended for all exercise types: mcq, typing, audio_mcq, matching, ordering, listen_select
import json
from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from db import get_db
from schemas import ValidateRequest, ApiResponse
from auth import require_user
from services.text_check import validate_text
from models import LanguageExercise
from sqlalchemy import select

router = APIRouter()


def _normalize_vietnamese(text: str) -> str:
    """Strip diacritics for loose comparison."""
    import unicodedata
    return "".join(
        c for c in unicodedata.normalize("NFD", text)
        if unicodedata.category(c) != "Mn"
    )


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

    exercise_type = (exercise.exercise_type or "").lower()
    is_correct = False
    feedback_vi = ""
    feedback_en = ""

    # ── MCQ / audio_mcq ──────────────────────────────────────────────
    if exercise_type in ("mcq", "audio_mcq", "listen_select"):
        # user sends the option text itself
        user_answer = (body.user_text or "").strip().lower()
        expected = (exercise.expected_text or "").strip().lower()
        if user_answer == expected:
            is_correct = True
        else:
            # fallback: compare by index if expected_text is numeric
            try:
                selected_idx = int(user_answer)
                is_correct = selected_idx == (exercise.correct_index or 0)
            except ValueError:
                is_correct = False

        feedback_vi = "Chính xác!" if is_correct else "Thử lại nhé!"
        feedback_en = "Correct!" if is_correct else "Try again!"

    # ── Typing ─────────────────────────────────────────────────────────
    elif exercise_type == "typing":
        is_correct = validate_text(
            user_input=body.user_text,
            expected=exercise.expected_text,
            mode=exercise.validation_mode or "exact",
            case_sensitive=exercise.case_sensitive or False,
            diacritic_sensitive=(
                exercise.diacritic_sensitive
                if exercise.diacritic_sensitive is not None
                else True
            ),
            max_distance=exercise.max_edit_distance or 0,
        )["is_correct"]

        feedback_vi = "Chính xác!" if is_correct else "Thử lại nhé!"
        feedback_en = "Correct!" if is_correct else "Try again!"

    # ── Matching ───────────────────────────────────────────────────────
    elif exercise_type == "matching":
        # user_text is JSON array of pairs: [["a", "ảnh A"], ["b", "ảnh B"]]
        try:
            user_pairs = json.loads(body.user_text or "[]")
        except json.JSONDecodeError:
            user_pairs = []

        correct_pairs = json.loads(exercise.expected_text or "[]")
        # Normalize: sort each pair, then sort the list of pairs
        def _norm(pairs):
            return sorted(
                (str(a).strip().lower(), str(b).strip().lower()) for a, b in pairs
            )

        is_correct = _norm(user_pairs) == _norm(correct_pairs)

        feedback_vi = "Chính xác!" if is_correct else "Ghép đúng hơn nhé!"
        feedback_en = "Correct!" if is_correct else "Try matching differently!"

    # ── Ordering ───────────────────────────────────────────────────────
    elif exercise_type == "ordering":
        # user_text is JSON array: ["con", "mèo", "đen"]
        try:
            user_order = json.loads(body.user_text or "[]")
        except json.JSONDecodeError:
            user_order = []

        correct_order = json.loads(exercise.expected_text or "[]")
        # Strip extra whitespace, lowercase
        user_order = [str(w).strip().lower() for w in user_order]
        correct_order = [str(w).strip().lower() for w in correct_order]
        is_correct = user_order == correct_order

        feedback_vi = "Chính xác!" if is_correct else "Thứ tự chưa đúng!"
        feedback_en = "Correct!" if is_correct else "The order isn't right!"

    # ── Unknown type ─────────────────────────────────────────────────────
    else:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported exercise type: {exercise_type}"
        )

    return ApiResponse(data={
        "is_correct": is_correct,
        "correct_answer": exercise.expected_text,
        "hint_vi": exercise.hint_vi if not is_correct else None,
        "hint_en": exercise.hint_en if not is_correct else None,
        "feedback_vi": feedback_vi,
        "feedback_en": feedback_en,
    })
