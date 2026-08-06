# Game Visual Source of Truth

---

## 1. Visual Identity Summary

**THRESHOLD** is a cozy, playful, and emotionally meaningful 2.5D social simulation game that blends the warm community atmosphere of *Animal Crossing* with the quirky, personality-driven interactions of *Tomodachi Life*. 

The game world is presented through modular 3D diorama boxes framed within a fixed-viewport dollhouse aesthetic. Characters are styled with expressive chibi proportions (1:2.5 to 1:3 head-to-body ratio), rounded soft geometry, handcrafted matte materials, and a warm pastel color palette. The overall visual experience feels like stepping into a living, tactile miniature world where small moments, unexpected encounters, and evolving relationships take center stage.

---

## 2. Non-Negotiable Visual Principles

Every asset created for THRESHOLD must strictly adhere to the following rules:

1. **Chibi Silhouette Supremacy**: All characters must use the 1:2.5 to 1:3 chibi head-to-body proportion with rounded forms. Sharp spikes, hyper-realistic human proportions, or realistic muscular definition are strictly forbidden.
2. **Handcrafted Matte Finish**: All surface materials must feature high roughness (`0.8 – 0.9`) with zero metallic gloss (`0.0`). Surfaces must look like painted wooden miniatures or soft matte vinyl toys.
3. **No Neon / Garish Colors**: All colors must come from the warm pastel & curated palette. Pure `#FF0000` reds, `#00FF00` greens, `#0000FF` blues, and harsh neon hues are strictly prohibited.
4. **Diorama Frame Compatibility**: All room environments must fit the standardized 16m (W) × 10m (D) × 5m (H) three-walled box template and look complete under the fixed `-14°` downward camera framing.
5. **Modular Accessory Independence**: Accessories (hats, glasses, scarves, aprons, backpacks) must exist as independent, interchangeable attachment nodes that can be attached to any character's joint pivots without rigid role lock-in.

---

## 3. Shape Language Rules

### Character Shapes
- **Head**: Smooth rounded sphere/oval forms with gentle jaw curves.
- **Limbs**: Soft cylindrical arms and legs ending in rounded hands and simple shoe bases.
- **Torso**: Soft tapered box forms without sharp anatomical angles.

### Environment & Furniture Shapes
- Rounded corners on all furniture (desks, couches, tables, counters, chairs).
- Beveled edges (`0.05m – 0.1m` radius) on all structural walls, doorframes, and trim.
- Chunky, solid proportions that feel sturdy and tactile.

### Forbidden Shapes
- ❌ Sharp needle-thin spikes or jagged points.
- ❌ Hyper-detailed anatomical muscles, ribs, or finger joints.
- ❌ Ultra-thin wire structures that break at gameplay camera distance.

---

## 4. Character Style Guide

### Body Proportions
| Parameter | Value |
|---|---|
| **Head-to-Body Ratio** | `1:2.5` to `1:3` |
| **Total Character Height** | `1.8 meters` (Collision capsule height `1.8m`, radius `0.4m`) |
| **Eye Scale** | Large, expressive oval/sphere eyes mounted on front face plate |
| **Hands / Feet** | Simplified rounded mitts (no individual finger joints) and smooth shoes |

### Head & Face Styling
- **Eyes**: Stylized dark oval spheres mounted at `Z = +0.195` to sit flush on the head surface.
- **Eyebrows**: Simple pill-shaped brow bars positioned above eyes for mood expressions.
- **Hair**: Low-poly solid hairpieces (swoop, bob, bun, curly, ponytail, combed, straight) with soft silhouette contours.

### Animation Profile
- **Walk Stride**: Bouncy, energetic leg swing (`±28°`) with arm counter-swing (`∓22°`) and vertical stride bob (`+0.035m`).
- **Idle State**: Soft breathing (`1.5 – 2.8 Hz`) with gentle head sway (`±2° – ±3.5°`).

---

## 5. Accessory Style Guide

### Modular Attachment Pipeline
Accessories are modular 3D attachments produced by `AccessoryFactory` and mounted on bone/pivot slots (`HeadPivot`, `BodyPivot`, `LeftArmPivot`, `RightArmPivot`).

