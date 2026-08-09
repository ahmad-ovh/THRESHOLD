# THRESHOLD — Official Prologue Storyboard

> **Document Status**: Authoritative Narrative & Visual Specification  
> **Target Experience**: Prologue Storybook Sequence (Game Start)  
> **Source of Truth Alignment**: `docs/PITCH_SOURCE_OF_TRUTH.md`, `content/npc_templates.yaml`, `docs/WORLD_SPECIFICATION.md`  
> **Technical Destination**: `scenes/ui/StoryboardLoading.tscn` & `scenes/rooms/Street.tscn`  

---

## 1. Narrative Purpose & Overview

The THRESHOLD prologue is an illustrated storybook sequence that plays immediately when a player begins a new game. 

It is **not** a tutorial, a backend explanation, or a standard loading screen. It is an atmospheric narrative prologue designed to establish the emotional identity of THRESHOLD before the player ever takes control of their character.

### Primary Emotional Goals
1. **Intimate Curiosity**: Make the player think *"I want to know these people"* rather than *"I have to complete tasks."*
2. **Living World**: Establish that the neighborhood and its residents exist independently of the player—they have histories, doubts, routines, and unspoken burdens.
3. **Thematic Grounding**: Give deep, human resonance to the word **THRESHOLD**.
4. **Natural Handoff**: Transition seamlessly from illustrated narrative panels into the 3D diorama street hub (`Street.tscn`).

---

## 2. Core Thematic Foundation: The Dual Threshold

