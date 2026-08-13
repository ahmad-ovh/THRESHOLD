# Storyboard Loading Implementation

This document describes how the current THRESHOLD storyboard system is implemented in the live Godot codebase. It covers the complete load path from the Main Menu to the first playable room.

## What this system does

The storyboard system is a **one-time, optional loading cinematic** shown when starting a new game for the first time. It combines:

- A 3-panel narrative UI with chapter text + imagery
- Real-time loading progress tied to a threaded resource preloader
- An `any key`/click handoff point to the gameplay scene
- Scene transition and player spawn handling in `SceneManager`

## Core files

- [client/scenes/main_menu/MainMenu.gd](C:\Users\User\Documents\THRESHOLD\client\scenes\main_menu\MainMenu.gd)
- [client/singletons/GameController.gd](C:\Users\User\Documents\THRESHOLD\client\singletons\GameController.gd)
- [client/singletons/SceneManager.gd](C:\Users\User\Documents\THRESHOLD\client\singletons\SceneManager.gd)
- [client/scenes/ui/StoryboardLoading.tscn](C:\Users\User\Documents\THRESHOLD\client\scenes\ui\StoryboardLoading.tscn)
- [client/scenes/ui/StoryboardLoading.gd](C:\Users\User\Documents\THRESHOLD\client\scenes/ui\StoryboardLoading.gd)

## Control flow (normal first-time start)

```mermaid
flowchart TD
  A[Start button pressed in MainMenu] --> B[GameController.start_new_game()]
  B --> C{enable_storyboard && !has_shown_storyboard}
  C -->|true| D[SceneManager.change_room_async(target=Street.tscn, show_storyboard=true)]
  C -->|false| E[SceneManager.change_room_async(target=Street.tscn, show_storyboard=false)]
  D --> F[SceneManager preloads target scene]
  F --> G[StoryboardLoading scene instantiated + target_scene_path set]
  G --> H[User can advance panels / wait for auto-advance]
  H --> I[Story loading loop checks SceneManager.is_scene_loaded()]
  I --> J{Sequence finished && scene loaded}
  J -->|true| K[storyboard emits storyboard_completed]
  K --> L[change_room_async switches to Street.tscn]
  L --> M[SceneManager positions player]
  M --> N[Storyboard fade_out_and_close()]
  N --> O[is_transitioning false]
  E --> O
```

## Start trigger and gating

### `MainMenu`

`_on_start_pressed()` sets `GameController.enable_storyboard` from the menu export and calls:

- `await GameController.start_new_game(name_txt)`

### `GameController`

- `enable_storyboard` (default `false` for controller, default `true` for menu export; menu currently drives the value).
- `has_shown_storyboard` ensures one-time playback per session.
- `start_new_game()` computes:
  - `show_sb = enable_storyboard and not has_shown_storyboard`
  - sets `has_shown_storyboard = true` when shown
  - calls `SceneManager.change_room_async("res://scenes/rooms/Street.tscn", "default", show_sb)`

## Scene manager orchestration

### `SceneManager.preload_scene(scene_path)`

- Starts threaded loading with:
  - `ResourceLoader.load_threaded_request(scene_path, "", true)`
- Tracks paths in `_preloaded_paths`.

### `SceneManager.is_scene_loaded(scene_path)`

- Returns `true` only if:
  - path is tracked in `_preloaded_paths`
  - `ResourceLoader.load_threaded_get_status(scene_path) == ResourceLoader.THREAD_LOAD_LOADED`

### `SceneManager.change_room_async(scene_path, spawn_id, show_storyboard)`

1. Guards transition with `is_transitioning`.
2. Saves prior player state (`_maybe_save_street_position`) and records spawn target.
3. Preloads the target scene.
4. If `show_storyboard == true`:
   - Instantiate `res://scenes/ui/StoryboardLoading.tscn`.
   - Set storyboard property: `target_scene_path = scene_path`.
   - Add to `root`.
   - Await `storyboard_completed` signal.
   - `_switch_to_scene(scene_path)`.
   - `await process_frame` then `_position_player()`.
   - Await `fade_out_and_close()` (or free immediately if method unavailable).
   - Mark transition complete.
5. Else:
   - Falls back to `change_room(scene_path, spawn_id)` and toggles the same `is_transitioning` contract.

### Player positioning behavior

After scene switch, `_position_player()` resolves into marker or restored street position:

