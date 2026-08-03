# THRESHOLD — Frontend Integration Guide

This document is a comprehensive, developer-facing integration guide for building a frontend client for **THRESHOLD**. It defines how the client UI layer maps backend FastAPI endpoints and state transformations into interactive gameplay.

---

## 1. Architecture Overview & Data Flow

THRESHOLD's backend operates as a stateless HTTP REST API with server-side persistent SQLite storage. All gameplay logic—scoring, metric calculations, state rule resolution, LLM dialogue generation, and progression formulas—runs strictly on the backend.

The frontend client serves as the **presentation and state orchestration layer**, driving the encounter lifecycle through a sequential 4-stage flow.

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 GET /interaction/daily                 │
                  │                 GET /player/status                     │
                  └──────────────────────────┬─────────────────────────────┘
                                             │
                                   [1. Game Launch / Lobby]
                                             │
                                             ▼
                  ┌────────────────────────────────────────────────────────┐
                  │                POST /interaction/start                 │
                  └──────────────────────────┬─────────────────────────────┘
                                             │
                                 [2. Encounter Initialization]
                                             │
                                             ▼
   ┌──────────────────────────────────────────────────────────────────────────────────┐
   │                               3. Interaction Loop                                │
   │                                                                                  │
   │   Player Types Message ──► POST /interaction/message ──► Response Received      │
   │            ▲                                                    │                │
   │            │                                                    ▼                │
   │            └──────────────── [ encounter_over == false ] ───────┤                │
   └─────────────────────────────────────────────────────────────────┼────────────────┘
                                                                     │
                                                        [ encounter_over == true ]
                                                                     │
                                                                     ▼
                  ┌────────────────────────────────────────────────────────┐
                  │                 4. Encounter Resolution                │
                  │                 POST /interaction/end                  │
                  └──────────────────────────┬─────────────────────────────┘
                                             │
                                 [5. Results & Rewards Modal]
                                             │
                                             ▼
                  ┌────────────────────────────────────────────────────────┐
                  │                 POST /interaction/report               │
                  └────────────────────────────────────────────────────────┘
```

### Turn Loop Breakdown (Player Action → API → UI Update)

1. **Player Action**: Player enters text into the message input field and presses Send.
2. **Client Locking**: Input field is disabled, submit button enters loading state, and an ambient NPC "thinking" animation is triggered.
3. **API Invocation**: Client sends `POST /interaction/message` with `{ player_id, npc_id, message }`.
4. **Backend Processing**:
   - Memory Formation LLM scores message across four dimensions (`clarity`, `empathy`, `politeness`, `expression`) and selects an interpretation label.
   - Relationship Service updates running effective metrics and evaluates state rules and relationship tier.
   - Character Voice LLM generates NPC reply text, emotional expression, coach hint, and optional narrative closure signal.
5. **Response Resolution**: Client receives `MessageResponse`.
6. **UI Synchronization**:
   - **Dialogue Panel**: Appends player text and triggers typewriter effect for `npc_reply`.
   - **Character Visuals**: Transitions portrait asset/sprite to match `npc_expression`.
   - **Scoring & Feedback**: Renders radar chart / metric bars for `turn_scores`, updates `strength` and `improvement` text cards.
   - **Coach Hint**: Displays coach hint tooltip/banner if `coach_hint.shown` is `true`.
   - **Badges**: Updates `relationship_tier` and `npc_state` badge chips.
   - **Encounter Check**: If `encounter_over` is `true`, locks input permanently and presents the "Complete Encounter" resolution CTA. Otherwise, re-enables text input for the next turn.

---

## 2. API Endpoint Specifications

Base URL: `http://<host>:<port>` (default dev: `http://127.0.0.1:8000`)

---

### 2.1 GET /health

- **When Frontend Calls It**: App initialization / splash screen to verify backend service availability.
- **Request Inputs**: None.
- **Response Fields**:
  - `status` (`string`): `"ok"`
  - `service` (`string`): `"THRESHOLD Backend"`
- **Game Usage**:
  - `status == "ok"`: Proceed to main menu.
  - Failure/Error: Display offline maintenance overlay with reconnect retry button.

---

### 2.2 GET /player/status

- **When Frontend Calls It**: Main menu / player profile dashboard load; after returning from encounters.
- **Request Inputs**:
  - `player_id` (`string`, Query Param, Required): Player identifier.
