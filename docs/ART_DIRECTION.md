# THRESHOLD — Visual Art Direction & Presentation Constraints

> **System Status**: `IMPLEMENTED`  
> **Visual Reference**: 2.5D Stylized Dollhouse Diorama Aesthetic in Godot 4

---

## 1. Aesthetic Vision & Palette

THRESHOLD utilizes a **stylized, warm diorama aesthetic**. The visual presentation prioritizes readable silhouettes, clean color separation, and inviting ambient environments over photorealistic detail.

```text
Warm Terracottas & Cream Tones
        +
Clean Low-Poly Silhouettes
        +
Expressive Character Emojis
        +
Dollhouse Diorama Framing
```

### Color Palette Constraints
- **Primary Environment Tones**: Warm cream (`#F5EDD9`), soft terracotta (`#E67314`), warm dark brown (`#2E261A`), muted sage green (`#7A8B7B`), and deep navy (`#1B263B`).
- **Background Separation**: Background walls and distant geometry must maintain lower saturation and contrast than foreground characters and interaction objects.
- **UI Contrast**: Floating HUD elements, dialogue speech bubbles, and mood emojis use high-contrast cream background containers (`#F5EDD9` with 95% opacity) and dark brown typography (`#2E261A`).

---

## 2. Camera Perspective & Diorama Framing

```text
                             ▲ Camera Y=2.2m, Pitch=-15°
                             │
     ┌───────────────────────┴───────────────────────┐
     │                                               │
     │                 DIORAMA ROOM                  │
     │                                               │
     │    [Player] ◄─── 2.4m Distance ───► [NPC]     │
     │                                               │
     └───────────────────────────────────────────────┘
     Front cutaway plane at Z = 2.5m (Keep clear of tall furniture!)
```

### Constraints for Camera Readability
- **Fixed Projection**: Camera is positioned at $Y = 2.2$m, $Z = 4.5$m with a downward tilt of $-15^\circ$ ($X$-rotation).
- **Dollhouse Cutaway**: The front plane of every room ($Z > 2.5$m) must remain entirely open to the camera.
- **Foreground Clearance**: No props or furniture exceeding $Y = 0.8$m height may be placed between $Z = 2.0$m and $Z = 4.5$m, ensuring character silhouettes are never obscured.

---

## 3. Character Representation & Proportions

Characters in THRESHOLD are rendered using articulated low-poly humanoid rigs assembled dynamically in GDScript via `CharacterFactory.gd`.

### Character Scale & Structure
- **Overall Height**: $\approx 1.7$ meters (1.7 Godot units).
- **Pivot Hierarchy**:
  - `BodyPivot`: Root height at $Y = 0.76$m. Handles breathing bobs and leg swings.
  - `HeadPivot`: Height at $Y = 1.40$m. Handles head tilts and rotation.
  - `LeftArmPivot` / `RightArmPivot`: Positioned at $X = \pm 0.30$m, $Y = 1.05$m.
  - `LeftLegPivot` / `RightLegPivot`: Positioned at $X = \pm 0.15$m, $Y = 0.72$m.

### Mood Emoji Billboard Overlay
- Each NPC features a floating `MoodSprite3D` positioned above the head marker ($Y \approx 2.1$m).
- Emojis pop in dynamically using `TRANS_BACK` / `EASE_OUT` tween scaling upon emotion changes (`neutral`, `warm`, `guarded`, `attentive`, `dismissive`, `encouraging`, `disappointed`, `skeptical`, etc.).

---

## 4. Lighting & Material Style

- **Materials**: All environment and character meshes use `StandardMaterial3D` with flat albedo colors or soft procedural gradients.
- **Roughness & Metallic**: Environment roughness defaults to $0.85$, metallic to $0.0$. Polished floors (e.g. office marble) use roughness $0.35$.
- **Lighting**: Warm ambient fill light ($3500\text{K}$ warmth) paired with a primary directional key light casting soft directional shadows toward the back wall.
- **Performance Budget**: Target $< 50,000$ triangles per diorama room to ensure smooth $60\text{ FPS}$ execution in web browser exports.
