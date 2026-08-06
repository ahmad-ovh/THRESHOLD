"""
SQLAlchemy async database setup.

Engine and session factory are created lazily on first use (or at startup)
to ensure they are bound to the event loop that actually runs requests.
Using NullPool prevents connection sharing across event loops.
"""
from __future__ import annotations

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase
from sqlalchemy.pool import NullPool

from src.config import get_settings

settings = get_settings()

# Module-level handles — populated by _ensure_engine() on first use.
_engine: AsyncEngine | None = None
_AsyncSessionLocal: async_sessionmaker[AsyncSession] | None = None


def _ensure_engine() -> tuple[AsyncEngine, async_sessionmaker[AsyncSession]]:
    """Return (engine, session_factory), creating them if needed."""
    global _engine, _AsyncSessionLocal
    if _engine is None:
        _engine = create_async_engine(
            settings.db_url,
            echo=False,
            poolclass=NullPool,  # one connection per request — safe across threads/loops
        )
        _AsyncSessionLocal = async_sessionmaker(_engine, expire_on_commit=False)
    return _engine, _AsyncSessionLocal  # type: ignore[return-value]


class Base(DeclarativeBase):
    pass


async def get_db() -> AsyncSession:  # type: ignore[return]
    _, session_factory = _ensure_engine()
    async with session_factory() as session:
        yield session


async def init_db() -> None:
    """Create all tables and run lightweight migrations."""
    from src import models  # noqa: F401 — ensure models are imported before create_all
    from sqlalchemy import inspect, text

    engine, _ = _ensure_engine()
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        
        def _migrate(sync_conn):
            inspector = inspect(sync_conn)
            tables = inspector.get_table_names()
            if "npc_instances" in tables:
                cols = [c["name"] for c in inspector.get_columns("npc_instances")]
                if "discovered_facts_json" not in cols:
                    sync_conn.execute(text("ALTER TABLE npc_instances ADD COLUMN discovered_facts_json TEXT DEFAULT '[]'"))
                if "perception_summary_json" not in cols:
                    sync_conn.execute(text("ALTER TABLE npc_instances ADD COLUMN perception_summary_json TEXT DEFAULT ''"))

        await conn.run_sync(_migrate)
