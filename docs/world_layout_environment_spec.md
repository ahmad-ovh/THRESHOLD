# THRESHOLD — World Layout & Environment Specification
*Indie Social Simulation — Stylized Production Pipeline*

**Document Version**: 3.0.0
**Author**: GameDesigner
**Architecture**: `RoomTemplate.tscn` — 16m W × 10m D × 5m H diorama box
**Camera**: Fixed at `Vector3(0, 3.2, 7.5)`, pitch `-14°`
**Art Direction**: Stylized low-poly. Tomodachi Life readability. Animal Crossing warmth. Miitopia expressiveness.

---

## 0. Design Philosophy

> A player should understand every room in 3 seconds.
> Not "what building is this?" — but "who lives here and what do they want from me?"

This is not a realistic world. It's a social diorama — a small stage where conversations happen. Every object exists to answer one of three questions:

1. **What gameplay happens here?** (NPC interaction, door transition)
2. **Who belongs here?** (character identity through object ownership)
3. **What does the arrangement say about them?** (personality through composition)

If an object doesn't answer at least one of these, it doesn't exist.

### What We're Building

| Metric | Count |
|---|---|
| Buildings | 4 |
| Interior rooms | 10 |
| Outdoor spaces | 2 (street + bench zone) |
| Street encounter zones | 1 |
| Total playable spaces | **13** |
| Total NPCs | **16** |
| Base 3D meshes | **22** |
| Furniture Families | **5** |

### How Rooms Feel Different With Shared Assets

| Method | Cost | Impact |
|---|---|---|
| **NPC presence & position** | Free | Highest — a room IS its occupant |
| **Object arrangement** | Free | High — same 4 objects in new positions = new room |
| **Lighting color** | Free | High — warm amber vs cool white changes everything |
| **Material/color swap** | Near-free | High — cream chair vs grey chair vs blue chair |
| **Prop density** | Free | Medium — cluttered vs sparse = personality |
| **Wall/floor color** | Near-free | Medium — wood vs tile vs carpet |
| **Scale variation** | Free | Low-medium — 0.6× table becomes a side table |

---

## 1. Furniture Families

Every room in the game is dressed from **5 Furniture Families** and a small **Props Library**. A Family is one base mesh with color, material, and scale variants.

### CHAIR Family — 1 mesh, 4 variants

**Base Mesh**: Simple stylized chair. Slightly rounded edges, readable silhouette at camera distance. Think Animal Crossing café chair — not realistic, just clearly "a chair."

| Variant | Method | Used In |
|---|---|---|
| **Classroom grey** | Grey material | Okoro's Classroom, Conference Room |
| **Café blue** | Blue fabric material | Café |
| **Office dark** | Dark fabric material | Office Lobby, Executive Suite guest |
| **Home warm** | Warm brown wood material | Living Room (dining area if needed) |

**Production tag**: `1 mesh · 4 materials · appears in 7 rooms · gameplay-required (NPC seating)`

**Special seating** (3 additional meshes for identity-critical needs):

| Mesh | Why It Can't Be the Chair | Used In |
|---|---|---|
| **Couch** | Reads as "home, family, comfort" — no chair substitute works | Living Room |
| **Bench** | Reads as "waiting, public, outdoor" — a chair in a hallway reads wrong | Campus Hallway, Street, Café window booth |
| **Plastic patio chair** | Reads as "outside, cheap, temporary" — defines the Balcony | Balcony |

**Total Seating meshes: 4** (chair + couch + bench + patio chair)

---

### TABLE Family — 1 mesh, 5 variants

**Base Mesh**: Simple stylized table. Flat top, four legs. The most versatile object in the game — a desk, a café table, a side table, a coffee table. Scale and material do all the work.

| Variant | Scale | Material | Reads As | Used In |
|---|---|---|---|---|
| **Desk** | 1.0× | Dark wood | Professor's desk, office desk | Adler, Okoro, Reception, Executive Suite |
| **Café table** | 0.7× round | Light wood | Small social table | Café (×2) |
| **Coffee table** | 0.5× low | Wood or glass-top | Living room centerpiece | Living Room, Lobby waiting area |
| **Side table** | 0.4× | Light wood | Personal surface | Balcony, beside couch |
| **Conference** | 1.4× long | Dark wood | Meeting table | Conference Room |

**Production tag**: `1 mesh · 5 scale+material combos · appears in 10 rooms · gameplay-required (defines room type)`

---

### STORAGE Family — 1 mesh, 4 variants

**Base Mesh**: Upright shelf unit. Boxy, 3-4 shelves, stylized. Contents are what differentiate it — not the shelf itself.

| Variant | Material | Contents (flat textures or tiny prop instances) | Reads As | Used In |
|---|---|---|---|---|
| **Bookshelf** | Dark wood | Book spines (texture strip) | Academic, old, serious | Adler's Office, Executive Suite |
| **Textbook shelf** | Light wood | Colorful book spines, handout stacks | Classroom, accessible | Okoro's Classroom |
| **Home shelf** | Warm wood | Photo frames, a few books, small plant | Personal, family | Living Room |
| **Café shelf** | White/metal | Mugs, jars, small plant | Service, casual | Café (behind counter) |

