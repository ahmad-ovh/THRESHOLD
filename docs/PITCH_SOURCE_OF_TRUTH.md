# THRESHOLD — Pitch Source of Truth

> **Authoritative Competition Pitch & Judging Source of Truth**  
> **Target Event**: Tencent Cloud × UTM Hackathon 2026 — Game Track ("AI CAN DO IT")  
> **Challenge Target**: *Relational Intelligence Engine* (AI-Powered Communication & Social Skills Training Game)  
> **Repository Basis**: `client/` (Godot 4 3D Diorama Client) & `src/` (Authoritative Python FastAPI Engine)  

---

## 1. Executive Pitch

### One-Sentence Pitch
THRESHOLD is a stylized 3D social-simulation RPG where players create personalized avatars, explore a vibrant diorama neighborhood, and master interpersonal communication through natural open-text dialogue grounded in an authoritative Relational Intelligence Engine.

### 10-Second Pitch
In THRESHOLD, players navigate authentic everyday, academic, and workplace social scenarios in a 3D diorama world, engaging with AI-driven NPCs whose trust, respect, and emotional states evolve through an authoritative, persistent relationship engine.

### 30-Second Pitch
THRESHOLD transforms communication practice into a complete, engaging 3D RPG experience. Players design custom avatars using a rich modular character system, explore a 2.5D dollhouse diorama neighborhood, and approach NPCs in realistic social encounters. Before every conversation, the Social Perception Layer surfaces relationship history and situational focus. As players communicate using open free-text input, THRESHOLD evaluates their responses across four core social dimensions—Clarity, Empathy, Politeness, and Expression—animating live 3D mood emoji overlays and updating persistent NPC relationship state machines. With Level 1–100 XP progression, daily challenges, an interactive notebook journal, AI Observer behavioral insights, and on-demand Growth Analytics Reports, THRESHOLD bridges the gap between knowing what to say and feeling confident enough to say it.

### 60-Second Pitch
Interpersonal communication is one of the most vital life skills, yet traditional workshops and passive e-learning modules fail to provide a safe, adaptive, and engaging practice environment. THRESHOLD solves this by delivering a complete 3D social-simulation RPG powered by Tencent Cloud's CodeBuddy and an authoritative Relational Intelligence Engine.

Players begin by creating their avatar using a modular customization system featuring over 270 hairstyles, 60 eye styles, skin palettes, clothing options, and real-time LookIK head tracking. Stepping into a warm 3D diorama neighborhood, players explore locations such as the Downtown Café, Professor Adler’s Study, and Office Executive Suites, meeting 16 distinct NPC archetypes. Before entering any dialogue, the Social Perception Layer provides crucial context, relationship tiers, and communication targets. 

During conversation, players speak naturally using free-text input. THRESHOLD’s dual-layer engine scores each turn across four social competencies, triggering live floating 3D mood emoji billboard reactions and real-time coach hints while deterministically updating backend metrics like Trust and Respect. Concluding an encounter awards XP toward a 100-level progression system, updates the persistent Notebook Journal connection graph, and activates an AI Observer pattern engine that detects recurring behavioral habits. By strictly separating deterministic game math from generative LLM text, THRESHOLD guarantees fair progression, zero hallucinated state shifts, and long-term social continuity.

---

## 2. What THRESHOLD Is

THRESHOLD is a standalone, playable 3D social-simulation RPG developed in Godot 4 and powered by an authoritative Python FastAPI backend engine.

In THRESHOLD, communication and active listening form the primary interaction mechanic. Players explore a stylized neighborhood, building meaningful, long-term relationships with diverse NPCs—including teachers, friends, colleagues, clients, and family members.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          THE COMPLETE GAMEPLAY LOOP                          │
│                                                                             │
│  [1. Avatar Creation]   → Customize hair, eyes, skin, clothes, LookIK head   │
│  [2. 3D Exploration]   → Move through stylized dollhouse diorama corridor   │
│  [3. Perception Layer] → Onboard with context, history & focus targets       │
│  [4. Free-Text Choice] → Communicate naturally using free-text dialogue     │
│  [5. Live Feedback]    → Watch 3D mood emojis pop & receive Coach Hints      │
│  [6. XP Settlement]    → Earn XP, level up (1–100) & adapt skill vectors     │
│  [7. Persistent State] → Update Notebook Journal facts & social graph       │
│  [8. AI Analytics]     → View Observer insights & AI Growth Reports          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. What the Player Actually Does

