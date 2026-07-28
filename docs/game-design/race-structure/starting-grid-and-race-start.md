# Starting Grid & Race Start

## Grid Layout

Racers start on a 4×4 rectangular grid behind the start/finish line. 16 positions total, numbered front-to-back, left-to-right:

```
[01] [02] [03] [04]    ← front row (closest to start/finish)
[05] [06] [07] [08]
[09] [10] [11] [12]
[13] [14] [15] [16]    ← back row
```

Each position is a `Marker3D` with a visible ground sprite. Positions beyond the configured `racer_count` are hidden.

## Position Assignment

Slots are assigned by qualifying position from the previous race (or randomly for race 1). The best qualifier gets position 01 (front row, inside). This mirrors real motorsport: qualifying order determines grid position.

- **Pole position** = position 01, front row left
- **Last qualifier** = position 16, back row right

In single-player campaign, qualifying is automatic based on the previous race result. In multiplayer, qualifying is determined by the previous race finish order across all human and AI racers.

## Race Start Sequence

```
PREGAME → COUNTDOWN (3 sec) → RACING
```

### PREGAME
- Racers placed on their grid positions
- All racers frozen (physics disabled or controls locked)
- Camera sweeps from behind the grid to the front
- 2–3 second pause for dramatic effect

### COUNTDOWN
- 3-second countdown: "3" → "2" → "1" → "GO"
- Visual: huge on-screen numbers with screen shake on each count
- Audio: countdown beeps (F-sharp, D, A in EP1R style), then a distinct GO sound
- Racer engines are on but idling — thrusters flicker, engine hum audible
- Controls remain locked until GO

### RACING
- On GO: all racers are released simultaneously
- Physics resumes, controls unlock
- **Takeoff boost window**: the first ~0.3 seconds after GO is a special window where the takeoff boost check fires

## Takeoff Boost (EP1R-Style)

A timing-based speed burst available at the very start of the race:

1. **During countdown:** Hold the accelerator button all the way through 3-2-1
2. **Moment of GO:** As the "GO" text appears, release the accelerator for a split-second (the digital display on your pod flickers)
3. **Re-press accelerator:** Immediately press accelerator again

If done correctly, you get a speed burst out of the gate — a full boost activation without needing to charge it.

**Why this exists:** The takeoff boost gives skilled players a meaningful advantage at race start without making the start random. It rewards timing precision and creates an exciting "launch" moment every race.

**Timing window:** ~150ms to release and re-press. Too late (held through GO) = no boost. Too early (released during countdown) = no boost. The window is generous enough to be learnable, tight enough to feel rewarding.

**No penalty for failure:** Missing the takeoff boost just means normal acceleration from the line. No speed penalty.

## Grid Authoring

The starting grid is a reusable scene (`Content/Scenes/starting_line.tscn` with `Content/Scripts/starting_line.gd`). Track scenes instance it and position it at the start/finish line. The grid auto-generates its 16 Marker3D positions based on exported properties (racer count, column/row spacing, marker height).

## Technical Reference

See `docs/technical/starting-grid-and-race-start.md` for the implementation — grid script, countdown timer, takeoff boost check, race placement logic.