**Production tag**: `1 mesh · 4 materials · contents differentiated by prop placement on shelves · appears in 6 rooms`

**Additional storage** (1 extra mesh):

| Mesh | Why | Used In |
|---|---|---|
| **Counter** | Horizontal surface that reads as "service point" or "kitchen" — a shelf turned sideways doesn't work | Café, Living Room kitchen |

**Total Storage meshes: 2** (shelf + counter)

---

### LIGHT Family — 1 mesh, 2 variants

**Base Mesh**: Simple lamp. Cone shade on a stand. As a desk lamp, it sits on a table. As a floor lamp, the stand is taller (scale Y).

| Variant | Scale | Used In |
|---|---|---|
| **Desk lamp** | 1.0× | Adler's Office, Executive Suite |
| **Floor lamp** | 1.8× Y-scale | Living Room, Office Lobby |

All other lighting variation comes from `OmniLight3D` and `SpotLight3D` color/energy values. Pendant lamps (Café) are the shade mesh hung from ceiling — same model, flipped and repositioned.

**Production tag**: `1 mesh · 2 scale variants + 1 ceiling reposition · appears in 5 rooms · critical for room mood`

**Total Light meshes: 1**

---

### WALL FEATURE Family — 2 meshes

These are flat or near-flat objects mounted on walls. They define room type at a glance.

| Mesh | Reads As | Variant Method | Used In |
|---|---|---|---|
| **Board** (flat rectangle, wall-mounted) | Whiteboard (white material), Notice board (cork material), Menu board (dark material with chalk texture) | Material swap | Okoro's Classroom, Conference Room, Campus Hallway, Café |
| **Frame** (small rectangle, wall-mounted or desk-standing) | Family photo, diploma, award, notice | Texture swap on face | Living Room, Executive Suite, Campus Hallway |

**Production tag**: `2 meshes · material/texture swaps · appear in 7 rooms combined`

**Total Wall Feature meshes: 2**

---

### PROPS Library — 9 meshes

Small objects that populate surfaces. These are the storytelling atoms — cheap to model, critical for identity.

| ID | Mesh | Reuse Count | Variation Method | Gameplay Role |
|---|---|---|---|---|
| `P1` | **Mug** | 9 rooms | Color swap (white ceramic, brown, branded) | Universal human prop. Every character has one. |
| `P2` | **Paper stack / folder** | 6 rooms | Thickness variation (scale Y). Thin = folder, thick = stack | Visual "work" indicator. Defines busy vs clean. |
| `P3` | **Plant pot** | 5 rooms | Texture on plant part: green (healthy), yellow (wilting), tiny (succulent) | Who cares for their space? Healthy = cared for. Wilting = neglected. |
| `P4` | **Book** (single, lying flat or standing) | 4 rooms | Color swap on cover | Shelf filler, desk dressing. Instanced in rows for bookshelves. |
| `P5` | **Bag / backpack** | 3 rooms | Material swap (canvas, fabric) | "Someone was here" — left on a chair, on the floor. |
| `P6` | **Phone** (mobile, small rectangle) | 3 rooms | — | Character prop: in hand, face-down on table, charging. |
| `P7` | **Pen holder / cup** (small cylinder with sticks) | 4 rooms | Material swap | Desk dressing. Markers in classroom, pens in office. |
| `P8` | **Pitcher + glass** (2-piece set) | 2 rooms | — | Meeting hospitality. "This is a formal space." |
| `P9` | **Newspaper / magazine** (flat rectangle with print texture) | 3 rooms | Texture swap | On coffee tables, on benches. "Someone reads here." |

**Total Props meshes: 9**

---

### OUTDOOR / ARCHITECTURAL — 4 meshes

| Mesh | Used In | Notes |
|---|---|---|
| **Streetlamp** | Street (×4) | Marks building entrances. Defines nighttime mood. |
| **Tree** (billboard or simple sphere-on-stick) | Street (×5) | Breaks up facades. Can be a single billboard quad with leaf texture. |
| **Door frame** (arch with door slab) | Every room transition | Structural. Invisible when working correctly. |
| **Railing** (metal bars, horizontal) | Balcony only | Defines "outdoor elevated space." The sibling leans on it. |

**Total Architectural meshes: 4**

---

### GRAND TOTAL: 22 Base Meshes

| Family | Meshes |
|---|---|
| Chair (chair + couch + bench + patio chair) | 4 |
| Table | 1 |
| Storage (shelf + counter) | 2 |
| Light | 1 |
| Wall Features (board + frame) | 2 |
| Props | 9 |
| Outdoor / Architectural | 4 |
| **TOTAL** | **22** |

> **22 meshes dress 13 playable spaces with 16 NPCs.**
> Every additional "unique" feeling comes from materials, lighting, arrangement, and the characters themselves.

---

## 2. Room Specifications

Every room uses a 3-tier kit:

