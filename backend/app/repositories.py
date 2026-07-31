from __future__ import annotations

from datetime import date, datetime, timezone
from uuid import UUID, uuid4

import httpx
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from .core.config import get_settings
from .core.security import hash_password
from .models import (
    AccessAction,
    AccessLog,
    Announcement,
    AnnouncementReaction,
    CommunityFaq,
    CommunityRule,
    ChatMessage,
    ChatThread,
    ChatThreadType,
    FaqQuestion,
    PanicAlert,
    PanicStatus,
    Report,
    ReportStatus,
    ResidentProfile,
    Unit,
    Community,
    AccountStatus,
    User,
    UserNotification,
    UserPreference,
    UserRole,
    Visit,
)


class AuthRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_user_for_login(self, community_slug: str, email: str) -> User | None:
        query = (
            select(User)
            .join(Community, Community.id == User.community_id)
            .where(func.lower(User.email) == email.lower())
            .where(Community.slug == community_slug)
            .where(User.deleted_at.is_(None))
        )
        result = await self.session.execute(query)
        return result.scalars().first()

    async def update_password(self, community_id: UUID, user_id: UUID, new_password_hash: str) -> bool:
        result = await self.session.execute(
            select(User)
            .where(User.community_id == community_id)
            .where(User.id == user_id)
            .where(User.deleted_at.is_(None))
        )
        user = result.scalars().first()
        if user is None:
            return False
        user.password_hash = new_password_hash
        return True


class DashboardRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def stats(self, community_id: UUID) -> dict[str, int]:
        today = date.today()
        residents = await self.session.scalar(
            select(func.count()).select_from(User).where(User.community_id == community_id, User.deleted_at.is_(None), User.role == UserRole.resident)
        )
        active_visits = await self.session.scalar(
            select(func.count())
            .select_from(Visit)
            .where(Visit.community_id == community_id, Visit.deleted_at.is_(None), func.date(Visit.created_at) == today)
        )
        pending_reports = await self.session.scalar(
            select(func.count())
            .select_from(Report)
            .where(Report.community_id == community_id, Report.deleted_at.is_(None), Report.status == ReportStatus.pending)
        )
        active_alerts = await self.session.scalar(
            select(func.count())
            .select_from(PanicAlert)
            .where(PanicAlert.community_id == community_id, PanicAlert.deleted_at.is_(None), PanicAlert.status == PanicStatus.active)
        )
        return {
            "total_residents": int(residents or 0),
            "active_visits_today": int(active_visits or 0),
            "pending_reports": int(pending_reports or 0),
            "active_alerts": int(active_alerts or 0),
        }


class ResidentRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(self, community_id: UUID) -> list[dict]:
        result = await self.session.execute(
            select(User, ResidentProfile, Unit)
            .join(ResidentProfile, ResidentProfile.user_id == User.id)
            .join(Unit, Unit.id == ResidentProfile.unit_id)
            .where(User.community_id == community_id, User.deleted_at.is_(None), User.role == UserRole.resident)
            .order_by(User.created_at.desc())
        )
        rows = result.all()
        items: list[dict] = []
        for user, profile, unit in rows:
            items.append(
                {
                    "id": str(user.id),
                    "full_name": user.full_name,
                    "email": user.email,
                    "phone": user.phone,
                    "unit": f"{unit.tower} - {unit.unit_number}",
                    "unit_id": str(unit.id),
                    "role": user.role.value if hasattr(user.role, "value") else str(user.role),
                    "status": user.status.value if hasattr(user.status, "value") else str(user.status),
                    "blood_type": profile.blood_type,
                    "illnesses": profile.conditions,
                    "allergies": profile.allergies,
                    "emergency_contact": profile.emergency_contact_name,
                    "avatar_url": "",
                }
            )
        return items

    async def create(
        self,
        *,
        community_id: UUID,
        full_name: str,
        email: str,
        phone: str,
        unit_id: UUID | None,
        unit_label: str | None,
        blood_type: str | None,
        conditions: str | None,
        allergies: str | None,
        emergency_contact_name: str | None,
        emergency_contact_phone: str | None,
        password: str,
    ) -> User:
        if unit_id is None:
            label = (unit_label or "").strip()
            if not label:
                raise ValueError("unit_id or unit_label is required")
            unit = Unit(
                id=uuid4(),
                community_id=community_id,
                tower="General",
                unit_number=label,
                floor=None,
                status=AccountStatus.active,
            )
            self.session.add(unit)
            await self.session.flush()
            unit_id = unit.id

        user = User(
            id=uuid4(),
            community_id=community_id,
            unit_id=unit_id,
            role=UserRole.resident,
            full_name=full_name,
            email=email,
            phone=phone,
            password_hash=hash_password(password),
            status=AccountStatus.active,
        )
        self.session.add(user)
        await self.session.flush()

        profile = ResidentProfile(
            id=uuid4(),
            community_id=community_id,
            user_id=user.id,
            unit_id=unit_id,
            blood_type=blood_type,
            conditions=conditions,
            allergies=allergies,
            emergency_contact_name=emergency_contact_name,
        )
        self.session.add(profile)
        return user


class AccessRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list_logs(self, community_id: UUID) -> list[AccessLog]:
        result = await self.session.execute(
            select(AccessLog)
            .options(selectinload(AccessLog.visit))
            .where(AccessLog.community_id == community_id, AccessLog.deleted_at.is_(None))
            .order_by(AccessLog.created_at.desc())
        )
        return list(result.scalars().all())


class AnnouncementRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(self, community_id: UUID) -> list[Announcement]:
        result = await self.session.execute(
            select(Announcement)
            .options(selectinload(Announcement.created_by_user))
            .where(Announcement.community_id == community_id, Announcement.deleted_at.is_(None))
            .order_by(Announcement.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, *, community_id: UUID, author_id: UUID, payload) -> Announcement:
        item = Announcement(
            id=uuid4(),
            community_id=community_id,
            created_by_user_id=author_id,
            category=payload.category,
            title=payload.title,
            content=payload.content,
            image_url=payload.image_url,
            is_important=payload.is_important,
        )
        self.session.add(item)
        return item

    async def reaction_summary(self, community_id: UUID, announcement_id: UUID, user_id: UUID) -> dict[str, int | str | None]:
        likes = await self.session.scalar(
            select(func.count()).select_from(AnnouncementReaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.reaction == "like",
            )
        )
        dislikes = await self.session.scalar(
            select(func.count()).select_from(AnnouncementReaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.reaction == "dislike",
            )
        )
        user_reaction = await self.session.scalar(
            select(AnnouncementReaction.reaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.user_id == user_id,
            )
        )
        return {
            "likes": int(likes or 0),
            "dislikes": int(dislikes or 0),
            "user_reaction": user_reaction,
        }

    async def set_reaction(self, *, community_id: UUID, announcement_id: UUID, user_id: UUID, reaction: str | None) -> dict[str, int | str | None]:
        result = await self.session.execute(
            select(AnnouncementReaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.user_id == user_id,
            )
        )
        item = result.scalars().first()
        if reaction is None or reaction == "":
            if item is not None:
                item.deleted_at = datetime.now(timezone.utc)
            return await self.reaction_summary(community_id, announcement_id, user_id)

        if item is None:
            item = AnnouncementReaction(
                id=uuid4(),
                community_id=community_id,
                announcement_id=announcement_id,
                user_id=user_id,
                reaction=reaction,
            )
            self.session.add(item)
        else:
            item.reaction = reaction
            item.deleted_at = None
        return await self.reaction_summary(community_id, announcement_id, user_id)


class ChatRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list_messages(self, community_id: UUID, thread_id: UUID) -> list[ChatMessage]:
        result = await self.session.execute(
            select(ChatMessage)
            .options(selectinload(ChatMessage.sender_user))
            .where(ChatMessage.community_id == community_id, ChatMessage.thread_id == thread_id, ChatMessage.deleted_at.is_(None))
            .order_by(ChatMessage.created_at.asc())
        )
        return list(result.scalars().all())

    async def send_message(self, *, community_id: UUID, sender_id: UUID, is_admin: bool, payload) -> ChatMessage:
        sender = await self.session.get(User, sender_id)
        if sender is None or sender.community_id != community_id or sender.deleted_at is not None:
            raise ValueError("Chat sender is not available in this community")

        msg = ChatMessage(
            id=uuid4(),
            community_id=community_id,
            thread_id=payload.thread_id,
            sender_user_id=sender_id,
            body=payload.body,
            audio_url=payload.audio_url,
            audio_duration=payload.audio_duration,
            is_admin=is_admin,
        )
        # Keep the relation available after commit so the response does not
        # trigger an async lazy load while FastAPI is serializing the message.
        msg.sender_user = sender
        self.session.add(msg)
        return msg

    async def summary(self, community_id: UUID) -> str:
        result = await self.session.execute(
            select(ChatMessage)
            .options(selectinload(ChatMessage.sender_user))
            .where(ChatMessage.community_id == community_id, ChatMessage.deleted_at.is_(None))
            .order_by(ChatMessage.created_at.desc())
            .limit(10)
        )
        messages = list(result.scalars().all())
        if not messages:
            return "No hay mensajes recientes para resumir."
        settings = get_settings()
        if not settings.groq_api_key:
            latest = messages[0]
            return (
                f"Se registraron {len(messages)} mensajes recientes en el chat comunitario. "
                f"El último mensaje fue enviado por {latest.sender_user_id} a las {latest.created_at:%H:%M}. "
                "Configura GROQ_API_KEY para activar el resumen generativo."
            )

        transcript = "\n".join(
            f"- {(getattr(item.sender_user, 'full_name', None) or item.sender_user_id)}: {item.body}"
            for item in reversed(messages)
        )

        prompt = (
            "Resume el siguiente chat comunitario en español, en 3 viñetas máximo. "
            "Resalta avisos, acuerdos y riesgos. No inventes información.\n\n"
            f"{transcript}"
        )

        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {settings.groq_api_key}",
                    "Content-Type": "application/json",
                },
                json={
                    "model": settings.groq_model,
                    "messages": [
                        {
                            "role": "system",
                            "content": "Eres un asistente que resume conversaciones de una comunidad residencial de forma clara y breve.",
                        },
                        {"role": "user", "content": prompt},
                    ],
                    "temperature": 0.2,
                },
            )
            response.raise_for_status()
            data = response.json()
            choices = data.get("choices") or []
            if choices:
                message = choices[0].get("message") or {}
                content = (message.get("content") or "").strip()
                if content:
                    return content

        latest = messages[0]
        return (
            f"Se registraron {len(messages)} mensajes recientes en el chat comunitario. "
            f"El último mensaje fue enviado por {latest.sender_user_id} a las {latest.created_at:%H:%M}."
        )

    async def ensure_default_thread(self, community_id: UUID) -> ChatThread:
        result = await self.session.execute(
            select(ChatThread).where(
                ChatThread.community_id == community_id,
                ChatThread.thread_type == ChatThreadType.community,
                ChatThread.deleted_at.is_(None),
            )
        )
        thread = result.scalars().first()
        if thread:
            return thread
        thread = ChatThread(
            id=uuid4(),
            community_id=community_id,
            thread_type=ChatThreadType.community,
            title="Chat comunitario",
        )
        self.session.add(thread)
        await self.session.flush()
        return thread


class ReportRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def list(self, community_id: UUID) -> list[Report]:
        result = await self.session.execute(
            select(Report).where(Report.community_id == community_id, Report.deleted_at.is_(None)).order_by(Report.created_at.desc())
        )
        return list(result.scalars().all())

    async def create(self, *, community_id: UUID, reporter_id: UUID, payload) -> Report:
        report = Report(
            id=uuid4(),
            community_id=community_id,
            reporter_user_id=reporter_id,
            title=payload.title,
            description=payload.description,
            latitude=payload.latitude,
            longitude=payload.longitude,
            evidence_url=payload.evidence_url,
            status=ReportStatus.pending,
        )
        self.session.add(report)
        return report

    async def update_status(self, *, community_id: UUID, report_id: UUID, status: ReportStatus) -> Report | None:
        result = await self.session.execute(
            select(Report).where(Report.community_id == community_id, Report.id == report_id, Report.deleted_at.is_(None))
        )
        report = result.scalars().first()
        if report is None:
            return None
        report.status = status
        return report

    async def emergency_profile(self, community_id: UUID, user_id: UUID) -> dict:
        result = await self.session.execute(
            select(User, ResidentProfile, Unit)
            .join(ResidentProfile, ResidentProfile.user_id == User.id)
            .join(Unit, Unit.id == ResidentProfile.unit_id)
            .where(User.community_id == community_id, User.id == user_id, User.deleted_at.is_(None), ResidentProfile.deleted_at.is_(None))
        )
        row = result.first()
        if not row:
            return {}
        user, profile, unit = row
        return {
            "nombre": user.full_name,
            "edad": None,
            "tipo_sangre": profile.blood_type,
            "padecimientos": profile.conditions,
            "alergias": profile.allergies,
            "contacto_emergencia": profile.emergency_contact_name,
            "direccion": f"{unit.tower} - {unit.unit_number}",
        }

    async def toggle_sos(self, *, community_id: UUID, resident_id: UUID, actor_id: UUID, active: bool) -> PanicAlert:
        alert = PanicAlert(
            id=uuid4(),
            community_id=community_id,
            resident_user_id=resident_id,
            activated_by_user_id=actor_id,
            status=PanicStatus.active if active else PanicStatus.resolved,
            message="SOS toggled from the app",
        )
        self.session.add(alert)
        return alert


