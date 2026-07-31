from dataclasses import dataclass
from typing import Annotated

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from .database import get_session
from .security import decode_token
from .rls import apply_rls_context


@dataclass(frozen=True)
class AuthClaims:
    user_id: str
    community_id: str
    role: str
    email: str


async def get_current_claims(authorization: Annotated[str | None, Header()] = None) -> AuthClaims:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")

    token = authorization.removeprefix("Bearer ").strip()
    try:
      payload = decode_token(token)
    except ValueError as exc:
      raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc)) from exc

    return AuthClaims(
        user_id=payload["sub"],
        community_id=payload["community_id"],
        role=payload["role"],
        email=payload["email"],
    )


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