- 🎮 **Gameplay Kit** — Minimum objects for the room to function. If you only ship this, the room is playable.
- 🧬 **Personality Kit** — Objects that communicate who lives/works here. Ships in standard scope.
- ✨ **Polish Kit** — Added last, only if time allows. The room works without these.

---

### 2.1 Main Street (`StreetConnector.tscn`)

**3-Second Read**: "A neighborhood sidewalk with four doors. I walk between places."

**Purpose**: Outdoor traversal spine. The player walks left/right on a sidewalk. Building entrances are the only interaction points.
**Camera**: Horizontal tracking, `lerp(5.0 * delta)`, clamped to street ends.

**Layout**:
```
  [Street Start]                                             [Street End]
   ▼                                                             ▼
   ┌───────┬──────────┬────────┬──────────┬─────────┬──────────┐
   │ Bench │ CAMPUS   │ CAFÉ   │  Stranger │  APT    │  OFFICE  │
   │ +Lamp │ Door     │ Door   │  Bench   │  Door   │  Door    │
   └───────┴──────────┴────────┴──────────┴─────────┴──────────┘
        ══════════════ SIDEWALK (player walks) ═══════════════
        ─────────────── ROAD (background art) ────────────────
```

**Building Facades**: Not 3D buildings. Each facade is a **flat colored wall** with a highlighted door zone. The player reads color, not architecture.

| Building | Wall Color | How Player Identifies It |
|---|---|---|
| Campus | Slate grey `#3d4a5c` | "The grey building — school" |
| Café | Sky blue `#4a90d9` | "The blue building — café" |
| Apartment | Warm cream `#e8dcc8` | "The warm building — home" |
| Office | Dark navy `#1a2744` | "The dark building — work" |

🎮 **Gameplay Kit**: 4 door colliders (one per building entrance). Sidewalk walkable surface. End walls.
🧬 **Personality Kit**: Streetlamp ×4 (one per door), Bench ×2 (outdoor), Tree ×5 (billboard).
✨ **Polish Kit**: Mailbox decals on building walls, trash can near Café door, fence texture along Apartment frontage.

**NPC**: Recurring Stranger sits on the bench between Café and Apartment. The bench is empty until they appear at specific progression thresholds.

---

### 2.2 Campus Hallway (`Room_Campus_Hallway.tscn`)

**3-Second Read**: "A hallway with two doors and a bench. Someone's waiting."

**Purpose**: Pass-through connecting street to faculty offices. Low-stakes hallway encounter with Mr. Vance.
**NPC**: Mr. Vance — standing near the back wall, between classes, not expecting you.

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Board: cork]              [Plant]       │
 │                                           │
 │     [Bench]              [MR. VANCE]      │
 │                          (standing)        │
 │                                           │
 │  [Door → Adler]       [Door → Okoro]     │
 │  (Left Wall)          (Right Wall)        │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Why |
|---|---|---|
| Door frame ×3 | Architectural | Two faculty doors + street exit. The room IS its doors. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Bench ×1 | Seating (bench) | Students wait here. Reads as "waiting area" instantly. |
| Board ×1 | Wall Feature (cork material) | Exam schedules, office hours. Reads as "school." |
| Plant ×1 | Props (succulent) | Institutional greenery. Someone waters it on Mondays. |

✨ **Polish Kit**: Pen holder on a small wall shelf near the board. Water cooler (would need unique mesh — skip unless trivial).

**Lighting**: Cool fluorescent `Color(0.85, 0.9, 1.0)`. Slightly harsh overhead. Nobody lingers here by choice.

**What Makes It Unique**: The only room that's a *pass-through*. No anchor furniture (no desk, no table). Just doors, a bench, and a person who happens to be here. The emptiness IS the identity.

---

### 2.3 Prof. Adler's Office (`Room_Adler_Office.tscn`)

**3-Second Read**: "A dark, warm, cluttered office. The person behind the desk has been here forever."

**Purpose**: Private one-on-one academic conversations. Grades, feedback, references.
**NPC**: Prof. Adler — seated behind the desk. He doesn't get up.

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Shelf: books]    [ADLER]    [Shelf]     │
 │                    (seated)                │
 │           [Table: dark desk]              │
 │           [lamp, mug, papers]             │
 │                                           │
 │       [Chair]         [Chair]             │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Table ×1 | Table (desk, 1.0×) | Dark wood | Adler's desk. He sits behind it. The room's anchor. |
| Chair ×2 | Chair | Dark fabric | Guest chairs. Player sits across from authority. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Shelf ×2 | Storage (bookshelf, dark wood) | Full of book spines (texture). Top shelf untouched for years. Academic decades. |
| Lamp ×1 | Light (desk variant) | Overhead fluorescents OFF. Adler prefers the lamp. Warm single-source makes this room moodier than the hallway. |
| Mug ×1 | Props | Half-full, cold. He's been here since morning. |
| Paper stack ×2 | Props | On desk + on table edge. Visual proof he's busy. |
| Pen holder ×1 | Props | On desk. Functional clutter. |

