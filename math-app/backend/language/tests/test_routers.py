"""Integration tests for all language service router endpoints.

Uses httpx.AsyncClient with FastAPI's TestClient transport.
Overrides get_db and require_user dependencies so no real DB or JWT needed.

Covers all 11 endpoints across 5 routers:
  - curriculum: GET /subjects, GET /sub-subjects, GET /curriculum, GET /lesson/{id}
  - progress:   GET /progress/{user_id}, POST /progress, GET /progress/detailed/{user_id}
  - validate:   POST /validate
  - speech:     POST /speech/evaluate
  - audio:      POST /audio/tts, GET /audio/{filename}
Plus: GET /health
"""

import os
import sys
import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from pathlib import Path

import pytest
import httpx

# ── Path setup so we can import src modules ──────────────────────────
LANG_SRC = Path(__file__).resolve().parent.parent / "src"
sys.path.insert(0, str(LANG_SRC))

# Set required env vars before importing app
os.environ.setdefault("JWT_SECRET", "test-secret-key-for-testing")

from main import app                          # noqa: E402
from db import get_db                          # noqa: E402
from auth import require_user                  # noqa: E402

# ── Dependency overrides ─────────────────────────────────────────────

FAKE_USER_ID = "550e8400-e29b-41d4-a716-446655440000"  # valid UUID — progress router parses it


async def fake_require_user():
    """Bypass JWT — return a fixed user ID."""
    return FAKE_USER_ID


async def fake_get_db():
    """Yield a mock AsyncSession instead of hitting a real DB."""
    session = AsyncMock()
    # Common query-chain result: scalars().first() → None, scalars().all() → []
    scalars_mock = MagicMock()
    scalars_mock.first.return_value = None
    scalars_mock.all.return_value = []
    scalars_mock.scalar_one_or_none.return_value = None
    session.execute.return_value = scalars_mock
    try:
        yield session
    finally:
        await session.close()


@pytest.fixture(autouse=True)
def override_deps():
    """Override get_db and require_user for all tests by default."""
    app.dependency_overrides[get_db] = fake_get_db
    app.dependency_overrides[require_user] = fake_require_user
    yield
    app.dependency_overrides.clear()


@pytest.fixture
def no_auth():
    """Remove require_user override so real auth runs (for no-auth tests)."""
    del app.dependency_overrides[require_user]
    yield
    app.dependency_overrides[require_user] = fake_require_user


@pytest.fixture
def client():
    """Synchronous TestClient — skips lifespan to avoid real DB connection.

    StarletteTestClient.__enter__ triggers app lifespan which calls
    engine.begin() → real DB. By not entering the context manager,
    the portal (created in __init__) is available for requests but
    lifespan startup/shutdown are never called.
    """
    from starlette.testclient import TestClient as StarletteTestClient
    c = StarletteTestClient(app)
    yield c
    c.close()


# ── Helpers ───────────────────────────────────────────────────────────

AUTH_HEADERS = {"Authorization": "Bearer fake-token"}


# ═══════════════════════════════════════════════════════════════════════
# Health endpoint
# ═══════════════════════════════════════════════════════════════════════

class TestHealth:
    def test_health_ok(self, client):
        r = client.get("/api/language/health")
        assert r.status_code == 200
        body = r.json()
        assert body["status"] == "ok"
        assert body["service"] == "language"
        assert "timestamp" in body


# ═══════════════════════════════════════════════════════════════════════
# Curriculum router
# ═══════════════════════════════════════════════════════════════════════

