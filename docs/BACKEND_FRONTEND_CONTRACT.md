# THRESHOLD — Backend to Frontend Contract & API Specification

> **System Status**: `IMPLEMENTED`  
> **Client Implementation**: `client/singletons/ApiClient.gd`  
> **Server Base URL**: `http://127.0.0.1:8000` (Local) / `window.location.origin` (Web Export)

---

## 1. Overview & Architecture

The Godot 4 client communicates with the backend strictly via HTTP REST API calls handled asynchronously by `ApiClient.gd`. 

### Request Lifecycle
```text
Godot UI / Node Action
        ↓
ApiClient.gd HTTP Request (_http_get / _http_post)
        ↓
FastAPI Router Endpoint (src/routers/interaction.py or player.py)
        ↓
DB Mutation & Response JSON Assembly
        ↓
Godot Singleton Callback / Signal Emit
        ↓
Godot Visual Updates (DialogueUI, SpeechBubble, Mood Emoji, OverviewModal)
```

---

## 2. API Endpoints Specification

### 2.1 System & Player Endpoints

#### `GET /health`
- **Purpose**: Health check endpoint for client readiness verification.
- **Response**:
  ```json
  {
    "status": "ok",
    "service": "THRESHOLD Backend"
  }
  ```

#### `GET /player/status?player_id={player_id}`
- **Purpose**: Fetch complete current state for player, including skill vector, level, XP progress, daily streak, and met NPC journal entries.
- **Query Params**: `player_id` (`String`)
- **Response**:
  ```json
  {
    "player_id": "player_default",
    "level": 1,
    "skill_vector": {
      "clarity": 0.5,
      "empathy": 0.5,
      "politeness": 0.5,
      "expression": 0.5
    },
    "xp_progress": 0.0,
    "daily_streak": 0,
    "journal_entries": [
      {
        "npc_id": "barista",
        "name": "The barista",
        "role": "Barista",
        "usual_location": "Downtown Café",
        "relationship_tier": "Noticed",
        "known_through": "First met at Downtown Café",
        "connections": [],
        "personality_notes": "Efficient and quietly observant...",
        "discovered_facts": ["Had a productive discussion (3 turns)"]
      }
    ],
    "created_at": "2026-08-09T10:00:00+00:00"
  }
  ```

#### `POST /player/reset`
- **Purpose**: Reset player profile, clear NPC instances, memory entries, and restore defaults (development utility).
- **Request Body**: `{"player_id": "player_default"}`
- **Response**: `{"player_id": "player_default", "reset": true}`

---

### 2.2 Interaction & Encounter Endpoints

#### `POST /interaction/start`
- **Purpose**: Initiate a new dialogue encounter with a specific NPC. Selects scenario, computes effective metrics, generates personalized opening line, and builds Social Perception Layer project.
- **Request Body**:
  ```json
  {
    "player_id": "player_default",
    "npc_id": "barista"
  }
  ```
- **Response Payload**:
  ```json
  {
    "npc_name": "The barista",
    "npc_expression": "pleasant",
    "opening_line": "First time around here? What can I get started for you today?",
    "interaction_id": "first_time_around_here",
    "encounter_over": false,
    "perception_layer": {
      "show_modal": true,
      "presentation_mode": "full",
      "location_name": "Downtown Café",
      "npc_name": "The barista",
      "npc_role": "Barista",
      "relationship_tier": "Stranger",
      "situation": "You step up to the counter at the Downtown Café...",
      "encounter_focus": "Establishing your grounding in the neighborhood...",
      "known_facts": [
        "The barista is a Stranger at Downtown Café.",
        "Seems focused on: Wants to welcome a new face..."
      ],
      "journal_entries": []
    }
  }
  ```

#### `POST /interaction/message`
- **Purpose**: Send a player dialogue turn. Scores message across 4 dimensions, updates effective metrics, checks NPC state rules, writes memory entry, calls Character Voice LLM, and evaluates encounter end triggers.
- **Request Body**:
  ```json
  {
    "player_id": "player_default",
    "npc_id": "barista",
    "message": "Hi there! I'm new to the neighborhood. What coffee do you recommend?"
  }
  ```