✨ **Polish Kit**: Frame on wall behind desk (diploma texture). Second small table as side surface for extra papers.

**Lighting**: Overhead OFF. Single warm `OmniLight3D` from desk lamp — `Color(1.0, 0.92, 0.78)`. Room feels like late afternoon even at midday.

**What Makes It Unique**: **Density.** Highest prop count of any room. Same shelf as the Living Room, same table as the Reception — but *everything* here is dark wood, and surfaces are buried in papers. The clutter says "decades of academic accumulation" without a single unique mesh.

---

### 2.4 Ms. Okoro's Classroom (`Room_Okoro_Classroom.tscn`)

**3-Second Read**: "A small bright classroom. Desks are slightly messy. Someone just taught here."

**Purpose**: Seminar room for teaching and informal office hours. Warmer and more open than Adler's study.
**NPC**: Ms. Okoro — standing near the board, or leaning on her desk. She's active, not seated.

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Board: white]                           │
 │                                           │
 │  [OKORO]         [Table: teacher desk]    │
 │  (standing)      [papers, pen holder]     │
 │                                           │
 │  [Table] [Table] [Table]                  │
 │  [Chair] [Chair] [Chair]                  │
 │  [book]          [bag on chair]           │
 │                                           │
 │  [Shelf: textbooks]                       │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Table ×4 | Table (desk) | 1× teacher (light wood), 3× student (0.8× white laminate) | Teacher desk + 3 student desks. Defines "classroom." |
| Chair ×3 | Chair | Grey | Student seating. Slightly rotated off-grid (5-10° each) to show students moved them. |
| Board ×1 | Wall Feature | White material, half-erased prompt texture | Defines "teaching space." |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Shelf ×1 | Storage (textbook, light wood) | Colorful book spines. Handouts available. Okoro keeps resources accessible. |
| Book ×1 | Props | On one student desk. Someone left their notebook. The room is mid-use. |
| Bag ×1 | Props | On one student chair. Another person's things. |
| Pen holder ×1 | Props | On Okoro's desk. Whiteboard markers. |

✨ **Polish Kit**: Plant on shelf. Coat hooks (use Frame mesh mounted horizontally as hook strip).

**Lighting**: Mixed — faux window light from `DirectionalLight3D` angled from right wall (the "window" is a bright rectangle texture, not a modeled opening) + warm overhead `Color(0.95, 0.9, 0.82)`. Approachable.

**What Makes It Unique**: **Disarray.** Student desks rotated off-grid. A notebook left behind. A bag on a chair. The room communicates "real people were just here" through arrangement chaos — same desks and chairs as every other room, but *rotated and scattered*.

---

### 2.5 The Café (`Room_Cafe.tscn`)

**3-Second Read**: "A cozy café. Counter at the back, tables in the middle, someone alone by the window."

**Purpose**: Social hub. Highest NPC density. Neutral ground — nobody owns this space, everyone shares it.
**NPCs**:
- **Barista** — behind the counter (working, doesn't leave)
- **Daria** — window booth bench (her regular spot, she likes the corner)
- **Felix** — center table (social, visible, easy to approach)
- **Priya** — standing near counter (just arrived, hasn't committed to staying)

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Counter]  [Board: menu]  [Shelf: mugs] │
 │  [BARISTA]                                │
 │                                           │
 │  [Table]         [Table]     [PRIYA]      │
 │  [Chair×2]       [Chair×2]   (standing,   │
 │  [FELIX]         [empty]      phone)      │
 │                                           │
 │  [Bench + Table = Window Booth]           │
 │  [DARIA seated, looking out]              │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Counter ×1 | Storage (counter) | Light wood top | Defines "café." The barista stands behind it. |
| Table ×3 | Table | 0.7× round, light wood (×2 center + ×1 booth) | Café tables. Small, round, social. |
| Chair ×4 | Chair | Blue fabric | Café chairs. Blue tint = only place with blue chairs. |
| Bench ×1 | Seating (bench) | Natural wood | Window booth seat. Same mesh as Hallway — here it's a booth. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Board ×1 | Wall Feature (dark material, chalk texture) | Menu board behind counter. Handwritten daily specials. "This is a local spot." |
| Shelf ×1 | Storage (café, white) | Behind counter. Mugs and jars on display. |
| Mug ×3 | Props | On tables, behind counter. Café's signature prop. |
| Plant ×1 | Props (healthy) | On the shelf. The barista waters it. |
| Phone ×1 | Props | In Priya's hand. She's between sips. |

✨ **Polish Kit**: Bag on floor near Felix's chair. Coat hook near entrance (Frame mesh on wall).

**Lighting**: Warm amber `Color(1.0, 0.88, 0.7)` from Lamp mesh hung as ceiling pendant ×2 over tables. Bright rectangle texture on one wall = "window." **Warmest room in the game.**

**What Makes It Unique**: **Social geometry.** Four NPCs, each in a position that communicates personality — Daria in the corner (introverted), Felix in the center (extroverted), Priya standing (uncommitted), Barista behind the counter (functional). The café is defined by *where people sit*, not by its furniture.

---

### 2.6 Apartment Living Room (`Room_Apartment_Living.tscn`)

**3-Second Read**: "A warm, lived-in family room. Couch, TV, kitchen counter. Someone's parent lives here."

**Purpose**: Family conversations. "What's the plan?" is asked here. "You seem off" is noticed here. Shared domestic space — everyone uses it, no one owns it.
**NPC**: Parent — seated on the couch, in the dent.

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Counter: kitchen]  [Shelf: family]      │
 │  [mugs, plant]       [photos, books]      │
 │                                           │
 │  [PARENT on Couch]               [TV]     │
 │                                           │
 │  [Table: coffee table]                    │
 │  [newspaper, mug]                         │
 │                                           │
 │  [Chair: warm]    [Frame×3: family photos]│
 │                   (on wall)               │
 │                                           │
 │  [Door → Balcony]      [● Player]        │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Couch ×1 | Seating (couch) | Warm faded fabric | The family couch. Only room with this mesh. Cushion dent baked into texture. |
