"""Create the initial community, one administrator, and one resident account."""

from __future__ import annotations

import argparse
import asyncio
import secrets
import sys
from pathlib import Path
from uuid import uuid4

from sqlalchemy import select

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.database import AsyncSessionLocal
from app.core.security import hash_password
from app.models import AccountStatus, Community, ResidentProfile, Unit, User, UserPreference, UserRole


def parser() -> argparse.ArgumentParser:
    command = argparse.ArgumentParser(description=__doc__)
    command.add_argument("--community-name", default="Comunidad SCA")
    command.add_argument("--community-slug", default="sca")
    command.add_argument("--admin-name", default="Administrador SCA")
    command.add_argument("--admin-email", default="admin@sca.mx")
    command.add_argument("--admin-phone", default="5550000001")
    command.add_argument("--admin-password")
    command.add_argument("--resident-name", default="Residente SCA")
    command.add_argument("--resident-email", default="residente@sca.mx")
    command.add_argument("--resident-phone", default="5550000002")
    command.add_argument("--resident-password")
    command.add_argument("--tower", default="A")
    command.add_argument("--unit", default="101")
    return command


async def find_or_create_user(session, *, community: Community, role: UserRole, name: str, email: str, phone: str, password: str, unit: Unit | None = None) -> tuple[User, bool]:
    result = await session.execute(
        select(User).where(User.community_id == community.id, User.email == email, User.deleted_at.is_(None))
    )
    user = result.scalars().first()
    if user is not None:
        if user.role != role:
            raise ValueError(f"The account {email} already exists with role {user.role.value}.")
        return user, False

    user = User(
        id=uuid4(),
        community_id=community.id,
        unit_id=unit.id if unit else None,
        role=role,
        full_name=name,
        email=email,
        phone=phone,
        password_hash=hash_password(password),
        status=AccountStatus.active,
    )
    session.add(user)
    await session.flush()
    return user, True


async def bootstrap(args: argparse.Namespace) -> None:
    admin_password = args.admin_password or secrets.token_urlsafe(18)
    resident_password = args.resident_password or secrets.token_urlsafe(18)

    async with AsyncSessionLocal() as session:
        result = await session.execute(
            select(Community).where(Community.slug == args.community_slug, Community.deleted_at.is_(None))
        )
        community = result.scalars().first()
        if community is None:
            community = Community(id=uuid4(), name=args.community_name, slug=args.community_slug, status=AccountStatus.active)
            session.add(community)
            await session.flush()

        unit_result = await session.execute(
            select(Unit).where(
                Unit.community_id == community.id,
                Unit.tower == args.tower,
                Unit.unit_number == args.unit,
                Unit.deleted_at.is_(None),
            )
        )
        unit = unit_result.scalars().first()
        if unit is None:
            unit = Unit(
                id=uuid4(),
                community_id=community.id,
                tower=args.tower,
                unit_number=args.unit,
                status=AccountStatus.active,
            )
            session.add(unit)
            await session.flush()

        admin, admin_created = await find_or_create_user(
            session,
            community=community,
            role=UserRole.admin,
            name=args.admin_name,
            email=args.admin_email,
            phone=args.admin_phone,
            password=admin_password,
        )
        resident, resident_created = await find_or_create_user(
            session,
            community=community,
            role=UserRole.resident,
            name=args.resident_name,
            email=args.resident_email,
            phone=args.resident_phone,
            password=resident_password,
            unit=unit,
        )

        profile_result = await session.execute(select(ResidentProfile).where(ResidentProfile.user_id == resident.id))
        if profile_result.scalars().first() is None:
            session.add(ResidentProfile(id=uuid4(), community_id=community.id, user_id=resident.id, unit_id=unit.id))
        for user in (admin, resident):
            preference_result = await session.execute(
                select(UserPreference).where(UserPreference.community_id == community.id, UserPreference.user_id == user.id)
            )
            if preference_result.scalars().first() is None:
                session.add(UserPreference(id=uuid4(), community_id=community.id, user_id=user.id))
        await session.commit()

    print(f"community_slug={args.community_slug}")
    print(f"admin_email={args.admin_email}")
    print(f"admin_created={str(admin_created).lower()}")
    if admin_created:
        print(f"admin_password={admin_password}")
    print(f"resident_email={args.resident_email}")
    print(f"resident_created={str(resident_created).lower()}")
    if resident_created:
        print(f"resident_password={resident_password}")


if __name__ == "__main__":
    asyncio.run(bootstrap(parser().parse_args()))