- **Response Fields**:
  - `player_id` (`string`): Player ID.
  - `level` (`integer`): Current player level (1–100).
  - `skill_vector` (`object`): Dict of floats `0.0–1.0` for `clarity`, `empathy`, `politeness`, `expression`.
  - `xp_progress` (`float`): Experience progress within current level (`0.0–1.0`).
  - `daily_streak` (`integer`): Daily login/encounter streak count.
  - `created_at` (`string`, ISO 8601): Account creation timestamp.
- **Game Usage**:
  - `level`: Rendered in top navigation bar and player avatar frame.
  - `xp_progress`: Drives the top bar XP progress bar width (`percentage = xp_progress * 100%`).
  - `skill_vector`: Renders player overall communication skill profile (radar chart / stat bars).
  - `daily_streak`: Displays streak counter flame/icon in header.

---

### 2.3 POST /player/reset

- **When Frontend Calls It**: Developer debug menu, settings "Reset Progress" button, or demo reset flow.
- **Request Inputs**:
  - `player_id` (`string`, JSON Body, Required): Player identifier.
- **Response Fields**:
  - `player_id` (`string`): Player ID.
  - `reset` (`boolean`): Always `true`.
- **Game Usage**:
  - Flushes client-side state cache, resets player store to defaults, navigates to welcome screen.

---

### 2.4 GET /interaction/daily

- **When Frontend Calls It**: Main lobby screen initialization to present the "Featured Scenario of the Day" card.
- **Request Inputs**:
  - `player_id` (`string`, Query Param, Required): Player identifier (auto-creates player if new).
- **Response Fields**:
  - `seed_id` (`string`): Featured scenario seed ID.
  - `npc_id` (`string`): Matched NPC template ID.
  - `focus` (`string`): Human-readable focus string (e.g. `"Clarity + Politeness"`).
  - `streak_count` (`integer`): Current daily streak.
- **Game Usage**:
  - `seed_id` & `npc_id`: Pre-populates the "Start Daily Challenge" banner card. Clicking triggers `POST /interaction/start` with `npc_id`.
  - `focus`: Rendered as focus tags on the daily challenge card.
  - `streak_count`: Updates daily streak badge UI.

---

### 2.5 POST /interaction/start

- **When Frontend Calls It**: When player selects an NPC / scenario seed and clicks "Begin Conversation".
- **Request Inputs**:
  ```json
  {
    "player_id": "player_01",
    "npc_id": "daria"
  }
  ```
- **Response Fields**:
  - `npc_name` (`string`): NPC display name (e.g. `"Daria"`).
  - `npc_expression` (`string`, Enum): Opening emotional expression.
  - `opening_line` (`string`): LLM-personalized opening line of dialogue.
  - `interaction_id` (`string`): Selected scenario seed ID.
  - `encounter_over` (`boolean`): Always `false` on start.
- **Game Usage**:
  - Initializes active encounter view.
  - Sets portrait asset/animation to `npc_expression`.
  - Sets header title to `npc_name` and scenario badge to `interaction_id`.
  - Clears chat history list and inserts `opening_line` as the first message (`role: "npc"`).
  - Enables message input text box and sets turn counter to 0.

---

### 2.6 POST /interaction/message

- **When Frontend Calls It**: On submitting a message during an active encounter turn loop.
- **Request Inputs**:
  ```json
  {
    "player_id": "player_01",
    "npc_id": "daria",
    "message": "I'm really sorry for canceling last minute, work was overwhelming."
  }
  ```
- **Response Fields**:
  - `npc_expression` (`string`, Enum): NPC emotional expression for this reply.
  - `npc_reply` (`string`): NPC dialogue response text.
  - `coach_hint` (`object`): `{ "shown": boolean, "line": string }`. Factual feedback observation.
  - `turn_scores` (`object`): `{ "clarity": float, "empathy": float, "politeness": float, "expression": float }` (values `0.0–1.0`).
  - `relationship_tier` (`string`): Current tier label (e.g., `"Comfortable"`, `"Trusted"`).
  - `npc_state` (`string`): Current deterministic state label (e.g., `"withdrawn"`, `"attentive"`).
  - `feedback` (`object`): `{ "strength": string, "improvement": string }`.
  - `encounter_over` (`boolean`): `true` if narrative outcome triggered or 8-turn safety cap hit.
  - `narrative_outcome` (`string | null`): `"good"`, `"neutral"`, `"poor"`, or `null`.
  - `performance_outcome` (`string`): `"good"`, `"neutral"`, or `"poor"`.
