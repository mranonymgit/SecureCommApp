from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_name: str = "SCA API"
    app_env: str = "production"
    database_url: str
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 120
    encryption_key: str | None = None
    supabase_project_url: str | None = None
    supabase_anon_key: str | None = None
    supabase_service_role_key: str | None = None
    supabase_storage_bucket: str = "sca-media"
    supabase_storage_signed_url_seconds: int = 900
    groq_api_key: str | None = None
    groq_model: str = "llama-3.3-70b-versatile"


@lru_cache
def get_settings() -> Settings:
    return Settings()
