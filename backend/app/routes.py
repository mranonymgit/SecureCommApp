from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from .core.deps import AuthClaims, get_current_claims, get_rls_session, require_admin
from .schemas import (
    AccessLogOut,
    AnnouncementCreate,
    AnnouncementOut,
    AnnouncementReactionRequest,
    ChatMessageCreate,
    ChatMessageOut,
    CommunityFaqCreate,
    CommunityRuleCreate,
    FaqOut,
    FaqQuestionCreate,
    FaqQuestionAnswer,
    FaqQuestionOut,
    DashboardStatsOut,
    EmergencyProfileOut,
    LoginResponse,
    LoginUserOut,
    LoginRequest,
    NotificationOut,
    PanicAlertOut,
    ReportCreate,
    ReportOut,
    ReportStatusUpdate,
    ResidentCreate,
    ResidentOut,
    PreferencesOut,
    PreferencesUpdateRequest,
    ProfileOut,
    ProfileUpdateRequest,
    RuleOut,
    SosToggleRequest,
    SosProximityOut,
    PasswordChangeRequest,
    PasswordChangeRequestOut,
    TokenResponse,
    StorageUploadOut,
)
from .services import AccessService, AnnouncementService, AuthService, ChatService, DashboardService, ReportService, ResidentService, UserProfileService
from .core.database import get_session
from .storage import SupabaseStorageService

router = APIRouter(prefix="/api")


async def _signed_media_url(value: str | None) -> str | None:
    try:
        return await SupabaseStorageService().signed_url(value)
    except Exception:
        # A missing storage configuration must not hide report or user data.
        return None


async def _serialize_report(item) -> ReportOut:
    return ReportOut(
        id=item.id,
        title=item.title,
        location="Ubicación registrada",
        coords=f"{item.latitude}, {item.longitude}" if item.latitude is not None and item.longitude is not None else "",
        description=item.description,
        latitude=float(item.latitude) if item.latitude is not None else None,
        longitude=float(item.longitude) if item.longitude is not None else None,
        status=item.status,
        reporter=str(item.reporter_user_id),
        created_at=item.created_at,
        evidence_url=await _signed_media_url(item.evidence_url),
    )


@router.post("/storage/{kind}", response_model=StorageUploadOut)
async def upload_storage_file(kind: str, file: UploadFile = File(...), claims: AuthClaims = Depends(get_current_claims)):
    if kind == "announcement-image" and claims.role != "admin":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only administrators can upload announcement images")
    storage = SupabaseStorageService()
    uploaded = await storage.upload(kind=kind, community_id=UUID(claims.community_id), user_id=UUID(claims.user_id), file=file)
    return StorageUploadOut(**uploaded)


async def _serialize_chat_message(item, current_user_id: UUID | None = None) -> ChatMessageOut:
    # All repository reads eager-load this relation. Avoid a lazy query here,
    # because response serialization happens after the route's commit.
    sender = item.__dict__.get("sender_user")
    audio_duration_seconds = None
    if item.audio_duration:
        try:
            if isinstance(item.audio_duration, str) and item.audio_duration.isdigit():
                audio_duration_seconds = int(item.audio_duration)
        except Exception:
            audio_duration_seconds = None

    return ChatMessageOut(
        id=item.id,
        sender=str(item.sender_user_id),
        body=item.body,
        audio_url=await _signed_media_url(item.audio_url),
        audio_duration=item.audio_duration,
        created_at=item.created_at,
        is_admin=item.is_admin,
        usuario_id=item.sender_user_id,
        nombre_usuario=sender.full_name if sender else str(item.sender_user_id),
        avatar_url=await _signed_media_url(getattr(sender, "avatar_url", None)),
        tipo_usuario="admin" if item.is_admin else "usuario",
        texto=item.body,
        duracion_audio_segundos=audio_duration_seconds,
        fecha_hora=item.created_at,
        es_mio=current_user_id is not None and item.sender_user_id == current_user_id,
    )


@router.post("/auth/login", response_model=LoginResponse)
async def login(payload: LoginRequest, session: AsyncSession = Depends(get_session)):
    service = AuthService(session)
    user, token = await service.login(payload.community_slug, payload.email, payload.password)
    await session.commit()
    return LoginResponse(
        access_token=token,
        user=LoginUserOut(
            id=user.id,
            username=user.email,
            role=user.role,
            community_id=user.community_id,
            full_name=user.full_name,
            email=user.email,
            phone=user.phone,
            avatar_url=await _signed_media_url(user.avatar_url),
        ),
    )


