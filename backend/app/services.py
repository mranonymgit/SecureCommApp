from __future__ import annotations

from uuid import UUID

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from .core.security import create_access_token, verify_password
from .models import UserRole
from .repositories import (
    AccessRepository,
    AnnouncementRepository,
    AuthRepository,
    ChatRepository,
    DashboardRepository,
    UserProfileRepository,
    ReportRepository,
    ResidentRepository,
)


class AuthService:
    def __init__(self, session: AsyncSession):
        self.repo = AuthRepository(session)

    async def login(self, community_slug: str, email: str, password: str):
        user = await self.repo.get_user_for_login(community_slug, email)
        if user is None or not user.password_hash or not verify_password(password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

        token = create_access_token(
            subject=str(user.id),
            community_id=str(user.community_id),
            role=user.role.value if isinstance(user.role, UserRole) else str(user.role),
            email=user.email,
        )
        return user, token

    async def change_password(self, community_id: UUID, user_id: UUID, new_password: str) -> bool:
        return await self.repo.update_password(community_id, user_id, hash_password(new_password))


class DashboardService:
    def __init__(self, session: AsyncSession):
        self.repo = DashboardRepository(session)

    async def stats(self, community_id: UUID):
        return await self.repo.stats(community_id)


class ResidentService:
    def __init__(self, session: AsyncSession):
        self.repo = ResidentRepository(session)

    async def list(self, community_id: UUID):
        return await self.repo.list(community_id)

    async def create(self, *, community_id: UUID, payload):
        return await self.repo.create(
            community_id=community_id,
            full_name=payload.full_name,
            email=payload.email,
            phone=payload.phone,
            unit_id=payload.unit_id,
            unit_label=payload.unit_label,
            blood_type=payload.blood_type,
            conditions=payload.conditions,
            allergies=payload.allergies,
            emergency_contact_name=payload.emergency_contact_name,
            emergency_contact_phone=payload.emergency_contact_phone,
            password=payload.initial_password,
        )


class AccessService:
    def __init__(self, session: AsyncSession):
        self.repo = AccessRepository(session)

    async def list_logs(self, community_id: UUID):
        return await self.repo.list_logs(community_id)


class AnnouncementService:
    def __init__(self, session: AsyncSession):
        self.repo = AnnouncementRepository(session)

    async def list(self, community_id: UUID):
        return await self.repo.list(community_id)

    async def create(self, *, community_id: UUID, author_id: UUID, payload):
        return await self.repo.create(community_id=community_id, author_id=author_id, payload=payload)


class ChatService:
    def __init__(self, session: AsyncSession):
        self.repo = ChatRepository(session)

    async def list_messages(self, community_id: UUID, thread_id: UUID):
        return await self.repo.list_messages(community_id, thread_id)

    async def send_message(self, *, community_id: UUID, sender_id: UUID, is_admin: bool, payload):
        return await self.repo.send_message(
            community_id=community_id,
            sender_id=sender_id,
            is_admin=is_admin,
            payload=payload,
        )

    async def default_thread(self, community_id: UUID):
        return await self.repo.ensure_default_thread(community_id)

    async def summary(self, community_id: UUID):
        return await self.repo.summary(community_id)


class ReportService:
    def __init__(self, session: AsyncSession):
        self.repo = ReportRepository(session)

    async def list(self, community_id: UUID):
        return await self.repo.list(community_id)

    async def create(self, *, community_id: UUID, reporter_id: UUID, payload):
        return await self.repo.create(community_id=community_id, reporter_id=reporter_id, payload=payload)

    async def update_status(self, *, community_id: UUID, report_id: UUID, new_status):
        report = await self.repo.update_status(community_id=community_id, report_id=report_id, status=new_status)
        if report is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")
        return report

    async def emergency_profile(self, *, community_id: UUID, user_id: UUID):
        return await self.repo.emergency_profile(community_id, user_id)

    async def toggle_sos(self, *, community_id: UUID, resident_id: UUID, actor_id: UUID, active: bool):
        return await self.repo.toggle_sos(community_id=community_id, resident_id=resident_id, actor_id=actor_id, active=active)


class UserProfileService:
    def __init__(self, session: AsyncSession):
        self.repo = UserProfileRepository(session)

    async def get_profile(self, community_id: UUID, user_id: UUID):
        return await self.repo.get_profile(community_id, user_id)

    async def update_profile(self, community_id: UUID, user_id: UUID, payload):
        return await self.repo.update_profile(community_id, user_id, payload)

    async def get_preferences(self, community_id: UUID, user_id: UUID):
        return await self.repo.get_preferences(community_id, user_id)

    async def update_preferences(self, community_id: UUID, user_id: UUID, payload):
        return await self.repo.update_preferences(community_id, user_id, payload)

    async def list_notifications(self, community_id: UUID, user_id: UUID):
        return await self.repo.list_notifications(community_id, user_id)

    async def mark_notification_read(self, community_id: UUID, user_id: UUID, notification_id: UUID):
        return await self.repo.mark_notification_read(community_id, user_id, notification_id)

    async def delete_notification(self, community_id: UUID, user_id: UUID, notification_id: UUID):
        return await self.repo.delete_notification(community_id, user_id, notification_id)

    async def list_rules(self, community_id: UUID):
        return await self.repo.list_rules(community_id)

    async def list_faqs(self, community_id: UUID):
        return await self.repo.list_faqs(community_id)

    async def submit_faq_question(self, community_id: UUID, user_id: UUID, question: str):
        return await self.repo.submit_faq_question(community_id, user_id, question)
