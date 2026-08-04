# Diorama Box Room & Viewport System Architecture
*A Non-Technical Overview & Design Pattern Guide for System Integration*

---

## 1. Executive Summary

This document describes the spatial, visual, and camera architecture used in **THRESHOLD** — a 2.5D social simulation game built in Godot 4. 

The game adopts a **fixed-viewport dollhouse aesthetic** inspired by games like *Tomodachi Life* and *Animal Crossing*. Instead of traditional free-orbit 3D cameras or endless scrolling spaces, the game world is constructed out of modular 3D "diorama boxes" that frame 100% within the player's screen.

---

## 2. Core Visual & Spatial Concepts

### 📦 The 3D Diorama Room Box
- **Structure**: Every interior environment in the game (a classroom, a coffee shop, an office, a living room) is built as a self-contained 3D room box.
- **Three-Walled Construction**: Rooms feature a Back Wall, Left Wall, Right Wall, and Floor, but **no front wall**. The camera looks directly inside the box like a miniature dollhouse set.
- **Fixed Standard Dimensions**: Standard rooms share uniform boundary dimensions (16m wide × 10m deep × 5m high).

### 🎥 Fixed Viewport Camera Framing
- **No Panning in Standard Rooms**: The camera stays fixed at a stationary position and angle pointing into the room box (`Vector3(0, 3.2, 7.5)` with `-14°` pitch).
- **Full-Room Framing**: As the player moves around inside the room box, the camera does **not** follow behind their back. The entire room and all its furniture remain 100% visible on screen at all times.
- **Large Corridor Exception**: For unusually long spaces (e.g. hallway or corridor), the camera smoothly slides horizontally along the X-axis while maintaining wall boundaries.

---

## 3. The Conversation & Encounter System

When a player interacts with an NPC inside a diorama room, the game seamlessly transitions into a **2.5D Tomodachi-style Dialogue View**:

### 🚶‍♂️ 1. Parallel Sideways Character Placement
- **Control Lock**: Ground movement is locked upon pressing the interaction key (`E`).
- **Parallel Standing Offset**: The player character glides smoothly to stand **2.4 meters away** from the NPC along the horizontal X-axis (`Player` on the left, `NPC` on the right).
- **Sideways Profile Alignment**: The `Player` rotates 90° to face right, and the `NPC` rotates -90° to face left. Both characters stand side-by-side facing each other in profile relative to the camera view.

### 🔍 2. Asymmetric Left Camera Framing
- **Viewport Offsetting**: Rather than centering the camera on the middle of the screen, the camera target position shifts **+1.8 meters to the left**.
- **UI Avoidance**: Shifting the 3D scene to the left frames both characters and their speech bubbles within the open mid-left area of the viewport (`25% to 55%` screen width).
- **Clear Right Panel**: This leaves the right 300px of the screen completely clear for the floating **Communication Reflection** performance panel without any overlap.

### 💬 3. Floating 2D Speech Bubbles
- **Spatial 3D-to-2D Projection**: Floating speech bubbles project dynamically over character heads using screen-space vector math (`camera.unproject_position`).
- **Auto-Expanding Vertical Height**: Speech bubbles expand downward dynamically based on text length without scrollbars or text truncation.
- **Distinct X-Offsets**: The Player's green bubble offsets slightly to the left, and the NPC's blue/orange bubble offsets slightly to the right, guaranteeing zero speech bubble clipping.

---

## 4. Modular Room Template Workflow (`RoomTemplate.tscn`)

Creating new rooms or expanding the game world uses a **Master Template Inheritance Pattern**:

1. **Base Master File**: `RoomTemplate.tscn` contains the standard 3D room box CSG geometry, lighting, spawn markers, and fixed camera anchor.
2. **Duplication & Customization**: To build a new room (e.g. `Room_Cafe.tscn` or `Room_Library.tscn`), duplicate `RoomTemplate.tscn`.
3. **Asset & Door Mapping**:
   - Swap or place 3D furniture props (desks, couches, lamps, counters).
   - Set the `target_room_scene` path on the door node (`Door3D`).
   - Assign the target `npc_id` to the room's NPC node.
4. **Zero Code Overhead**: No camera math or physics scripts need to be written for new rooms — the system automatically inherits the fixed diorama camera tracking and encounter logic.

---

## 5. Key System Attributes for AI Agents & Developers

| Parameter | System Value | Purpose |
|---|---|---|
| **Room Standard Size** | `16m (W) × 10m (D) × 5m (H)` | Fits standard viewport aspect ratio (16:9) |
| **Room Camera Position** | `Vector3(0.0, 3.2, 7.5)` | Stationed in front of the open diorama wall |
| **Room Camera Angle** | `Vector3(-14.0°, 0.0°, 0.0°)` | Low-angle downward pitch into room |
| **Dialogue Standing Gap** | `2.4 meters` | Natural social distance between characters |
| **Dialogue Cam Shift** | `+1.8 meters` (Left-Framed) | Unblocks right UI performance panel |
| **Theme Aesthetic** | Cream (`#fffdf2`), Orange (`#ff8c1a`), Cyan (`#29b6f6`) | Nintendo Tomodachi Life / Animal Crossing |
