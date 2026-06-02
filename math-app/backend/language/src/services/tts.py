import os
import tempfile
from uuid import uuid4
from gtts import gTTS
from services.audio_storage import upload_audio, ensure_bucket

async def generate_tts(text: str, language: str = "vi") -> str:
    tts = gTTS(text=text, lang=language, slow=False)
    
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as tmp:
        tts.save(tmp.name)
        object_name = f"{language}/{uuid4()}.mp3"
        await upload_audio("audio-files", object_name, tmp.name)
        os.unlink(tmp.name)
    
    base_url = os.environ.get("BASE_URL", "https://sekklings.com")
    return f"{base_url}/api/language/audio/{object_name}"
