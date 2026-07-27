# Prison

This location is confirmed as one of the map's tile clusters (see `world/map-generation/overview.md`) — see also `gameplay/npcs/prison-guard.md` and `gameplay/npcs/captive.md` for the NPCs normally associated with it (Captive purchase/delivery flow).

## Getting Captured

A separate path into the Prison, distinct from the normal Captive economy: while playing as a Thief on the main map, attacking a Castle Guard draws aggro from Soldiers. If your Viper partner is killed while you're being chased this way, you're automatically arrested — the screen transitions to the Prison and you're shoved into an empty cell (not a normal Captive holding pen) next to a cameo NPC, **Mad Martigan** `[Ref: Willow (1988)]`.

- **Escape:** beat a **hard-difficulty** Lockpicking minigame (see `minigames/lockpicking/`).
- **Failure:** you die and restart in town.

`[TBD]` Whether a Thief with no Viper partner at all (never had one, vs. lost one this way) can trigger this same arrest path isn't specified.

`[Discrepancy — flagged, not resolved]` `iphone-notes.txt` describes a different encounter for the same cameo: a **10% chance** of finding Mad Martigan in a normally-empty cage near the Captive-selling Prison Guard (i.e. as part of the normal Captive economy, not the arrest path above). He calls out "Hey Peck! Get me some water, Peck" — fetching him water frees him; he jumps out spinning a two-handed sword, shouts "I'm free!", and **your Viper eats him**. This conflicts with the cell-mate version above on trigger condition (random Captive-pen encounter vs. the Castle-Guard-aggro arrest path), what state he's found in, and the outcome (eaten by your Viper vs. an escape-via-Lockpicking puzzle). Needs your call on which is canon, or whether both exist as separate encounters.
