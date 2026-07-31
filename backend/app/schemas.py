from datetime import datetime
from typing import Literal
from urllib.parse import urlparse
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator

from .models import AnnouncementCategory, PanicStatus, PasswordChangeStatus, ReportStatus, UserRole, VisitStatus


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class LoginUserOut(BaseModel):
    id: UUID
    username: str
    role: UserRole
    community_id: UUID
    full_name: str
    email: EmailStr
    phone: str
    avatar_url: str | None = None


class LoginResponse(BaseModel):
    access_token: str
    realtime_token: str | None = None
    token_type: str = "bearer"
    user: LoginUserOut


class RealtimeTokenResponse(BaseModel):
    realtime_token: str
    expires_in: int


class PasswordChangeRequest(BaseModel):
    new_password: str = Field(min_length=12, max_length=72)


class PublicPasswordChangeRequest(PasswordChangeRequest):
    community_slug: str = Field(min_length=2, max_length=120)
    email: EmailStr


class PasswordChangeRequestOut(BaseModel):
    id: UUID
    user_id: UUID
    full_name: str
    email: EmailStr
    status: PasswordChangeStatus
    created_at: datetime
    reviewed_at: datetime | None = None


class CommunityRuleCreate(BaseModel):
    title: str = Field(min_length=3, max_length=160)
    description: str = Field(min_length=3, max_length=4000)
    display_order: int = Field(default=0, ge=0)


class CommunityFaqCreate(BaseModel):
    question: str = Field(min_length=3, max_length=500)
    answer: str = Field(min_length=3, max_length=4000)


class FaqQuestionOut(BaseModel):
    id: UUID
    question: str
    status: str
    full_name: str
    email: EmailStr
    created_at: datetime


class FaqQuestionAnswer(BaseModel):
    answer: str = Field(min_length=3, max_length=4000)


class LoginRequest(BaseModel):
    community_slug: str
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: UUID
    community_id: UUID
    unit_id: UUID | None = None
    role: UserRole
    full_name: str
    email: EmailStr
    phone: str
    status: str
    avatar_url: str | None = None


class ProfileOut(BaseModel):
    id: UUID
    full_name: str
    email: EmailStr
    phone: str
    avatar_url: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class ProfileUpdateRequest(BaseModel):
    full_name: str | None = None
    email: EmailStr | None = None
    phone: str | None = None
    avatar_url: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class PreferencesOut(BaseModel):
    theme_mode: str
    notifications_enabled: bool
    language: str
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class PreferencesUpdateRequest(BaseModel):
    theme_mode: str | None = None
    notifications_enabled: bool | None = None
    language: str | None = None
    address: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class NotificationOut(BaseModel):
    id: UUID
    title: str
    message: str
    time: str
    is_read: bool
    source_type: str | None = None


class FaqOut(BaseModel):
    id: UUID
    question: str
    answer: str


class RuleOut(BaseModel):
    id: UUID
    title: str
    description: str


class DashboardStatsOut(BaseModel):
    total_residents: int
    active_visits_today: int
    pending_reports: int
    active_alerts: int


class ResidentCreate(BaseModel):
    full_name: str
    email: EmailStr
    phone: str
    initial_password: str = Field(min_length=12, max_length=72)
    unit_id: UUID | None = None
    unit_label: str | None = None
    blood_type: str | None = None
    conditions: str | None = None
    allergies: str | None = None
    emergency_contact_name: str | None = None
    emergency_contact_phone: str | None = None


class ResidentOut(BaseModel):
    id: UUID
    full_name: str
    email: EmailStr
    phone: str
    unit: str | None = None
    unit_id: UUID | None = None
    role: UserRole
    status: str
    blood_type: str | None = None
    illnesses: str | None = None
    allergies: str | None = None
    emergency_contact: str | None = None
    avatar_url: str | None = None


class ResidentStatusUpdate(BaseModel):
    active: bool


class AccessLogOut(BaseModel):
    id: UUID
    visitor_name: str
    resident_user_id: UUID
    time: datetime
    action: str
    status: str
    resident: str | None = None
    type: str | None = None
    plate: str | None = None
    qr_code: str | None = None
    entry_guard: str | None = None


class AnnouncementCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    category: AnnouncementCategory
    content: str = Field(min_length=3, max_length=10000)
    image_url: str | None = Field(default=None, max_length=1024)
    link_url: str | None = Field(default=None, max_length=2048)
    is_important: bool = False

    @field_validator("link_url")
    @classmethod
    def validate_link_url(cls, value: str | None) -> str | None:
        if value is None or value == "":
            return None
        parsed = urlparse(value)
        if parsed.scheme not in {"http", "https"} or not parsed.netloc:
            raise ValueError("link_url must be a complete HTTP or HTTPS URL")
        return value


class AnnouncementOut(BaseModel):
    id: UUID
    title: str
    category: AnnouncementCategory
    created_at: datetime
    author: str
    content: str
    image_url: str | None = None
    link_url: str | None = None
    is_important: bool
    likes: int = 0
    dislikes: int = 0
    user_reaction: str | None = None


class AnnouncementReactionRequest(BaseModel):
    reaction: Literal["like", "dislike"] | None = None


class ChatMessageCreate(BaseModel):
    thread_id: UUID
    body: str = Field(min_length=1, max_length=4000)
    audio_url: str | None = Field(default=None, max_length=1024)
    audio_duration: str | None = Field(default=None, pattern=r"^\d{1,6}$")


class ChatMessageOut(BaseModel):
    id: UUID
    sender: str
    body: str
    audio_url: str | None = None
    audio_duration: str | None = None
    created_at: datetime
    is_admin: bool
    usuario_id: UUID | None = None
    nombre_usuario: str | None = None
    avatar_url: str | None = None
    tipo_usuario: str | None = None
    texto: str | None = None
    duracion_audio_segundos: int | None = None
    fecha_hora: datetime | None = None
    es_mio: bool | None = None


class StorageUploadOut(BaseModel):
    object_path: str
    content_type: str
    size: int


class ReportCreate(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = Field(min_length=3, max_length=10000)
    latitude: float = Field(ge=-90, le=90)
    longitude: float = Field(ge=-180, le=180)
    evidence_url: str | None = Field(default=None, max_length=1024)


class ReportOut(BaseModel):
    id: UUID
    title: str
    location: str | None = None
    coords: str | None = None
    description: str
    latitude: float | None = None
    longitude: float | None = None
    status: ReportStatus
    reporter: str
    created_at: datetime
    evidence_url: str | None = None


class ReportStatusUpdate(BaseModel):
    status: ReportStatus


class EmergencyProfileOut(BaseModel):
    nombre: str
    edad: int | None = None
    tipo_sangre: str | None = None
    padecimientos: str | None = None
    alergias: str | None = None
    contacto_emergencia: str | None = None
    direccion: str | None = None
    sos_active: bool = False


class SosToggleRequest(BaseModel):
    active: bool


class FaqQuestionCreate(BaseModel):
    question: str


class PanicAlertOut(BaseModel):
    id: UUID
    status: PanicStatus
    created_at: datetime
    proximity_level: str | None = None


class SosProximityOut(BaseModel):
    active: bool
    level: str | None = None
    message: str | None = None
    latitude: float | None = None
    longitude: float | None = None
