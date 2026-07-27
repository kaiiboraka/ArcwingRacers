# Town

## Overview

Between play sessions, you return to town to load up and further interact with this world and its people. Each location in town is a UI-only scene with its own purpose.

## Town Locations

| Location | Purpose |
|---|---|
| **Tavern** | Character & item selection |
| **Bank** | Coin deposits/withdrawals, chests, lockpicking minigame |
| **Market** | IAP store |
| **Mystery Ad Theater** | Story-based rewarded ad experience |
| **Beats Alley** | Interactive boombox for the game soundtrack |
| **Social Plaza** | Referrals & social media |
| **Graveyard** | High scores & game stats |
| **Thieves' Den** | Daily Thief quests, Game of Thieves idle minigame |
| **Viper's Pit** | Daily Viper quests, 1-on-1 snake fights & betting |
| **Flynn's Arcade** | Play classic Snake! |

See individual `town-scenes/` docs for each location's detailed design.

`[TBD]` An Outlaw wanted sign is described in source material as appearing hammered into the ground just outside town when an NPC Thief maxes out their coin purse — see `gameplay/player-characters/thief-gameplay.md`'s Outlaw Bounties section for the mechanic.

## Tone & Art Direction

Pitched as a "modern renaissance faire" — a medieval town that openly mixes in 80s references (movies, music, toys) without trying to hide the anachronism, similar to how a real renaissance faire mixes period setting with modern vendors and visitors. Townspeople are a visibly diverse crowd, many wearing cloaks/hoods — readable as ambient "everyone's a potential thief" flavor rather than a uniform.

## Entering Town

How you enter town depends on what you're playing as when you arrive:

- **Lone Viper:** Cannot enter town at all — treat the town tile as impassable.
- **Lone Thief:** Stops at the border tile and fades out (possibly via expanding black bars). After the fade, you see a small, town-scale figure walk into the Tavern.
- **Thief riding a Viper:** Stops at the border; the Thief dismounts (animated). Both fade out, then reappear together at town scale — the Thief leads the Viper on a leash, ties it to a post outside, and walks into the Tavern. The Viper coils up and waits outside.

## Leaving Town

Reverse of the entry fade — animate exiting the Tavern back to your previous map position. You're still stopped on exit, so you need to issue a move action again to continue. `[TBD: exact exit trigger — source suggests either a dedicated Thief action button, or a "leave town" wheel icon shaped like an open door.]`

## In-Town Actions

A wheel of icons appears around the town letting you choose which location to visit/interact with.

## Town Building Leveling

`[Planned post-launch feature — not required for initial launch, per source material.]` Each town building can independently level up. Leveling requires both **experience** (earned via that building's specific activity — see each `town-scenes/` doc) and **currency** (silver at lower levels, possibly gems at higher levels — exact thresholds `[TBD]`).

Every individual building level grants its own incremental bonus — a slightly better version of that building's existing reward, scaling level over level — on top of which **Level 5** and **Level 10 (max)** each add a distinct **new** bonus type, not just a bigger version of the per-level scaling. Specifics (which reward scales, what the L5/L10 new bonus is) differ per building and are documented in that building's own doc.

**Building levels are independent of character levels.** "Character level" only applies to Vipers, and is really just their body length (see `gameplay/experience-and-levels.md`) — it has nothing to do with Town Building Leveling. Thieves have no level at all; their only equivalent progression is the wealth gap over poorer thieves (see `gameplay/player-characters/thief-gameplay.md`).

Each building upgrade gets a new banner image at Level 5 and Level 10, intended as the centerpiece of a social-media announcement campaign leading up to that update.