1. **Create Your Avatar**: Launch the game and design a unique stylized avatar in the `CharacterCustomization` interface, tailoring skin tones, 270+ hairstyles, eye shapes, nose/mouth geometry, clothing colors, and testing real-time LookIK mouse tracking in a Polaroid-style 3D viewport.
2. **Explore the 3D World**: Control your avatar along a side-scrolling 3D street hub corridor (`Street.tscn`), taking in warm diorama architecture, storefronts, lanterns, and outdoor seating.
3. **Discover NPCs & Hotspots**: Approach characters standing throughout the neighborhood—such as Daria at the café terrace or Professor Adler near the academic hallway—and press `[E]` to interact.
4. **Read the Social Perception Layer**: Review the `PerceptionModal` before conversing to understand your relationship tier (`Stranger` → `Acquaintance` → `Trusted`), known facts, situational premise, and recommended communication focus.
5. **Respond Naturally in Free Text**: Type open-ended, authentic responses into the dialogue interface (`DialogueUI`).
6. **Watch Live NPC Reactions**: Observe the floating 3D `MoodSprite3D` billboard above the NPC’s head scale up and glow with expressive emojis (`warm`, `guarded`, `skeptical`, `attentive`) as the NPC responds in character.
7. **Receive Real-Time Coaching**: Read immediate Coach Hints explaining communication strengths (e.g., *"Good open question establishing authentic presence"*).
8. **Resolve Encounters & Earn XP**: Finish the conversation to trigger the `OverviewModal` settlement screen, displaying your 4D score breakdown (Clarity, Empathy, Politeness, Expression), XP gains, and Level Up progress bar.
9. **Build Persistent Relationships**: Watch relationship tiers advance based on accumulated turn performance, unlocking deeper scenario seeds.
10. **Inspect the Notebook Journal**: Open `JournalUI` to review met NPC dossiers, discovered personal facts, and cross-NPC connection network graphs.
11. **Track Long-Term Growth**: Generate on-demand **AI Growth Analytics Reports** (`/interaction/report`) to view skill radar trends, identify strongest competencies, and receive targeted practice recommendations.

---

## 4. The Core Problem & Solution

### The Problem
* **Underdeveloped Social Confidence**: Students and professionals frequently experience social anxiety and struggle with workplace collaboration, boundary setting, and conflict resolution.
* **Passive Training Methods**: Traditional textbooks, lectures, and static e-learning modules lack interactive, safe practice environments.
* **Flaws of Unconstrained AI Chatbots**: Generic "AI NPC" projects lack game design—characters suffer from short memory windows, flip moods unpredictably, and offer zero persistent progression or diagnostic feedback.

### The Solution: Authoritative Relational Intelligence
THRESHOLD introduces a dual-layer engine architecture that enforces a strict division of responsibility:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                      AUTHORITATIVE GAME ENGINE (Python)                      │
│  • Evaluates 4D turn scores (Clarity, Empathy, Politeness, Expression)      │
│  • Computes deterministic metric updates & dampening decay (Trust, Respect) │
│  • Safe regex state engine evaluates rules (Neutral → Guarded → Warm)       │
│  • Resolves Level 1–100 XP progression & skill vector updates               │
│  • Tracks memory entries & triggers Observer pattern (Signal Count ≥ 2)     │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Constrains & Contextualizes
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GENERATIVE AI PIPELINE (LLM)                         │
│  • Renders context-aware character voice dialogue replies                   │
│  • Personalizes scenario opening lines based on history                     │
│  • Synthesizes behavioral reflection lines for Observer patterns            │
│  • Generates diagnostic progress reports for growth analytics               │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Why AI Is Necessary

* **Authentic Open-Ended Communication**: Scripted dialogue trees limit players to multiple-choice buttons, testing reading comprehension rather than self-expression. AI enables natural free-text input.
* **Adaptive Character Voice**: LLMs render natural NPC replies that instantly reflect the character’s identity, emotional state, and relationship history without requiring millions of branching tree nodes.
* **Personalized Insights**: AI analyzes memory entries to synthesize personalized observer reflections and tailored growth reports.

---

## 6. Comprehensive Feature Inventory Matrix