- **Response Payload**:
  ```json
  {
    "npc_expression": "warm",
    "npc_reply": "Welcome! Our pour-over house blend is pretty popular. I'll get one started for you.",
    "coach_hint": {
      "shown": true,
      "line": "Good open question establishing authentic presence."
    },
    "turn_scores": {
      "clarity": 0.75,
      "empathy": 0.60,
      "politeness": 0.85,
      "expression": 0.70
    },
    "relationship_tier": "Noticed",
    "npc_state": "pleasant",
    "feedback": {
      "strength": "Your tone was respectful and considerate.",
      "improvement": "You responded to the words, but not the feeling behind them."
    },
    "encounter_over": false,
    "narrative_outcome": null,
    "performance_outcome": "good"
  }
  ```

#### `POST /interaction/end`
- **Purpose**: Conclude active encounter session, commit final metrics to persistent NPC instance, compute XP and skill vector progression, run Observer pattern check, perform background fact extraction, and archive encounter history.
- **Request Body**:
  ```json
  {
    "player_id": "player_default",
    "npc_id": "barista"
  }
  ```
- **Response Payload**:
  ```json
  {
    "observer_event": {
      "fired": true,
      "npc_id": "barista",
      "message": "Across these exchanges with The barista, a pattern of polite engagement recurred."
    },
    "encounter_summary": {
      "narrative_outcome": "good",
      "performance_outcome": "good"
    },
    "level_up": {
      "new_level": 2
    }
  }
  ```

#### `POST /interaction/report`
- **Purpose**: Generate on-demand diagnostic report summarizing skill strengths, improving areas, and practice recommendations based on recent encounters.
- **Request Body**: `{"player_id": "player_default"}`
- **Response Payload**:
  ```json
  {
    "current_level": 2,
    "skill_vector": {
      "clarity": 0.65,
      "empathy": 0.55,
      "politeness": 0.70,
      "expression": 0.50
    },
    "strongest_skill": "Politeness",
    "improving_area": "Expression",
    "recent_pattern_summary": "You consistently maintain a respectful tone across conversations.",
    "recommended_practice": "Try sharing your own perspective more openly in casual exchanges."
  }
  ```

#### `GET /interaction/daily?player_id={player_id}`
- **Purpose**: Fetch daily featured scenario and player streak count.
- **Query Params**: `player_id` (`String`)
- **Response Payload**:
  ```json
  {
    "seed_id": "first_time_around_here",
    "npc_id": "barista",
    "focus": "Politeness + Expression",
    "streak_count": 1
  }
  ```

---

## 3. Frontend Client Integration Architecture

### 3.1 Key Singletons (`client/singletons/`)
- `ApiClient.gd`: Manages HTTP requests (`_http_get`, `_http_post`), URI encoding, and CORS fallback for web builds.
- `GameController.gd`: Global phase state machine (`MAIN_MENU`, `EXPLORING`, `DIALOGUE`, `PAUSED`).
- `EncounterManager.gd`: Orchestrates encounter lifecycle:
  1. Freeze player movement (`set_physics_process(false)`).
  2. Smoothly glide player to 2.4m side-by-side standing position relative to target NPC.
  3. Rotate character meshes to face each other across the camera view.
  4. Call `ApiClient.start_interaction()`.
  5. Present `PerceptionModal` if `show_modal` is true.
  6. Manage dialogue loop via `DialogueUI`.
  7. On exit, invoke async prefetch (`_start_prefetch()`) to eliminate latency during settlement transition.
  8. Present `OverviewModal` with settlement details and unfreeze player.
- `PlayerStore.gd`: Stores active `player_id` and cached status values.

### 3.2 UI Scenes (`client/scenes/ui/`)
- `DialogueUI.tscn`: Speech bubble presentation, response input text box, coach hint overlay, leave confirmation button.
- `PerceptionModal.tscn`: Pre-dialogue Social Perception Layer onboarding modal.
- `OverviewModal.tscn`: Post-encounter settlement summary, XP gain, level up notifications, Observer insights.
- `JournalUI.tscn`: Notebook interface presenting met NPC pages, discovered facts, and cross-NPC connection network.
- `IdCardUI.tscn`: Player profile ID card preview displaying level, streak, and skill radar/vector bars.
- `HUD.tscn`: In-game overlay with location header, journal button, ID card button, daily quest indicator.