- **Game Usage**:
  - `npc_reply`: Appended to chat stream with typewriter effect.
  - `npc_expression`: Triggers portrait emotion state transition (e.g. cross-fade sprite to `irritated` or `warm`).
  - `turn_scores`: Animated score meters / radar chart update for current turn.
  - `feedback`: Renders "Key Strength" and "Growth Opportunity" info cards.
  - `coach_hint`: If `shown == true`, animates coach hint tooltip into view.
  - `relationship_tier` & `npc_state`: Updates status pill tags in header.
  - `encounter_over`: If `true`, disables input box, displays end-of-encounter overlay CTA ("View Encounter Results").

---

### 2.7 POST /interaction/end

- **When Frontend Calls It**: When `encounter_over` is `true` and player clicks "Complete Encounter" (or when player manually exits early).
- **Request Inputs**:
  ```json
  {
    "player_id": "player_01",
    "npc_id": "daria"
  }
  ```
- **Response Fields**:
  - `observer_event` (`object`): `{ "fired": boolean, "npc_id": string, "message": string | null }`.
  - `encounter_summary` (`object`): `{ "narrative_outcome": string | null, "performance_outcome": string }`.
  - `level_up` (`object`, Optional): Present only if leveled up: `{ "new_level": integer }`.
- **Game Usage**:
  - Opens Encounter Settlement Modal.
  - `encounter_summary`: Renders performance outcome badge (`GOOD`, `NEUTRAL`, `POOR`) and narrative conclusion summary.
  - `observer_event`: If `fired == true`, displays special "Observer Insight" card/modal with `message`.
  - `level_up`: If present, triggers Level-Up splash particle animation and updates stored player level.
  - Closes active encounter view and updates player status in background.

---

### 2.8 POST /interaction/report

- **When Frontend Calls It**: Player opens the "Communication Growth Report" tab/modal.
- **Request Inputs**:
  ```json
  {
    "player_id": "player_01"
  }
  ```
- **Response Fields**:
  - `current_level` (`integer`): Player level.
  - `skill_vector` (`object`): Dict of floats `0.0–1.0` for 4 dimensions.
  - `strongest_skill` (`string`): One of `clarity`, `empathy`, `politeness`, `expression`.
  - `improving_area` (`string`): Interpretive area key (e.g. `emotional_acknowledgment`).
  - `recent_pattern_summary` (`string`): AI-generated synthesis of recent communication pattern.
  - `recommended_practice` (`string`): AI recommendation for next encounter focus.
- **Game Usage**:
  - Displays comprehensive player growth report dashboard with radar graph, pattern analysis text card, and recommended practice call-to-action button.

---

## 3. Gameplay Component & Response Mapping

| Backend Response Field | Frontend Component / Target | Visual / Behavioural Effect |
|---|---|---|
| `opening_line` | Dialogue Stream | Appends initial NPC message bubble with typewriter effect |
| `npc_reply` | Dialogue Stream | Appends turn reply bubble; autoscrolls chat window to bottom |
| `npc_expression` | NPC Portrait Container | Swaps sprite texture or triggers animation clip (`warm`, `hurt`, `guarded`, etc.) |
| `coach_hint.shown` | Coach Hint Bar | Shows/hides hint container |
| `coach_hint.line` | Coach Hint Bar | Renders factual coaching text note |
| `turn_scores` | Score Breakdown Panel | Updates 4 dimension progress bars (0–100%) or radar chart |
| `feedback.strength` | Feedback Card (Green) | Displays primary positive observation |
| `feedback.improvement` | Feedback Card (Amber) | Displays primary growth area observation |
| `relationship_tier` | Header Status Bar | Updates relationship status chip (e.g. `Comfortable` → `Trusted`) |
| `npc_state` | Header Status Bar | Updates NPC mood badge (e.g. `neutral` → `attentive`) |
| `encounter_over` | Input Container & CTA | Disables text input, hides send button, shows "View Results" CTA |
| `narrative_outcome` | Summary Modal | Displays story closure badge (`good`, `neutral`, `poor`, or `safety limit reached`) |
| `performance_outcome` | Summary Modal | Displays mechanical performance rating driving XP rewards |
| `observer_event.fired` | Observer Insight Modal | Triggers pattern reveal popup if `true` |
| `observer_event.message` | Observer Insight Modal | Renders factual multi-encounter pattern observation text |
| `level_up` | Overlay / Banner | Triggers Level-Up celebration banner & sound effect |
| `xp_progress` | Player Header Bar | Animate-fills top XP bar |

