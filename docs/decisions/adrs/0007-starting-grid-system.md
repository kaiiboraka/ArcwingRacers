# ADR 0007: Starting Grid System

## Status
Accepted

## Context
Every race needs a starting grid — racers positioned behind the start/finish line in numbered slots. The grid must be authorable in the editor and support a variable number of racers (up to 16). The existing implementation is a `@tool` script at `Content/Scripts/starting_line.gd` attached to `Content/Scenes/starting_line.tscn`.

## Decision
The starting grid is a `@tool` script extending `Node3D` that auto-generates a configurable grid of `Marker3D` positions:

1. **Grid layout:** 4 columns × 4 rows (16 positions), anchored at the origin for first position. Column spacing = `RACER_POSITION_WIDTH` (float, default 15), row spacing = `RACER_ROWS_SPACING` (float, default 25). Positions are numbered `Position_01`–`Position_16`.
2. **Racer count:** Exported `racer_count` (int, 0–16, default 8) controls how many positions get a visible `Sprite3D` ground marker. Markers beyond the count are hidden.
3. **Idempotent rebuild:** The script detects existing `Position_NN` children and reuses them, freeing any unrecognized children. Rebuild triggers on property changes via block-style setters and on `_ready()` via `call_deferred()`.
4. **Public API:** `start_positions: Array[Marker3D]`, `get_start_positions()`, `place_racers(racers: Array[Node3D])`.
5. **No class_name:** The script uses `extends Node3D` without a registered class name to avoid namespace conflicts. Attached via scene resource reference.

## Consequences
- **Positive:** Grid is authorable in the editor — drag the scene into any track, adjust `racer_count` in the Inspector.
- **Positive:** Positions persist on disk and survive scene reload.
- **Positive:** Simple API for Race Manager to place racers at race start.
- **Tradeoff:** Grid shape is rectangular (4×4). Non-rectangular starting layouts (e.g., funnel, staggered) would require a different approach.
