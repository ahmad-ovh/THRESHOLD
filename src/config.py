import os
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


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
    max_turns_safety_limit: int = 8
    min_turns_before_end: int = 3

    @property
    def effective_db_url(self) -> str:
        if os.getenv("VERCEL") or os.getenv("AWS_EXECUTION_ENV"):
            if "sqlite" in self.db_url and "./threshold.db" in self.db_url:
                return "sqlite+aiosqlite:////tmp/threshold.db"
        return self.db_url


@lru_cache
def get_settings() -> Settings:
    return Settings()

