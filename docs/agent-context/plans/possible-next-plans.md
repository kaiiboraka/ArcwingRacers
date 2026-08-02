# Possible Next Plans (Survey Landscape)

Status: 🔜 CANDIDATES (2026-08-02). Not a plan — a dated snapshot of the landscape after the
Phase-1/post-Phase-3 survey, so a later session can pick a direction without re-doing the
investigation. Companion context: `technical/` docs and `agent-context/` maps. Track Editor
Phase 3 (mesh generation) is parked; see `plan-mesh-generation.md`.

## What's already in code

- Spline + track editor — complete (all phases + dock)
- Pod physics — `PodController.gd` (736 lines) covers hover, steering/traction, banking,
  tilt, pitch, boost/heat, gravity, collision params
- InputCollector — autoload polling local input into buffer fields
- Starting grid scene — `starting_line.tscn` (auto-gen grid), skybox, `Test_Level.tscn`,
  phantom_camera + netfox addons installed
- Audio — NOT done (see the Audio Breakdown section below; the earlier "done" claim was wrong)

## Fully specified in docs but not implemented

The docs are ahead of the code — these all have complete technical + game-design write-ups
waiting to be built:

| System | Docs | Depends on | Notes |
| --- | --- | --- | --- |
| Race Manager + Lap/Position | `race-manager.md` (310 ln), `race-structure/race-manager.md` | Input buffer, grid, spline, pod | The heart of Phase 2 |
| Input Buffer slot model | `input-buffer.md` (223 ln) | InputCollector (exists) | Current is local-only; the slot abstraction (AI/network/replay) isn't built |
| Starting grid / race start wiring | `starting-grid-and-race-start.md` (216 ln) | grid scene (exists) | Countdown + takeoff-boost logic not wired |
| AI Racer | `racer-ai.md` (318 ln), `ai-opponents.md` | Input buffer, spline, pod | Fills race slots |
| Mana / Shield / Ability | `mana-system.md` (255), `shield-system.md` (225), `ability-system.md` (320) | Pod | Self-contained combat layer |
| Race HUD | `hud/hud.md` | Race mgr, pod | No `ui/` folder exists yet |
| Minimap | `minimap.md` (210 ln) | Spline only | Self-contained, visual |

## Recommended next: make it a race

The dependency chain points to a vertical slice: **Input Buffer slot model → Race Manager
(state machine + lap/position + countdown) → wire the starting grid → minimal HUD → AI to fill
slots.** Every dependency except the buffer slot model already exists, and all four systems are
fully specified in docs. This turns `Test_Level` from a "drive around" scene into an actual
race — the natural milestone given Phase 1 is done.

### Flag to decide first

There's a doc inconsistency to resolve before Race Manager: `race-manager.md` and `ui-events.md`
reference an `EventBus` autoload and `InputBufferManager`, but `game-events.md:26` says the
EventBus is TBD — not implemented, and there's no such autoload in `project.godot`. The race
manager literally can't be built as specified until that's resolved (build a GDScript EventBus
+ InputBufferManager, or revise the docs to Tier-1 signals).

### Which direction to take

1. Race vertical slice (buffer → race manager → grid → HUD) — recommended
2. AI racer first (fill the field, then race manager)
3. Mana/shield/ability combat suite (independent of race structure)
4. Minimap (small, self-contained, visible win)
5. Something else

Also worth deciding: the EventBus discrepancy above — build one, or rewrite the docs?

## Audio Breakdown: "audio is not done"

The ✅ in `next-technical-breakdowns.md` is misleading: it marked the breakdown doc as written,
not the system. Audio has no playable wiring.

### What actually exists

| Piece | Status |
| --- | --- |
| `docs/technical/audio-system.md` | Draft spec only — bus layout, import-settings TBD, Doppler, reverb-per-spline, per-pod engine plan, heat-beep thresholds. Explicitly says "Remaining Decisions" unresolved. |
| `Content/Scripts/Resources/audio_file.gd`, `audio_bucket.gd`, `audio_data.gd` | The three custom resource classes (the "custom nodes"). **Moved to `addons/Custom_Nodes/Audio/` (2026-08-02).** Present, but no `.tres` assets have been authored with them. |
| `Content/Audio/SFX/pod_racer/*.wav` | ~250 imported EP1R-ripped clips (engine loops, crashes, ambience, beeps, vox). Imported only. |
| Actual audio wiring | Nothing. Zero `AudioStreamPlayer`/`AudioStreamPlayer3D` in any script or scene. No bus layout `.tres`, no EngineAudio controller, no ambient/music system, no heat-beep logic, no collision SFX. |

So the gap: the doc + resource scaffolding + raw clips exist, but there is no playable audio.
`audio-system.md` itself is mostly a plan — its "Per-Pod Engine Architecture" section (the
EngineAudio node tree) is entirely unimplemented, and the doc lists import settings and
ambience as undecided.

One caveat: `audio-player.md` is a Unity/C# legacy doc (`AudioSource`, `AudioMixer`,
`GameObject`) — it's not Godot-relevant and belongs on the legacy-audit list alongside
`game-events.md`/`ui-events.md`/`object-pooling.md` (which are also C#-flavored).

### What "doing audio" would actually mean

1. Create the audio bus layout (Master → Music/SFX/UI, per `audio-system.md`)
2. Write the EngineAudio controller that pitch-blends the pod engine loops from
   PodController speed/heat (the doc gives the exact formula)
3. Author `.tres` assets (`AudioFile`/`AudioBucket`/`AudioData`) wiring the imported clips
4. Hook boost/heat beeps, collision/scrape, pickups to the existing signals
5. Decide the unresolved items (import load modes, mono, ambience 2D/3D, music)

Pending decision: fix the ✅ in `next-technical-breakdowns.md` to reflect the true state (doc
written, system not implemented), and add an audio-implementation item to the follow-up tasks.