class UserProfileRepository:
    def __init__(self, session: AsyncSession):
        self.session = session

    async def get_profile(self, community_id: UUID, user_id: UUID) -> dict:
        result = await self.session.execute(
            select(User, ResidentProfile, Unit, UserPreference)
            .join(ResidentProfile, ResidentProfile.user_id == User.id, isouter=True)
            .join(Unit, Unit.id == ResidentProfile.unit_id, isouter=True)
            .join(
                UserPreference,
                (UserPreference.user_id == User.id) & (UserPreference.community_id == User.community_id),
                isouter=True,
            )
            .where(User.community_id == community_id, User.id == user_id, User.deleted_at.is_(None))
        )
        row = result.first()
        if not row:
            return {}
        user, profile, unit, prefs = row
        address = prefs.address_text if prefs and prefs.address_text else (f"{unit.tower} - {unit.unit_number}" if unit else None)
        latitude = float(prefs.home_latitude) if prefs and prefs.home_latitude is not None else None
        longitude = float(prefs.home_longitude) if prefs and prefs.home_longitude is not None else None
        return {
            "id": str(user.id),
            "full_name": user.full_name,
            "email": user.email,
            "phone": user.phone,
            "avatar_url": user.avatar_url,
            "address": address,
            "latitude": latitude,
            "longitude": longitude,
            "blood_type": profile.blood_type if profile else None,
            "conditions": profile.conditions if profile else None,
            "allergies": profile.allergies if profile else None,
            "emergency_contact_name": profile.emergency_contact_name if profile else None,
        }

    async def update_profile(self, community_id: UUID, user_id: UUID, payload) -> dict:
        result = await self.session.execute(
            select(User, ResidentProfile, UserPreference)
            .join(ResidentProfile, ResidentProfile.user_id == User.id, isouter=True)
            .join(
                UserPreference,
                (UserPreference.user_id == User.id) & (UserPreference.community_id == User.community_id),
                isouter=True,
            )
            .where(User.community_id == community_id, User.id == user_id, User.deleted_at.is_(None))
        )
        row = result.first()
        if not row:
            raise ValueError("User not found")

        user, profile, prefs = row
        if payload.full_name is not None:
            user.full_name = payload.full_name
        if payload.email is not None:
            user.email = payload.email
        if payload.phone is not None:
            user.phone = payload.phone
        if payload.avatar_url is not None:
            user.avatar_url = payload.avatar_url

        if prefs is None:
            prefs = UserPreference(
                id=uuid4(),
                community_id=community_id,
                user_id=user_id,
                theme_mode="default",
                notifications_enabled=True,
                language="es",
            )
            self.session.add(prefs)
            await self.session.flush()

        if payload.address is not None:
            prefs.address_text = payload.address
        if payload.latitude is not None:
            prefs.home_latitude = payload.latitude
        if payload.longitude is not None:
            prefs.home_longitude = payload.longitude

        if profile and payload.address is not None:
            profile.conditions = profile.conditions

        return await self.get_profile(community_id, user_id)

    async def get_preferences(self, community_id: UUID, user_id: UUID) -> dict:
        result = await self.session.execute(
            select(UserPreference)
            .where(
                UserPreference.community_id == community_id,
                UserPreference.user_id == user_id,
            )
        )
        prefs = result.scalars().first()
        if prefs is None:
            prefs = UserPreference(
                id=uuid4(),
                community_id=community_id,
                user_id=user_id,
                theme_mode="default",
                notifications_enabled=True,
                language="es",
            )
            self.session.add(prefs)
            await self.session.flush()
        return {
            "theme_mode": prefs.theme_mode,
            "notifications_enabled": prefs.notifications_enabled,
            "language": prefs.language,
            "address": prefs.address_text,
            "latitude": float(prefs.home_latitude) if prefs.home_latitude is not None else None,
            "longitude": float(prefs.home_longitude) if prefs.home_longitude is not None else None,
        }

    async def update_preferences(self, community_id: UUID, user_id: UUID, payload) -> dict:
        result = await self.session.execute(
            select(UserPreference)
            .where(UserPreference.community_id == community_id, UserPreference.user_id == user_id)
        )
        prefs = result.scalars().first()
        if prefs is None:
            prefs = UserPreference(
                id=uuid4(),
                community_id=community_id,
                user_id=user_id,
                theme_mode="default",
                notifications_enabled=True,
                language="es",
            )
            self.session.add(prefs)
            await self.session.flush()

        if payload.theme_mode is not None:
            prefs.theme_mode = payload.theme_mode
        if payload.notifications_enabled is not None:
            prefs.notifications_enabled = payload.notifications_enabled
        if payload.language is not None:
            prefs.language = payload.language
        if payload.address is not None:
            prefs.address_text = payload.address
        if payload.latitude is not None:
            prefs.home_latitude = payload.latitude
        if payload.longitude is not None:
            prefs.home_longitude = payload.longitude

        return await self.get_preferences(community_id, user_id)

    async def list_notifications(self, community_id: UUID, user_id: UUID) -> list[UserNotification]:
        result = await self.session.execute(
            select(UserNotification)
            .where(
                UserNotification.community_id == community_id,
                UserNotification.user_id == user_id,
                UserNotification.deleted_at.is_(None),
            )
            .order_by(UserNotification.created_at.desc())
        )
        return list(result.scalars().all())

    async def mark_notification_read(self, community_id: UUID, user_id: UUID, notification_id: UUID) -> UserNotification | None:
        result = await self.session.execute(
            select(UserNotification).where(
                UserNotification.community_id == community_id,
                UserNotification.user_id == user_id,
                UserNotification.id == notification_id,
                UserNotification.deleted_at.is_(None),
            )
        )
        item = result.scalars().first()
        if item is None:
            return None
        item.is_read = True
        return item

    async def delete_notification(self, community_id: UUID, user_id: UUID, notification_id: UUID) -> bool:
        result = await self.session.execute(
            select(UserNotification).where(
                UserNotification.community_id == community_id,
                UserNotification.user_id == user_id,
                UserNotification.id == notification_id,
                UserNotification.deleted_at.is_(None),
            )
        )
        item = result.scalars().first()
        if item is None:
            return False
        item.deleted_at = datetime.now(timezone.utc)
        return True

    async def list_rules(self, community_id: UUID) -> list[CommunityRule]:
        result = await self.session.execute(
            select(CommunityRule)
            .where(CommunityRule.community_id == community_id, CommunityRule.deleted_at.is_(None), CommunityRule.is_active.is_(True))
            .order_by(CommunityRule.display_order.asc(), CommunityRule.created_at.asc())
        )
        return list(result.scalars().all())

    async def list_faqs(self, community_id: UUID) -> list[CommunityFaq]:
        result = await self.session.execute(
            select(CommunityFaq)
            .where(CommunityFaq.community_id == community_id, CommunityFaq.deleted_at.is_(None), CommunityFaq.is_active.is_(True))
            .order_by(CommunityFaq.created_at.asc())
        )
        return list(result.scalars().all())

    async def submit_faq_question(self, community_id: UUID, user_id: UUID, question: str) -> FaqQuestion:
        item = FaqQuestion(id=uuid4(), community_id=community_id, user_id=user_id, question=question, status="pending")
        self.session.add(item)
        return item