| Table ×1 | Table (coffee table, 0.5× low) | Wood | Living room centerpiece. Remote, newspaper, glasses. |
| Door frame ×1 | Architectural | Standard | To the Balcony. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Counter ×1 | Storage (counter) | Kitchen counter. Same mesh as Café — but here it has a kettle texture decal, mugs, and a plant instead of an espresso machine. |
| Shelf ×1 | Storage (home, warm wood) | Family photos, a few books, small plant. Personal history on display. |
| Chair ×1 | Chair (warm brown) | Armchair by the TV. Same mesh as classroom chair — warm material = home. |
| Lamp ×1 | Light (floor, 1.8× Y) | Standing beside the couch. Evening glow. |
| Frame ×3 | Wall Feature | Family photos: younger player, a holiday, a graduation. Texture swaps on one mesh. |
| Mug ×1 | Props | Parent's tea. On the coffee table. |
| Newspaper ×1 | Props | Yesterday's. Someone reads here. |
| Plant ×1 | Props (healthy) | On the kitchen counter. The parent tends it. |

✨ **Polish Kit**: Wall clock (flat disc decal, not a mesh). Shoe silhouettes decal near the door. Fridge magnet texture on a colored wall rectangle near the counter.

**Lighting**: Warm domestic `Color(1.0, 0.93, 0.82)` from floor lamp + faux kitchen light (overhead `OmniLight3D`). Evening golden hour. **This room feels like coming home.**

**What Makes It Unique**: **Personal history.** The family photos (3 frames with different textures), the worn couch (unique mesh but the only unique-to-one-room seating), the newspaper, the mug. Every shared prop tells a specific family story. The room is cluttered because it's *lived in*, not because it's messy.

**Unique mesh note**: The Couch is the one seating mesh that only appears here. It earns its slot because "home" doesn't read without a couch — no chair or bench substitution works.

---

### 2.7 Apartment Balcony (`Room_Apartment_Balcony.tscn`)

**3-Second Read**: "A tiny balcony at night. Two cheap chairs, a dying plant, and someone looking out."

**Purpose**: Private sibling conversations. You come here when you don't want the parent to hear. Small, cold, honest.
**NPC**: Sibling — leaning on the railing, looking out.