| Feature Category | Feature Name | What the Player Experiences | Implementation & Codebase Location | Status | Pitch Value | Best Demo Moment |
|---|---|---|---|---|---|---|
| **Player & Identity** | **Avatar Customization** | Design avatar with skin tones, 270+ hairstyles, 60 eye styles, nose/mouth shapes, clothing colors, and Polaroid viewport. | `CharacterCustomization.gd`, `CharacterCustomization.tscn`, `PlayerStore.gd` | `IMPLEMENTED` | Demonstrates deep player agency & visual polish. | Open Customization tab, cycle hairstyles & change shirt color. |
| **Player & Identity** | **LookIK Head Tracking** | Character head smoothly tilts and rotates in real time to track mouse cursor movement. | `CharacterCustomization.gd` (`_process`), `mixamorig:Head` bone slerp | `IMPLEMENTED` | Visual "WOW" factor & interactive responsiveness. | Move cursor across customizer preview. |
| **Player & Identity** | **Procedural Rigs** | Articulated low-poly humanoid character rigs with body, head, arm, and leg pivots. | `CharacterFactory.gd` (`_add_base_humanoid`) | `IMPLEMENTED` | Modular visual strategy for high performance. | Show character side-by-side standing alignment. |
| **World & Presentation**| **3D Diorama World** | Explore a stylized 2.5D dollhouse neighborhood corridor with storefronts, lanterns, and benches. | `Street.tscn`, `Street.gd`, Camera Y=2.2m, Pitch=-15° | `IMPLEMENTED` | High visual charm & cohesive art direction. | Avatar walking along the 3D sidewalk hub. |
| **World & Presentation**| **Diorama Room Scenes** | Modular 3D interior environments (Café, Study, Classroom, Office, Apartment). | `Room_Cafe.tscn`, `Room_AdlerOffice.tscn`, `Room_*.tscn` | `IMPLEMENTED` (Street Hub active) | Proves scalable environment architecture. | Show scene files in editor / docs. |
| **World & Presentation**| **Mood Billboard Overlays** | Floating 3D mood emojis above NPC heads scale and pop with emotional transitions. | `MoodSprite3D`, `DialogueUI.tscn`, `TRANS_BACK` tweens | `IMPLEMENTED` | Instant visual feedback on communication impact. | Dialogue turn causing emoji pop from guarded to warm. |
| **Social Gameplay** | **Social Perception Layer** | Onboarding modal displaying location premise, relationship tier, known facts, and focus targets. | `perception_service.py`, `PerceptionModal.tscn` | `IMPLEMENTED` | Grounding players in situational awareness before speaking. | Pressing `[E]` near NPC to open Perception Modal. |
| **Social Gameplay** | **Free-Text Dialogue** | Type natural open-ended responses into the dialogue interface. | `DialogueUI.tscn`, `ApiClient.gd` (`send_message`) | `IMPLEMENTED` | Core player input mechanic allowing authentic self-expression. | Typing a personalized response to Daria. |
| **Social Gameplay** | **4D Social Scoring** | Turn responses are evaluated across Clarity, Empathy, Politeness, Expression. | `scoring_service.py`, `llm_service.py` | `IMPLEMENTED` | Direct alignment with hackathon multi-dimensional scoring rubric. | Live turn scoring breakdown in settlement. |
| **Social Gameplay** | **State Machine & Tiering** | NPC metrics (Trust, Respect) shift deterministically, driving emotional states and relationship tiers. | `state_engine.py`, `relationship_service.py` | `IMPLEMENTED` | Guarantees fair progression & anti-hallucination. | Relationship tier promoting from Stranger to Acquaintance. |
| **Social Gameplay** | **Real-Time Coach Hints** | Surfacing immediate actionable advice on tone, structure, and perspective-taking. | `DialogueUI.tscn`, `interaction.py` (`coach_hint`) | `IMPLEMENTED` | Immediate pedagogical feedback during gameplay. | Coach Hint overlay appearing above text box. |
| **Progression** | **Level 1–100 Progression** | Earning XP from performance outcomes to advance player levels and adapt 4D skill vectors. | `progression_service.py`, `models.py` (`players`) | `IMPLEMENTED` | Direct alignment with 1–100 level progression rubric. | Level up animation on Overview Modal. |
| **Progression** | **Daily Tasks & Streaks** | Rotating daily featured scenario seeds and streak counter incentives. | `player_service.py`, `/interaction/daily`, HUD | `IMPLEMENTED` | Direct alignment with Daily Missions rubric. | HUD daily quest indicator & streak counter. |
| **Progression** | **Notebook Journal** | Dossier interface tracking met NPCs, discovered facts, and cross-NPC connection networks. | `perception_service.py`, `JournalUI.tscn` | `IMPLEMENTED` | Visualizing persistent social memory & relationship growth. | Flipping pages in the Notebook Journal. |
| **AI Capabilities** | **AI Observer Engine** | Detects recurring behavioral habits across memory entries ($\text{count} \ge 2$) to generate insights. | `observer_service.py`, `memory_service.py` | `IMPLEMENTED` | Unique innovation: AI acts as a reflective observer. | Observer reflection text on Settlement screen. |
| **AI Capabilities** | **Growth Analytics Report** | On-demand diagnostic report summarizing skill radar trends, strengths, and recommendations. | `llm_service.py`, `/interaction/report` | `IMPLEMENTED` | Direct alignment with AI Growth Analytics Report rubric. | Fetching report JSON via API / Profile card. |
| **AI Capabilities** | **Character Voice LLM** | Context-aware NPC dialogue text generation grounded in state & memory. | `llm_service.py` (`character_voice_reply`) | `IMPLEMENTED` | Authentic, adaptive role-play dialogue. | NPC responding in character during encounter. |
| **Engine & Infrastructure**| **Authoritative Backend** | FastAPI server managing state, rules, database persistence, and API contracts. | `src/main.py`, Async SQLAlchemy, SQLite (`threshold.db`) | `IMPLEMENTED` | Production-grade software architecture & safety. | Terminal output running `demo_flow.py` / tests. |
| **Engine & Infrastructure**| **CodeBuddy & Tencent Cloud** | Full-stack rapid development powered by CodeBuddy AI assistant and cloud infrastructure. | `.codebuddy`, `export_presets.cfg`, `requirements.txt` | `IMPLEMENTED` | Core hackathon tool requirement compliance. | Exported CodeBuddy chat history. |

