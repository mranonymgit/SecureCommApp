from __future__ import annotations

import enum
from datetime import datetime
from uuid import UUID

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class UserRole(str, enum.Enum):
    admin = "admin"
    resident = "resident"


class AccountStatus(str, enum.Enum):
    pending = "pending"
    active = "active"
    suspended = "suspended"
    archived = "archived"


class VisitStatus(str, enum.Enum):
    requested = "requested"
    approved = "approved"
    inside = "inside"
    exited = "exited"
    denied = "denied"
    cancelled = "cancelled"


class ReportStatus(str, enum.Enum):
    pending = "pending"
    in_progress = "in_progress"
    resolved = "resolved"
    critical = "critical"
    cancelled = "cancelled"


class AnnouncementCategory(str, enum.Enum):
    general = "general"
    maintenance = "maintenance"
    meeting = "meeting"
    security = "security"
    urgent = "urgent"


class ChatThreadType(str, enum.Enum):
    community = "community"
    support = "support"


class PanicStatus(str, enum.Enum):
    inactive = "inactive"
    active = "active"
    resolved = "resolved"


class AccessAction(str, enum.Enum):
    entry = "entry"
    exit = "exit"
    validation = "validation"
    revocation = "revocation"


class PasswordChangeStatus(str, enum.Enum):
    pending = "pending"
    approved = "approved"
    rejected = "rejected"


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class Community(Base, TimestampMixin):
    __tablename__ = "communities"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    name: Mapped[str] = mapped_column(Text, nullable=False)
    slug: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    status: Mapped[AccountStatus] = mapped_column(Enum(AccountStatus, name="account_status", schema="app"), nullable=False)


class Unit(Base, TimestampMixin):
    __tablename__ = "units"
    __table_args__ = (UniqueConstraint("community_id", "tower", "unit_number", name="uq_unit_scope"), {"schema": "app"})

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    tower: Mapped[str] = mapped_column(Text, nullable=False)
    unit_number: Mapped[str] = mapped_column(Text, nullable=False)
    floor: Mapped[int | None] = mapped_column(Integer, nullable=True)
    status: Mapped[AccountStatus] = mapped_column(Enum(AccountStatus, name="account_status", schema="app"), nullable=False)


class User(Base, TimestampMixin):
    __tablename__ = "users"
    __table_args__ = (
        UniqueConstraint("community_id", "email", name="uq_user_email_scope"),
        UniqueConstraint("community_id", "phone", name="uq_user_phone_scope"),
        {"schema": "app"},
    )

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    unit_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.units.id", ondelete="RESTRICT"), nullable=True)
    role: Mapped[UserRole] = mapped_column(Enum(UserRole, name="user_role", schema="app"), nullable=False)
    full_name: Mapped[str] = mapped_column(Text, nullable=False)
    email: Mapped[str] = mapped_column(Text, nullable=False)
    phone: Mapped[str] = mapped_column(Text, nullable=False)
    password_hash: Mapped[str | None] = mapped_column(Text, nullable=True)
    avatar_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    document_ciphertext: Mapped[bytes | None] = mapped_column(nullable=True)
    status: Mapped[AccountStatus] = mapped_column(Enum(AccountStatus, name="account_status", schema="app"), nullable=False)


class ResidentProfile(Base, TimestampMixin):
    __tablename__ = "resident_profiles"
    __table_args__ = (UniqueConstraint("user_id", name="uq_resident_profile_user"), {"schema": "app"})

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    unit_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.units.id", ondelete="RESTRICT"), nullable=False)
    blood_type: Mapped[str | None] = mapped_column(Text, nullable=True)
    conditions: Mapped[str | None] = mapped_column(Text, nullable=True)
    allergies: Mapped[str | None] = mapped_column(Text, nullable=True)
    emergency_contact_name: Mapped[str | None] = mapped_column(Text, nullable=True)
    emergency_contact_phone_ciphertext: Mapped[bytes | None] = mapped_column(nullable=True)


class Visit(Base, TimestampMixin):
    __tablename__ = "visits"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    resident_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    visitor_name: Mapped[str] = mapped_column(Text, nullable=False)
    visitor_type: Mapped[str] = mapped_column(Text, nullable=False)
    qr_code: Mapped[str] = mapped_column(Text, nullable=False, unique=True)
    plate_ciphertext: Mapped[bytes | None] = mapped_column(nullable=True)
    status: Mapped[VisitStatus] = mapped_column(Enum(VisitStatus, name="visit_status", schema="app"), nullable=False)
    entry_guard_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=True)
    exit_guard_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=True)
    entry_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    exit_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)


