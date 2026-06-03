from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from db import engine, Base
from router import curriculum, audio, validate, progress, speech

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    await engine.dispose()

app = FastAPI(title="Language Service", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(curriculum, prefix="/api/language")
app.include_router(audio, prefix="/api/language")
app.include_router(validate, prefix="/api/language")
app.include_router(progress, prefix="/api/language")
app.include_router(speech, prefix="/api/language")

@app.get("/api/language/health")
async def health():
    return {"status": "ok", "service": "language", "timestamp": __import__("datetime").datetime.utcnow().isoformat()}