@router.post("/me/password")
async def change_password(
    payload: PasswordChangeRequest,
    session: AsyncSession = Depends(get_rls_session),
    claims: AuthClaims = Depends(get_current_claims),
):
    service = AuthService(session)
    if claims.role == "admin":
        updated = await service.change_password(UUID(claims.community_id), UUID(claims.user_id), payload.new_password)
        if not updated:
            return {"success": False}
        await session.commit()
        return {"success": True, "pending_approval": False}
    await service.request_password_change(UUID(claims.community_id), UUID(claims.user_id), payload.new_password)
    await session.commit()
    return {"success": True, "pending_approval": True}


@router.get("/admin/password-change-requests", response_model=list[PasswordChangeRequestOut], dependencies=[Depends(require_admin)])
async def list_password_change_requests(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    items = await AuthService(session).list_password_change_requests(UUID(claims.community_id))
    return [PasswordChangeRequestOut(id=item.id, user_id=item.user_id, full_name=item.requester.full_name if item.requester else "Residente", email=item.requester.email if item.requester else "unknown@example.invalid", status=item.status, created_at=item.created_at, reviewed_at=item.reviewed_at) for item in items]


@router.post("/admin/password-change-requests/{request_id}/{decision}", response_model=PasswordChangeRequestOut, dependencies=[Depends(require_admin)])
async def review_password_change_request(request_id: UUID, decision: str, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    if decision not in {"approve", "reject"}:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="Decision must be approve or reject")
    item = await AuthService(session).review_password_change_request(UUID(claims.community_id), request_id, UUID(claims.user_id), decision == "approve")
    await session.commit()
    return PasswordChangeRequestOut(id=item.id, user_id=item.user_id, full_name=item.requester.full_name if item.requester else "Residente", email=item.requester.email if item.requester else "unknown@example.invalid", status=item.status, created_at=item.created_at, reviewed_at=item.reviewed_at)


@router.get("/admin/dashboard/stats", response_model=DashboardStatsOut, dependencies=[Depends(require_admin)])
async def get_dashboard_stats(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = DashboardService(session)
    stats = await service.stats(UUID(claims.community_id))
    return DashboardStatsOut(**stats)


@router.get("/admin/residents", response_model=list[ResidentOut], dependencies=[Depends(require_admin)])
async def list_residents(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ResidentService(session)
    residents = await service.list(UUID(claims.community_id))
    for resident in residents:
        resident["avatar_url"] = await _signed_media_url(resident.get("avatar_url"))
    return [ResidentOut(**item) for item in residents]


@router.post("/admin/residents", response_model=ResidentOut, dependencies=[Depends(require_admin)])
async def create_resident(payload: ResidentCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ResidentService(session)
    user = await service.create(community_id=UUID(claims.community_id), payload=payload)
    await session.commit()
    return ResidentOut(
        id=user.id,
        full_name=user.full_name,
        email=user.email,
        phone=user.phone,
        unit=payload.unit_label,
        unit_id=user.unit_id,
        role=user.role,
        status=user.status.value if hasattr(user.status, "value") else str(user.status),
        blood_type=payload.blood_type,
        illnesses=payload.conditions,
        allergies=payload.allergies,
        emergency_contact=payload.emergency_contact_name,
        avatar_url="",
    )


@router.get("/admin/access-logs", response_model=list[AccessLogOut], dependencies=[Depends(require_admin)])
async def list_access_logs(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = AccessService(session)
    logs = await service.list_logs(UUID(claims.community_id))
    result = []
    for item in logs:
        visit = item.visit
        result.append(
            AccessLogOut(
                id=item.id,
                visitor_name=visit.visitor_name if visit else "",
                resident_user_id=visit.resident_user_id if visit else UUID(claims.user_id),
                time=item.created_at,
                action=item.action.value if hasattr(item.action, "value") else str(item.action),
                status=visit.status.value if visit and hasattr(visit.status, "value") else "unknown",
                resident=str(visit.resident_user_id) if visit else None,
                type=visit.visitor_type if visit else None,
                plate="",
                qr_code=visit.qr_code if visit else None,
                entry_guard=str(visit.entry_guard_id) if visit and visit.entry_guard_id else None,
            )
        )
    return result


@router.get("/admin/announcements", response_model=list[AnnouncementOut])
async def list_announcements(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = AnnouncementService(session)
    items = await service.list(UUID(claims.community_id))
    result = []
    for item in items:
        summary = await service.repo.reaction_summary(UUID(claims.community_id), item.id, UUID(claims.user_id))
        result.append(
            AnnouncementOut(
                id=item.id,
                title=item.title,
                category=item.category,
                created_at=item.created_at,
                author=item.created_by_user.full_name if getattr(item, "created_by_user", None) else "Administración",
                content=item.content,
                image_url=await _signed_media_url(item.image_url),
                link_url=item.link_url,
                is_important=item.is_important,
                likes=summary["likes"],
                dislikes=summary["dislikes"],
                user_reaction=summary["user_reaction"],
            )
        )
    return result


@router.post("/admin/announcements", response_model=AnnouncementOut, dependencies=[Depends(require_admin)])
async def create_announcement(payload: AnnouncementCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = AnnouncementService(session)
    item = await service.create(community_id=UUID(claims.community_id), author_id=UUID(claims.user_id), payload=payload)
    await session.commit()
    return AnnouncementOut(
        id=item.id,
        title=item.title,
        category=item.category,
        created_at=item.created_at,
        author=item.created_by_user.full_name if getattr(item, "created_by_user", None) else "Administración",
        content=item.content,
        image_url=await _signed_media_url(item.image_url),
        link_url=item.link_url,
        is_important=item.is_important,
        likes=0,
        dislikes=0,
        user_reaction=None,
    )


@router.post("/admin/announcements/{announcement_id}/reaction")
async def react_to_announcement(announcement_id: UUID, payload: AnnouncementReactionRequest, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = AnnouncementService(session)
    summary = await service.repo.set_reaction(
        community_id=UUID(claims.community_id),
        announcement_id=announcement_id,
        user_id=UUID(claims.user_id),
        reaction=payload.reaction.lower() if payload.reaction else None,
    )
    await session.commit()
    return {"success": True, **summary}


@router.get("/chat/thread/default")
async def get_default_thread(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ChatService(session)
    thread = await service.default_thread(UUID(claims.community_id))
    await session.commit()
    return {"id": str(thread.id), "title": thread.title}


@router.get("/chat/summary")
async def get_chat_summary(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ChatService(session)
    summary = await service.summary(UUID(claims.community_id))
    return {"summary": summary}


@router.get("/chat/messages", response_model=list[ChatMessageOut])
async def list_chat_messages(thread_id: UUID, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ChatService(session)
    messages = await service.list_messages(UUID(claims.community_id), thread_id)
    current_user_id = UUID(claims.user_id)
    return [await _serialize_chat_message(item, current_user_id=current_user_id) for item in messages]


@router.post("/chat/messages", response_model=ChatMessageOut)
async def send_chat_message(payload: ChatMessageCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ChatService(session)
    item = await service.send_message(
        community_id=UUID(claims.community_id),
        sender_id=UUID(claims.user_id),
        is_admin=claims.role == "admin",
        payload=payload,
    )
    await session.commit()
    return await _serialize_chat_message(item, current_user_id=UUID(claims.user_id))


@router.get("/admin/reports", response_model=list[ReportOut])
async def list_reports(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ReportService(session)
    items = await service.list(UUID(claims.community_id))
    return [await _serialize_report(item) for item in items]


@router.post("/admin/reports", response_model=ReportOut)
async def create_report(payload: ReportCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ReportService(session)
    item = await service.create(community_id=UUID(claims.community_id), reporter_id=UUID(claims.user_id), payload=payload)
    await session.commit()
    return await _serialize_report(item)


@router.patch("/admin/reports/{report_id}/status", response_model=ReportOut, dependencies=[Depends(require_admin)])
async def update_report_status(report_id: UUID, payload: ReportStatusUpdate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ReportService(session)
    item = await service.update_status(community_id=UUID(claims.community_id), report_id=report_id, new_status=payload.status)
    await session.commit()
    return await _serialize_report(item)


@router.get("/me/emergency-profile", response_model=EmergencyProfileOut)
async def get_emergency_profile(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ReportService(session)
    profile = await service.emergency_profile(community_id=UUID(claims.community_id), user_id=UUID(claims.user_id))
    return EmergencyProfileOut(**profile)


@router.post("/me/sos", response_model=PanicAlertOut)
async def toggle_sos(payload: SosToggleRequest, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = ReportService(session)
    alert, level = await service.toggle_sos(
        community_id=UUID(claims.community_id),
        resident_id=UUID(claims.user_id),
        actor_id=UUID(claims.user_id),
        active=payload.active,
    )
    await session.commit()
    return PanicAlertOut(id=alert.id, status=alert.status, created_at=alert.created_at, proximity_level=level)


@router.get("/me/sos/proximity", response_model=SosProximityOut)
async def get_sos_proximity(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    data = await ReportService(session).sos_proximity(community_id=UUID(claims.community_id), user_id=UUID(claims.user_id), is_admin=claims.role == "admin")
    return SosProximityOut(**data)


@router.get("/me/profile", response_model=ProfileOut)
async def get_profile(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    profile = await service.get_profile(UUID(claims.community_id), UUID(claims.user_id))
    profile["avatar_url"] = await _signed_media_url(profile.get("avatar_url"))
    return ProfileOut(**profile)


@router.patch("/me/profile", response_model=ProfileOut)
async def update_profile(payload: ProfileUpdateRequest, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    profile = await service.update_profile(UUID(claims.community_id), UUID(claims.user_id), payload)
    profile["avatar_url"] = await _signed_media_url(profile.get("avatar_url"))
    await session.commit()
    return ProfileOut(**profile)


@router.get("/me/preferences", response_model=PreferencesOut)
async def get_preferences(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    prefs = await service.get_preferences(UUID(claims.community_id), UUID(claims.user_id))
    return PreferencesOut(**prefs)


@router.patch("/me/preferences", response_model=PreferencesOut)
async def update_preferences(payload: PreferencesUpdateRequest, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    prefs = await service.update_preferences(UUID(claims.community_id), UUID(claims.user_id), payload)
    await session.commit()
    return PreferencesOut(**prefs)


@router.get("/me/notifications", response_model=list[NotificationOut])
async def list_notifications(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    items = await service.list_notifications(UUID(claims.community_id), UUID(claims.user_id))
    return [
        NotificationOut(
            id=item.id,
            title=item.title,
            message=item.message,
            time=item.created_at.isoformat(),
            is_read=item.is_read,
            source_type=item.source_type,
        )
        for item in items
    ]


@router.patch("/me/notifications/{notification_id}/read", response_model=NotificationOut)
async def mark_notification_read(notification_id: UUID, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    item = await service.mark_notification_read(UUID(claims.community_id), UUID(claims.user_id), notification_id)
    if item is None:
        return NotificationOut(id=notification_id, title="", message="", time="", is_read=False, source_type=None)
    await session.commit()
    return NotificationOut(
        id=item.id,
        title=item.title,
        message=item.message,
        time=item.created_at.isoformat(),
        is_read=item.is_read,
        source_type=item.source_type,
    )


@router.delete("/me/notifications/{notification_id}")
async def delete_notification(notification_id: UUID, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    deleted = await service.delete_notification(UUID(claims.community_id), UUID(claims.user_id), notification_id)
    if deleted:
        await session.commit()
    return {"success": deleted}


@router.get("/community/rules", response_model=list[RuleOut])
async def list_rules(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    items = await service.list_rules(UUID(claims.community_id))
    return [RuleOut(id=item.id, title=item.title, description=item.description) for item in items]


@router.get("/community/faqs", response_model=list[FaqOut])
async def list_faqs(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    items = await service.list_faqs(UUID(claims.community_id))
    return [FaqOut(id=item.id, question=item.question, answer=item.answer) for item in items]


@router.post("/community/faqs/questions")
async def submit_faq_question(payload: FaqQuestionCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    service = UserProfileService(session)
    item = await service.submit_faq_question(UUID(claims.community_id), UUID(claims.user_id), payload.question)
    await session.commit()
    return {"success": True, "id": str(item.id)}


@router.post("/admin/community/rules", response_model=RuleOut, dependencies=[Depends(require_admin)])
async def create_rule(payload: CommunityRuleCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    item = await UserProfileService(session).create_rule(UUID(claims.community_id), payload)
    await session.commit()
    return RuleOut(id=item.id, title=item.title, description=item.description)


@router.post("/admin/community/faqs", response_model=FaqOut, dependencies=[Depends(require_admin)])
async def create_faq(payload: CommunityFaqCreate, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    item = await UserProfileService(session).create_faq(UUID(claims.community_id), payload)
    await session.commit()
    return FaqOut(id=item.id, question=item.question, answer=item.answer)


@router.get("/admin/community/faqs/questions", response_model=list[FaqQuestionOut], dependencies=[Depends(require_admin)])
async def list_faq_questions(session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    items = await UserProfileService(session).list_faq_questions(UUID(claims.community_id))
    return [FaqQuestionOut(id=item.id, question=item.question, status=item.status, full_name=user.full_name, email=user.email, created_at=item.created_at) for item, user in items]


@router.post("/admin/community/faqs/questions/{question_id}/answer", response_model=FaqOut, dependencies=[Depends(require_admin)])
async def answer_faq_question(question_id: UUID, payload: FaqQuestionAnswer, session: AsyncSession = Depends(get_rls_session), claims: AuthClaims = Depends(get_current_claims)):
    item = await UserProfileService(session).answer_faq_question(UUID(claims.community_id), question_id, payload.answer)
    await session.commit()
    return FaqOut(id=item.id, question=item.question, answer=item.answer)
