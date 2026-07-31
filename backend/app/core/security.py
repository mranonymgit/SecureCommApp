import json
from datetime import datetime, timedelta, timezone
from typing import Any

import bcrypt
from jose import JWTError, jwt

from .config import get_settings

settings = get_settings()


def hash_password(password: str) -> str:
    password_bytes = password.encode("utf-8")
    if len(password_bytes) > 72:
        raise ValueError("Password must not exceed 72 UTF-8 bytes")
    return bcrypt.hashpw(password_bytes, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain_password: str, hashed_password: str) -> bool:
    password_bytes = plain_password.encode("utf-8")
    if len(password_bytes) > 72:
        return False
    try:
        return bcrypt.checkpw(password_bytes, hashed_password.encode("utf-8"))
    except (TypeError, ValueError):
        return False


def create_access_token(*, subject: str, community_id: str, role: str, email: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_access_token_expire_minutes)
    payload: dict[str, Any] = {
        "sub": subject,
        "community_id": community_id,
        "role": role,
        "email": email,
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "iss": "sca-api",
    }
    return jwt.encode(payload, settings.jwt_secret_key, algorithm=settings.jwt_algorithm)


def create_realtime_token(*, subject: str, community_id: str, user_role: str) -> str | None:
    """Create the short-lived JWT used only by Supabase Realtime/RLS.

    Supabase requires its built-in ``role`` claim to be ``authenticated``.
    SCA's authorization role is deliberately stored separately in
    ``user_role`` so an admin cannot acquire Supabase privileges implicitly.
    """
    configured_key = settings.supabase_jwt_signing_key or settings.supabase_jwt_secret
    if not configured_key:
        return None
    signing_key: str | dict[str, Any] = configured_key
    if configured_key.lstrip().startswith("{"):
        try:
            parsed_key = json.loads(configured_key)
        except json.JSONDecodeError as exc:
            raise ValueError("SUPABASE_JWT_SIGNING_KEY is not valid JSON") from exc
        if not isinstance(parsed_key, dict):
            raise ValueError("SUPABASE_JWT_SIGNING_KEY must be a private JWK object")
        signing_key = parsed_key
    now = datetime.now(timezone.utc)
    expire = now + timedelta(minutes=settings.supabase_realtime_token_expire_minutes)
    payload: dict[str, Any] = {
        "sub": subject,
        "role": "authenticated",
        "user_role": user_role,
        "community_id": community_id,
        "aud": "authenticated",
        "iat": now,
        "exp": expire,
    }
    headers = {"kid": settings.supabase_jwt_key_id} if settings.supabase_jwt_key_id else None
    return jwt.encode(
        payload,
        signing_key,
        algorithm=settings.supabase_jwt_algorithm,
        headers=headers,
    )


def decode_token(token: str) -> dict[str, Any]:
    try:
        return jwt.decode(token, settings.jwt_secret_key, algorithms=[settings.jwt_algorithm], issuer="sca-api")
    except JWTError as exc:
        raise ValueError("Invalid token") from exc
