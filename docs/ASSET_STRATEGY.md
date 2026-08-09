# THRESHOLD — Asset Strategy & Modular Kit Requirements

> **System Status**: `IMPLEMENTED`  
> **Target Consumer**: Future automated world-builder and asset-import agents.

---

## 1. Modular Asset Strategy Hierarchy

To build believable, readable diorama rooms efficiently without overwhelming the project with hundreds of unique assets, THRESHOLD prioritizes a **reusable kit-of-parts strategy**.

```text
1. Gameplay-Critical Anchors (Spawn points, interaction triggers, floor colliders)
        ↓
2. Identity-Critical Reusable Assets (Counters, desks, tables, chairs, sofas, bookshelves)
        ↓
3. Modular Architecture Kit (Wall shells, floor tiles, window frames, doors)
        ↓
4. Surface Dressing & Props (Lamps, potted plants, coffee mugs, books, frames)
        ↓
5. Material & Scale Variations (Albedo color swaps, 0.9x–1.1x scaling)
```

---

## 2. Required Asset Categories & Kit Specifications

The automated asset-import pass should search for assets matching the following core categories:

| Asset Category | Core Items Required | Reusability Strategy | Collision Needed | Interaction Metadata |
|---|---|---|---|---|
| **Seating** | Dining chairs, armchairs, office swivel chairs, 2-seater sofa, bench | Reuse across café, study, office, apartment | Yes (`StaticBody3D`) | Sitting anchor offset |
| **Tables & Surfaces** | Dining tables, coffee tables, executive desks, student desks, reception counters | Color/material variants (wood, glass, white) | Yes (`StaticBody3D`) | Surface Y-height anchor |
| **Storage & Walls** | Bookshelves, filing cabinets, credenzas, room dividers | Scale scaling (1x, 1.5x width) | Yes (`StaticBody3D`) | None |
| **Counters & Bars** | Café service counter bar, pastry case, reception desk | Modular straight/corner pieces | Yes (`StaticBody3D`) | Counter standing spot |
| **Lighting** | Desk lamps, floor lamps, pendant lamps, streetlight poles | Material emissions for warm light glow | No (Visual only) | Light node child |
| **Plants & Decor** | Potted desk plants, floor ficus plants, wall framed pictures, rugs | Reuse across all indoor rooms | No | None |
| **Props** | Coffee mugs, books, laptops, papers, wall clocks, whiteboards | Cluster small props on surfaces | No | None |
| **Architecture** | Wall planes, floor tile modules, door frames, window frames | Seamless modular snap tiling | Yes (`StaticBody3D`) | Door transition trigger |

---

## 3. Variation Through Materials & Scaling

Rather than requiring unique 3D models for every location:
- **Material Tinting**: Apply `albedo_color` overrides to standard materials (e.g., turning a light oak desk into a dark mahogany study desk or a white office desk).
- **Non-Uniform Scaling**: Scale prop assets slightly ($0.9\times$ to $1.1\times$) or adjust stretch along single axes to fit room dimensions.
- **Procedural Geometry**: Simple geometric objects (e.g. chalkboards, floor rings, rugs, wall trims) can be constructed using Godot's built-in primitives (`BoxMesh`, `QuadMesh`, `CylinderMesh`) via script when 3D models are absent.
