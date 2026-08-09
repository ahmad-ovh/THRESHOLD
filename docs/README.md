# THRESHOLD — Documentation Source of Truth Index

> **Notice**: This directory has been completely reconstructed to reflect the **actual current codebase** (`src/` backend engine and `client/` Godot 4 frontend). Legacy files have been consolidated into these implementation-grounded documents.

---

## Documentation Sitemap

| Document | Description & Scope |
|---|---|
| 📄 **[GAME_DIRECTION.md](./GAME_DIRECTION.md)** | **Highest-Level Source of Truth**: Game identity, core player fantasy, main loop, social simulation model, system implementation status, and core constraints. |
| 📄 **[GAMEPLAY_ARCHITECTURE.md](./GAMEPLAY_ARCHITECTURE.md)** | **Backend Architecture**: Authoritative FastAPI engine, SQLite database schemas, state engine, deterministic relationship/progression math, and deterministic vs. AI boundaries. |
| 📄 **[BACKEND_FRONTEND_CONTRACT.md](./BACKEND_FRONTEND_CONTRACT.md)** | **API Contract & Client Integration**: Complete REST API specification (endpoints, request/response JSON schemas), HTTP singleton flows, and Godot UI singletons. |
| 📄 **[WORLD_SPECIFICATION.md](./WORLD_SPECIFICATION.md)** | **Physical World Design**: Room specifications (Street Hub, Café, Study, Classroom, Apartment, Office), NPC mapping, and element categorization (Gameplay-Critical, Identity-Critical, Decorative). |
| 📄 **[ART_DIRECTION.md](./ART_DIRECTION.md)** | **Visual Language & Constraints**: Warm 2.5D dollhouse diorama aesthetic, color palette, camera framing, character proportions, and lighting. |
| 📄 **[ASSET_STRATEGY.md](./ASSET_STRATEGY.md)** | **Modular Kit-of-Parts Strategy**: Reusable asset categories, variation guidelines, collision requirements, and fallback rules for automated world builders. |
| 📄 **[WORLD_BUILDING_RULES.md](./WORLD_BUILDING_RULES.md)** | **Operational Constraints**: Rules for automated world-generation and asset-import agents to ensure gameplay and camera integrity. |

---

## Quick Reference Commands

### Start Backend Locally
```powershell
uvicorn src.main:app --reload --port 8000
```

### Run Test Suite
```powershell
python run_tests.py
```

### End-to-End Demo Flow
```powershell
python demo_flow.py
```