**Layout**:
```
 BACK WALL (apartment exterior)
 ┌───────────────────────────────────────────┐
 │  [Door: glass, back to Living Room]       │
 │                                           │
 │  [SIBLING leaning on Railing]             │
 │                                           │
 │  ═══════ [Railing] ═══════════════        │
 │                                           │
 │  [Patio Chair]      [Patio Chair]         │
 │  [bag/hoodie]       [empty]               │
 │                                           │
 │  [Table: side table]                      │
 │  [phone, mug]                             │
 │                                           │
 │  [Plant: wilting]                          │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT (sky beyond railing)
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Railing ×1 | Architectural | Metal | Defines "outdoor elevated space." The sibling leans on it. Can't be faked. |
| Patio Chair ×2 | Seating (patio chair) | White plastic | Cheap outdoor chairs. Domestic, temporary. |
| Door frame ×1 | Architectural | Glass door variant (texture swap on door slab) | Back to Living Room. Slightly open — TV sound bleeds through. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Table ×1 | Table (side table, 0.4×) | Between the chairs. Same café table mesh, tiny. |
| Bag ×1 | Props | Draped on one chair. Sibling's hoodie. Same mesh, fabric texture. |
| Phone ×1 | Props | Face-down on the table. They came out here to *not* look at it. |
| Mug ×1 | Props | Brought from inside, cooling. |
| Plant ×1 | Props (wilting) | Someone put it here months ago. Nobody waters it. It's barely alive. |

✨ **Polish Kit**: None. **The emptiness is the point.** Don't add polish objects. Sparseness is this room's identity.

**Lighting**: Cool evening exterior `Color(0.7, 0.75, 0.9)` ambient. Warm light spills from the glass door (`OmniLight3D` from Living Room side, `Color(1.0, 0.93, 0.82)`). **The contrast between inside warmth and outside cold IS the emotion.**

**What Makes It Unique**: **The sparsest room in the game.** 7 objects. The sky is visible beyond the railing — the only room where you can see "outside." No shelves, no papers, no evidence of work. Just two chairs and whatever you're willing to say out loud. The wilting plant says everything about how much attention this space gets.

---

### 2.8 Office Lobby (`Room_Office_Lobby.tscn`)

**3-Second Read**: "A clean, cold professional lobby. Three people, each doing something different."

**Purpose**: Transitional workspace. Casual colleague encounters. Three NPCs sharing a common area with completely different body language.
**NPCs**:
- **Nadia** — standing near back wall (passing through, efficient, always in motion)
- **Tomás** — leaning on the reception desk (socializing, likes being seen)
- **Seren** — seated in waiting area (reviewing notes, preparing)

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Table: reception desk]  [Frame: company │
 │  [pen holder, plant]       name on wall]  │
 │  [TOMÁS leaning]                          │
 │                                           │
 │                        [NADIA standing]   │
 │                                           │
 │  [Chair×2]  [Table: coffee table]         │
 │  [SEREN]    [magazine, mug]               │
 │  (seated)                                 │
 │                                           │
 │  [Door → Conference]  [Door → Suite]      │
 │  (Left Wall)          (Right Wall)        │
 │                        [● Player]         │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Table ×1 | Table (desk, 1.0×) | White laminate | Reception desk. Same mesh as Adler's — white instead of dark. |
| Chair ×2 | Chair | Dark fabric | Waiting area. Same mesh, corporate color. |
| Table ×1 | Table (coffee table, 0.5×) | Glass-top | Waiting area table. Same as Living Room — glass tint, not wood. |
| Door frame ×2 | Architectural | Standard | Conference (left), Suite (right). |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Frame ×1 | Wall Feature | Company name — text texture on the Frame mesh, mounted on wall with a backlit glow (small `OmniLight3D` behind it). |
| Lamp ×1 | Light (floor, 1.8× Y) | Near waiting area. Same as Living Room lamp. |
| Plant ×1 | Props (succulent) | On reception desk. Someone in the office waters it. |
| Pen holder ×1 | Props | On reception desk. Functional. |
| Newspaper ×1 | Props (magazine texture) | On coffee table. Trade magazines. |
| Mug ×1 | Props | On coffee table. Someone's. |

✨ **Polish Kit**: Elevator door texture (flat colored rectangle on back wall — signals multi-floor building at zero mesh cost).

**Lighting**: Bright, cold white `Color(0.95, 0.95, 1.0)` from wide `SpotLight3D` overhead. **The coldest artificial light in the game. This is not a place for comfort.**

**What Makes It Unique**: **Three NPCs with three different postures in one room.** Tomás is *leaning* (relaxed, owning the space). Nadia is *standing* (passing through, efficient). Seren is *seated and reading* (prepared, deliberate). Same chairs, same desk — completely different people. The room's identity is its social choreography.

---

### 2.9 Conference Room (`Room_Office_Conference.tscn`)

**3-Second Read**: "A meeting room with too many empty chairs. Two people, a long table, and tension."

**Purpose**: Workplace confrontations. Credit disputes, scope alignment, overcommitment.
**NPC**: One of Tomás, Nadia, or Seren (rotates per scenario — one colleague per encounter)

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  [Board: white — project timeline]        │
 │                                           │
 │  [Table: conference, 1.4×]               │
 │  [Chair ×6 — grey]                        │
 │  [NPC at far end]                         │
 │  [paper, mug, pen holder]                 │
 │                                           │
 │  [Shelf: pitcher + glasses]               │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Table ×1 | Table (conference, 1.4× long) | Dark wood | The meeting table. Seats 6 but only 2 people are here. Empty chairs = isolation. |
| Chair ×6 | Chair | Grey | Same classroom chairs. 4 are empty. The emptiness matters. |
| Board ×1 | Wall Feature | White material, timeline sketch texture | A project is at stake. Checked and unchecked boxes. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Paper stack ×1 | Props | NPC's meeting notes. Work in progress. |
| Mug ×1 | Props | Someone brought coffee. |
| Pitcher + glass ×1 | Props | On a shelf at the side. Meeting room hospitality. One glass used. |
| Shelf ×1 | Storage (café/white) | Holds the water set. Same shelf as Café — white, neutral. |
| Pen holder ×1 | Props | On the table. |

✨ **Polish Kit**: "Frosted glass" wall texture on one wall plane (implies glass partition — no mesh needed). Flat screen texture on wall (frozen presentation slide).

**Lighting**: Neutral fluorescent `Color(0.9, 0.92, 0.95)`. "Glass wall" lets lobby light bleed via secondary `OmniLight3D`. **The room feels exposed — you can be seen.**

**What Makes It Unique**: **Scale and emptiness.** The 1.4× conference table is the largest single object in the game. Six chairs around it, but only 2 occupied. The empty chairs communicate "you are one person in a structure bigger than you." Same chairs as classroom and café — but the scale of the table changes everything.

---

### 2.10 Executive Suite (`Room_Office_Suite.tscn`)

**3-Second Read**: "A powerful, quiet office. Clean desk, big window, someone waiting for you."

**Purpose**: High-stakes client meetings. Bad news delivery, scope defense, trust testing.
**NPC**: Ms. Hartwell, Mr. Osei, or Ms. Vidal (one at a time, seated behind the desk)

**Layout**:
```
 BACK WALL
 ┌───────────────────────────────────────────┐
 │  ["Window" — panorama texture + light]    │
 │                                           │
 │  [Table: desk, dark wood — CLEAN]         │
 │  [single paper, pen holder]               │
 │  [CLIENT NPC seated]                      │
 │                                           │
 │  [Chair ×2 — dark, guest]                 │
 │                                           │
 │  [Shelf: business books, frame×2]         │
 │                                           │
 │  [Table: side table + pitcher/glasses]    │
 │                                           │
 │            [● Player]                     │
 └───────────────────────────────────────────┘
 OPEN FRONT