---

## 4. NPC Expressions & Visual Animations

The backend returns `npc_expression` as an enum string in `/start` and `/message` responses. The frontend maps these enum keys to visual portrait assets, lighting/vignette overlays, and posture presets.

```
+------------------+----------------------------------------------------+----------------------------+
| Enum Value       | Visual Mood / Facial Asset Mapping                  | Color / Vignette Accent    |
+------------------+----------------------------------------------------+----------------------------+
| neutral          | Default posture, relaxed eye contact               | Neutral grey / Clear       |
| warm             | Gentle smile, relaxed eyebrows, leaning forward    | Warm gold (#E6B800)        |
| hurt             | Averted glance, furrowed brow, tightened lips      | Muted slate blue           |
| guarded          | Crossed arms, reserved eye contact, slight distance| Cool grey                  |
| irritated        | Sharp gaze, tense jaw, stiff posture               | Burnt amber                |
| concerned        | Slightly raised inner eyebrows, focused gaze       | Soft cyan                  |
| disappointed     | Lowered gaze, slight head shake posture            | Dimmed grey                |
| approving        | Slight nodding frame, warm confident smile         | Vibrant emerald            |
| dismissive       | Head turned slightly away, neutral eye fold        | Dusty purple               |
| satisfied        | Confident smile, relaxed shoulders                 | Soft green                 |
| frustrated       | Pressed lips, tension around eyes                  | Deep orange                |
| hostile          | Direct intense gaze, rigid stance                  | Muted crimson              |
| defensive        | Slightly leaned back, closed body language         | Steel blue                 |
| withdrawn        | Downward gaze, hands clasped, recessed lighting    | Dark grey vignette         |
| collaborative    | Open posture, direct engaging eye contact          | Soft indigo                |
+------------------+----------------------------------------------------+----------------------------+
```

---

## 5. Client-Side State Architecture

The frontend must maintain state organized into distinct logical domains:

```
                                  ┌────────────────────────┐
                                  │      Client Store      │
                                  └───────────┬────────────┘
                                              │
      ┌──────────────────┬────────────────────┼──────────────────┬──────────────────┐
      │                  │                    │                  │                  │
      ▼                  ▼                    ▼                  ▼                  ▼
┌──────────────┐   ┌───────────┐     ┌──────────────────┐   ┌──────────┐   ┌────────────────┐
│  Encounter   │   │ NPC State │     │   Conversation   │   │ Outcomes │   │     Player     │
│    State     │   │   Store   │     │   History Store  │   │  Store   │   │  Progression   │
└──────────────┘   └───────────┘     └──────────────────┘   └──────────┘   └────────────────┘
```

### 5.1 Store Definitions

#### 1. Encounter State
- `sessionId` (`string | null`): Current active scenario seed ID (`interaction_id`).
- `activeNpcId` (`string | null`): Selected NPC template ID.
- `turnCount` (`number`): Current turn count (starts at 0, incremented per message).
- `isOver` (`boolean`): Flags whether encounter turn loop has concluded.
- `isSubmitting` (`boolean`): Loading guard during backend API request.

#### 2. NPC State
- `npcName` (`string`): Active NPC name.
- `currentExpression` (`NpcExpression`): Current emotional expression.
- `currentState` (`string`): Current deterministic state label (e.g. `"attentive"`).
- `relationshipTier` (`string`): Current relationship tier (e.g. `"Comfortable"`).

#### 3. Conversation History
- `messages` (`Array<ChatMessage>`): Array of chat objects:
  ```typescript
  interface ChatMessage {
    id: string;
    role: "player" | "npc";
    text: string;
    timestamp: number;
    turnScores?: TurnScores;
    feedback?: Feedback;
    expression?: NpcExpression;
  }
  ```

#### 4. Outcomes State
- `narrativeOutcome` (`"good" | "neutral" | "poor" | null`): LLM narrative outcome.
- `performanceOutcome` (`"good" | "neutral" | "poor" | null`): Deterministic rating.
- `observerEvent` (`ObserverEvent | null`): Observer pattern payload if fired.

