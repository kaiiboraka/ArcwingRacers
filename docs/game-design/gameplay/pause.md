# Pause

Accessed via the Pause button on the Thief-side inventory belt buckle (see `hud/hud.md`).

## Pause Menu

`[Source: hand-written-notes.txt]` The Pause screen has three parts:

- **A Daily Quests panel** — shows your currently accepted daily quests (see `town-scenes/thieves-guild.md` / `town-scenes/vipers-pit.md`).
- **A Quick Buy panel** — purchase a limited set of consumables directly with gems, with a "buy more gems" IAP shortcut alongside it. `[TBD — idea, not confirmed]` Possibly gated behind leveling up the Market first, rather than available from the start.
- **Settings:** toggle music/sound, Resume, and a "tombstone" option to restart/retry.

`[Resolved 2026-06-19]` "Tombstone" is confirmed equivalent to the old "Quit / Return to Menu" item — same action, just renamed. `[TBD]` Exact menu visualization for the tombstone option isn't settled yet.

## In-Game HUD Behavior

- Available HUD action buttons are visually highlighted (brightened) whenever a valid action is in range — see `systems/action-range.md`.
- The game must support both **landscape and portrait** orientation — all UI elements, including the pause menu, need layouts that work in both.
