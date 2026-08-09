# THRESHOLD — Game Direction & High-Level Source of Truth

> **System Status**: `IMPLEMENTED` (Backend engine & Godot client baseline active)  
> **Source of Truth Priority**: Implementation (`src/` backend & `client/` frontend) overrides historical documents.

---

## 1. Game Identity

**THRESHOLD** is a 3D stylized social-simulation RPG focused on interpersonal relationships, active listening, and social communication dynamics. 

Unlike traditional RPGs that revolve around physical combat or resource gathering, THRESHOLD treats **social interaction as the core gameplay loop**. The player navigates everyday, workplace, academic, and personal relationships, engaging in natural turn-based conversations with NPCs whose internal metric states (e.g., trust, respect, patience, closeness, candor) evolve deterministically based on the player's communication choices.

### Key Highlights & Differentiators
- **Backend/Gameplay-First Architecture**: Game rules, relationship state machines, progression formulas, and narrative outcomes are strictly owned and computed by an authoritative Python backend (`FastAPI` + `SQLAlchemy`).
- **Hybrid AI System**: Combines **deterministic state machines** (for gameplay fairness, XP computation, relationship metric shifts, and phase progression) with **LLM generative text pipelines** (for nuanced character voice dialogue, personalized scenario introductions, and observer pattern reflections).
- **Social Perception Layer**: Onboards the player into encounters by surfacing situational context, relationship history, and known facts prior to conversation.
- **3D Stylized Diorama World**: Presented in Godot 4 via a 2.5D dollhouse diorama perspective with stylized humanoid character models, expressive mood emoji overlays, and smooth camera tracking.

---

## 2. Core Player Experience & Gameplay Loop

```text
3D Exploration & Discovery
        ↓
Approach NPC & Initiate Encounter ([E] Key)
        ↓
Social Perception Layer Onboarding (Context, Known Facts, Focus)
        ↓
Turn-Based Dialogue Exchange (Scored on 4 Communication Dimensions)
        ↓
Dynamic NPC State Updates & Live Visual Feedback (Mood Emojis, Expressions, Coach Hints)
        ↓
Encounter Resolution & Settlement (XP Gain, Skill Vector Updates, Observer Insights)
        ↓
Journal Update & Persistent Relationship Progression
```

### Player Actions
1. **Explore**: Move through 3D neighborhood locations (street corridor, café, campus, offices, apartments).
2. **Initiate Encounter**: Interact with NPCs to start tailored scenarios selected based on relationship tier and player level.
3. **Communicate**: Formulate natural text responses evaluated across four core dimensions:
   - **Clarity**: Directness, structure, and focus.
   - **Empathy**: Attunement to feelings and perspective-taking.
   - **Politeness**: Respect, boundary awareness, and tone.
   - **Expression**: Authenticity, personal honesty, and openness.
4. **Reflect & Progress**: Review post-encounter settlement summaries, earn XP, advance player level (1–100), refine skill vectors, and unlock deeper relationship tiers with NPCs.

---

## 3. Social Simulation Model

Each NPC in THRESHOLD represents a distinct identity governed by an archetype role (`teacher`, `friend`, `colleague`, `client`, `family`, `stranger`).

### Authoritative NPC Architecture
- **Metrics**: Quantitative tracking variables per NPC instance (e.g., `trust`, `respect`, `confidence`, `closeness`, `candor`, `ease`, `alignment`, `rapport`, `satisfaction`, `engagement`, `reassurance`, `impression`).
- **Deterministic Metric Updates**: Updated every turn via weighted formulas based on player turn scores and template decay rates (`src/services/relationship_service.py`).
- **State Engine**: State rules map current metrics to emotional/behavioral states (`neutral`, `guarded`, `warm`, `dismissive`, `attentive`, `collaborative`, `hostile`, etc.) via deterministic condition parsing (`src/state_engine.py`).
- **Relationship Tiers**: Relationship tiers (`Stranger` → `Acquaintance` → `Comfortable` / `Respected` → `Trusted` → `Close Friend` / `Strong Ally` / `Regarded Highly`) are resolved from metric thresholds.
- **Memory & Connections**: Persistent turn memories and discovered facts are stored in SQLite, allowing NPCs to maintain continuous context across encounters and recognize connections to other NPCs.

---

## 4. World Structure & Presentation

The physical game world is structured as modular 3D diorama environments:
- **Main Street Hub Corridor**: Primary side-scrolling 3D environment connecting neighborhood locations.
- **Interior Diorama Rooms**: Café, Academic Study, Classroom, Office Lobby, Executive Suite, Apartment Living Room & Balcony.
- **Camera Perspective**: Fixed-pitch dollhouse camera (pitch ~ -15°, Y = 2.2m, Z = 4.5m) that smoothly follows the player and smoothly glides to frame characters in a 2.4m side-by-side standing alignment during dialogue.

---

## 5. Current Implementation Status

| System | Status | Implementation Details |
|---|---|---|
| **Authoritative Backend Engine** | `IMPLEMENTED` | FastAPI server (`src/main.py`), SQLite DB (`src/models.py`), Async SQLAlchemy. |
| **Content Registry** | `IMPLEMENTED` | 16 NPC Templates (`content/npc_templates.yaml`) & 25 Scenario Seeds (`content/scenario_seeds.yaml`). |
| **Deterministic State Engine** | `IMPLEMENTED` | Safe expression parser (`src/state_engine.py`) evaluating metric rules. |
| **Relationship & Metric Updates** | `IMPLEMENTED` | Formula-based updates (`src/services/relationship_service.py`) with tunable dampening. |
| **Progression System** | `IMPLEMENTED` | Deterministic XP & level calculation (`src/services/progression_service.py`), skill vector updates. |
| **Perception Layer & Journal** | `IMPLEMENTED` | `build_perception_layer()` & `get_player_journal_entries()` (`src/services/perception_service.py`). |
| **Observer Pattern Trigger** | `IMPLEMENTED` | Pattern detection (`src/services/observer_service.py`) + LLM phrasing synthesis. |
| **LLM AI Pipelines** | `IMPLEMENTED` | Character voice, scenario personalization, report generation (`src/services/llm_service.py`). |
| **Godot 4 Client & UI** | `IMPLEMENTED` | Street scene, CharacterFactory rig assembly, DialogueUI, PerceptionModal, OverviewModal, JournalUI, HUD. |
| **Interior Room Transitions** | `PARTIALLY IMPLEMENTED` | Individual diorama room scenes exist (`Room_Cafe.tscn`, `Room_AdlerOffice.tscn`, etc.); Street hub is primary active room. |
| **Full 3D Asset Import Pipeline** | `PLANNED` | Automated import and placement pass from external asset dumps into diorama room scenes. |
| **Branching Combat / Inventory** | `DEAD / OBSOLETE` | Featured in old documentation drafts but non-existent in backend/frontend architecture. |

---

## 6. Authoritative Constraints for Future Passes

1. **No Gameplay Code Modifications in World Building**: World creation passes must not alter backend python logic, database models, or client API contracts.
2. **Preserve Godot Signal & Group Hooks**: Node groups (`"player"`, `"npcs"`) and interaction detector areas must remain functionally intact.
3. **Respect Camera & Character Scale**: Maintain 1 unit = 1 meter scale, 2.4m side-by-side dialogue standing offset, and clear front diorama line-of-sight.
