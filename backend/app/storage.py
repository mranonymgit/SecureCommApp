from __future__ import annotations

import logging
from pathlib import Path
from uuid import UUID, uuid4

import httpx
from fastapi import HTTPException, UploadFile, status

from .core.config import get_settings

logger = logging.getLogger(__name__)


class SupabaseStorageService:
    """Private Supabase Storage access. The service-role key never reaches Flutter."""

    _POLICIES = {
        "report-evidence": ({"image/jpeg", "image/png", "image/webp"}, 5 * 1024 * 1024, "reports"),
        "avatar": ({"image/jpeg", "image/png", "image/webp"}, 2 * 1024 * 1024, "avatars"),
        "announcement-image": ({"image/jpeg", "image/png", "image/webp"}, 5 * 1024 * 1024, "announcements"),
        "chat-audio": ({"audio/mpeg", "audio/mp4", "audio/aac", "audio/ogg", "audio/webm", "audio/wav"}, 10 * 1024 * 1024, "chat"),
    }

    def __init__(self) -> None:
        self.settings = get_settings()

    def _headers(self, content_type: str | None = None) -> dict[str, str]:
        key = self.settings.supabase_secret_key or self.settings.supabase_service_role_key
        if not self.settings.supabase_project_url or not key:
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Supabase Storage is not configured")
        headers = {"apikey": key}
        # New sb_secret_* keys are not JWTs and must never be placed in a
        # Bearer header. Legacy service_role keys still require that header.
        if not key.startswith("sb_secret_"):
            headers["Authorization"] = f"Bearer {key}"
        if content_type:
            headers["Content-Type"] = content_type
        return headers

    async def upload(self, *, kind: str, community_id: UUID, user_id: UUID, file: UploadFile) -> dict[str, object]:
        if kind not in self._POLICIES:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Unsupported upload type")
        allowed_types, max_bytes, folder = self._POLICIES[kind]
        content_type = (file.content_type or "").split(";", 1)[0].lower()
        if content_type not in allowed_types:
            raise HTTPException(status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE, detail="Unsupported file type")

        content = await file.read(max_bytes + 1)
        if not content or len(content) > max_bytes:
            raise HTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, detail="File exceeds the permitted size")

        extension = Path(file.filename or "").suffix.lower()
        if not extension or len(extension) > 8:
            extension = {"image/jpeg": ".jpg", "image/png": ".png", "image/webp": ".webp", "audio/mpeg": ".mp3", "audio/mp4": ".m4a", "audio/aac": ".aac", "audio/ogg": ".ogg", "audio/webm": ".webm", "audio/wav": ".wav"}[content_type]
        object_path = f"communities/{community_id}/{folder}/{user_id}/{uuid4()}{extension}"
        base_url = self.settings.supabase_project_url.rstrip("/")
        url = f"{base_url}/storage/v1/object/{self.settings.supabase_storage_bucket}/{object_path}"
        try:
            async with httpx.AsyncClient(timeout=30) as client:
                # Supabase creates new objects with POST. PUT is reserved for
                # replacing an existing object and rejects newly generated paths.
                response = await client.post(
                    url,
                    headers={**self._headers(content_type), "x-upsert": "false"},
                    content=content,
                )
        except httpx.HTTPError as exc:
            logger.exception("Supabase Storage could not be reached for kind=%s", kind)
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="No fue posible conectar con Supabase Storage",
            ) from exc
        if response.status_code not in (200, 201):
            try:
                storage_detail = response.json().get("message") or response.json().get("error")
            except (ValueError, AttributeError):
                storage_detail = response.text[:300]
            logger.error(
                "Supabase Storage upload failed status=%s kind=%s bucket=%s detail=%s",
                response.status_code,
                kind,
                self.settings.supabase_storage_bucket,
                storage_detail,
            )
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="No fue posible guardar el archivo en Supabase Storage",
            )
        return {"object_path": object_path, "content_type": content_type, "size": len(content)}

    async def signed_url(self, object_path: str | None) -> str | None:
        if not object_path or not object_path.startswith("communities/"):
            return object_path
        key = self.settings.supabase_secret_key or self.settings.supabase_service_role_key
        if not self.settings.supabase_project_url or not key:
            logger.warning("Signed media URL requested before Supabase Storage was configured")
            return None
        base_url = self.settings.supabase_project_url.rstrip("/") if self.settings.supabase_project_url else ""
        url = f"{base_url}/storage/v1/object/sign/{self.settings.supabase_storage_bucket}/{object_path}"
        try:
            async with httpx.AsyncClient(timeout=15) as client:
                response = await client.post(
                    url,
                    headers=self._headers(),
                    json={"expiresIn": self.settings.supabase_storage_signed_url_seconds},
                )
        except httpx.HTTPError:
            logger.exception("Supabase Storage signed URL request failed")
            return None
        if response.status_code != 200:
            return None
        try:
            response_data = response.json()
        except ValueError:
            logger.error("Supabase Storage returned a malformed signed URL response")
            return None
        if not isinstance(response_data, dict):
            return None
        signed = response_data.get("signedURL") or response_data.get("signedUrl")
        return signed if isinstance(signed, str) and signed.startswith("http") else f"{base_url}/storage/v1{signed}" if signed else None