In THRESHOLD, the title operates on two interconnected levels:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            THE DUAL THRESHOLD                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  LITERAL THRESHOLD                                                          │
│  Stepping off the arrival train onto the damp brick sidewalk of Main Street.│
│  Crossing from the outside world into the stylized 3D diorama neighborhood. │
│                                                                             │
│  EMOTIONAL THRESHOLD                                                        │
│  The fragile boundary between:                                             │
│  • Stranger ───────► Acquaintance ───────► Trusted Friend                  │
│  • Silence ────────► Speech                                                 │
│  • Hesitation ─────► Connection                                             │
│  • Who you were ───► Who you become                                         │
└─────────────────────────────────────────────────────────────────────────────┘
```

The prologue introduces the protagonist as an observer standing outside these invisible boundaries, gradually building the desire to step across them.

---

## 3. Character & Visual Continuity Guide

### 3.1 Protagonist Specification
* **Silhouette**: Traveler in a dark charcoal wool coat, textured amber scarf, carrying a worn leather notebook journal under one arm.
* **Appearance Adaptability**: Stylized low-poly proportions matching `CharacterFactory.gd`. The dark coat and amber scarf establish a recognizable visual anchor across all panels, accommodating avatar customization (skin tone, hair style) without breaking visual continuity.

### 3.2 Key Neighborhood Characters
* **Daria**: Wears an emerald-green jacket over a cream knit sweater. Dark hair tied back loosely. Sits at the corner booth of the Downtown Café, thoughtful and observant.
* **Prof. Adler**: Senior academic in a tweed vest and round wire spectacles. Works under the warm amber glow of a desk lamp in his study surrounded by stacked volumes.
* **Ms. Okoro**: Educator in a warm mustard-yellow cardigan. Carries herself with steady composure in the campus hallway.
* **Tomás**: Ambitious young professional in a structured dark navy blazer, standing in the office lobby.

### 3.3 Visual Identity & Art Direction
* **Style**: Paper-craft 2.5D diorama aesthetics, combining crisp paper edges, warm tungsten lamplight, and soft overcast twilight reflections.
* **Palette**: Muted navy blues and charcoal dusk tones contrasted with warm amber lantern glow, aged parchment cream, and subtle emerald accents.

---

## 4. The Complete Storyboard Sequence

---

### PANEL 1 — Arrival at Dusk

#### Narrative Text
> Every city has a rhythm. Most people learn to walk to it without thinking.

#### Visual
An overhead wide shot of a quiet neighborhood train platform at dusk. Wet asphalt reflects the indigo twilight sky. Steam rises from under stationary passenger train cars. In the foreground, a single traveler carrying a leather notebook stands near a lit station sign reading *THRESHOLD*. In the distance, warm streetlights flicker to life along a curved hillside street.

#### Composition / Camera
* **Angle**: High-angle wide shot (2.5D diorama tilt, $-20^\circ$ pitch).
* **Framing**: Protagonist placed at the lower-left third grid line, facing toward the lit street on the right.
* **Depth**: Deep focal plane with soft atmospheric fog separating the foreground platform from the distant cityscape.
* **Lighting**: Cool indigo sky ($80\%$) punctuated by warm $2700\text{K}$ point lights from station lanterns ($20\%$).

#### Characters
* **Protagonist**: Standing still, suitcase in left hand, dark wool coat blowing slightly in the evening breeze.

#### Story Purpose
Establishes the protagonist as a newly arrived outsider entering a world that was already moving before they got here.

#### Image Generation Direction
> Low-poly paper-craft 3D diorama scene of a train station platform at dusk, wet pavement reflections, cool indigo ambient lighting with warm tungsten lamp posts, single traveler silhouette with amber scarf in lower left, stylized paper-cut buildings in background, cinematic depth of field, 16:9 ratio.

#### Transition
Slow horizontal camera pan to the right, following the direction of the street lamps toward the neighborhood sidewalk.

---

### PANEL 2 — The Street Hub

#### Narrative Text
> You arrive as a stranger, carrying only what fits in your hands and what you haven't figured out how to say yet.

#### Visual
The protagonist walks along the main neighborhood sidewalk of THRESHOLD (`Street.tscn`). Detailed storefront facades line the street—the Downtown Café on the left, leafy planters, dark wood benches, and glowing streetlamps casting soft pools of yellow light on the brick pavement.

#### Composition / Camera
* **Angle**: Classic 2.5D side-scrolling perspective ($Y = 2.2\text{m}$, pitch $-15^\circ$).
* **Framing**: Medium-wide shot. Protagonist in center-left, walking right.
* **Focal Point**: The warm lit window of the Downtown Café in the background right.
* **Depth**: Foreground street curb and bench; midground protagonist; background storefront facades at $Z = -2.0\text{m}$.

#### Characters
* **Protagonist**: Walking right, eyes lowered slightly, clutching the leather journal.
* **Mr. Vance** (Background): A distant figure in a dark trench coat standing near the campus entryway, checking his watch.

#### Story Purpose
Anchors the player directly into the main gameplay corridor (`Street.tscn`), establishing spatial familiarity with the world they will soon explore.

#### Image Generation Direction
> 2.5D dollhouse diorama view of a European-style neighborhood street at dusk, storefronts with glowing windows, paper-craft trees and benches along brick sidewalk, traveler figure walking through pools of lamplight, warm cozy atmosphere, tilt-shift camera focus.

#### Transition
Match-cut zoom into the warm, illuminated window pane of the Downtown Café.

---

### PANEL 3 — The Glass Window (Daria)

#### Narrative Text
> Behind every window, someone is carrying a story they rarely tell out loud.

#### Visual
Looking through the steam-fogged glass window of the Downtown Café (`Room_Cafe.tscn`). Inside, Daria sits alone at a wooden booth, holding a ceramic mug with both hands. Her reflection overlays slightly on the glass. Outside, rain droplets cling to the window pane. She looks out thoughtfully into the evening street, unaware of being watched.

#### Composition / Camera
* **Angle**: Eye-level close-medium shot through a window frame.
* **Framing**: Daria framed slightly right of center; window frame edges visible on left and top.
* **Focal Point**: Daria's face and her quiet, contemplative expression.
* **Depth**: Foreground raindrops on glass; midground Daria at booth; background café counter with espresso machine out of focus.

#### Characters
* **Daria**: Wearing an emerald green jacket, dark hair tied loosely, expression quiet and guarded yet receptive.

#### Story Purpose
Demonstrates that NPCs in THRESHOLD are not static quest markers—they have internal emotional lives and silent doubts.

#### Image Generation Direction
> Cozy café window interior shot viewed from outside, young woman with dark hair in green jacket holding coffee cup in a wooden booth, warm interior light, rain droplets and soft condensation on glass window pane, atmospheric paper-cut diorama art style, intimate emotional mood.

#### Transition
Dissolve tilt to the adjacent campus building window.

---

### PANEL 4 — The Advisor's Desk (Prof. Adler)

#### Narrative Text
> Some build walls out of expectations. Others build them out of silence.

#### Visual
Inside Professor Adler's study (`Room_AdlerOffice.tscn`). Floor-to-ceiling bookshelves lined with leather-bound volumes frame a heavy oak desk. Professor Adler sits under the sharp glow of a brass desk lamp, red pen in hand, marking a stack of student essays. A half-empty porcelain teacup rests beside a globe. His posture is rigid, but his brows are furrowed with careful concern.

#### Composition / Camera
* **Angle**: Slightly high-angle interior view ($Y = 2.0\text{m}$, pitch $-12^\circ$).
* **Framing**: Medium shot centered on Professor Adler behind his desk.
* **Focal Point**: The pool of brass lamplight illuminating the open papers on the desk.
* **Depth**: Foreground armchairs; midground desk and Adler; background book-lined walls.

#### Characters
* **Prof. Adler**: Senior professor, wire-rimmed glasses resting low on his nose, dark vest over white shirt.

#### Story Purpose
Introduces academic authority figures who demand rigor, hinting that gaining respect requires clarity rather than excuses.

#### Image Generation Direction
> Warmly lit professor study diorama, floor-to-ceiling bookshelves, elderly professor with glasses at heavy wooden desk reading papers under brass lamp, quiet academic atmosphere, paper-craft textures, rich wood tones and warm light.

#### Transition
Horizontal slide along the building facade to the campus hallway window.

---

### PANEL 5 — The Shared Corridor (Ms. Okoro)

#### Narrative Text
> Most distance isn't made of space. It's made of hesitation.

#### Visual
Inside the campus hallway (`Room_CampusHallway.tscn`). Ms. Okoro stands near a classroom doorway holding a clip-board and a folder of course schedules. Sunlight filters through high arch windows, casting long geometric shadows across the polished floor. She pauses, looking down the hallway as if waiting for a student who hasn't arrived.

#### Composition / Camera
* **Angle**: Wide interior diorama corridor view.
* **Framing**: One-point perspective leading down the hallway. Ms. Okoro standing near the left wall.
* **Focal Point**: Ms. Okoro's poised, attentive silhouette against the bright window light.
* **Depth**: Foreground classroom door frame; midground Ms. Okoro; background hallway archway.

#### Characters
* **Ms. Okoro**: Wearing a mustard-yellow cardigan, expression patient yet demanding.

#### Story Purpose
Reveals that opportunities for connection are often missed simply because neither person takes the initiative to speak.

#### Image Generation Direction
> Paper-craft diorama of a sunlit school hallway, female teacher in yellow cardigan standing near classroom door with clipboard, long afternoon shadows across floor, clean architectural lines, quiet expectant atmosphere.

#### Transition
Reverse camera angle pulling back outside onto the sidewalk.

---

### PANEL 6 — The First Glance

#### Narrative Text
> Then a moment occurs—unplanned, small, easily missed—where two paths touch.

#### Visual
On the sidewalk outside the café. The protagonist has paused near the entrance. Inside the window, Daria turns her head and notices the protagonist standing outside. Their eyes meet through the glass for a brief fraction of a second. Steam rises from the café door vent.

#### Composition / Camera
* **Angle**: Over-the-shoulder shot from behind the protagonist looking toward the café window.
* **Framing**: Protagonist's shoulder and amber scarf in foreground left ($30\%$ screen space); Daria's face visible through window ($70\%$ screen space).
* **Focal Point**: Eye contact between Daria and the protagonist across the glass boundary.
* **Depth**: High contrast depth between dark foreground protagonist and warm lit interior Daria.

#### Characters
* **Protagonist**: Back turned to camera, subtle tilt of the head.
* **Daria**: Looking directly toward the camera/protagonist through the window glass, slight surprise in her eyes.

#### Story Purpose
The dramatic shift from passive observation to active recognition. The player feels seen by the world.

#### Image Generation Direction
> Over the shoulder view of traveler in dark coat looking through café window, young woman inside café looking up and making direct eye contact through the glass, warm golden glow from inside contrast with cool blue evening outside, paper-craft diorama style, high emotional tension.

#### Transition
Slow push-in toward the café door handle.

---

### PANEL 7 — The Unspoken Question

#### Narrative Text
> A single word can shift a posture. A thoughtful answer can earn a friend.

#### Visual
Close-up of the protagonist's hand reaching toward the brass door handle of the café. The surface of the brass reflects the streetlamps behind them. In the soft-focus background, the café interior waits—warm, inviting, filled with low murmur and the aroma of roasted coffee.

#### Composition / Camera
* **Angle**: Close-up detail shot ($45^\circ$ angle).
* **Framing**: Hand and brass handle in sharp focus in lower right; warm blurred café interior in upper left.
* **Focal Point**: The hand hovering inches from the door handle—the moment of decision.
* **Depth**: Shallow depth of field ($f/1.8$ equivalent).

#### Characters
* **Protagonist**: Hand visible in dark coat sleeve, reaching forward.

#### Story Purpose
Captures the exact physical and psychological threshold before initiating dialogue.

#### Image Generation Direction
> Close up paper-craft artwork of a hand in a coat sleeve reaching for a polished brass door handle of a café, warm golden light spilling through glass door, shallow depth of field, tactile paper textures, suspenseful threshold moment.

#### Transition
Visual dissolve into a montage of overlapping social moments.

---

### PANEL 8 — The Invisible Web

#### Narrative Text
> Nobody lives here in isolation. Every conversation leaves a trace, weaving connections you cannot see until you look closer.

#### Visual
A stylized paper-craft graphic overlay of the neighborhood. Stylized thread-like lines of warm light extend between key figures across different locations—connecting Daria at the café to Tomás at the office lobby, and Prof. Adler to Ms. Okoro in the campus hall. Floating icon cards reveal small remembered details: a teacup, a paper draft, a shared nod.

#### Composition / Camera
* **Angle**: Top-down stylized diorama map view ($Y = 10\text{m}$, pitch $-60^\circ$).
* **Framing**: Full neighborhood layout spanning café, street, campus, and office.
* **Focal Point**: Luminous connections branching outwards from the protagonist's position on the street.
* **Depth**: Flat graphical layer overlaid on 3D environment geometry.

#### Characters
* **Daria**, **Tomás**, **Prof. Adler**, **Ms. Okoro** visible in their respective diorama locations.

#### Story Purpose
Foreshadows THRESHOLD's relational intelligence engine, social memory graph, and cross-NPC relationship networks (`JournalUI.tscn`).

#### Image Generation Direction
> Stylized 3D paper diorama map of a neighborhood at night, glowing golden threads of light connecting different character figures in buildings, floating paper cards with icon sketches, network graph aesthetic, magical realism, warm and intricate.

#### Transition
Camera drops down from map view back into a close personal perspective.

---

### PANEL 9 — The Open Journal

#### Narrative Text
> What you notice matters. What you remember changes everything.

#### Visual
Close-up of the protagonist holding their open leather notebook journal. On the cream parchment page, hand-written notes and quick pencil sketches of the neighborhood appear—a sketch of Daria at the booth, a note reading *"Clarity • Empathy • Politeness"*, and a small map marker pointing to Main Street.

#### Composition / Camera
* **Angle**: First-person perspective looking down at hands holding the journal.
* **Framing**: Open notebook fills $70\%$ of screen frame.
* **Focal Point**: The hand-written text and pencil sketches on the paper page.
* **Depth**: Background shows blurred street pavement illuminated by warm lamp light.

#### Characters
* **Protagonist**: Hands holding the notebook edges.

#### Story Purpose
Introduces the Notebook Journal (`JournalUI.tscn`) as the player's personal record of discovered facts, emotional insights, and social growth.

#### Image Generation Direction
> First person view holding an open vintage leather journal with creamy paper pages, hand-drawn pencil sketches of people and handwritten notes on pages, warm lamplight from above, detailed paper texture, cozy tactile feeling.

#### Transition
Page-turn flip transition, dissolving back to the full street view.

---

### PANEL 10 — The Weight of Choice

#### Narrative Text
> You cannot force someone to trust you. But you can choose how you listen.

#### Visual
Night has settled over Main Street. The streetlamps cast long, gentle shadows across the sidewalk. The protagonist stands in the center of the walkway, looking up at the glowing signs of the neighborhood. Floating above the buildings are subtle, warm 3D emoji icons—a gentle heart, a listening ear, a quiet light—symbolizing the emotional dimensions of speech.

#### Composition / Camera
* **Angle**: Low-angle medium shot looking up at protagonist and street architecture.
* **Framing**: Protagonist centered, looking slightly upward into the night sky.
* **Focal Point**: The glowing warmth of the street signs and floating mood motifs.
* **Depth**: Foreground street lamp pole; midground protagonist; background detailed building roofs against starry dusk sky.

#### Characters
* **Protagonist**: Standing upright, scarf slightly rustling, expression resolute and open.

#### Story Purpose
Communicates the game's core philosophy: communication is about active listening, empathy, and authentic presence, not winning an argument.

#### Image Generation Direction
> Low angle shot of traveler standing on a cozy illuminated street at night, looking up at paper-craft store signs, glowing warm floating emoji icons softly hovering above, starry indigo sky, whimsical yet grounded emotional atmosphere, paper diorama style.

#### Transition
Camera pans down smoothly to eye-level behind the protagonist's shoulder.

---

### PANEL 11 — Standing at the Edge

#### Narrative Text
> Every encounter is a threshold. You stand on this side of the door.

#### Visual
Eye-level shot directly behind the protagonist. Ahead lies the open sidewalk of Main Street (`Street.tscn`). In the distance, Daria is walking out of the café onto the porch, looking up at the evening sky. Mr. Vance walks along the upper walkway. The entire 3D diorama street is alive with warm light, subtle movement, and quiet possibility.

#### Composition / Camera
* **Angle**: Eye-level third-person perspective ($Y = 1.7\text{m}$, matching in-game exploration camera).
* **Framing**: Protagonist's back in lower center frame. The open sidewalk stretches straight ahead.
* **Focal Point**: The open pathway leading toward Daria and the storefronts.
* **Depth**: Exact match to `Street.tscn` camera parameters ($Z = 4.5\text{m}$, pitch $-15^\circ$).

#### Characters
* **Protagonist**: Positioned at $X = 0.0, Y = 0.0, Z = 0.0$ origin.
* **Daria**: Standing on café porch in mid-distance right.
* **Mr. Vance**: Walking along upper sidewalk left.

#### Story Purpose
Prepares the player for the immediate transition into gameplay by matching the exact camera alignment of the starting scene.

#### Image Generation Direction
> Third person view behind traveler standing on a stylized 3D diorama street, sidewalk leading forward toward warm café porch where a young woman stands, cozy evening atmosphere, clean game camera composition, inviting and open.

#### Transition
Seamless dissolve—the illustrated storyboard texture dissolves outward from the center, revealing the real-time 3D rendered `Street.tscn` engine node underneath.

---

### PANEL 12 — Step Across

#### Narrative Text
> Step across.

#### Visual
The final panel frame fades its text. The static artwork transforms seamlessly into the live 3D Godot game scene (`Street.tscn`). The player's avatar stands on the brick sidewalk. The HUD overlay (`HUD.tscn`) softly fades in, displaying the player profile badge, daily challenge indicator, and interaction hint `[Press E to Talk]`. The player now has full movement control.

#### Composition / Camera
* **Angle**: Exact Godot 4 3D diorama camera ($Y = 2.2\text{m}$, $Z = 4.5\text{m}$, pitch $-15^\circ$).
* **Framing**: Active gameplay viewport.
* **Focal Point**: Player character ready for movement input.
* **Depth**: Live 3D environment rendering with real-time lighting and LookIK head tracking enabled.

#### Characters
* **Player Avatar**: Fully active, idle animation playing smoothly, head tracking mouse movement.
* **Daria**: Live NPC instance at café porch ($X = 6.0\text{m}$).

#### Story Purpose
Completes the journey from spectator to active participant. The story is no longer being told to the player—they are now writing it.

#### Image Generation Direction
> In-game UI screenshot transition of 3D diorama street RPG, player avatar standing on sidewalk, minimal elegant HUD elements fading in, high visual polish, vibrant warm lighting, seamless transition from narrative prologue into gameplay.

#### Transition
No further transition—this frame **is** the active game.

---

## 5. Final Seamless Transition Specification

To ensure zero visual pop or immersion break when handing off control to the player:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                    PROLOGUE TO GAMEPLAY HANDOFF FLOW                        │
├─────────────────────────────────────────────────────────────────────────────┤
│ 1. PANEL 11 (Storybook) ─► Panel text finishes typewriter animation.        │
│ 2. PANEL 12 (Dissolve)  ─► Storyboard canvas layer opacity tweens 1.0 ➔ 0.0. │
│ 3. 3D ENGINE SCENE      ─► Street.tscn is already preloaded in background.  │
│ 4. CAMERA SYNC          ─► Camera position & FOV match Panel 11 exactly.    │
│ 5. HUD FADE-IN          ─► HUD.tscn elements (Profile, Daily) fade in.     │
│ 6. INPUT UNLOCK         ─► Player control unlocked at X=0.0, Y=0.0, Z=0.0.   │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **Preload Guarantee**: `res://scenes/rooms/Street.tscn` is 100% preloaded during the storyboard sequence via `SceneManager.preload_scene()`.
2. **Camera Matching**: Panel 11 and Panel 12 use identical spatial framing ($Y = 2.2\text{m}, Z = 4.5\text{m}, \text{pitch} = -15^\circ$) matching `Street.tscn`'s `Camera3D` node.
3. **Dissolve Timing**: On Panel 12, `StoryboardLoading.gd` executes a 0.6s cubic fade out (`Tween.EASE_IN_OUT`).
4. **Input Activation**: `GameController.set_phase(Phase.EXPLORING)` is called as the overlay clears, enabling player movement, LookIK mouse tracking, and `[E]` interaction triggers.