class AccessLog(Base, TimestampMixin):
    __tablename__ = "access_logs"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    visit_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.visits.id", ondelete="RESTRICT"), nullable=False)
    actor_user_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=True)
    action: Mapped[AccessAction] = mapped_column(Enum(AccessAction, name="access_action", schema="app"), nullable=False)
    details: Mapped[dict] = mapped_column(JSONB, default=dict, nullable=False)
    visit = relationship("Visit", lazy="joined")


class Announcement(Base, TimestampMixin):
    __tablename__ = "announcements"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    created_by_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    category: Mapped[AnnouncementCategory] = mapped_column(Enum(AnnouncementCategory, name="announcement_category", schema="app"), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    link_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_important: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_by_user = relationship("User", foreign_keys=[created_by_user_id], lazy="joined")


class AnnouncementReaction(Base, TimestampMixin):
    __tablename__ = "announcement_reactions"
    __table_args__ = (UniqueConstraint("community_id", "announcement_id", "user_id", name="uq_announcement_reaction_scope"), {"schema": "app"})

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    announcement_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.announcements.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    reaction: Mapped[str] = mapped_column(Text, nullable=False)


class ChatThread(Base, TimestampMixin):
    __tablename__ = "chat_threads"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    thread_type: Mapped[ChatThreadType] = mapped_column(Enum(ChatThreadType, name="chat_thread_type", schema="app"), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)


class ChatMessage(Base, TimestampMixin):
    __tablename__ = "chat_messages"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    thread_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.chat_threads.id", ondelete="RESTRICT"), nullable=False)
    sender_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    audio_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    audio_duration: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    sender_user = relationship("User", foreign_keys=[sender_user_id], lazy="joined")


class Report(Base, TimestampMixin):
    __tablename__ = "reports"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    reporter_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    status: Mapped[ReportStatus] = mapped_column(Enum(ReportStatus, name="report_status", schema="app"), nullable=False)
    assigned_to_user_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=True)
    evidence_url: Mapped[str | None] = mapped_column(Text, nullable=True)
    reporter_user = relationship("User", foreign_keys=[reporter_user_id], lazy="joined")


class PanicAlert(Base, TimestampMixin):
    __tablename__ = "panic_alerts"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    resident_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    activated_by_user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    status: Mapped[PanicStatus] = mapped_column(Enum(PanicStatus, name="panic_status", schema="app"), nullable=False)
    message: Mapped[str | None] = mapped_column(Text, nullable=True)


class UserPreference(Base, TimestampMixin):
    __tablename__ = "user_preferences"
    __table_args__ = (UniqueConstraint("community_id", "user_id", name="uq_user_preferences_scope"), {"schema": "app"})

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    theme_mode: Mapped[str] = mapped_column(Text, nullable=False, default="default")
    notifications_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    language: Mapped[str] = mapped_column(Text, nullable=False, default="es")
    address_text: Mapped[str | None] = mapped_column(Text, nullable=True)
    home_latitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)
    home_longitude: Mapped[float | None] = mapped_column(Numeric(10, 7), nullable=True)


class UserNotification(Base, TimestampMixin):
    __tablename__ = "user_notifications"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    source_type: Mapped[str] = mapped_column(Text, nullable=False, default="system")
    is_read: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)


class CommunityRule(Base, TimestampMixin):
    __tablename__ = "community_rules"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    title: Mapped[str] = mapped_column(Text, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    display_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class CommunityFaq(Base, TimestampMixin):
    __tablename__ = "community_faqs"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    question: Mapped[str] = mapped_column(Text, nullable=False)
    answer: Mapped[str] = mapped_column(Text, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class FaqQuestion(Base, TimestampMixin):
    __tablename__ = "faq_questions"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    question: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(Text, nullable=False, default="pending")


class PasswordChangeApproval(Base, TimestampMixin):
    __tablename__ = "password_change_requests"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="RESTRICT"), nullable=False)
    user_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=False)
    requested_password_hash: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[PasswordChangeStatus] = mapped_column(Enum(PasswordChangeStatus, name="password_change_status", schema="app"), nullable=False, default=PasswordChangeStatus.pending)
    reviewed_by_user_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="RESTRICT"), nullable=True)
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    requester = relationship("User", foreign_keys=[user_id], lazy="joined")


class AuditLog(Base):
    __tablename__ = "audit_log"
    __table_args__ = {"schema": "app"}

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True)
    community_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.communities.id", ondelete="SET NULL"), nullable=True)
    table_name: Mapped[str] = mapped_column(Text, nullable=False)
    row_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), nullable=True)
    action: Mapped[str] = mapped_column(Text, nullable=False)
    changed_by_user_id: Mapped[UUID | None] = mapped_column(PGUUID(as_uuid=True), ForeignKey("app.users.id", ondelete="SET NULL"), nullable=True)
    old_data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    new_data: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