#### 5. Player Progression State
- `playerId` (`string`): Current player identifier.
- `level` (`number`): Player level.
- `xpProgress` (`number`): Float `0.0–1.0`.
- `dailyStreak` (`number`): Current daily streak.
- `skillVector` (`SkillVector`): `{ clarity, empathy, politeness, expression }`.

---

## 6. Encounter Lifecycle & State Machine

```
              ┌──────────────────────────────────────────────────┐
              │                   [UNINITIALIZED]                │
              └─────────────────────────┬────────────────────────┘
                                        │
                             POST /interaction/start
                                        │
                                        ▼
              ┌──────────────────────────────────────────────────┐
              │                     [ACTIVE]                     │
              │             Turn 0: Opening line shown           │
              └─────────────────────────┬────────────────────────┘
                                        │
                         POST /interaction/message (×N)
                                        │
                                        ▼
             ┌────────────────────────────────────────────────────┐
             │                 [RESOLUTION_READY]                 │
             │           encounter_over == true returned          │
             └──────────────────────────┬─────────────────────────┘
                                        │
                              POST /interaction/end
                                        │
                                        ▼
              ┌──────────────────────────────────────────────────┐
              │                    [RESOLVED]                    │
              │          Encounter Settlement Modal shown        │
              └──────────────────────────────────────────────────┘
```

### Stage 1: Initialization (`POST /interaction/start`)
- Client sends `player_id` and `npc_id`.
- Client resets turn history and sets `encounter_over = false`.
- Receives `opening_line` and opening `npc_expression`.
- UI displays NPC greeting bubble and activates message input box.

### Stage 2: Turn Loop (`POST /interaction/message`)
- Player inputs text → client validates message is non-empty (`message.trim().length > 0`).
- Input locked (`isSubmitting = true`).
- Response returns updated `npc_expression`, `npc_reply`, `turn_scores`, `feedback`, `coach_hint`, `relationship_tier`, and `npc_state`.
- UI updates all corresponding components.
- If `encounter_over` is `false`, input unlocks (`isSubmitting = false`).

### Stage 3: Resolution Ready (`encounter_over == true`)
- Backend sets `encounter_over = true` either when:
  - Character Voice LLM triggers narrative closure (after `min_turns_before_end` = 3 turns).
  - Safety cap (`max_turns_safety_limit` = 8 turns) is reached.
- Client permanently locks message input field.
- CTA button changes to "Complete Encounter".

### Stage 4: End & Settlement (`POST /interaction/end`)
- Client calls `/interaction/end`.
- Receives `observer_event`, `encounter_summary`, and optional `level_up`.
- Settlement modal displays narrative + performance outcomes.
- If `observer_event.fired == true`, displays Observer modal.
- If `level_up` is returned, displays Level Up animation.
- Navigates back to main menu.

---

## 7. Data Models & TypeScript Interfaces

Below are production-ready TypeScript definitions matching backend FastAPI models.

```typescript
// ── Enums & Literal Types ──

export type NpcExpression =
  | "neutral"
  | "warm"
  | "hurt"
  | "guarded"
  | "irritated"
  | "concerned"
  | "disappointed"
  | "approving"
  | "dismissive"
  | "satisfied"
  | "frustrated"
  | "hostile"
  | "defensive"
  | "withdrawn"
  | "collaborative";

export type PerformanceOutcome = "good" | "neutral" | "poor";
export type NarrativeOutcome = "good" | "neutral" | "poor" | null;

export type ArchetypeRole =
  | "teacher"
  | "friend"
  | "colleague"
  | "client"
  | "family"
  | "stranger";

// ── Sub-Structures ──

export interface SkillVector {
  clarity: number;
  empathy: number;
  politeness: number;
  expression: number;
}

export interface TurnScores {
  clarity: number;
  empathy: number;
  politeness: number;
  expression: number;
}

export interface CoachHint {
  shown: boolean;
  line: string;
}

export interface Feedback {
  strength: string;
  improvement: string;
}

export interface ObserverEvent {
  fired: boolean;
  npc_id: string;
  message: string | null;
}

export interface EncounterSummary {
  narrative_outcome: NarrativeOutcome;
  performance_outcome: PerformanceOutcome;
}

export interface LevelUpInfo {
  new_level: number;
}

// ── API Request DTOs ──

export interface StartRequest {
  player_id: string;
  npc_id: string;
}

export interface MessageRequest {
  player_id: string;
  npc_id: string;
  message: string;
}

export interface EndRequest {
  player_id: string;
  npc_id: string;
}

export interface ReportRequest {
  player_id: string;
}

export interface ResetRequest {
  player_id: string;
}

// ── API Response DTOs ──

export interface HealthResponse {
  status: string;
  service: string;
}

export interface PlayerStatusResponse {
  player_id: string;
  level: number;
  skill_vector: SkillVector;
  xp_progress: number;
  daily_streak: number;
  created_at: string;
}

export interface ResetResponse {
  player_id: string;
  reset: boolean;
}

export interface DailyResponse {
  seed_id: string;
  npc_id: string;
  focus: string;
  streak_count: number;
}

export interface StartResponse {
  npc_name: string;
  npc_expression: NpcExpression;
  opening_line: string;
  interaction_id: string;
  encounter_over: boolean;
}

export interface MessageResponse {
  npc_expression: NpcExpression;
  npc_reply: string;
  coach_hint: CoachHint;
  turn_scores: TurnScores;
  relationship_tier: string;
  npc_state: string;
  feedback: Feedback;
  encounter_over: boolean;
  narrative_outcome: NarrativeOutcome;
  performance_outcome: PerformanceOutcome;
}

export interface EndResponse {
  observer_event: ObserverEvent;
  encounter_summary: EncounterSummary;
  level_up?: LevelUpInfo;
}

export interface ReportResponse {
  current_level: number;
  skill_vector: SkillVector;
  strongest_skill: string;
  improving_area: string;
  recent_pattern_summary: string;
  recommended_practice: string;
}
```

