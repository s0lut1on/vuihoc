import os
from jose import jwt, JWTError
from fastapi import HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

JWT_SECRET = os.environ["JWT_SECRET"]
security = HTTPBearer()

async def require_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"], audience="math-app")
        return payload["sub"]
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")

async def optional_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str | None:
    try:
        return await require_user(credentials)
    except HTTPException:
        return None
