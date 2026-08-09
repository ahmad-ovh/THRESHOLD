# THRESHOLD — World-Building Rules for Automated Agents

> **System Status**: `IMPLEMENTED`  
> **Mandatory Compliance**: Mandatory for all future world-building, asset-import, and environment-generation agents.

---

## 1. Non-Negotiable Operational Rules

### Rule 1: Do Not Invent or Modify Backend Gameplay Systems
- Never edit Python backend code (`src/`), database schemas (`src/models.py`), or API endpoints (`src/routers/`) during a world-building or asset pass.
- Do not create custom client-side game logic that bypasses backend state calculation.

### Rule 2: Preserve Godot Group Memberships & Signal Connections
- `Player3D` must remain in the `"player"` group.
- All NPC nodes must remain in the `"npcs"` group and preserve the export variable `npc_id: String`.
- `InteractionDetector` Area3D nodes must remain attached to `Player3D` and NPCs with collision layer/mask signals intact.

### Rule 3: Maintain 1:1 Scale & Coordinate Conventions
- 1 Godot Unit = 1.0 Meter.
- Character height must remain $\approx 1.7$ meters.
- Street corridor hub bounds span $X \in [-38.0, 38.0]$ meters. Do not move spawn points outside these bounds.

---

## 2. Spatial & Camera Clearances

### Rule 4: Preserve Dialogue Standing Clearances
- During dialogue, `EncounterManager.gd` smoothly moves the player to $X = X_{\text{npc}} - 2.4$ meters.
- **Clearance Zone**: Never place colliders, tall furniture, or blocking obstacles between $(X_{\text{npc}} - 3.0)$ and $(X_{\text{npc}} + 1.0)$ along the standing axis ($Z \in [-0.5, 0.5]$).

### Rule 5: Keep Front Diorama Plane Clear
- Because the camera is positioned at $Y = 2.2$m, $Z = 4.5$m with a $-15^\circ$ tilt, the front wall of diorama rooms is omitted.
- **Line-of-Sight Rule**: Do not place furniture or props exceeding $Y = 0.8$m height at $Z > 2.0$m.

---

## 3. Asset Selection & Room Density Rules

### Rule 6: Prioritize Reusable Assets Over Unique Meshes
- Use existing assets from `client/assets/` or modular kits from `/dump/`.
- Prefer material color tinting and scaling variations over creating unique mesh files for identical prop categories.

### Rule 7: Avoid Over-Decoration
- Rooms must remain readable at a glance from the fixed diorama camera view.
- Maintain clear visual contrast between the floor/character area and background walls.
- Limit decorative Tier 3 clutter items to $\le 10$ props per room.

---

## 4. Handling Missing Assets & Fallbacks

### Rule 8: Use Procedural Fallbacks When Assets Are Missing
- If a specific 3D mesh model is missing, build clean low-poly primitives using `CharacterFactory.gd` style helper methods (`_box()`, `_cylinder()`, `_sphere()`) with warm `StandardMaterial3D` colors.
- Never leave broken model references or missing node paths in scenes.
