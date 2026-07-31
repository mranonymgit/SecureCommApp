from __future__ import annotations

from pathlib import Path
from uuid import UUID, uuid4

import httpx
from fastapi import HTTPException, UploadFile, status

from .core.config import get_settings


class SupabaseStorageService:
    """Private Supabase Storage access. The service-role key never reaches Flutter."""

    _POLICIES = {
        "report-evidence": ({"image/jpeg", "image/png", "image/webp"}, 5 * 1024 * 1024, "reports"),
        "avatar": ({"image/jpeg", "image/png", "image/webp"}, 2 * 1024 * 1024, "avatars"),
        "chat-audio": ({"audio/mpeg", "audio/mp4", "audio/aac", "audio/ogg", "audio/webm", "audio/wav"}, 10 * 1024 * 1024, "chat"),
    }

    def __init__(self) -> None:
        self.settings = get_settings()

    def _headers(self, content_type: str | None = None) -> dict[str, str]:
        key = self.settings.supabase_service_role_key
        if not self.settings.supabase_project_url or not key:
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, detail="Supabase Storage is not configured")
        headers = {"Authorization": f"Bearer {key}", "apikey": key}
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
        async with httpx.AsyncClient(timeout=30) as client:
            response = await client.put(url, headers={**self._headers(content_type), "x-upsert": "false"}, content=content)
        if response.status_code not in (200, 201):
            raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail="Storage upload failed")
        return {"object_path": object_path, "content_type": content_type, "size": len(content)}

    async def signed_url(self, object_path: str | None) -> str | None:
        if not object_path or not object_path.startswith("communities/"):
            return object_path
        base_url = self.settings.supabase_project_url.rstrip("/") if self.settings.supabase_project_url else ""
        url = f"{base_url}/storage/v1/object/sign/{self.settings.supabase_storage_bucket}/{object_path}"
        async with httpx.AsyncClient(timeout=15) as client:
            response = await client.post(url, headers=self._headers(), json={"expiresIn": self.settings.supabase_storage_signed_url_seconds})
        if response.status_code != 200:
            return None
        signed = response.json().get("signedURL") or response.json().get("signedUrl")
        return signed if isinstance(signed, str) and signed.startswith("http") else f"{base_url}/storage/v1{signed}" if signed else None
