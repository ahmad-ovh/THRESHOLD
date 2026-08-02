"""
Application configuration — reads from .env.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    # LLM
    llm_key: str = ""
    llm_base_url: str = "https://api.deepseek.com"
    llm_model: str = "deepseek-chat"

    # Database
    db_url: str = "sqlite+aiosqlite:///./threshold.db"

    # Progression
    xp_per_level: int = 100
    max_level: int = 100

    # Encounter
    max_turns_per_encounter: int = 6


@lru_cache
def get_settings() -> Settings:
    return Settings()
