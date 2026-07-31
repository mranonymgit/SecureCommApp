from dataclasses import dataclass
from typing import Annotated
from uuid import UUID

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from ..models import AccountStatus, User
from .database import get_session
from .security import decode_token
from .rls import apply_rls_context


@dataclass(frozen=True)
class AuthClaims:
    user_id: str
    community_id: str
    role: str
    email: str


async def get_current_claims(
    session: Annotated[AsyncSession, Depends(get_session)],
    authorization: Annotated[str | None, Header()] = None,
) -> AuthClaims:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        payload = decode_token(token)
    except ValueError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    try:
        claims = AuthClaims(
            user_id=str(payload["sub"]),
            community_id=str(payload["community_id"]),
            role=str(payload["role"]),
            email=str(payload["email"]),
        )
    except (KeyError, TypeError) as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token claims") from exc
    try:
        user_id = UUID(claims.user_id)
        community_id = UUID(claims.community_id)
    except (TypeError, ValueError) as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token claims") from exc

    await apply_rls_context(
        session,
        user_id=claims.user_id,
        community_id=claims.community_id,
        role=claims.role,
    )
    user = await session.scalar(
        select(User).where(
            User.id == user_id,
            User.community_id == community_id,
            User.status == AccountStatus.active,
            User.deleted_at.is_(None),
        )
    )
    if user is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Account is not active")
    current_role = user.role.value if hasattr(user.role, "value") else str(user.role)
    if current_role != claims.role:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Account permissions changed")
    return claims


async def require_admin(claims: Annotated[AuthClaims, Depends(get_current_claims)]) -> AuthClaims:
    if claims.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Administrator role required")
    return claims


async def get_rls_session(
    claims: Annotated[AuthClaims, Depends(get_current_claims)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AsyncSession:
    await apply_rls_context(
        session,
        user_id=claims.user_id,
        community_id=claims.community_id,
        role=claims.role,
    )
    return session