---

## 7. Top 10 Judge WOW Moments

1. **Interactive Avatar Customization & LookIK Tracking**: Opening the customizer to see a stylized 3D avatar that interactively tracks your mouse cursor in real time while cycling through 270+ hairstyles and custom color swatches.
2. **Stylized 2.5D Dollhouse Diorama World**: Watching the 3D camera smoothly track your character along the sidewalk hub past warm storefronts, outdoor cafés, and lanterns.
3. **Pre-Dialogue Social Perception Layer Modal**: Pressing `[E]` near an NPC and having an elegant modal pop up detailing situational context, relationship tier, known facts, and communication focus targets.
4. **Natural Free-Text Dialogue Input**: Typing any free-form response into the speech interface and watching the backend evaluate it in real time.
5. **Live Floating 3D Mood Emoji Reactions**: Seeing the `MoodSprite3D` billboard above an NPC’s head scale up and glow with expressive emojis (`warm`, `guarded`, `attentive`) as dialogue turns unfold.
6. **Real-Time Communication Coach Hints**: Receiving instant, encouraging coaching advice explaining why a response was effective.
7. **Settlement Overview & Level 1–100 XP Animation**: Concluding an encounter to reveal a 4D score breakdown (Clarity, Empathy, Politeness, Expression), XP bar fill animation, and Level Up notifications.
8. **AI Observer Pattern Insights**: Discovering a deep behavioral pattern reflection on the settlement screen after multiple conversations (e.g., *"Across these exchanges with Daria, a pattern of protective honesty recurred"*).
9. **Interactive Notebook Journal & Connection Graph**: Opening the notebook UI to view unlocked NPC dossiers, discovered personal facts, and cross-NPC connection networks.
10. **On-Demand AI Growth Analytics Report**: Triggering a comprehensive diagnostic report that visualizes performance trends, highlights improving areas, and recommends targeted practice scenarios.

---

## 8. The Relational Intelligence Engine Architecture

```text
Godot 4 Client (client/)                   FastAPI Authoritative Engine (src/)
┌───────────────────────────┐             ┌───────────────────────────────────┐
│ • Character Customization │             │ • Routers (/interaction, /player) │
│ • 3D Diorama Street Hub   │  HTTP REST  │ • 4D Scoring (scoring_service.py) │
│ • MoodSprite3D Overlay    │ ──────────► │ • Metric Math (relationship_s.py) │
│ • PerceptionModal         │ ◄────────── │ • State Engine (state_engine.py)  │
│ • DialogueUI & HUD        │   JSON      │ • Progression (progression_s.py)  │
│ • OverviewModal           │             │ • Observer (observer_service.py)  │
│ • JournalUI               │             │ • SQLite DB (threshold.db)        │
└───────────────────────────┘             └─────────────────┬─────────────────┘
                                                            │ LLM Calls
                                                            ▼
                                          ┌───────────────────────────────────┐
                                          │ LLM Service (llm_service.py)      │
                                          │ • Character Voice Reply           │
                                          │ • Observer Phrasing Synthesis     │
                                          │ • AI Growth Analytics Reports     │
                                          └───────────────────────────────────┘
```

---

## 9. Player & Identity Systems (Avatar Customization & LookIK)

THRESHOLD provides a deep player identity experience through its custom avatar system:
* **8 Skin Color Palettes**: From light cream to deep warm tones.
* **270+ Hairstyles & Color Swatches**: Ranging from short crops to long layered styles with 8 color swatches.
* **60 Eye Styles & High-Res Textures**: 1024×1024 crisp texture maps with dynamic RGB channel remapping for Sclera, Iris, and Pupil colors.
* **6 Nose & 6 Mouth Shapes**: Procedural and sprite-based facial geometry with dual-lip auto-shading.
* **Custom Clothing Palettes**: 12 shirt colors and 12 pants colors.
* **Real-Time LookIK Mouse Tracking**: The avatar’s head (`mixamorig:Head` bone) smoothly slerps to track mouse movement across the screen.
* **Polaroid Viewport Preview**: SubViewport camera framing presenting the avatar inside a stylized Polaroid card.

