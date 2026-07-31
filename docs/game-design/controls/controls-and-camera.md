# Controls and Camera

## Input

### Supported Devices
- Keyboard + Mouse
- Gamepad (Xbox/PlayStation layout)

### Gamepad Mapping — Baseline Layout

| Action | Gamepad |
|---|---|
| Accelerate | South Button (A / Cross) |
| Brake / Reverse | East Button (B / Circle) |
| Steer + Nose Pitch | Left Analog Stick (horizontal = steer, vertical = pitch) |
| Ship Tilt (90° left/right) | Right Analog Stick (horizontal only) |
| Shield (hold to block) | Left Trigger |
| Ability | Right Trigger |

Analog sticks have a **deadzone** (`InputCollector.ANALOG_DEADZONE`, default 0.2): tiny stick values below the threshold snap to 0 and the remaining range is rescaled to full deflection. The per-action `deadzone` in Project Settings → Input Map (0.5) only applies to button-style reads (`Input.get_action_strength`); `InputCollector` reads raw joypad motion events, so its own deadzone governs steer/pitch/tilt sensitivity and prevents stick jitter from registering as input.
| Boost (activate) | TBD — no gamepad binding yet |
| Item | TBD — see preset variations below |
| Repair (hold) | TBD — see preset variations below |
| Look Behind | Left Bumper |
| Minimap Mode Cycle | Select / Minus / Touchpad |
| Pause | Start |
| D-pad | TBD — may be redundant with left stick |

### Controller Preset Variations

| Action | Preset A | Preset B | Preset C |
|---|---|---|---|
| Repair (hold) | Right Bumper | West (X) | West (X) |
| Item | North (Y) | Right Bumper | North (Y) |
| Look Behind | Left Bumper | Left Bumper | North (Y) |

All other inputs shared across presets. Custom remapping available.

### Keyboard + Mouse Mapping

| Action | Keyboard |
|---|---|
| Accelerate | W |
| Brake / Reverse | S |
| Steer Left / Right | A / D |
| Ship Tilt Left / Right | Q / E |
| Nose Pitch Back (air control) | Up Arrow |
| Nose Pitch Forward (boost charge) | Down Arrow |
| Boost (activate when gauge full) | Left Shift |
| Shield (hold to block) | Space |
| Ability | Left Click |
| Item | F |
| Repair (hold) | R |
| Look Behind | C |
| Minimap Mode Cycle | Tab |
| Pause | Escape |

### Debug Tuning Keys
| Action | Keyboard |
|---|---|
| Increase hover height (live) | Ctrl+= (holding repeats) |
| Decrease hover height (live) | Ctrl+- (holding repeats) |

These re-target the hover springs immediately (step = `PodController.debug_hover_step`, default 0.5 m) so you can tune ride height while driving. Wired in `PodController._debug_hover_tuning()`.

### Shield Mechanics
- Hold shield button (Left Trigger / Left Shift) to raise shield.
- Shield drains mana while held.
- Time the shield just before impact to **parry**: successful parry restores mana instead of consuming it.
- Shield direction TBD — previously right stick (now tilt), may use auto-facing or a simpler scheme.

### Boost
Pushing the nose down (pitch forward) **fully** — within `charge_pitch_deadzone_deg` (default 10°) of full stick deflection — while at or near maximum speed charges the boost gauge. A partial nose-down (one you could also steer with) does not charge. When the gauge is full, the status indicator turns yellow. Pressing the Boost key/button activates boost — a single press, no release-repress trick. Boost continues while the accelerator is held; releasing the accelerator or pressing brake ends it immediately. No mana cost — the cost is handling loss (turn rate penalty while boosting), collision risk, and eventual overheating. The Right Trigger is the **Ability**, not accelerator — it does not affect boost.

### Repair (EP1R-style)
Hold the repair button to repair the most-damaged engine segment first. The engine goes briefly offline (pod slows, handles poorly). Segments only restore to yellow condition — never full green. The pod's Repair Rate stat governs how fast this cycles.

### Look Behind
Toggles a rear-view perspective. While active, the spline minimap mirrors to match the reversed camera direction (the minimap always orients so you're going "up").

---

## Minimap

Four minimap modes cycled with the dedicated button (Select/Tab). None show terrain geometry — only route information via the track spline.

### Mode 1 — Spline Zoomed Out
Wide view of the track spline ahead. Shows the general flow of the track — "there's a turn coming up" — without terrain detail. Does not reveal whether a section is narrow cave or wide chasm.

### Mode 2 — Spline Zoomed In
Same spline display, tighter zoom. More precise approach view for the upcoming sequence.

### Mode 3 — Vertical Position Comparison
A "neck-and-neck" display showing nearby racers' relative positions as vertical bars. Who's furthest ahead is at the top. Useful for gauging distance to the next racer without the full minimap.

### Mode 4 — Screen-Circling Progress Map
The entire race spline is mapped to the screen perimeter. Each racer's icon orbits along the screen edge at their spline t position:
- t=0% at top-left, moving clockwise around the border
- Further-ahead positions draw on top (higher Z priority)
- Player's icon is 1.5× larger
- No other UI overlaps the edge area — the design intentionally leaves a gap around the border

#### Top Bar Changes in Mode 4
The standard top bar (lap counter | race timer | position) is restructured:
- **Position counter** ("3/16") is hidden — redundant since all positions are visible on the edge
- **Race timer** moves to the top-right corner
- **Top bar background** is hidden so the edge-circling icons are not obscured

### HUD Layout

```
+------------------------------------------+
| Lap 3      00:42.150          3/16       |  ← Top bar (24px)
|                                  ┌──────┐|
|                                  │ MINI │|  ← Minimap panel (modes 1/2, 120×120)
|                                  │ MAP  │|
|                                  └──────┘|
|                                       ┌──┤  ← Position bars (mode 3, right side)
|                                       │  │
|                                       └──┤
+------------------------------------------+
```

The minimap panel sits in the top-right corner, just below the top bar. In mode 4, the top bar background hides and elements shift to make room for the edge-circling icons.

### Design Principles
- **Never see the whole track layout during a race.** The minimap shows only the upcoming route — you learn the track geometry through practice, not a bird's-eye view. A full overview may be available in the pre-race menu.
- **Player is fixed at center, minimap rotates around them.** The minimap always rotates so you're going "up." When looking behind, the minimap mirrors to maintain this orientation.
- **Spline only, no terrain.** The minimap communicates route intent, not environment detail.
- **Racer icons.** Each racer has a nation/faction symbol or character portrait thumbnail. The player's icon is larger. Icons are small (8–12px) to avoid clutter.

---

## Camera

Four camera views, toggled with a dedicated camera-cycle key/button:

| View | Description |
|---|---|
| Far Chase | Camera behind and above the pod. Wide view of the track ahead. |
| Medium Chase | Closer follow cam. More immersive, less peripheral vision. |
| Close Chase | Tight follow cam. Pod fills more of the frame. |
| First Person | Camera at pilot eye level. Shows the front of the pod (no character/seat visible). |

All chase cameras follow the pod with smoothing and look-ahead that scales with speed. Camera collision (wall occlusion) handled via transparency fade or spring-in.
