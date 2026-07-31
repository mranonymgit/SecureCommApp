from __future__ import annotations

from datetime import date, datetime, timezone
from math import asin, cos, radians, sin, sqrt
from uuid import UUID, uuid4

import httpx
from sqlalchemy import func, select, text, update
from sqlalchemy.dialects.postgresql import insert as pg_insert
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
    PasswordChangeApproval,
    PasswordChangeStatus,
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

    async def request_password_change_by_email(self, community_slug: str, email: str, password_hash: str) -> bool:
        user = await self.get_user_for_login(community_slug, email)
        if user is None or user.role != UserRole.resident:
            return False
        await self.create_password_change_request(user.community_id, user.id, password_hash)
        return True

    async def create_password_change_request(self, community_id: UUID, user_id: UUID, password_hash: str) -> PasswordChangeApproval:
        result = await self.session.execute(
            select(PasswordChangeApproval).options(selectinload(PasswordChangeApproval.requester)).where(
                PasswordChangeApproval.community_id == community_id,
                PasswordChangeApproval.user_id == user_id,
                PasswordChangeApproval.status == PasswordChangeStatus.pending,
                PasswordChangeApproval.deleted_at.is_(None),
            )
        )
        pending = result.scalars().first()
        if pending:
            pending.requested_password_hash = password_hash
            return pending
        item = PasswordChangeApproval(
            id=uuid4(), community_id=community_id, user_id=user_id,
            requested_password_hash=password_hash, status=PasswordChangeStatus.pending,
        )
        self.session.add(item)
        return item

    async def list_password_change_requests(self, community_id: UUID) -> list[PasswordChangeApproval]:
        result = await self.session.execute(
            select(PasswordChangeApproval)
            .options(selectinload(PasswordChangeApproval.requester))
            .where(PasswordChangeApproval.community_id == community_id, PasswordChangeApproval.deleted_at.is_(None))
            .order_by(PasswordChangeApproval.created_at.desc())
        )
        return list(result.scalars().all())

    async def review_password_change_request(self, community_id: UUID, request_id: UUID, reviewer_id: UUID, approved: bool) -> PasswordChangeApproval | None:
        result = await self.session.execute(
            select(PasswordChangeApproval).options(selectinload(PasswordChangeApproval.requester)).where(
                PasswordChangeApproval.id == request_id,
                PasswordChangeApproval.community_id == community_id,
                PasswordChangeApproval.status == PasswordChangeStatus.pending,
                PasswordChangeApproval.deleted_at.is_(None),
            )
        )
        item = result.scalars().first()
        if item is None:
            return None
        item.status = PasswordChangeStatus.approved if approved else PasswordChangeStatus.rejected
        item.reviewed_by_user_id = reviewer_id
        item.reviewed_at = datetime.now(timezone.utc)
        if approved:
            updated = await self.update_password(community_id, item.user_id, item.requested_password_hash)
            if not updated:
                return None
        return item


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
                    "avatar_url": user.avatar_url,
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

    async def set_active(self, community_id: UUID, user_id: UUID, active: bool) -> User | None:
        result = await self.session.execute(select(User).where(User.community_id == community_id, User.id == user_id, User.role == UserRole.resident, User.deleted_at.is_(None)))
        user = result.scalars().first()
        if user is None:
            return None
        user.status = AccountStatus.active if active else AccountStatus.suspended
        return user

    async def soft_delete(self, community_id: UUID, user_id: UUID) -> bool:
        result = await self.session.execute(select(User).where(User.community_id == community_id, User.id == user_id, User.role == UserRole.resident, User.deleted_at.is_(None)))
        user = result.scalars().first()
        if user is None:
            return False
        deleted_at = datetime.now(timezone.utc)
        user.deleted_at = deleted_at
        user.status = AccountStatus.archived
        for model in (
            ResidentProfile,
            UserPreference,
            UserNotification,
            PasswordChangeApproval,
        ):
            await self.session.execute(
                update(model)
                .where(
                    model.community_id == community_id,
                    model.user_id == user_id,
                    model.deleted_at.is_(None),
                )
                .values(deleted_at=deleted_at)
            )
        return True


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
        author = await self.session.get(User, author_id)
        if (
            author is None
            or author.community_id != community_id
            or author.status != AccountStatus.active
            or author.deleted_at is not None
        ):
            raise ValueError("Announcement author is not available in this community")
        if payload.image_url and not payload.image_url.startswith(
            f"communities/{community_id}/announcements/{author_id}/"
        ):
            raise ValueError("Announcement image does not belong to this user")
        item = Announcement(
            id=uuid4(),
            community_id=community_id,
            created_by_user_id=author_id,
            category=payload.category,
            title=payload.title,
            content=payload.content,
            image_url=payload.image_url,
            link_url=payload.link_url,
            is_important=payload.is_important,
        )
        # Keep the author relationship available for the response after commit.
        item.created_by_user = author
        self.session.add(item)
        await _notify_role(self.session, community_id, UserRole.resident, "Nuevo aviso", f"Administración publicó: {payload.title}", "announcement")
        await self.session.flush()
        return item

    async def reaction_summary(self, community_id: UUID, announcement_id: UUID, user_id: UUID) -> dict[str, int | str | None]:
        likes = await self.session.scalar(
            select(func.count()).select_from(AnnouncementReaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.reaction == "like",
                AnnouncementReaction.deleted_at.is_(None),
            )
        )
        dislikes = await self.session.scalar(
            select(func.count()).select_from(AnnouncementReaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.reaction == "dislike",
                AnnouncementReaction.deleted_at.is_(None),
            )
        )
        user_reaction = await self.session.scalar(
            select(AnnouncementReaction.reaction).where(
                AnnouncementReaction.community_id == community_id,
                AnnouncementReaction.announcement_id == announcement_id,
                AnnouncementReaction.user_id == user_id,
                AnnouncementReaction.deleted_at.is_(None),
            )
        )
        return {
            "likes": int(likes or 0),
            "dislikes": int(dislikes or 0),
            "user_reaction": user_reaction,
        }

    async def set_reaction(self, *, community_id: UUID, announcement_id: UUID, user_id: UUID, reaction: str | None) -> dict[str, int | str | None]:
        if reaction not in {None, "", "like", "dislike"}:
            raise ValueError("Unsupported announcement reaction")
        announcement_exists = await self.session.scalar(
            select(Announcement.id).where(
                Announcement.id == announcement_id,
                Announcement.community_id == community_id,
                Announcement.deleted_at.is_(None),
            )
        )
        if announcement_exists is None:
            raise LookupError("Announcement not found in this community")
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
            await self.session.flush()
            return await self.reaction_summary(community_id, announcement_id, user_id)

        await self.session.execute(
            pg_insert(AnnouncementReaction)
            .values(
                id=uuid4(),
                community_id=community_id,
                announcement_id=announcement_id,
                user_id=user_id,
                reaction=reaction,
            )
            .on_conflict_do_update(
                index_elements=[
                    AnnouncementReaction.community_id,
                    AnnouncementReaction.announcement_id,
                    AnnouncementReaction.user_id,
                ],
                set_={
                    "reaction": reaction,
                    "deleted_at": None,
                    "updated_at": func.now(),
                },
            )
        )
        await self.session.flush()
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
        if (
            sender is None
            or sender.community_id != community_id
            or sender.status != AccountStatus.active
            or sender.deleted_at is not None
        ):
            raise ValueError("Chat sender is not available in this community")
        thread = await self.session.scalar(
            select(ChatThread).where(
                ChatThread.id == payload.thread_id,
                ChatThread.community_id == community_id,
                ChatThread.thread_type == ChatThreadType.community,
                ChatThread.deleted_at.is_(None),
            )
        )
        if thread is None:
            raise LookupError("Chat thread not found in this community")
        if payload.audio_url and not payload.audio_url.startswith(
            f"communities/{community_id}/chat/{sender_id}/"
        ):
            raise ValueError("Chat audio does not belong to this user")

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
        recipients = await self.session.execute(select(User.id).where(User.community_id == community_id, User.id != sender_id, User.status == AccountStatus.active, User.deleted_at.is_(None)))
        self.session.add_all([UserNotification(id=uuid4(), community_id=community_id, user_id=user_id, title="Nuevo mensaje comunitario", message=f"{sender.full_name}: {'envió un audio' if payload.audio_url else payload.body[:180]}", source_type="chat") for user_id in recipients.scalars().all()])
        await self.session.flush()
        return msg

    async def summary(self, community_id: UUID) -> str:
        result = await self.session.execute(
            select(ChatMessage)
            .options(selectinload(ChatMessage.sender_user))
            .where(ChatMessage.community_id == community_id, ChatMessage.deleted_at.is_(None))
            .order_by(ChatMessage.created_at.desc())
            .limit(80)
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
            f"- {'Administración' if item.is_admin else (getattr(item.sender_user, 'full_name', None) or 'Residente')}: "
            f"{item.body if not item.audio_url else '[envió un audio]'}"
            for item in reversed(messages)
        )

        prompt = (
            "Resume el siguiente chat comunitario completo en español, en máximo 3 frases. "
            "Indica quién dijo qué y la respuesta relevante. Si solo hubo saludos, dilo claramente. "
            "Incluye acuerdos, preguntas sin respuesta y riesgos, pero nunca inventes información.\n\n"
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
        reporter = await self.session.get(User, reporter_id)
        if (
            reporter is None
            or reporter.community_id != community_id
            or reporter.status != AccountStatus.active
            or reporter.deleted_at is not None
        ):
            raise ValueError("Report author is not active in this community")
        if payload.evidence_url and not payload.evidence_url.startswith(
            f"communities/{community_id}/reports/{reporter_id}/"
        ):
            raise ValueError("Report evidence does not belong to this user")
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
        report.reporter_user = reporter
        self.session.add(report)
        await _notify_role(self.session, community_id, UserRole.admin, "Nuevo reporte", f"Se reportó: {payload.title}", "report")
        await self.session.flush()
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
        active_sos = await self.session.scalar(
            select(func.count())
            .select_from(PanicAlert)
            .where(
                PanicAlert.community_id == community_id,
                PanicAlert.resident_user_id == user_id,
                PanicAlert.status == PanicStatus.active,
                PanicAlert.deleted_at.is_(None),
            )
        )
        return {
            "nombre": user.full_name,
            "edad": None,
            "tipo_sangre": profile.blood_type,
            "padecimientos": profile.conditions,
            "alergias": profile.allergies,
            "contacto_emergencia": profile.emergency_contact_name,
            "direccion": f"{unit.tower} - {unit.unit_number}",
            "sos_active": bool(active_sos),
        }

    async def toggle_sos(self, *, community_id: UUID, resident_id: UUID, actor_id: UUID, active: bool) -> tuple[PanicAlert, str]:
        await self.session.execute(
            text("select pg_advisory_xact_lock(hashtextextended(:resident_key, 0))"),
            {"resident_key": f"{community_id}:{resident_id}:sos"},
        )
        active_alert_query = (
            select(PanicAlert)
            .where(
                PanicAlert.community_id == community_id,
                PanicAlert.resident_user_id == resident_id,
                PanicAlert.status == PanicStatus.active,
                PanicAlert.deleted_at.is_(None),
            )
            .order_by(PanicAlert.created_at.desc())
        )
        if not active:
            result = await self.session.execute(active_alert_query)
            alert = result.scalars().first()
            if alert is None:
                alert = PanicAlert(id=uuid4(), community_id=community_id, resident_user_id=resident_id, activated_by_user_id=actor_id, status=PanicStatus.resolved, message="SOS resolved from the app")
                self.session.add(alert)
            else:
                alert.status = PanicStatus.resolved
            return alert, "resolved"
        result = await self.session.execute(active_alert_query)
        existing_alert = result.scalars().first()
        if existing_alert is not None:
            return existing_alert, "active"
        alert = PanicAlert(
            id=uuid4(),
            community_id=community_id,
            resident_user_id=resident_id,
            activated_by_user_id=actor_id,
            status=PanicStatus.active if active else PanicStatus.resolved,
            message="SOS toggled from the app",
        )
        self.session.add(alert)
        location = await self.session.execute(select(UserPreference.home_latitude, UserPreference.home_longitude).where(UserPreference.community_id == community_id, UserPreference.user_id == resident_id, UserPreference.deleted_at.is_(None)))
        origin = location.first()
        latitude = float(origin[0]) if origin and origin[0] is not None else None
        longitude = float(origin[1]) if origin and origin[1] is not None else None
        actor = await self.session.get(User, resident_id)
        users = await self.session.execute(select(User, UserPreference).join(UserPreference, (UserPreference.user_id == User.id) & (UserPreference.community_id == User.community_id), isouter=True).where(User.community_id == community_id, User.id != resident_id, User.status == AccountStatus.active, User.deleted_at.is_(None)))
        for user, preference in users.all():
            level = "notification"
            if user.role == UserRole.resident and latitude is not None and longitude is not None and preference and preference.home_latitude is not None and preference.home_longitude is not None:
                distance = _distance_meters(latitude, longitude, float(preference.home_latitude), float(preference.home_longitude))
                level = "critical_nearby" if distance <= 200 else "warning" if distance <= 250 else "notification"
            self.session.add(UserNotification(id=uuid4(), community_id=community_id, user_id=user.id, title="SOS cercano" if level == "critical_nearby" else "Alerta SOS de la comunidad", message=f"{actor.full_name if actor else 'Un residente'} activó SOS.", source_type=f"sos:{level}"))
        return alert, "active"

    async def sos_proximity(self, community_id: UUID, user_id: UUID, is_admin: bool) -> dict:
        result = await self.session.execute(select(PanicAlert).where(PanicAlert.community_id == community_id, PanicAlert.status == PanicStatus.active, PanicAlert.deleted_at.is_(None)).order_by(PanicAlert.created_at.desc()))
        alert = result.scalars().first()
        if alert is None or alert.resident_user_id == user_id:
            return {"active": False}
        origin = await self.session.execute(select(UserPreference.home_latitude, UserPreference.home_longitude).where(UserPreference.community_id == community_id, UserPreference.user_id == alert.resident_user_id, UserPreference.deleted_at.is_(None)))
        target = await self.session.execute(select(UserPreference.home_latitude, UserPreference.home_longitude).where(UserPreference.community_id == community_id, UserPreference.user_id == user_id, UserPreference.deleted_at.is_(None)))
        source_row, target_row = origin.first(), target.first()
        latitude = float(source_row[0]) if source_row and source_row[0] is not None else None
        longitude = float(source_row[1]) if source_row and source_row[1] is not None else None
        level = "notification"
        if not is_admin and latitude is not None and longitude is not None and target_row and target_row[0] is not None and target_row[1] is not None:
            distance = _distance_meters(latitude, longitude, float(target_row[0]), float(target_row[1]))
            level = "critical_nearby" if distance <= 200 else "warning" if distance <= 250 else "notification"
        return {"active": True, "level": level, "message": "Un residente activó una alerta SOS.", "latitude": latitude, "longitude": longitude}


async def _notify_role(session: AsyncSession, community_id: UUID, role: UserRole, title: str, message: str, source_type: str) -> None:
    result = await session.execute(select(User.id).where(User.community_id == community_id, User.role == role, User.status == AccountStatus.active, User.deleted_at.is_(None)))
    session.add_all([UserNotification(id=uuid4(), community_id=community_id, user_id=user_id, title=title, message=message, source_type=source_type) for user_id in result.scalars().all()])


def _distance_meters(latitude_a: float, longitude_a: float, latitude_b: float, longitude_b: float) -> float:
    delta_lat, delta_lon = radians(latitude_b - latitude_a), radians(longitude_b - longitude_a)
    value = sin(delta_lat / 2) ** 2 + cos(radians(latitude_a)) * cos(radians(latitude_b)) * sin(delta_lon / 2) ** 2
    return 6371000 * 2 * asin(sqrt(value))


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
            if not payload.avatar_url.startswith(
                f"communities/{community_id}/avatars/{user_id}/"
            ):
                raise ValueError("Avatar does not belong to this user")
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

    async def create_rule(self, community_id: UUID, payload) -> CommunityRule:
        item = CommunityRule(id=uuid4(), community_id=community_id, title=payload.title, description=payload.description, display_order=payload.display_order, is_active=True)
        self.session.add(item)
        return item

    async def create_faq(self, community_id: UUID, payload) -> CommunityFaq:
        item = CommunityFaq(id=uuid4(), community_id=community_id, question=payload.question, answer=payload.answer, is_active=True)
        self.session.add(item)
        return item

    async def list_faq_questions(self, community_id: UUID) -> list[tuple[FaqQuestion, User]]:
        result = await self.session.execute(
            select(FaqQuestion, User).join(User, User.id == FaqQuestion.user_id).where(
                FaqQuestion.community_id == community_id, FaqQuestion.deleted_at.is_(None)
            ).order_by(FaqQuestion.created_at.desc())
        )
        return list(result.all())

    async def answer_faq_question(self, community_id: UUID, question_id: UUID, answer: str) -> CommunityFaq | None:
        result = await self.session.execute(
            select(FaqQuestion).where(
                FaqQuestion.id == question_id, FaqQuestion.community_id == community_id,
                FaqQuestion.deleted_at.is_(None), FaqQuestion.status == "pending",
            )
        )
        submitted = result.scalars().first()
        if submitted is None:
            return None
        submitted.status = "answered"
        faq = CommunityFaq(id=uuid4(), community_id=community_id, question=submitted.question, answer=answer, is_active=True)
        self.session.add(faq)
        return faq