```

🎮 **Gameplay Kit**:
| Asset | Family | Variant | Why |
|---|---|---|---|
| Table ×1 | Table (desk, 1.0×) | Dark wood | Same mesh as Adler's desk — but **deliberately clean**. One folder. One pen holder. Power through absence. |
| Chair ×2 | Chair | Dark fabric | Guest chairs. You're a guest in someone else's space. |

🧬 **Personality Kit**:
| Asset | Family | Why |
|---|---|---|
| Shelf ×1 | Storage (bookshelf, dark wood) | Business books (texture), Frame as award plaque, Frame as diploma. Career on display. |
| Lamp ×1 | Light (desk) | Warm supplementary light. Same lamp as Adler's. |
| Frame ×2 | Wall Feature | Award plaque + diploma. Same mesh, different face textures. |
| Paper stack ×1 | Props | Single thin folder. The one about *you*. |
| Pen holder ×1 | Props | Expensive-looking. Same mesh, dark material. |
| Pitcher + glass ×1 | Props | On side table. Hospitality, but structured. |
| Table ×1 | Table (side table, 0.4×) | Holds the water set. |

✨ **Polish Kit**: Nameplate decal on desk surface. Plant (healthy) on the shelf.

**Lighting**: Warm golden from "window" wall — `DirectionalLight3D` at low angle, `Color(1.0, 0.95, 0.85)`. Plus `OmniLight3D` desk lamp at `Color(1.0, 0.9, 0.75)`. **The most visually impressive room in the game.**

**What Makes It Unique**: **The opposite of Adler's office.** Same desk mesh, same shelf mesh, same lamp mesh — but Adler's room is CLUTTERED (papers everywhere, full shelves, overflowing). This room is EMPTY (one folder, clean desk, minimal objects). Density = academic chaos. Emptiness = executive control. **Same 22 meshes. Opposite identities. This is the entire production philosophy in one comparison.**

---

## 3. Room Interconnection Map

```
STREET ──[Door]──► CAMPUS HALLWAY ──[Left]──► ADLER'S OFFICE
                                   ──[Right]──► OKORO'S CLASSROOM

STREET ──[Door]──► CAFÉ (single room, no internal doors)

STREET ──[Door]──► LIVING ROOM ──[Glass Door]──► BALCONY

STREET ──[Door]──► OFFICE LOBBY ──[Left]──► CONFERENCE ROOM
                                  ──[Right]──► EXECUTIVE SUITE
