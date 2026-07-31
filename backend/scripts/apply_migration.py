"""Apply a reviewed SQL migration using the configured PostgreSQL connection."""

from __future__ import annotations

import asyncio
import sys
from pathlib import Path

import asyncpg

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import get_settings


async def main(sql_path: Path) -> None:
    if not sql_path.is_file():
        raise SystemExit(f"Migration file not found: {sql_path}")

    database_url = get_settings().database_url.replace("postgresql+asyncpg://", "postgresql://", 1)
    connection = await asyncpg.connect(database_url)
    try:
        await connection.execute(sql_path.read_text(encoding="utf-8"))
    finally:
        await connection.close()

    print(f"Applied migration: {sql_path.name}")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("Usage: python scripts/apply_migration.py sql/<migration>.sql")
    asyncio.run(main(Path(sys.argv[1])))