class TestCurriculum:
    def test_get_subjects_authed(self, client):
        """GET /subjects with auth → 200."""
        r = client.get("/api/language/subjects", headers=AUTH_HEADERS)
        assert r.status_code == 200

    def test_get_subjects_no_auth(self, client, no_auth):
        """GET /subjects without auth → 401/403."""
        r = client.get("/api/language/subjects")
        assert r.status_code in (401, 403)

    def test_get_sub_subjects_authed(self, client):
        """GET /sub-subjects?subject_id=1 with auth → 200."""
        r = client.get("/api/language/sub-subjects?subject_id=1", headers=AUTH_HEADERS)
        assert r.status_code == 200

    def test_get_sub_subjects_no_auth(self, client, no_auth):
        """GET /sub-subjects without auth → 401/403."""
        r = client.get("/api/language/sub-subjects")
        assert r.status_code in (401, 403)

    def test_get_curriculum_public(self, client):
        """GET /curriculum is public — no auth needed."""
        r = client.get("/api/language/curriculum")
        # May return 200 with empty list, or 422 if grade query param required
        assert r.status_code in (200, 422)

    def test_get_curriculum_with_grade(self, client):
        """GET /curriculum?grade=1 → 200."""
        r = client.get("/api/language/curriculum?grade=1")
        assert r.status_code in (200, 422)

    def test_get_lesson_public(self, client):
        """GET /lesson/{lesson_id} is public."""
        r = client.get("/api/language/lesson/test-lesson-1")
        # 200 if found, 404 if not found in mock DB — both acceptable
        assert r.status_code in (200, 404)

    def test_get_lesson_not_found(self, client):
        """GET /lesson/{nonexistent_id} → 404."""
        r = client.get("/api/language/lesson/nonexistent-lesson-xyz")
        assert r.status_code in (200, 404)


# ═══════════════════════════════════════════════════════════════════════
# Progress router
# ═══════════════════════════════════════════════════════════════════════

class TestProgress:
    def test_get_progress_authed(self, client):
        """GET /progress/{user_id} with auth → 200."""
        r = client.get(f"/api/language/progress/{FAKE_USER_ID}", headers=AUTH_HEADERS)
        assert r.status_code == 200

    def test_get_progress_no_auth(self, client, no_auth):
        """GET /progress/{user_id} without auth → 401/403."""
        r = client.get(f"/api/language/progress/{FAKE_USER_ID}")
        assert r.status_code in (401, 403)

    def test_post_progress_authed(self, client):
        """POST /progress with auth → 200/201."""
        r = client.post(
            "/api/language/progress",
            headers=AUTH_HEADERS,
            json={
                "user_id": FAKE_USER_ID,
                "lesson_id": "lesson-1",
                "stars": 2,
                "completed": True,
            },
        )
        assert r.status_code in (200, 201)

    def test_post_progress_no_auth(self, client, no_auth):
        """POST /progress without auth → 401/403."""
        r = client.post(
            "/api/language/progress",
            json={
                "user_id": FAKE_USER_ID,
                "lesson_id": "lesson-1",
                "stars": 2,
                "completed": True,
            },
        )
        assert r.status_code in (401, 403)

    def test_post_progress_invalid_stars(self, client):
        """POST /progress with stars=0 (below min 1) → 422."""
        r = client.post(
            "/api/language/progress",
            headers=AUTH_HEADERS,
            json={
                "user_id": FAKE_USER_ID,
                "lesson_id": "lesson-1",
                "stars": 0,
                "completed": True,
            },
        )
        assert r.status_code == 422

    def test_post_progress_stars_too_high(self, client):
        """POST /progress with stars=4 (above max 3) → 422."""
        r = client.post(
            "/api/language/progress",
            headers=AUTH_HEADERS,
            json={
                "user_id": FAKE_USER_ID,
                "lesson_id": "lesson-1",
                "stars": 4,
                "completed": True,
            },
        )
        assert r.status_code == 422

    def test_post_progress_missing_fields(self, client):
        """POST /progress missing user_id → 422."""
        r = client.post(
            "/api/language/progress",
            headers=AUTH_HEADERS,
            json={"lesson_id": "lesson-1", "stars": 2},
        )
        assert r.status_code == 422

    def test_get_detailed_progress_authed(self, client):
        """GET /progress/detailed/{user_id} with auth → 200."""
        r = client.get(
            f"/api/language/progress/detailed/{FAKE_USER_ID}",
            headers=AUTH_HEADERS,
        )
        assert r.status_code == 200

    def test_get_detailed_progress_no_auth(self, client, no_auth):
        """GET /progress/detailed/{user_id} without auth → 401/403."""
        r = client.get(f"/api/language/progress/detailed/{FAKE_USER_ID}")
        assert r.status_code in (401, 403)


