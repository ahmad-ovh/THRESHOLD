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


# Ensure registry is loaded immediately on import
try:
    registry.load()
except Exception as e:
    logger.warning("Initial registry load on import: %s", e)


@app.on_event("startup")
async def startup_event() -> None:
    logger.info("THRESHOLD backend starting up...")
    try:
        registry.load()
        logger.info(
            "Content loaded: %d NPC templates, %d scenario seeds.",
            len(registry.all_templates()),
            len(registry.all_seeds()),
        )
        await init_db()
        logger.info("Database initialised.")
    except Exception as e:
        logger.error("Startup error: %s", e, exc_info=True)



import os
from fastapi.staticfiles import StaticFiles

# ... existing app setup ...

app.include_router(interaction.router)
app.include_router(player.router)


from fastapi import FastAPI, Response
from fastapi.responses import RedirectResponse


@app.get("/")
async def root() -> RedirectResponse:
    return RedirectResponse(url="/game/")


@app.get("/health")
async def health() -> dict:
    return {"status": "ok", "service": "THRESHOLD Backend"}



@app.get("/favicon.ico", include_in_schema=False)
async def favicon() -> Response:
    return Response(status_code=204)


if os.path.exists("public/game"):
    app.mount("/game", StaticFiles(directory="public/game", html=True), name="game")


