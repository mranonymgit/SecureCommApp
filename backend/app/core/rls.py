from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


async def apply_rls_context(session: AsyncSession, *, user_id: str, community_id: str, role: str) -> None:
    await session.execute(text("select set_config('app.user_id', :v, true)"), {"v": user_id})
    await session.execute(text("select set_config('app.community_id', :v, true)"), {"v": community_id})
    await session.execute(text("select set_config('app.user_role', :v, true)"), {"v": role})
