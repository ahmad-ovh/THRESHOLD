# THRESHOLD — Godot 4 Step-by-Step Implementation Guide & Progress Checklist

This guide is a step-by-step tutorial for building the **THRESHOLD** game client in **Godot 4**. The client codebase has been instantiated under `client/`. Use this document as both an implementation blueprint and a progress checklist.

---

## 📊 Implementation Progress Checklist

| Component / Task | Status | Location in Codebase |
|---|---|---|
| **Project Creation & Rendering** | ✅ Completed | `client/project.godot` (GL Compatibility mode) |
| **Window Size & Stretch Settings** | ✅ Completed | `client/project.godot` (`1280x720`, `canvas_items`, `expand`) |
| **Input Map Actions** | ✅ Completed | `client/project.godot` (`interact` [E], `toggle_journal` [J]) |
| **Autoload Registrations** | ✅ Completed | `client/project.godot` (`SceneManager`, `PlayerStore`, `ApiClient`, `EncounterManager`) |
| **Directory Structure** | ✅ Completed | `client/singletons/`, `client/resources/`, `client/scenes/` |
| **SceneManager Autoload** | ✅ Completed | `client/singletons/SceneManager.gd` (Fade transition & spawn positioning) |
| **PlayerStore Autoload** | ✅ Completed | `client/singletons/PlayerStore.gd` (Player stats & skill vector storage) |
| **ApiClient REST Autoload** | ✅ Completed | `client/singletons/ApiClient.gd` (FastAPI REST HTTP client) |
| **EncounterManager Autoload** | ✅ Completed | `client/singletons/EncounterManager.gd` (Encounter state machine & API loop) |
| **3D Player Character** | ✅ Completed | `client/scenes/player/Player3D.tscn` & `Player3D.gd` |
| **Modular Room Doors** | ✅ Completed | `client/scenes/rooms/Door3D.tscn` & `Door3D.gd` |
| **Sample 3D Rooms** | ✅ Completed | `client/scenes/rooms/Room_Start.tscn` & `Room_Office.tscn` |
| **Reusable NPC Template** | ✅ Completed | `client/scenes/templates/NPC.tscn` & `NPC.gd` |
| **Custom NPCData Resource** | ✅ Completed | `client/resources/npc_data/NPCData.gd` |
| **Floating Mood Emoji Billboard** | ✅ Completed | `client/scenes/templates/NPC.tscn` (`HeadMarker/MoodSprite3D` Sprite3D) |
| **Dialogue UI Overlay** | ✅ Completed | `client/scenes/ui/DialogueUI.tscn` & `DialogueUI.gd` (Typewriter & input) |
| **Main Menu Login Scene** | ✅ Completed | `client/scenes/main_menu/MainMenu.tscn` & `MainMenu.gd` (Main scene) |
| **In-Game HUD Overlay** | ✅ Completed | `client/scenes/ui/HUD.tscn` & `HUD.gd` (Level, XP, Streak, Journal button) |
| **Journal Profile Book Modal** | ✅ Completed | `client/scenes/ui/JournalUI.tscn` & `JournalUI.gd` (Skill vector & `/report`) |
| **3D Mesh Art Assets (.glTF)** | ⏳ Optional Editor Task | Replace placeholder capsules with custom 3D models in `NPCData` |
| **2D Mood Emoji PNG Assets** | ⏳ Optional Editor Task | Add PNG icons to `res://resources/mood_emojis/` & assign in `.tres` |
| **Godot Web (HTML5) Export** | ⏳ User Task | Download export templates & click Export Project to Web |

---

## Part 1: Project Creation & Godot Engine Settings

### Step 1.1: Create New Project
1. Open **Godot 4.x**.
2. Click **Open** (or **Import**) and select `c:/Users/User/Documents/THRESHOLD/client/project.godot`.
3. **Renderer**: **Compatibility** *(recommended for Web / HTML5 exports)*.