- Restores saved street transforms for returning from non-street scenes.
- Otherwise picks marker by:
  - exact/fuzzy `spawn_id` match
  - known default names (`spawndefault`, `default`, `playerstart`, etc.)
  - final fallback first available `Marker3D` in scene
- Clamps camera pivot x on non-fixed diorama states.

## Storyboard UI scene graph

`StoryboardLoading.tscn` is a `CanvasLayer` (layer 95) with:

- `Root` overlay container
- Paper background + heading card
- Chapter title (`ChapterLabel`)
- Panel image (`PanelImage`) and narrative rich text (`NarrativeLabel`)
- Bottom status bar:
  - `ProgressBar`
  - `StatusLabel` (e.g., loading progress)
  - `PromptLabel`

## `StoryboardLoading.gd` state machine

### Exposed + runtime state

- `@export var target_scene_path: String = "res://scenes/rooms/Street.tscn"`
- Signal: `storyboard_completed`
- Panel data: `_narrative_panels` array of 3 entries
- Runtime flags:
  - `_sequence_finished`
  - `_scene_loaded`
  - `_can_advance`

### Initialization (`_ready`)

- Sets layer and fade-in state.
- Initializes prompt text.
- Calls `_show_panel(0)`.
- Starts automatic panel timer via `_start_panel_timer()`.
- Starts with `root` alpha at `0.0`, then tween to `1.0` over `0.4s`.

### Loading loop (`_process`)

While `_scene_loaded == false`, each frame:

- Checks `SceneManager.is_scene_loaded(target_scene_path)` (preferred path).
- Fallback to `ResourceLoader.load_threaded_get_status`.
- If loaded:
  - sets `progress_bar = 100`
  - `status_label = "World Loaded 100%"`
  - calls `_check_completion()`
- Else:
  - reads `progress` array and sets bar to clamped `15..95`
  - sets `"Loading World... N%"`

### Input handling (`_unhandled_input`)

On key or mouse click:

- Esc-like / cancel (`KEY_ESCAPE` or `ui_cancel`) => `_skip_to_end()`
- Else:
  - If sequence finished => `_complete()`
  - Else if advance allowed => `_advance_panel()`

### Panel display (`_show_panel`)

- Updates chapter / text / image.
- Applies paper-card intro tween: scale from `0.95` to `1.0` over `0.4s`.
- Re-enables advancement immediately (`_can_advance = true`).
- Triggers hover SFX if available.

### Timer-driven progression (`_start_panel_timer`)

- Creates a `4.0s` timer that:
  - advances panel if not finished and not at last panel
  - marks finished and checks completion if already at final panel

### Completion checks and handoff (`_check_completion`)

- If both sequence finished and scene loaded:
  - prompt changes to `"Press [Any Key] to enter Threshold"`
  - prompt label blinks (`set_loops()` with alpha 1.0 ↔ 0.3)
  - after `0.8s` calls `_complete()`
- If sequence finished but scene not loaded:
  - status label becomes `"Finalizing world generation..."`

### Completion and teardown

- `_complete()` only emits `storyboard_completed` when `_scene_loaded == true`.
- `fade_out_and_close()` in storyboard scene fades overlay alpha to `0.0` in `0.5s` and frees itself.

## Behavioral notes and caveats

- The storyboard can be skipped with Escape/Cancel.
- User input is always accepted after first panel load and while not finished, but final transition usually auto-triggers once both conditions are met.
- Auto-advance and manual input timers can both run; callbacks are guarded with `_sequence_finished` checks.
- The loading bar intentionally never exceeds 95% until load completion state is confirmed.

## Integration/extension points

- Panel content:
  - Edit `_narrative_panels` in `StoryboardLoading.gd` (chapter, text, image paths).
- Loading UX:
  - Panel duration (`4.0` seconds), fade times, and prompt strings are in `StoryboardLoading.gd`.
- Scene/target control:
  - `target_scene_path` is passed from `SceneManager.change_room_async`.
- Feature control:
  - In menu, `enable_storyboard` export decides whether to request storyboard on fresh session start.

## Related references

- Legacy authored storyboard prose is documented in:
  - [THRESHOLD_PROLOGUE_STORYBOARD.md](C:\Users\User\Documents\THRESHOLD\THRESHOLD_PROLOGUE_STORYBOARD.md)