---

## 10. 3D World & Presentation Systems

* **Visual Aesthetic**: Warm terracottas (`#E67314`), creams (`#F5EDD9`), dark browns (`#2E261A`), sage greens (`#7A8B7B`), and deep navies (`#1B263B`).
* **Camera Perspective**: Fixed-pitch dollhouse diorama angle (Y = 2.2m, Z = 4.5m, pitch = -15°).
* **Environment Scale**: 1 Godot Unit = 1.0 Meter; street corridor spans 76 meters ($X \in [-38, 38]$).
* **Audio & Feedback**: `AudioManager.gd` providing UI hover/click sounds, ambient music, and toast notifications (`ToastManager.gd`).

---

## 11. Social Gameplay & Perception System

* **Social Perception Layer**: Surfaces relationship history, known facts, and focus targets prior to dialogue.
* **16 NPC Archetype Templates**: Teachers, friends, colleagues, clients, family members, and strangers (`content/npc_templates.yaml`).
* **25 Scenario Seeds**: Categorized across 3 level bands (1–30, 31–70, 71–100) and 4 categories (`everyday_social`, `friendship`, `workplace`, `high_pressure`).
* **4D Social Competency Evaluation**:
  - **Clarity**: Directness, structure, and focus.
  - **Empathy**: Attunement to feelings and perspective-taking.
  - **Politeness**: Respect, boundary awareness, and tone.
  - **Expression**: Authenticity, personal honesty, and openness.

---

## 12. Progression & Gamification Systems

* **Level 1–100 System**: Deterministic XP calculation based on encounter performance outcomes (`good`, `neutral`, `poor`), level dampening, and skill vector adaptation.
* **Daily Tasks & Streaks**: Rotating featured daily scenario seeds and streak counter tracking.
* **Notebook Journal**: Persistent record of met NPCs, discovered facts, and cross-NPC connection network graph.

---

## 13. AI Capabilities & Subsystems

1. **Character Voice LLM**: Context-aware NPC dialogue generation.
2. **AI Observer Pattern Engine**: Fires when memory interpretation signals reach $\text{count} \ge 2$, generating reflective behavioral insights.
3. **AI-Powered Growth Analytics Report**: On-demand diagnostic summaries generated via `/interaction/report`.

---

## 14. Hackathon Judging Rubric Alignment

| Evaluation Dimension | Weight | Rubric Requirements | THRESHOLD Evidence | Demo Strategy | Strength |
|---|---|---|---|---|---|
| **Theme Alignment** | **30 pts** | Close alignment with Relational Intelligence Engine challenge; gamifies social interactions, workplace collaboration, and conflict resolution. | Direct 1:1 match. Features 25 scenarios spanning everyday social interactions, academic advisement, office collaboration, and high-pressure conflict resolution. | Demonstrate multi-turn social interaction showing clear social skills coaching. | **HIGH** |
| **Use of AI Tools** | **40 pts** | Effective use of CodeBuddy; depth & originality of AI modules (worldbuilding, intelligent NPCs, key art, audio/video); CodeBuddy transcript exported. | Built using CodeBuddy; features hybrid LLM character voice pipeline, AI Observer engine, and AI Growth Analytics Report generator. | Showcase CodeBuddy chat transcript, AI character voice responses, and diagnostic report generation. | **HIGH** |
| **Game Quality** | **30 pts** | Playability, creativity, visual polish, avatar customization, and overall balance of gameplay experience. | Complete 3D diorama game in Godot 4 with avatar customizer, LookIK tracking, smooth camera glides, mood emojis, HUD, journal, and settlement modals. | Live browser/standalone gameplay run-through of the end-to-end loop from customization to settlement. | **HIGH** |
| **Bonus Item** | **+5 pts** | Social media post with hashtags `#CodeBuddy` and `#TencentCloudHackathon`. | Public demo video upload planned with required hashtags. | Include social post link in submission form. | **HIGH** |

---

## 15. Pitch Deck Source (10 Slides)

* **Slide 1: THRESHOLD — Relational Intelligence Engine** (Hero visual & pitch)
* **Slide 2: The Social Experience** (What the player does)
* **Slide 3: The 3D Diorama World** (Stylized neighborhood & diorama framing)
* **Slide 4: Player Avatar & Identity** (Customization system, 270+ hairstyles, LookIK tracking)
* **Slide 5: Social Perception & Open Dialogue** (Free-text conversation & perception layer)
* **Slide 6: Relationships That Remember** (Authoritative state, metrics & persistence)
* **Slide 7: AI Relational Intelligence** (4D scoring, character voice, observer, analytics)
* **Slide 8: Level 1–100 Progression & Gamification** (XP, daily tasks, streaks, journal)
* **Slide 9: Authoritative Technical Architecture** (FastAPI + Godot 4 + CodeBuddy)
* **Slide 10: Rubric Alignment & Winning Vision** (Summary & call to action)

