# THRESHOLD — Documentation Index

## Contents

| File | What It Covers |
|---|---|
| [01_game_overview.md](./01_game_overview.md) | What THRESHOLD is, core gameplay loop, player experience, characters, relationship tiers, major systems overview, memory and consequences, AI role, intentional scope |
| [02_backend_architecture.md](./02_backend_architecture.md) | Project structure, tech stack, startup sequence, request flows for start/message/end, module responsibilities, data ownership, persistence, runtime notes |
| [03_api_reference.md](./03_api_reference.md) | Every endpoint: method, route, request schema, response schema, field descriptions, enums, error conditions, examples. Also: all ORM table schemas. |
| [04_game_content.md](./04_game_content.md) | All NPCs (metrics, update rules, state rules), relationship tier config, all scenario seeds (context, scoring focus, outcomes, overrides), distribution bands, interpretation vocabulary, expression enum |
| [05_systems.md](./05_systems.md) | How each system works: player, NPC, memory, scoring, relationship/metric update formula, state engine, scenario selection, progression (XP/level/outcome formulas), observer, all 5 LLM pipelines, AI vs. deterministic boundary table |
| [06_setup_and_operations.md](./06_setup_and_operations.md) | Environment variables, local setup, running the server, running tests, running the demo, database files, deployment notes, content extension guide |
| [07_frontend_integration.md](./07_frontend_integration.md) | Godot 4 Web & Game Engine Integration Guide (Modular room architecture, SceneManager, reusable NPC template & resource registry, floating billboard mood emojis, GDScript Autoloads, API mapping, HUD & Journal overlay, build roadmap) |
| [08_godot_setup_step_by_step.md](./08_godot_setup_step_by_step.md) | Dummy-proof Godot 4 project creation & setup guide (Project settings, Input Map, Window stretch, step-by-step scene creation, GDScript copy-paste snippets, Web export instructions) |

## Quick Reference

**Start a server locally:**
```powershell
pip install -r requirements.txt
# Create .env with LLM_KEY=your_key
uvicorn src.main:app --reload --port 8000
```

**Run tests:**
```powershell
pytest tests/ -v
```

**Full lifecycle demo:**
```powershell
python demo_flow.py
```

**Available Archetypes & NPCs:** 16 NPCs across 6 archetypes — `teacher` (`prof_adler`, `ms_okoro`, `mr_vance`), `friend` (`daria`, `felix`, `priya`), `colleague` (`nadia`, `tomas`, `seren`), `client` (`ms_hartwell`, `mr_osei`, `ms_vidal`), `family` (`parent`, `sibling`), `stranger` (`barista`, `recurring_stranger`).


**Encounter lifecycle:**
```
POST /interaction/start  →  POST /interaction/message (×N)  →  POST /interaction/end
```

**Other endpoints:** `POST /interaction/report`, `GET /interaction/daily`, `GET /player/status`, `POST /player/reset`, `GET /health`
