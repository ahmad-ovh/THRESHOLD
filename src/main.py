"""
THRESHOLD — FastAPI application entry point.
"""
from __future__ import annotations

import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.config import get_settings
from src.content import registry
from src.database import init_db
from src.routers import interaction, player

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
)
logger = logging.getLogger(__name__)
settings = get_settings()

app = FastAPI(
    title="THRESHOLD Backend",
    description="Social simulation game backend — authoritative game engine.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
async def startup_event() -> None:
    logger.info("THRESHOLD backend starting up...")
    # Load content registry (NPC templates + scenario seeds)
    registry.load()
    logger.info(
        "Content loaded: %d NPC templates, %d scenario seeds.",
        len(registry.all_templates()),
        len(registry.all_seeds()),
    )
    # Initialise database
    await init_db()
    logger.info("Database initialised.")


import os
from fastapi.staticfiles import StaticFiles

# ... existing app setup ...

app.include_router(interaction.router)
app.include_router(player.router)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "THRESHOLD Backend"}


if os.path.exists("public/game"):
    app.mount("/game", StaticFiles(directory="public/game", html=True), name="game")

