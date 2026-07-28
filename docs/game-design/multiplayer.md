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

## Lobby

Custom lobby system for LAN/online:
- Host configures: track, racer count, lap count, AI difficulty, slot assignments
- Lobby screen shows: all connected players, their chosen racers, ready state
- Race starts when host launches (all players ready toggle optional)