---

## 16. Demo Video Source

```text
[0:00 - 0:20] AVATAR CUSTOMIZATION & WORLD EXPLORATION
SHOW: Player customizing avatar in CharacterCustomization.tscn (cycling hair, skin tone, watching LookIK head track mouse). Transition to avatar walking down 3D Street Hub diorama.
SAY: "Welcome to THRESHOLD—a 3D social-simulation RPG where communication is your primary gameplay mechanic. Players begin by creating a custom avatar with real-time head tracking before stepping into a vibrant diorama neighborhood."

[0:20 - 0:45] SOCIAL PERCEPTION LAYER & DIALOGUE
SHOW: Player approaches Daria, hits [E]. PerceptionModal appears showing relationship status 'Stranger' and focus 'Politeness + Expression'. DialogueUI opens.
SAY: "Before entering an encounter, THRESHOLD's Social Perception Layer surfaces situational context and relationship history. As you communicate using natural free text, your words are evaluated in real time across four social competencies."

[0:45 - 1:15] LIVE METRIC SHIFT & MOOD EMOJI
SHOW: Player types a thoughtful message. The MoodSprite3D billboard above Daria's head scales up with a warm emoji glow. Coach hint pops up.
SAY: "Unlike raw chatbots with unpredictable mood swings, THRESHOLD's backend runs deterministic metric math. High empathy and politeness directly increase Trust and Respect state machines, triggering live 3D mood emoji reactions and real-time coach hints."

[1:15 - 1:40] SETTLEMENT, OBSERVER PATTERN & PROGRESSION
SHOW: Dialogue ends. OverviewModal opens. XP bar animates, Level Up banner appears. Observer pattern text highlights: "A pattern of protective honesty recurred."
SAY: "At encounter end, players gain XP toward a 100-level progression system, while our AI Observer engine detects recurring behavioral habits across memory entries."

[1:40 - 2:00] JOURNAL & AI GROWTH ANALYTICS REPORT
SHOW: Player opens JournalUI, flips notebook pages showing met NPCs, discovered facts, and triggers the AI Growth Analytics Report.
SAY: "The persistent Notebook Journal tracks discovered facts and social connection networks, while on-demand Growth Reports visualize skill trends and recommend targeted practice scenarios."

[2:00 - 2:15] TECHNICAL ARCHITECTURE & OUTRO
SHOW: Quick split-screen of Godot 4 editor and FastAPI backend terminal running tests. Tencent Cloud & CodeBuddy credits.
SAY: "Built in Godot 4 and powered by Python FastAPI and CodeBuddy, THRESHOLD bridges the gap between AI innovation and game design."
```

---

## 17. Live Presentation Script

**[0:00–0:30] Introduction & Vision**  
"Honored judges, imagine standing in a high-stakes workplace meeting or resolving a conflict with a close friend. Knowing *what* to say is easy; having the confidence and skill to say it effectively is hard. Traditional training relies on static slides and passive role-play. But when developers try to use AI for this, they usually drop a raw ChatGPT prompt into a text box—resulting in hallucinated character reactions, zero long-term memory, and no real gameplay loop. Today, we present **THRESHOLD**—a 3D social-simulation RPG powered by an authoritative **Relational Intelligence Engine**."

**[0:30–1:15] The Player Experience**  
"In THRESHOLD, communication replaces physical combat. You begin by creating your custom avatar using a rich customization system with over 270 hairstyles, skin palettes, and real-time mouse-tracking LookIK animation. Stepping into a warm 3D diorama neighborhood, you explore locations like the Downtown Café and Office Executive Suites. As you approach an NPC, our **Social Perception Layer** surfaces your relationship history, known facts, and communication focus before you speak."

**[1:15–2:00] Dual-Layer Engine Innovation**  
"What makes THRESHOLD truly innovative is its dual-layer architecture. We strictly decouple game math from generative text. When the player sends a message, our Python FastAPI backend scores the response across four core social competencies: Clarity, Empathy, Politeness, and Expression. These scores feed into deterministic mathematical formulas that update persistent NPC metrics—like Trust, Respect, and Patience. Notice how Daria's floating 3D mood emoji transitions live from guarded to warm. That shift wasn't a random LLM hallucination—it was calculated by our safe backend state engine."

**[2:00–2:45] Progression, Observer & Growth Analytics**  
"When an encounter ends, THRESHOLD rewards you with XP, advancing you through a 100-level difficulty progression system. Our **Observer Pattern Engine** monitors memory entries across encounters to surface deep behavioral insights when recurring habits are detected. Players can open their Notebook Journal to inspect discovered NPC facts, or generate comprehensive **AI Growth Analytics Reports** that benchmark skills and recommend specific future practice scenarios."