---

## 6. Summary Matrix of Storyboard Panels

| Panel # | Title | Key Character(s) | Primary Setting | Narrative Purpose | Transition Method |
|---|---|---|---|---|---|
| **1** | Arrival at Dusk | Protagonist | Train Station Platform | Establish outsider arrival & world identity | Horizontal Pan |
| **2** | The Street Hub | Protagonist, Mr. Vance | Main Street Sidewalk | Connect player to `Street.tscn` hub | Match-cut Zoom |
| **3** | The Glass Window | Daria | Downtown Café Window | Show internal life of NPCs | Dissolve Tilt |
| **4** | The Advisor's Desk | Prof. Adler | Prof. Adler's Study | Introduce academic expectations & rigor | Slide Pan |
| **5** | The Shared Corridor | Ms. Okoro | Campus Hallway | Highlight spatial & emotional hesitation | Camera Pull-back |
| **6** | The First Glance | Protagonist, Daria | Café Entrance Window | First mutual recognition between characters | Push-in Zoom |
| **7** | The Unspoken Question | Protagonist (Hand) | Café Door Handle | Physical & psychological threshold moment | Graphic Dissolve |
| **8** | The Invisible Web | All NPCs | Neighborhood Overview Map | Foreshadow relational graph & social memory | Downward Drop |
| **9** | The Open Journal | Protagonist | Notebook Journal | Introduce Journal UI & discovery records | Page-turn Flip |
| **10** | The Weight of Choice | Protagonist | Main Street Sidewalk | Communicate philosophy of active listening | Eye-level Pan |
| **11** | Standing at the Edge | Protagonist, Daria | Main Street Sidewalk | Match exact camera framing of gameplay | Canvas Dissolve |
| **12** | Step Across | Player Avatar, Daria | Active `Street.tscn` Scene | Hand off full 3D control to player | Seamless Gameplay |