```

**Transition**: Every door triggers `0.3s` fade-to-black → `SpawnMarker3D` in target room. Exit via same door. Max 2 internal doors per room.

---

## 4. NPC Placement — Identity Through Position

No custom environments. No unique character furniture. Identity comes from **where they sit** and **what's on their surface**.

| NPC | Room | Position | What It Says About Them |
|---|---|---|---|
| **Prof. Adler** | Office | Behind desk, seated | He doesn't get up. You come to him. Authority. |
| **Ms. Okoro** | Classroom | Standing near board | She teaches by moving. Active, engaged. |
| **Mr. Vance** | Hallway | Standing, untethered | He's between places. Doesn't belong to a room. Transient. |
| **Daria** | Café | Window booth corner | She chose the quietest spot. Observational, introverted. |
| **Felix** | Café | Center table | He chose the most visible spot. Social, open. |
| **Priya** | Café | Standing near counter | She just got here. Hasn't committed to staying. Decisive but new. |
| **Barista** | Café | Behind counter | Functional role. They serve, they watch. |
| **Parent** | Living Room | On couch, in the dent | Their spot. They've been sitting here for years. Comfort, routine. |
| **Sibling** | Balcony | Leaning on railing | Looking away from the apartment. Needs distance. |
| **Nadia** | Lobby | Standing, back wall | In transit. Efficient. Doesn't sit when she can stand. |
| **Tomás** | Lobby | Leaning on desk | Performing relaxation. He wants to be seen being casual. |
| **Seren** | Lobby | Seated, reading | She prepares. Measured, deliberate. |
| **Ms. Hartwell** | Suite | Behind desk, seated | Clean desk. She's already decided before you walked in. |
| **Mr. Osei** | Suite | Behind desk, seated | Same desk, warmer posture. He leans forward. He wants to connect. |
| **Ms. Vidal** | Suite | Behind desk, seated | Same desk, slightly anxious. She has questions she keeps circling back to. |
| **Recurring Stranger** | Street bench | Seated, watching | They chose a bench nobody else uses. They've been paying attention. |

---

## 5. Asset Reuse Matrix

Every mesh and how many rooms it appears in:

| Mesh | Rooms | Differentiation |
|---|---|---|
| Chair (base) | **7** | Material: grey / blue / dark / warm |
| Table (base) | **10** | Scale + material: 0.4× side table to 1.4× conference |
| Shelf (base) | **6** | Contents: books / textbooks / photos / mugs / business books |
| Counter | **2** | What's on top: espresso area vs kettle + mugs |
| Lamp | **5** | Scale: desk (1×) / floor (1.8×) / pendant (flipped, ceiling) |
| Board | **4** | Material: white / cork / dark chalk |
| Frame | **4** | Texture: photo / diploma / award / notice |
| Bench | **3** | Context: hallway (waiting) / street (public) / café (booth) |
| Mug | **9** | Color: white / brown / branded. Universal. |
| Paper stack | **6** | Scale Y: thin folder vs thick stack |
| Plant pot | **5** | Plant texture: green / yellow / tiny succulent |
| Door frame | **7** | Door slab texture: wood / glass / metal |

---

## 6. Production Pipeline

### Phase 1 — Playable (ship-blocking)
*Every room functions. NPCs can be spoken to. Doors work.*

| Priority | Meshes | Count |
|---|---|---|
| 1st | Chair, Table, Door frame | 3 |
| 2nd | Bench, Counter, Couch | 3 |
| 3rd | Streetlamp, Tree | 2 |
| | **Phase 1 total** | **8 meshes** |

> At 8 meshes: every room has seating, surfaces, and transitions. All 16 NPCs are reachable. The game is *playable*.

### Phase 2 — Identity (rooms feel distinct)
*Each room reads differently. NPC spaces have personality.*

| Priority | Meshes | Count |
|---|---|---|
| 4th | Shelf, Lamp, Board | 3 |
| 5th | Frame, Patio Chair, Railing | 3 |
| | **Phase 2 total** | **14 meshes cumulative** |

> At 14 meshes: each room has its defining feature. Adler's shelves. Okoro's whiteboard. The café's counter. The balcony's railing. Players can recognize every room from a screenshot.

### Phase 3 — Story (rooms feel alive)
*Props tell character stories. Spaces feel inhabited.*

| Priority | Meshes | Count |
|---|---|---|
| 6th | Mug, Paper stack, Plant pot, Book | 4 |
| 7th | Bag, Phone, Pen holder, Newspaper | 4 |
| 8th | Pitcher + glass set (1 mesh) | 1 |
| | **Phase 3 total** | **22 meshes cumulative (FINAL)** |

> At 22 meshes: every room tells a story. Adler's cold mug. The sibling's face-down phone. The wilting balcony plant nobody waters. The game is *alive*.

---

## 7. Atmospheric Summary

| Room | Feeling | Light | Key Read |
|---|---|---|---|
| **Street** | Open, breezy | Cool evening blue | "A neighborhood. Four colored doors." |
| **Hallway** | Institutional, passing-through | Cool fluorescent | "Wait here or go through a door." |
| **Adler's Office** | Focused, slightly intimidating | Warm desk lamp only | "Someone important who's been here forever." |
| **Okoro's Classroom** | Approachable, mid-use | Warm natural + overhead | "Class just ended. Come in." |
| **Café** | Cozy, social | Warm amber pendants | "Your friends are here." |
| **Living Room** | Domestic, nostalgic | Warm golden evening | "Home. Your parent's waiting." |
| **Balcony** | Exposed, honest | Cool blue + warm door spill | "Private. Cold. Honest." |
| **Lobby** | Professional, cold | Bright neutral white | "Work. Everyone's busy." |
| **Conference** | Tense, exposed | Neutral fluorescent | "Too many empty chairs." |
| **Executive Suite** | Powerful, quiet | Warm golden window + lamp | "They're waiting for you." |

---

## 8. Summary

> **22 meshes. 13 spaces. 16 NPCs. 10 material variants. 3 lighting moods.**

The world doesn't feel big because of polygon count. It feels big because every room has a different person in it, a different light on the walls, and a different reason you're there.

A café table and a professor's desk are the same mesh. What makes them different is that Felix is leaning back with a grin across the table from you, and Prof. Adler is staring at you over a stack of papers he hasn't looked up from.

**The asset is the person. The room is the arrangement. The world is the conversation.**