**[2:45–3:00] Closing Statement**  
"THRESHOLD demonstrates what happens when AI is treated not just as a gimmick, but as an expressive layer governed by authoritative game design. Built with Godot 4 and Tencent Cloud's CodeBuddy, THRESHOLD turns everyday social interactions into a measurable, persistent, and engaging 3D game. Thank you!"

---

## 18. Technical Proof Points & Authoritative Code Grounding

1. **Avatar Customization & LookIK**: Implemented in `CharacterCustomization.gd`, `CharacterFactory.gd`, `PlayerStore.gd`, supporting 270+ hairstyles, 60 eye styles, 1024×1024 high-res texture maps, and bone pose slerping (`mixamorig:Head`).
2. **Backend-Authoritative Architecture**: All game state, relationship math, state rules, and progression formulas reside strictly in the Python FastAPI backend (`src/`), ensuring total client separation (`client/singletons/ApiClient.gd`).
3. **Deterministic Metric & State Formulas**: Metric updates follow exact weighted dampening math:
   $$\text{delta} = \left(\sum \text{score}[\text{dim}] \times \text{weight}\right) \times 0.15$$
   $$\text{new\_metric} = \text{clamp}(\text{old\_metric} + \text{delta} - \text{turn\_decay},\; \text{min},\; \text{max})$$
4. **Safe Regex Expression Parsing**: NPC state transitions (`state_engine.py`) evaluate conditions like `respect >= 0.70 and confidence >= 0.65` using custom regex comparison dicts with zero dynamic `eval()` calls.
5. **Structured Content Registry**: Loaded at startup from `content/npc_templates.yaml` (16 complete NPC archetype templates) and `content/scenario_seeds.yaml` (25 scenario seeds across 3 level bands).
6. **Observer Pattern Frequency Engine**: Memory entries (`memory_entries` table) log structured interpretation signals (`interpretation`). When signal count $\ge 2$, `observer_service.py` triggers pattern synthesis.
7. **Automated Test Suite**: 58 automated unit & integration tests (`run_tests.py`) covering state rules, metric clamping, level advancement, scenario selection, and perception assembly passing cleanly in under 2 seconds.

---

## 19. Competitive Differentiation

```text
┌─────────────────────────┬──────────────────────────┬──────────────────────────┬──────────────────────────┐
│ Dimension               │ Traditional Visual Novel │ Raw AI Chatbot Project   │ THRESHOLD                │
├─────────────────────────┼──────────────────────────┼──────────────────────────┼──────────────────────────┤
│ Player Avatar           │ Static 2D portrait       │ Plain web text avatar    │ Custom 3D Avatar + LookIK│
│ Player Input            │ Fixed multiple choice    │ Free-form text           │ Free-form text           │
│ Input Processing        │ Hardcoded branch index   │ Sent directly to LLM     │ 4D Social Skill Scoring  │
│ State Machine           │ Boolean flag triggers    │ Forgotten context window │ Authoritative SQLite DB  │
│ Mood Shift Guarantee    │ Static asset swap        │ Unpredictable/Volatile   │ Deterministic Math Engine│
│ Progression System      │ Linear chapter unlock    │ None                     │ Level 1–100 XP System    │
│ Pedagogical Feedback    │ None                     │ Generic chat response    │ Observer & Growth Report │
│ Visual Environment      │ Static 2D background     │ Plain text web page      │ 3D Stylized Diorama Hub  │
└─────────────────────────┴──────────────────────────┴──────────────────────────┴──────────────────────────┘
```

---

## 20. Claims Audit

### 20.1 Verified / Safe Claims (100% Implemented & Demonstrable)
- "THRESHOLD is a 3D social-simulation RPG built in Godot 4 with a Python FastAPI backend."
- "Features an interactive 3D avatar customizer supporting skin tones, 270+ hairstyles, 60 eye styles, clothing colors, and LookIK head tracking."
- "Game state, relationship metric shifts, state rules, and Level 1–100 XP progression are 100% deterministic."
- "Player free-text responses are evaluated across four social dimensions: Clarity, Empathy, Politeness, Expression."
- "Features 16 distinct NPC templates and 25 scenario seeds categorized across Level 1–100 progression bands."
- "Includes a pre-dialogue Social Perception Layer onboarding modal and persistent Notebook Journal."
- "Includes an AI Observer pattern engine that triggers on recurring memory interpretation signals ($\text{count} \ge 2$)."
- "Generates on-demand AI Growth Analytics Reports summarizing strengths, improving areas, and recommendations."
- "Developed with Tencent Cloud CodeBuddy integration and automated backend test coverage (58 passing tests)."

