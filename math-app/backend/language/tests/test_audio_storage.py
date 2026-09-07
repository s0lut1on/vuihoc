"""Unit tests for the MinIO audio-storage service.

All Minio client calls are mocked — no real MinIO server needed.
Env vars must be set before import because audio_storage.py checks
them at module level and raises RuntimeError if missing.
"""

import asyncio
import os

# Set env vars BEFORE importing the module
os.environ["MINIO_ACCESS_KEY"] = "test-access-key"
os.environ["MINIO_SECRET_KEY"] = "test-secret-key"
os.environ["MINIO_ENDPOINT"] = "localhost:9000"
os.environ["MINIO_SECURE"] = "false"

import pytest
from unittest.mock import MagicMock, patch

from minio.error import S3Error

from services.audio_storage import ensure_bucket, upload_audio, get_audio_stream


def _make_s3_error(code: str) -> S3Error:
    """Create a minimal S3Error instance without invoking __init__."""
    err = S3Error.__new__(S3Error)
    err.code = code
    return err


# ── ensure_bucket ─────────────────────────────────────────────────────


@patch("services.audio_storage.client")
def test_ensure_bucket_creates_new_bucket(mock_client):
    ensure_bucket("test-bucket")
    mock_client.make_bucket.assert_called_once_with("test-bucket")


@patch("services.audio_storage.client")
def test_ensure_bucket_handles_already_exists(mock_client):
    mock_client.make_bucket.side_effect = _make_s3_error("BucketAlreadyExists")
    # Should not raise
    ensure_bucket("test-bucket")


@patch("services.audio_storage.client")
def test_ensure_bucket_raises_on_other_errors(mock_client):
    mock_client.make_bucket.side_effect = _make_s3_error("SomeOtherError")
    with pytest.raises(S3Error):
        ensure_bucket("test-bucket")


# ── upload_audio ──────────────────────────────────────────────────────


@patch("services.audio_storage.client")
def test_upload_audio_calls_fput_object(mock_client):
    result = asyncio.run(upload_audio("bucket", "obj.mp3", "/path/file.mp3"))
    mock_client.fput_object.assert_called_once_with(
        "bucket", "obj.mp3", "/path/file.mp3", content_type="audio/mpeg"
    )
    assert result == "obj.mp3"


@patch("services.audio_storage.client")
def test_upload_audio_ensures_bucket_first(mock_client):
    asyncio.run(upload_audio("bucket", "obj.mp3", "/path/file.mp3"))

    # ensure_bucket calls make_bucket; upload calls fput_object
    mock_client.make_bucket.assert_called_once_with("bucket")
    mock_client.fput_object.assert_called_once_with(
        "bucket", "obj.mp3", "/path/file.mp3", content_type="audio/mpeg"
    )

    # Verify ordering: make_bucket before fput_object
    call_names = [call[0] for call in mock_client.method_calls]
    assert call_names.index("make_bucket") < call_names.index("fput_object")


# ── get_audio_stream ──────────────────────────────────────────────────


@patch("services.audio_storage.client")
def test_get_audio_stream_calls_get_object(mock_client):
    mock_response = MagicMock()
    mock_client.get_object.return_value = mock_response

    result = get_audio_stream("bucket", "obj.mp3")

    mock_client.get_object.assert_called_once_with("bucket", "obj.mp3")
    assert result is mock_response