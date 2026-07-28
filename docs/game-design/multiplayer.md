# Multiplayer

## Architecture

Multiplayer is designed as a first-class feature from day one. The same code path handles single-player, splitscreen, LAN, and online play (see [ADR 0006: Multiplayer Architecture](../decisions/adrs/0006-multiplayer-architecture.md)).

**Core principle:** A race defines up to 16 player slots. Each slot is filled by a local player, an AI bot, or a network peer. The simulation treats all slots identically — only the input source differs.

## Modes

### Splitscreen (Launch)
- 2–4 players on one machine.
- Each player gets a viewport region.
- Supports mixed input: Player 1 on keyboard, Players 2–4 on gamepads.
- AI fills remaining slots up to configured racer count.

### LAN (Launch)
- Multiple machines on the same local network.
- One machine acts as host (authoritative Race Manager).
- Other machines connect and send inputs.
- AI fills remaining slots.

### Online (Post-Launch)
- Peer-to-peer with self-hosted custom lobbies.
- No official matchmaking servers.
- One peer acts as host.
- Remote peers send input packets; host broadcasts state snapshots.

## Input System

All player input routes through a unified **input buffer** per slot:
- **Local keyboard/gamepad** → direct to buffer
- **AI decision system** → buffer
- **Network packet** → deserialize → buffer

The Race Manager reads from buffers once per tick. This abstraction lets any slot be any input type without branching code.

## State Synchronization

- The Race Manager is authoritative.
- Visuals (engine sounds, particles, animation) run locally on each client — never synced.
- Network sync uses: input packets from remote peers → host simulation → state snapshots broadcast to all peers.
- State snapshots include: racer transforms, lap/position data, heat/boost state, crash state.
- Snapshot rate tunable per session (default: 20 Hz).

### Implementation Approach

Godot's built-in [High-Level Multiplayer API](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) provides the foundation: `ENetMultiplayerPeer` for transport, `@rpc` for remote calls, `MultiplayerSpawner` for scene spawning, and `MultiplayerSynchronizer` for property sync (position, rotation, state). The server is always peer ID 1; clients get random IDs.

Key pattern for this project: write all game code as if multiplayer is always active, then use `OfflineMultiplayerPeer` for single-player mode. This ensures the same code path runs everywhere — no separate single-player branch to maintain. See [this community guide](https://old.reddit.com/r/godot/comments/1lt0wdc/online_coopmultiplayer_guide_for_beginners_beyond/) for the "same codebase, selective execution" pattern, and [this discussion](https://old.reddit.com/r/godot/comments/17z1q80/how_is_godots_multiplayer/) for tradeoffs vs Unity/Unreal.

The input buffer abstraction (29 bytes/slot per tick) is designed specifically for network transport — fixed-size structs serialize trivially via `PackedByteArray` and are small enough to send at 20+ Hz without meaningful bandwidth cost.

State snapshots (transforms, lap, heat) are broadcast at tunable rate (default 20 Hz) using reliable-ordered RPCs or synchronizer nodes.

### Rollback Netcode

For responsive online play, **rollback netcode** is desired. Godot's built-in API has none — but the [netfox](https://github.com/foxssake/netfox) addon (MIT license, 1.1k stars, [docs](https://foxssake.github.io/netfox/)) provides it out of the box:

| Feature | What netfox provides |
|---|---|
| Rollback tick | Replace `_physics_process()` with `_rollback_tick(dt, tick, is_fresh)` |
| State save/restore | `RollbackSynchronizer` + `_get_rollback_state_properties()` |
| Input gathering | `BaseNetInput` + `_gather()` — directly maps to our input buffer pattern |
| Interpolation | `TickInterpolator` for smooth visual state between rollbacks |
| Prediction | `PredictiveSynchronizer` for client-side prediction + server reconciliation |
| NPCs in rollback | `RollbackSynchronizer` works for nodes without input (see [rollback-npc example](https://github.com/foxssake/netfox/tree/main/examples/rollback-npc)) |
| Deterministic RNG | `RewindableRNG` for reproducible random during rollback re-sim |
| Timing | `NetworkTime` with `physics_factor` compensating `move_and_slide()` delta |
| Connection | `netfox.noray` for NAT punchthrough / signaling |

**Why netfox fits this project:**
- Our architecture already aligns — slot-based input buffer = `BaseNetInput` subclass, one per player slot
- Pod physics are deterministic (same input → same output), which is the prerequisite for rollback
- `_rollback_tick()` maps cleanly to our existing `_physics_process()` pattern
- netfox handles the hard parts (state save/restore, tick sync, prediction reconciliation) that would otherwise be custom
- Shipping games use it — Godot Rocket League uses netfox's physics rollback
- `OfflineMultiplayerPeer` still works for single-player

All netfox addons are installed at `addons/` (core, extras, noray, internals). Enable them in Project → Project Settings → Plugins. netfox.noray is ready for NAT punchthrough when online P2P is implemented.

Rollback is a **Phase 5** addition (post-launch). For splitscreen and LAN at launch, netfox's rollback is unnecessary — the input buffer + direct physics sync is sufficient. But the code path should be designed from the start to support `_rollback_tick()` migration.

### Links

| Resource | What it covers |
|---|---|
| [netfox](https://github.com/foxssake/netfox) | Main repo — addon for timing, rollback, interpolation, prediction |
| [netfox docs](https://foxssake.github.io/netfox/) | Full documentation, tutorials, guides, class reference |
| [rollback-npc example](https://github.com/foxssake/netfox/tree/main/examples/rollback-npc) | Working example: NPCs participating in rollback with `RollbackSynchronizer` |
| [rollback-npc/scripts](https://github.com/foxssake/netfox/tree/main/examples/rollback-npc/scripts) | Source: `player.gd`, `npc.gd`, `player-input.gd` — direct pattern reference |
| [Forest Brawl](https://github.com/foxssake/netfox/tree/main/examples/forest-brawl) | Full game example using netfox |
| [Godot HLM API](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html) | Transport layer (`ENetMultiplayerPeer`), RPCs, `MultiplayerSpawner` |
| [Community guide](https://old.reddit.com/r/godot/comments/1lt0wdc/online_coopmultiplayer_guide_for_beginners_beyond/) | "Same codebase, selective execution" pattern, authority vs client patterns |
| [Multiplayer discussion](https://old.reddit.com/r/godot/comments/17z1q80/how_is_godots_multiplayer/) | Godot built-in vs custom vs rollback tradeoffs |
| [OfflineMultiplayerPeer](https://docs.godotengine.org/en/stable/classes/class_offlinemultiplayerpeer.html) | Single-player using the same multiplayer code path |
| [Offline example thread](https://old.reddit.com/r/godot/comments/1kmk06y/new_game_dev_question_about_multiplayercoop/msbyb5e/) | Discussion: "write as multiplayer, use OfflineMultiplayerPeer for single" |

## Lobby

Custom lobby system for LAN/online:
- Host configures: track, racer count, lap count, AI difficulty, slot assignments
- Lobby screen shows: all connected players, their chosen racers, ready state
- Race starts when host launches (all players ready toggle optional)