### Step 1.2: Configure Input Map (Controls)
Go to **Project -> Project Settings -> Input Map**.
- `interact` -> Key **E**
- `toggle_journal` -> Key **J**

### Step 1.3: Configure Window & Stretch Mode
1. Go to **Project -> Project Settings -> General -> Display -> Window**.
2. Under **Size** (at the top):
   - **Viewport Width**: `1280`
   - **Viewport Height**: `720`
   - **Mode**: Keep as `Windowed`.
3. Scroll down to the **Stretch** subsection (at the bottom of the Window page):
   - **Mode**: Select `canvas_items` *(Note: Under the Stretch sub-header at the bottom!)*
   - **Aspect**: Select `expand`

---

## Part 2: Implementation Details & File Reference

### 1. Autoload Singletons (`client/singletons/`)
- `SceneManager.gd`: Controls room transitions via `change_room(scene_path, spawn_id)` with screen fade-to-black.
- `PlayerStore.gd`: Manages `player_id`, `level`, `xp_progress`, `daily_streak`, and `skill_vector`.
- `ApiClient.gd`: Handles FastAPI HTTP REST API endpoints (`/player/status`, `/interaction/start`, `/interaction/message`, `/interaction/end`, `/interaction/report`).
- `EncounterManager.gd`: Manages conversation triggers, freezes/unfreezes 3D player movement, opens `DialogueUI.tscn`, updates billboard mood emojis, and finalizes encounters.

### 2. Player & Doors (`client/scenes/player/` & `client/scenes/rooms/`)
- `Player3D.tscn`: 3D player character (`CharacterBody3D`) with WASD movement and `InteractionDetector` Area3D.
- `Door3D.tscn`: Door trigger (`Area3D`) with "Press [E] to Enter" 3D label.
- `Room_Start.tscn`: Starter room scene containing floor mesh, lighting, player spawn point, door to office room, and NPC Daria (`npc_id="daria"`).
- `Room_Office.tscn`: Office room scene containing door back to start and NPC Prof. Adler (`npc_id="prof_adler"`).

### 3. Reusable NPC System (`client/scenes/templates/` & `client/resources/npc_data/`)
- `NPC.tscn`: Reusable NPC template scene with `HeadMarker` Marker3D, billboard Y-axis `MoodSprite3D`, `PromptLabel3D`, and interaction Area3D.
- `NPCData.gd`: Custom Resource type for loading 3D character meshes and mood emoji textures.

### 4. UI Layer (`client/scenes/ui/` & `client/scenes/main_menu/`)
- `MainMenu.tscn`: Login menu with username input (`player_id`) and Start Game button loading `Room_Start.tscn`.
- `DialogueUI.tscn`: Dialogue text overlay with typewriter animation, player input text box, and send button.
- `HUD.tscn`: Always-on HUD showing Player ID, Level, XP progress bar, Streak flame, and Journal toggle button (`J`).
- `JournalUI.tscn`: Tabbed profile modal displaying Skill Vector meters and calling `POST /interaction/report` for AI pattern analysis.

---

## Part 3: Running & Exporting the Game

### Testing in Godot Editor
1. Open Godot 4 and open the `client` project.
2. Ensure your backend FastAPI server is running on `http://127.0.0.1:8000`:
   ```powershell
   uvicorn src.main:app --reload --port 8000
   ```
3. Press **F5** in Godot to run the main menu (`MainMenu.tscn`), enter your player ID, and click **Start Game**!

### Exporting to Web (HTML5)
1. Go to **Editor -> Manage Export Templates -> Download & Install**.
2. Go to **Project -> Export -> Add... -> Web**.
3. Set **Export Path**: `build/web/index.html`.
4. Click **Export Project** -> Save.
5. In terminal:
   ```powershell
   cd build/web
   python -m http.server 8060
   ```
6. Open `http://localhost:8060` in your web browser!
