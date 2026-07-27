# Side Quest Entrance

A Special Location (see `world/map-generation/overview.md`) — a map tile/cluster acting as an entrance to another level. Usually a small, one-room Zelda-style cave; occasionally a full quest level.

There are two separate side-quest pools:

- **Character-specific quests:** each character has their own side quest(s), some of which include unique levels that appear during a run with that character. These need dedicated main-map entrance tiles created for them.
- **General random pool:** separately, there's a general pool of randomly-spawned levels (and their main-map entrance tiles) that can appear on any run, regardless of character.

These are not tied to the Thieves'/Vipers' daily-quest board systems in `town-scenes/thieves-guild.md` / `town-scenes/vipers-pit.md` — those are a different system. `[TBD]` Whether character-specific entrances are seeded up front at map generation or dynamically spawned on the fly (like Secret Cave) is still unconfirmed — the deck ticket raises this as an open question without resolving it.

## Known Quests

A source pricing/content sheet names three side-quest dungeons, with no further detail given:

- **Secret Tunnel**
- **Secret Cave** `[Note: distinct from the Retrogasm-triggered "Secret Treasure Cave" in world/locations/secret-cave.md — that location has its own separate unlock condition (eating a same-length Viper) and isn't accessed via this entrance. Don't conflate the two.]`
- **Highway Robbery**

## Archive Findings

Checked the old V&T prototype (`C:\Repos\IMS\VipersAndThieves-archive`, a separate archived Unity project) per your direction, since some quest data may exist there even as unimplemented stubs.

- **No "Side Quest Entrance" concept exists in the archive** as a distinct location/tile type. What does exist is a family of generic cave/location entry-trigger events: `EnterCave-Tunnel`, `EnterCave-Random`, `EnterCave-Treasure`, `EnterCave-PartyCave`, and similar. `[Inferred]` `EnterCave-Tunnel` plausibly corresponds to the **Secret Tunnel** quest above, given the name match — but this is a guess, not a confirmed mapping.
- The archive's quest base class (`QuestData`) has a `playerCardKey` field meant for character-specific quest assignment — but it's **empty on every quest asset inspected**, confirming the old prototype never actually tied quests to specific characters even though the data model supported it.
- **Secret Tunnel**, **Secret Cave**, and **Highway Robbery** exist in the archive only as UI strings plus GameEvent trigger ScriptableObjects — not as fully-built quest data (no reward values, difficulty, or level content attached). They read as placeholder/never-fully-implemented content in the old prototype, not finished designs to port over as-is.

`[TBD]` Whether the current design should treat these three as flavor names for generic `EnterCave-*`-style map triggers (matching the archive's approach) or build them out as distinct named quest levels is still an open call — flagging for your review rather than deciding unilaterally.
