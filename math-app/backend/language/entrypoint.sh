#!/bin/bash
set -e

# Convert postgresql+asyncpg:// → postgresql:// for psql
DB_URL="${DATABASE_URL/+asyncpg:/:}"

echo "Waiting for database..."
until psql "$DB_URL" -c "SELECT 1" > /dev/null 2>&1; do
  sleep 1
done

echo "Creating tables if missing..."
python -c "
import asyncio, sys
sys.path.insert(0, '/app/src')
from db import engine, Base
async def init():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
asyncio.run(init())
"

# Track which .sql files have already run
psql "$DB_URL" -c "
CREATE TABLE IF NOT EXISTS _migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT NOW()
);
" > /dev/null

for f in /app/migrations/*.sql; do
  filename=$(basename "$f")
  already=$(psql "$DB_URL" -t -c "SELECT 1 FROM _migrations WHERE filename = '$filename'" | xargs || true)
  if [ "$already" = "1" ]; then
    echo "Skip (applied): $filename"
    continue
  fi
  echo "Apply: $filename"
  psql "$DB_URL" -f "$f"
  psql "$DB_URL" -c "INSERT INTO _migrations (filename) VALUES ('$filename')" > /dev/null
done

echo "Migrations complete. Starting uvicorn..."
exec uvicorn main:app --host 0.0.0.0 --port 3000
