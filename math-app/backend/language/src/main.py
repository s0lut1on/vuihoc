from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import logging
import sys

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("language-service")

from db import engine, Base
from router import curriculum, audio, validate, progress, speech

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting language service")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    logger.info("Shutting down language service")
    await engine.dispose()

app = FastAPI(title="Language Service", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://sekklings.com", "https://www.sekklings.com"],
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
    logger.info("health check")
    return {"status": "ok", "service": "language", "timestamp": __import__("datetime").datetime.utcnow().isoformat()}
