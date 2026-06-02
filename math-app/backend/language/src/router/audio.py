from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from db import get_db
from schemas import TtsRequest, TtsResponse, ApiResponse
from auth import require_user
from services.tts import generate_tts
from services.audio_storage import get_audio_stream
import os

router = APIRouter()

@router.post("/audio/tts", response_model=ApiResponse)
async def create_tts(
    body: TtsRequest,
    user_id: str = Depends(require_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        audio_url = await generate_tts(body.text, body.language)
        return ApiResponse(data={"audio_url": audio_url})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"TTS generation failed: {e}")

@router.get("/audio/{filename}")
async def stream_audio(filename: str):
    try:
        stream = get_audio_stream("audio-files", filename)
        return StreamingResponse(
            stream,
            media_type="audio/mpeg",
            headers={"Cache-Control": "public, max-age=86400"},
        )
    except Exception:
        raise HTTPException(status_code=404, detail="Audio file not found")
