# THRESHOLD — Physical World Specification

> **System Status**: `IMPLEMENTED` (Street corridor hub active; interior diorama rooms structured as Godot scenes)  
> **Authoritative Location Grounding**: Mapped directly to `perception_service.py` (`LOCATION_MAP`) and `client/scenes/rooms/`.

---

## 1. Overview & World Layout Architecture

The physical 3D world of THRESHOLD is structured around a **side-scrolling neighborhood street hub corridor** (`Street.tscn`) connecting modular **3D interior diorama rooms** (`Room_*.tscn`).

```text
                       [ Main Street Hub Corridor ] (Street.tscn)
                                    │
    ┌─────────────────┬─────────────┼───────────────┬──────────────────┐
    ▼                 ▼             ▼               ▼                  ▼
Downtown Café   Prof. Adler   Campus Hall   Office Building   Apartment Building
(Room_Cafe)    (AdlerOffice) (OkoroClass)  (OfficeLobby/Suite) (ApartmentLiving/Balcony)
```

### Camera & Spatial Constraints
- **Perspective**: 2.5D fixed-pitch dollhouse diorama perspective.
- **Camera Anchor**: Positioned at Y = 2.2m, Z = 4.5m, pitch = -15° relative to room/player origin.
- **Corridor Bounds**: Street hub spans $X \in [-38.0, 38.0]$ meters.
- **Scale Standard**: 1 Godot unit = 1.0 meter. Character height = ~1.7 meters.

---

## 2. Location & Room Breakdown

Each location maps directly to specific NPCs and scenario categories.

### 2.1 Main Street Hub Corridor (`Street.tscn`)
- **Purpose**: Central exploration hub connecting all neighborhood venues.
- **NPCs Present**: `recurring_stranger` (bench), `mr_vance` (walkway near campus entrance).
- **Gameplay Interactions**: Walking movement (left/right along X-axis), approaching storefront doorways, initiating conversation with outdoor NPCs.
- **Required Geometry**: 76-meter sidewalk/road surface, storefront facades along back wall (Z = -2.0m), street curb, background skyline silhouette.
- **Required Furniture & Props**: Street benches, streetlight poles, trash receptacles, planters with small shrubs, outdoor café tables.
- **Entry/Exit Points**: Spawn point at $X = 0.0, Y = 0.0, Z = 0.0$. Transition doors leading to interior scenes.

### 2.2 Downtown Café (`Room_Cafe.tscn`)
- **Purpose**: Casual everyday social interactions, coffee shop encounters, and friend catch-ups.
- **NPCs Mapped**: `barista` (behind counter), `daria` (window booth), `felix` (center table), `priya` (café seating).
- **Gameplay Interactions**: Ordering at counter, sitting at tables, initiating encounters.
- **Required Geometry**: 8m × 6m diorama shell, wooden floor, back wall with large window frame (showing street backdrop).
- **Required Furniture**: Service counter bar, espresso machine unit, pastry display case, 2-person dining tables, window booth seating, wooden chairs.
- **Required Props**: Coffee mugs, cash register/POS terminal, menu chalkboard, pendant ceiling lamps, small potted plants.

### 2.3 Prof. Adler's Study (`Room_AdlerOffice.tscn`)
- **Purpose**: Academic advisor meetings, paper feedback, and formal student-faculty discussions.
- **NPCs Mapped**: `prof_adler`.
- **Gameplay Interactions**: Approaching advisor desk, sitting in guest armchair.
- **Required Geometry**: 6m × 5m diorama shell, dark wood flooring, wainscot paneled back wall.
- **Required Furniture**: Heavy wooden executive desk, professor swivel chair, 2 visitor armchairs, floor-to-ceiling bookshelf units.
- **Required Props**: Stacked books, desk lamp (warm light emission), framed academic diplomas, coffee cup, globe.

### 2.4 Campus Seminar Room & Hallway (`Room_OkoroClassroom.tscn` / `Room_CampusHallway.tscn`)
- **Purpose**: Educational scenarios, extension requests, grade disputes, and campus staff interactions.
- **NPCs Mapped**: `ms_okoro`, `mr_vance`.
- **Gameplay Interactions**: Approaching teacher podium, classroom navigation.
- **Required Geometry**: 10m × 7m diorama shell, linoleum tile floor, institutional wall trim.
- **Required Furniture**: Teacher desk/podium, student desk & chair combos (arranged in rows), storage cabinets.
- **Required Props**: Wall chalkboard/whiteboard with written notes, wall clock, bulletin board with notices.

### 2.5 Apartment Living Room & Balcony (`Room_ApartmentLiving.tscn` / `Room_ApartmentBalcony.tscn`)
- **Purpose**: Intimate family conversations, post-graduation discussions, sibling favors, and personal reflection.
- **NPCs Mapped**: `parent`, `sibling`.
- **Gameplay Interactions**: Living room seating, balcony railing conversations.
- **Required Geometry**: 7m × 5m living room shell + attached 4m × 2m balcony exterior.
- **Required Furniture**: Comfortable fabric sofa, low coffee table, TV stand/credenza, balcony railing.
- **Required Props**: Throw pillows, rug, table lamp, potted houseplant, coffee cups, balcony chair.

### 2.6 Office Building Lobby & Executive Suite (`Room_OfficeLobby.tscn` / `Room_OfficeSuite.tscn`)
- **Purpose**: Workplace discussions, colleague collaboration, client negotiations, scope clarifications, and deliverable reviews.
- **NPCs Mapped**: `nadia`, `tomas`, `seren`, `ms_hartwell`, `mr_osei`, `ms_vidal`.
- **Gameplay Interactions**: Reception desk check-in, executive conference table meetings.
- **Required Geometry**: 12m × 8m lobby shell / 8m × 6m executive suite shell, polished marble floor tiles.
- **Required Furniture**: Curved reception desk, leather lounge chairs, glass coffee table, executive glass desk, conference table.
- **Required Props**: Reception computer monitor, corporate logo sign, tall architectural ficus plants, recessed spotlight fixtures.

---

## 3. Element Categorization Framework

To assist future automated world builders operating under time and asset constraints, all physical world elements are strictly categorized into three priority tiers:

```text
[ TIER 1: GAMEPLAY-CRITICAL ] → Required for basic room function & mechanics.
[ TIER 2: IDENTITY-CRITICAL ] → Required for room to visually communicate its purpose.
[ TIER 3: DECORATIVE ] → Presentation polish (can be omitted if assets are unavailable).
```

### 3.1 Tier 1: Gameplay-Critical Elements
- **Player & NPC Spawn Anchors**: `Node3D` markers specifying exact spawn coordinates.
- **Side-by-Side Dialogue Offset Anchors**: X-offset of -2.4 meters relative to target NPC position, ensuring clear framing during encounters.
- **Floor & Boundary Colliders**: Solid `StaticBody3D` floor planes and invisible room boundary walls ($X, Z$ bounds).
- **Interaction Area3D Detectors**: Trigger zones on NPCs with radius $R = 2.0$ meters listening to group `"player"`.

### 3.2 Tier 2: Identity-Critical Elements
- **Café**: Service counter bar + espresso machine + 1 seating table.
- **Professor Study**: Advisor desk + main bookshelf + visitor chair.
- **Classroom**: Teacher podium + chalkboard + 3 student desks.
- **Apartment**: Living room sofa + coffee table + balcony railing.
- **Office Lobby**: Reception counter + lounge seating unit.

### 3.3 Tier 3: Decorative Elements
- Wall framed art pieces, loose papers/books, rugs, decorative ceiling lamps, outdoor street trash cans, window curtain variants, small table clutter.
