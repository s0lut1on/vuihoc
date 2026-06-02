from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from db import get_db
from schemas import ApiResponse, SpeechEvaluateResult
from auth import require_user

router = APIRouter()

@router.post("/speech/evaluate", response_model=ApiResponse)
async def evaluate_speech(
    exercise_id: str,
    audio: UploadFile = File(...),
    user_id: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    raise HTTPException(
        status_code=501,
        detail="Speech evaluation is planned for Phase 2. Use audio_mcq, dictation, typing, or repeat exercise types for now."
    )
