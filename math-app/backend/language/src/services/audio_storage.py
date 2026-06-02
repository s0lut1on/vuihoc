import os
import tempfile
from minio import Minio
from minio.error import S3Error

MINIO_ENDPOINT = os.environ.get("MINIO_ENDPOINT", "minio:9000")
MINIO_ACCESS_KEY = os.environ.get("MINIO_ACCESS_KEY", "minioadmin")
MINIO_SECRET_KEY = os.environ.get("MINIO_SECRET_KEY", "minioadmin")
MINIO_SECURE = os.environ.get("MINIO_SECURE", "false").lower() == "true"

client = Minio(
    MINIO_ENDPOINT,
    access_key=MINIO_ACCESS_KEY,
    secret_key=MINIO_SECRET_KEY,
    secure=MINIO_SECURE,
)

def ensure_bucket(bucket_name: str):
    try:
        client.make_bucket(bucket_name)
    except S3Error as err:
        if err.code != "BucketAlreadyExists":
            raise

async def upload_audio(bucket: str, object_name: str, file_path: str) -> str:
    ensure_bucket(bucket)
    client.fput_object(bucket, object_name, file_path, content_type="audio/mpeg")
    return object_name

def get_audio_stream(bucket: str, object_name: str):
    response = client.get_object(bucket, object_name)
    return response
