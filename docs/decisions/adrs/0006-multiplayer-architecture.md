# ADR 0006: Multiplayer Architecture from Day One

## Status
Accepted

## Context
Retrofitting multiplayer into a single-player game mid-development is notoriously difficult — it affects physics timestep, input handling, game state management, and netcode architecture at every level. ArcwingRacers plans to support local splitscreen, LAN, and online multiplayer via self-hosted peer-to-peer custom lobbies (no official servers).

Building the game with multiplayer as a first-class concern from the start means choosing an architecture that supports all three modes without major rewrites.

## Decision

Architect the game with an abstraction layer that treats local, LAN, and online players as interchangeable "inputs" from the perspective of the race simulation:

1. **Race Manager** (`systems/race/race_manager.gd`) is the authoritative simulation. It controls:
   - Race state machine (countdown, running, finished, results)
   - Lap counting and position tracking
   - World state (hazards, timers)
   - The Race Manager runs once per frame, deterministic given the same input sequence

2. **Player Slots** — The race defines up to 16 player slots. Each slot is filled by either a local player, an AI bot, or a network peer. The slot abstraction handles input routing:
   - **Local player:** keyboard/gamepad → input buffer → slot
   - **AI bot:** AI decision system → input buffer → slot
   - **Network peer:** remote input packet → input buffer → slot (eventual P2P implementation)

3. **Splitscreen:** When multiple local players are in the same race, each gets a viewport/camera assigned to a screen region. All share the same Race Manager instance.

4. **LAN/Online (future):** The Race Manager runs on one peer (host). Remote peers send input packets; the host broadcasts world state snapshots at a tunable rate. P2P with one peer as authority, no dedicated server.

5. **State synchronization:** The race simulation is the single source of truth. Visuals (engine sounds, particle effects, animation) are purely cosmetic and run locally. This minimizes bandwidth: only inputs and compact state snapshots travel the wire.

6. **All multiplayer modes built on the same slot system:**
   - **Campaign/single-player:** 1 local player + 15 AI bots (or fewer)
   - **Splitscreen:** 2–4 local players + AI bots to fill
   - **LAN/Online:** N local players + M remote players + AI bots to fill to configured count

## Consequences
- **Positive:** Single-player and multiplayer share the same code path — no separate "multiplayer mode" to maintain.
- **Positive:** Adding online multiplayer later requires only the network transport layer, not a game architecture rewrite.
- **Positive:** AI bots can fill arbitrary slot counts, keeping races full regardless of human player count.
- **Tradeoff:** The input abstraction layer adds up-front complexity — every input path goes through the buffer system.
- **Tradeoff:** Determinism must be maintained. Any per-frame randomness must use a shared seed or be authoritatively resolved by the host.