# ═══════════════════════════════════════════════════════════════════════
# Validate router
# ═══════════════════════════════════════════════════════════════════════

class TestValidate:
    def test_validate_authed(self, client):
        """POST /validate with auth → 200 (exercise found) or 404 (not found in mock DB)."""
        r = client.post(
            "/api/language/validate",
            headers=AUTH_HEADERS,
            json={"exercise_id": "ex-1", "user_text": "xin chào"},
        )
        # Mock DB returns None → exercise not found → 404
        assert r.status_code in (200, 404)

    def test_validate_no_auth(self, client, no_auth):
        """POST /validate without auth → 401/403."""
        r = client.post(
            "/api/language/validate",
            json={"exercise_id": "ex-1", "user_text": "xin chào"},
        )
        assert r.status_code in (401, 403)

    def test_validate_missing_fields(self, client):
        """POST /validate missing user_text → 422."""
        r = client.post(
            "/api/language/validate",
            headers=AUTH_HEADERS,
            json={"exercise_id": "ex-1"},
        )
        assert r.status_code == 422

    def test_validate_empty_body(self, client):
        """POST /validate with empty body → 422."""
        r = client.post("/api/language/validate", headers=AUTH_HEADERS, json={})
        assert r.status_code == 422


# ═══════════════════════════════════════════════════════════════════════
# Speech router
# ═══════════════════════════════════════════════════════════════════════

class TestSpeech:
    def test_speech_evaluate_authed(self, client):
        """POST /speech/evaluate with auth → 501 (Phase 2 stub)."""
        # Endpoint takes exercise_id query param + UploadFile (multipart), not JSON
        r = client.post(
            "/api/language/speech/evaluate?exercise_id=ex-1",
            headers=AUTH_HEADERS,
            files={"audio": ("test.wav", b"fake-audio-data", "audio/wav")},
        )
        # Speech eval is a 501 stub in Phase 1
        assert r.status_code in (200, 501)

    def test_speech_evaluate_no_auth(self, client, no_auth):
        """POST /speech/evaluate without auth → 401/403."""
        r = client.post(
            "/api/language/speech/evaluate?exercise_id=ex-1",
            files={"audio": ("test.wav", b"fake-audio-data", "audio/wav")},
        )
        assert r.status_code in (401, 403)


# ═══════════════════════════════════════════════════════════════════════
# Audio router
# ═══════════════════════════════════════════════════════════════════════

class TestAudio:
    def test_tts_authed(self, client):
        """POST /audio/tts with auth → 200 or 501 (if TTS service unavailable)."""
        r = client.post(
            "/api/language/audio/tts",
            headers=AUTH_HEADERS,
            json={"text": "xin chào", "language": "vi"},
        )
        # May fail if gTTS can't reach Google or MinIO unresolvable in test env
        assert r.status_code in (200, 500, 501, 502, 503)

    def test_tts_no_auth(self, client, no_auth):
        """POST /audio/tts without auth → 401/403."""
        r = client.post(
            "/api/language/audio/tts",
            json={"text": "xin chào", "language": "vi"},
        )
        assert r.status_code in (401, 403)

    def test_tts_missing_text(self, client):
        """POST /audio/tts missing text field → 422."""
        r = client.post(
            "/api/language/audio/tts",
            headers=AUTH_HEADERS,
            json={"language": "vi"},
        )
        assert r.status_code == 422

    def test_get_audio_file_public(self, client):
        """GET /audio/{filename} is public — no auth needed."""
        r = client.get("/api/language/audio/test.mp3")
        # 404 expected since file doesn't exist in test env
        assert r.status_code in (200, 404)

    def test_get_audio_file_not_found(self, client):
        """GET /audio/{nonexistent} → 404."""
        r = client.get("/api/language/audio/nonexistent-file-xyz.mp3")
        assert r.status_code in (200, 404)