### 20.2 Strong but Qualified Claims (Phrase Carefully)
- *"Includes full 3D interior diorama rooms."* → **Qualification**: Interior diorama rooms (`Room_Cafe.tscn`, `Room_AdlerOffice.tscn`, etc.) are fully structured scene files in Godot; the main Street Hub corridor (`Street.tscn`) is the primary active exploration scene where gameplay and dialogue take place.
- *"Real-time speech interaction."* → **Qualification**: The system supports natural open free-text dialogue input with stylized speech bubble overlays and floating 3D mood emojis; RTC real-time voice input is a designed expansion route.

### 20.3 Claims We Must NOT Make (Unsupported / Do Not Claim)
- ❌ Do NOT claim THRESHOLD includes physical combat, weapons, or traditional inventory item management.
- ❌ Do NOT claim NPC dialogue is 100% pre-scripted branching paths (it is open free-text interpreted by AI).
- ❌ Do NOT claim the LLM directly modifies database state or metric math (metric math is strictly deterministic).
- ❌ Do NOT claim infinite procedural 3D map generation (world is structured around diorama scenes).

---

## 21. Judge Q&A Preparation

### Q1: Why does this game need AI? Why not just use traditional dialogue trees?
**Answer**: Traditional dialogue trees require hardcoding every possible multiple-choice option, which tests reading comprehension rather than genuine self-expression. AI enables THRESHOLD to interpret open free-text responses and generate natural, context-aware NPC replies that adapt to the NPC’s current emotional state and relationship history, without requiring millions of pre-scripted branching lines.
*Technical Proof*: `llm_service.py` (`character_voice_reply`) takes the NPC profile, effective metrics, emotional state, and recent turn history, generating authentic character responses constrained by the backend state.

### Q2: How do you prevent the AI from hallucinating or breaking character?
**Answer**: By strictly decoupling game rules from text generation. The LLM is never allowed to modify relationship metrics, grant XP, or decide emotional state transitions. All state logic is evaluated by an authoritative Python engine using safe regex condition matching (`state_engine.py`). The LLM is given strict system prompts containing only the NPC’s current state and character rules.
*Technical Proof*: `state_engine.py` evaluates metric expressions like `respect >= 0.70` deterministically with zero dynamic `eval()` execution.

### Q3: What features did you implement for player identity and avatar customization?
**Answer**: THRESHOLD features a full avatar customization suite (`CharacterCustomization.gd`) with 8 skin color palettes, 270+ hairstyles, 60 eye styles with 1024×1024 high-res texture maps and dynamic RGB chroma-key remapping, 6 nose and 6 mouth shapes, clothing palettes, Polaroid viewport preview, and real-time LookIK head tracking that follows mouse movement.
*Technical Proof*: Implemented in `client/scenes/ui/CharacterCustomization.gd` and `CharacterFactory.gd`.

### Q4: How are relationships and memory represented?
**Answer**: Relationships are tracked per-player, per-NPC in SQLite (`npc_instances` table) through quantitative metrics (`trust`, `respect`, `patience`, `closeness`, `candor`, `confidence`). Memory is stored in `memory_entries` logging exact turn snippets and mapped `interpretation` signals.
*Technical Proof*: `src/models.py` schema defines `NpcInstance` metrics JSON and `MemoryEntry` event/interpretation mappings.

### Q5: How does the Observer Pattern work?
**Answer**: As the player interacts with NPCs, each turn logs an interpretation signal (e.g., `named_own_shortfall_honestly`). `observer_service.py` monitors these entries. When any single signal count reaches $\ge 2$, the Observer pattern fires, invoking the LLM to synthesize a reflective insight for the player's settlement modal.
*Technical Proof*: Tested in `tests/test_observer_service.py`, verifying trigger execution at signal count threshold.

### Q6: How does THRESHOLD align with the hackathon's "Relational Intelligence Engine" challenge?
**Answer**: THRESHOLD directly answers the problem statement by gamifying real-life social interactions, workplace collaboration, and conflict resolution. It incorporates all required gamification elements: 1–100 level progression, multi-dimensional scoring (Clarity, Empathy, Politeness, Expression), daily challenges, emotion recognition, avatar customization, and AI-powered growth reports.
*Technical Proof*: Matches evaluation dimensions across Theme Alignment (30 pts), Use of AI Tools (40 pts), and Game Quality (30 pts).

---

## 22. Product-Oriented Closing Statement

THRESHOLD redefines what AI can bring to video games and social skills education. By pairing a rich 3D diorama world and custom avatar system with an authoritative **Relational Intelligence Engine**, THRESHOLD turns interpersonal communication into a safe, persistent, and deeply engaging game loop.

**AI CAN DO IT — and in THRESHOLD, AI empowers players to master the most vital human skill of all: relational intelligence.**