### Attachment Slots & Offset Rules
| Accessory Category | Attachment Slot | Scale / Offset | Examples |
|---|---|---|---|
| **Eyewear** | `HeadPivot` | Position `(0.0, 0.14, 0.16)` | `glasses_wire`, `glasses_tortoiseshell`, `glasses_modern` |
| **Headwear** | `HeadPivot` | Position `(0.0, 0.18–0.20, 0.0)` | `barista_cap`, `beanie`, `fedora` |
| **Neckwear** | `BodyPivot` / `Chest` | Position `(0.0, 0.22, 0.0)` | `scarf_knit`, `tie_burgundy`, `tie_navy` |
| **Workwear** | `BodyPivot` | Position `(0.0, -0.05, 0.0)` | `apron`, `vest`, `belt` |
| **Backpacks / Gear** | `BodyPivot` (Back) | Position `(0.0, 0.0, -0.23)` | `backpack_student` |

### Accessory Design Rules
- All accessories must support **dynamic color modulation** (`tint_color`).
- Accessories must maintain a clean Z-depth offset (`> 0.015m`) relative to body surfaces to eliminate Z-fighting.
- Accessories are pure aesthetic customization — they can be combined freely on any NPC or player model.

---

## 6. Color Palette Rules

### Primary Palette (Environment & Base Clothing)
- **Cream / Warm Ivory**: `#fffdf2` (Diorama walls, interior floors)
- **Warm Ochre / Gold**: `#e6a135` (Wood furniture, knitted sweaters)
- **Warm Sage Green**: `#6b9075` (Plants, outdoor accents, trim)

### Secondary Palette (Outfits & Highlights)
- **Terracotta Red**: `#c84b31` (Scarves, backpacks, accent cushions)
- **Warm Teal / Cyan**: `#29b6f6` / `#1e7a8c` (Jackets, denim, accent trim)
- **Soft Navy Blue**: `#22304a` (Trousers, suit coats, dark accents)
- **Burgundy**: `#8b263e` (Ties, cardigans, upholstery)

### Forbidden Usage
- ❌ Zero `#000000` pitch blacks (use deep charcoal `#181a1f`).
- ❌ Zero `#FFFFFF` pure unshaded whites (use warm cream `#fffdf2`).
- ❌ Zero neon or fluorescent hues.

---

## 7. Material Rules

| Property | Value | Rationale |
|---|---|---|
| **Material Class** | `StandardMaterial3D` | Native Godot 4 PBR shader |
| **Albedo Color** | Curated warm HSL palette | Consistent color harmony |
| **Roughness** | `0.80 – 0.90` | Non-reflective, painted wooden/vinyl texture |
| **Metallic** | `0.00` | Eliminates harsh specular glints |
| **Texture Filter** | Linear / Nearest | Clean low-poly albedo rendering |

---

## 8. Environment & Diorama Rules

### Room Box Architecture
- **Dimensions**: `16.0m (Width) × 10.0m (Depth) × 5.0m (Height)`.
- **Construction**: 3 walls (Back Wall, Left Wall, Right Wall, Floor, no front wall).
- **Camera Frame**: Stationed at `Vector3(0.0, 3.2, 7.5)` with `-14.0°` pitch pointing directly into the room.

### Furniture & Props
- Created via `FurnitureFactory` or matching low-poly scene templates.
- Uniform beveling on all edges to catch warm ambient light.
- Scale matched to 1:2.5 chibi character dimensions.

---

## 9. Lighting Rules

| Parameter | Setting | Effect |
|---|---|---|
| **Directional Sun** | Color `#fff4e0`, Energy `1.2` | Warm golden-hour daylight |
| **Sun Rotation** | Pitch `-35°`, Yaw `25°` | Soft directional depth across diorama box |
| **Ambient Light** | Color `#f4ebd0`, Energy `0.6` | Gentle warm beige fill into shadows |
| **Shadow Quality** | Soft Shadows (`PCF5`), Bias `0.02` | Eliminates hard jagged shadow edges |

---

## 10. Asset Creation Checklist

Before any new 3D model, character, room prop, or accessory is merged into THRESHOLD, it must pass this 5-point checklist:

- [ ] **1. Silhouette Check**: Does it use chibi proportions (1:2.5 to 1:3 ratio) with rounded, approachable forms?
- [ ] **2. Material Check**: Is roughness set to `0.8–0.9` and metallic set to `0.0`?
- [ ] **3. Color Palette Check**: Does it use warm pastel colors from the curated palette, avoiding neon or unshaded blacks/whites?
- [ ] **4. Modular Offset Check**: Does it attach cleanly to target pivot slots without Z-fighting or clipping?
- [ ] **5. Viewport Camera Check**: Does it look distinct, readable, and appealing under the fixed `-14°` diorama camera framing?