---

## 8. Error Handling & Loading Strategies

### 8.1 HTTP Status Code Handling

| HTTP Code | Condition / Cause | Frontend Action |
|---|---|---|
| **400 Bad Request** | Encounter is already over (call `/message` after `encounter_over == true`). | Lock message input immediately; prompt user to click "Complete Encounter". |
| **404 Not Found** | `npc_id` invalid, player not found, or active session missing. | Display error modal ("Session expired or lost"); redirect to scenario selection screen to call `/start`. |
| **422 Unprocessable Entity** | `message` field is empty or whitespace-only. | Show inline input validation error ("Please enter a message before sending"). |
| **500 Internal Error** | Scenario seed missing or LLM API exception. | Display toast error ("Server error occurred. Please retry."); unlock submit button. |
| **Network Timeout** | Backend API / LLM latency spike (>10s). | Show retry banner; keep draft message in input box. |

### 8.2 Loading UI & Pessimistic Locking

Because backend response times depend on two sequential LLM pipeline calls (Memory Formation scoring and Character Voice dialogue generation), response latency typically ranges from **1.5 to 3.5 seconds per turn**.

- **Pessimistic Locking**: Optimistic message bubbles must **not** be appended until `/message` succeeds, as turn score and NPC reaction depend on backend scoring.
- **Thinking / Typing Indicator**:
  1. Immediately append player message to chat stream with a "sending..." status icon.
  2. Display an animated "NPC is thinking..." bubble in the chat view.
  3. Disable text input field and send button.
  4. On response, replace typing indicator with `npc_reply` text and activate typewriter effect.

---

## 9. Existing Architecture Gaps & TODOs

The following features or metrics are required for complete frontend rendering but are currently missing or unexposed in the existing backend architecture:

- **TODO (Raw Metrics Exposure)**: Individual underlying metric float values (e.g. `trust: 0.55`, `respect: 0.60`, `patience: 0.40`) are updated server-side but are **not exposed** in `StartResponse` or `MessageResponse` (only `npc_state` and `relationship_tier` string labels are returned). If the UI needs raw metric bars/sliders, the backend must expose `effective_metrics` in API responses.
- **TODO (Memory Archive API)**: Memory entries are stored in the backend `memory_entries` table, but there is no GET endpoint for fetching an NPC's full memory history list to display in a "Relationship Memory Journal" UI tab.
- **TODO (Daily Streak Tracking Logic)**: `daily_streak` is returned in `/player/status` and `/interaction/daily`, but backend logic to increment streaks based on daily calendar logins is not implemented.
- **TODO (Streaming Responses)**: `POST /interaction/message` is a blocking HTTP REST endpoint. Implementing Server-Sent Events (SSE) or WebSockets for streaming LLM response tokens would significantly improve perceived dialogue latency.
- **TODO (Authentication & Player Accounts)**: `player_id` is an unauthenticated client-supplied string. Production frontend integration will require JWT / session auth headers.
