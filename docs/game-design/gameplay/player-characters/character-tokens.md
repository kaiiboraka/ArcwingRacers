# Character Tokens

A Character Token is an unlockable alternate playable character — a themed reskin of the base Viper or Thief with its own mechanical identity, not just a cosmetic swap.

A Character Token always represents **one playable character.** Some characters have a **special partner** from the same universe — but that partner is not bundled into the purchase as a second playable character. Instead, the partner is found, saved, or encountered separately, somewhere on the world map or in a quest level, and then interacts with your Character Token character in some way (e.g., as a summonable companion, an escort, a mount). See the Atreyu entry below for the clearest example of this pattern.

## Token Economy

Each Character Token is "spent," not equipped permanently:

- Unlocking a character grants a **character token**.
- Spending a token lets you play as that character for one run.
- **On death**, the token is consumed.
- **On a successful return to town** (the character survives and comes home on its own), the token is returned to your inventory for reuse.

This makes each character a high-stakes, limited-use pick rather than a permanent unlock — losing a run with a Character Token costs you the token itself, not just the run. You can acquire multiple quantity of each token.

`[Source: hand-written-notes.txt]` **Replenishing tokens via Achievements:** every Character Token has 3 Achievements (see `game-cycle/meta-progress.md`), and completing each one grants **+1 of that character's token** — a way to earn back tokens beyond the initial unlock, separate from the spend/consume loop above.

`[Updated 2026-06-20]` **Completing all 3 of a character's Achievements unlocks the permanent Legendary (Tier 5) version of that card** — this replaces the earlier "completing all 3 grants a gem reward" framing, and is now the primary acquisition path for permanent character unlocks.

Characters that are **permanently unlocked** (earned, like Thief Lord/Grand Viper, or by completing all 3 Achievements) are **exempt** from this spend/consume model — see `loot/item-rarity.md`'s Tier 5 ("Legendary") definition. All permanent unlocks are Legendary-tier, and all Legendary-tier characters are permanently available (infinite-use, never consumed on death).

`[Removed 2026-06-20]` Direct real-cash purchase of a permanent character unlock (including the former "Complete Character Set" bundle) is no longer part of the model. Single-use Character Tokens can still be purchased with **Gems** (single or 5x packs) — see `monetization/iap.md`. Gems themselves are earned via gameplay/ads or bought with real cash, so this is an indirect path, not a direct real-money character purchase.

## What a Character Token Includes

Every Character Token is composed of four parts:

1. **A visual skin** — its own set of animated frames, distinct from the base Viper/Thief.
2. **Unique abilities or gameplay mechanics** — something that changes how the run plays, not just how it looks.
3. **A unique quest** — often tied to a separate unique level or scripted encounter.
4. **3 Achievements** — character-specific goals; completing one grants a replacement token, completing all 3 unlocks the permanent Legendary version of the card (see Token Economy above).

`[TBD]` where a character below is missing one of these four parts — see notes per character.

---

## Fleshed-Out Concepts

These are the Character Token concepts from source material that include real mechanical detail, as opposed to the long list of bare 80s-reference names with no design behind them yet (see `character-token-ideas-unsorted.md` for that list — those are **not** canonical and should not be treated as real characters). 

Also a note on design rules for these characters, quests, and appearances: this game is a parody of 80s excess. Yes a homage too! But the use of characters, plot points, and themes must be paired with quote rewrites, jokes, humor, mockery, and generally not taking oneself seriously or following the original script. The joke has to be aimed *at* what's being referenced — its trope, its excess, its cliché — not just placed near it; humor alone doesn't make something a parody if it isn't commenting on the thing it's borrowing from.

Real people are excluded from this approach entirely: genericize or fictionalize rather than parody a real person's likeness, even affectionately — that's a different (and stricter) risk category than a fictional character. See the Captain's rewrite in `gameplay/boss-battles/captain-battle.md` for a worked example: a generic "wannabe rockstar" archetype instead of a specific real performer.

`[TBD — parody pass in progress, not all entries below have been revised yet]`

### Vipernator *(Terminator)*
- **Role:** Viper
- **Skin:** Glasses, red laser eye, exposed metal patch.
- **Quest:** Find the kid. Save him from liquid-transforming Vipers coming to eat him. Pick up the kid. Evac to the exit. Kid is a reskinned captive. You can eat him (and fail the quest, but gain a normal captive amount of food).
- **Ability — Track Prey:** Locks onto a target and relentlessly pursues it (auto-chase).
- **Quotes:** "Come with me if you want to live." / "It doesn't feel pity, or remorse, or fear, and it absolutely will not stop. Ever. Until you are dead."
- **Achievements:** `[TBD]`

### MacDIY *(MacGuyver)*
- **Role:** Thief
- **Skin:** `[TBD — not described]`
- **Quest — Diffuse Bomb:** 60-second bomb timer. Must collect string, gum, and pinball parts (randomly placed in the level) and bring them to the bomb before time runs out. On success, Mac builds a Newton's Cradle and disarms it: "Hey, look what I made!"
- **Ability:** `[TBD — source describes the quest but no unique traversal/combat ability beyond it]`
- **Achievements:** `[TBD]`

### Atreyu *(The NeverEnding Story)*
- **Role:** Thief
- **Skin:** `[TBD — not described]`
- **Special partner — Luck Dragon:** A luck dragon is a flying mount/companion. He won't betray / eat you if hungry. [TBD] what lucky outcomes does the dragon influence?
- **Quest:** Chase bullies into dumpsters while riding the dragon. `[Source: iphone-notes.txt]` Set in an alley of dumpsters; mechanically, this is a Steal targeting an NPC Thief ("bully") — the normal post-steal knockback (see `gameplay/player-characters/thief-gameplay.md`'s Steal detail) shoves them into a dumpster instead of the usual knockback. Sending 3 thieves dumpster-diving this way unlocks an achievement (name `[TBD]` — not given in source).
- **Relic — Oryn:** Summons dragon.
- **Luck Dragon Ability:** Fist Pump speed boost; NES theme jingle plays when mounted.
- **Quotes:** "Never give up and good luck will find you" / "They look like good strong hands don't they?" / "But that is another story and shall be told another time."
- **Achievements:** `[TBD]`
- **Note:** this entry is a foundation, expected to be expanded later.

### Kumite Champ *(Bloodsport)*
- **Role:** Viper (solo)
- **Skin:** `[TBD — not described]`
- **Ability — Dim Mak:** Stuns opponents and bosses. While performing the move (or winding up for it), the floating text **"Bottom One!"** briefly appears.
- **Quest:** Get past guards in a dark Hong Kong alley, then fight a boss (a boss **Viper**, per the encounter framing) in the kumite ring.
- **Quotes:** "Bottom One!" (also the move's floating text, see above) / "Very good, but brick not hit back."
- **Related item:** Harley Bandana consumable ("That hurts me just lookin' at it.") — `[TBD: is this item a reward exclusive to the Kumite Champ quest, or part of the general item pool? See open questions.]`
- **Achievements:** `[TBD]`

### First Blood *(Rambo)*
- **Role:** Viper
- **Skin:** Red bandana, machine gun ammo down the tail.
- **Ability:** Machine gun fires constantly from the Viper's mouth — gun down as many enemies as you can.
- **Quote:** "To survive a war, you gotta become war." / (Queen lyric, paired flavor text) "And another one gone, and another one gone..."
- **Quest:** `[TBD — no unique quest described beyond the ability itself]`
- **Achievements:** `[TBD]`

### Highlander Thief *(Highlander)*
- **Role:** Thief
- **Skin:** `[TBD — not described]`
- **Quotes:** "There can be only one" / (Queen lyrics, paired flavor text) "Who wants to live forever?" / "I am immortal, I have inside me blood of kings..."
- **Restriction:** `[Source: hand-written-notes.txt]` Cannot ride Vipers at all — this locks the Highlander Thief out of the swamp and the Witch fight entirely, but doesn't block primary Thief victory (bribing into the Castle and defeating the King) since that path doesn't require a Viper partner.
- **Ability — Katana:** `[Source: hand-written-notes.txt]` Carries a katana. Timed correctly against an incoming Viper strike, a swing **deflects** the Viper (defensive parry, no Viper-riding workaround). Against Thieves, the katana **kills** them outright, steals some of their gold, and triggers an electricity visual effect.
- **Quest:** `[TBD — no unique quest described]`
- **Achievements:** `[TBD]`

### Light Warrior *(Tron)*
- **Role:** Thief — specifically so the Light Disc relic can summon a findable, Tron-styled **Viper** as a discoverable special partner (matching the general Character Token partner pattern — see the Atreyu/Falkor entry above).
- **Skin:** `[TBD — not described]`
- **Quest — Light Cycle Race**
- **Ability:** `[TBD — no mechanic beyond the quest and Relic described]`
- **Relic — Light Disc:** Presumably the means of summoning/finding the Tron-styled partner Viper, though this isn't explicitly confirmed.
- **Design note:** Tron's neon aesthetic was the stated inspiration for the T4 Laser Chest (`loot/chests.md`).
- **Quotes:** "Prepare to transport to light cycle grid. We have transport." / "On the other side of the screen, it all looks so easy." / "Greetings, program!"
- **Achievements:** `[TBD]`
- `[Discrepancy — unresolved]` `world/locations/secret-cave.md`'s Retrogasm event (triggered by any Viper eating another Viper of exactly its own length) describes a universal effect for any Viper: "Your body turns into a Tron-like Light Viper." Unclear whether this is just thematic reuse of Tron-neon styling, or whether it overlaps/conflicts with Light Warrior being a dedicated Tron-themed character.

### Gizmo *(Gremlins)*
- **Role:** Viper
- **Skin:** `[TBD — not described]`
- **Ability:** No bright lights — takes damage near light sources. Getting wet spawns rival mogwais. After midnight, transforms into a gremlin. Adds a day/night cycle to the run.
- **Quest:** `[TBD — no unique quest described beyond the ability itself]`
- **Quotes:** "Look Mister, there's three rules you've got to follow." / "...never, NEVER feed him after midnight"
- **Achievements:** `[TBD]`

### Pac-Man Skin
- **Role:** Viper
- **Skin:** One-headed snake skin (the visual is the character's namesake — see Ability for what comes with it).
- **Ability:** One-hit death (replaces the normal hunger/health system for this run), much faster speed, "never ending noms" (implies no hunger cap / unrestricted eating — exact rule `[TBD]`).
- **Quest:** `[TBD — no quest described]`
- **Achievements:** `[TBD]`

### Lil' Tom *(Legend, 1985)*
`[Renamed]` Previously "Jack" in earlier source material — renamed to move away from an exact reference name. Use "Lil' Tom" on first mention, "Tom" thereafter.
- **Role:** Thief — solo, no paired Viper for this quest (explicitly enters the boss arena alone and vulnerable).
- **Skin:** `[TBD — not described]`
- **Source note:** sourced from a Codecks "Project Management" deck card created 2025-10-03 — by far the most recently authored card in the full export (everything else dates to 2021–2022). Flagging the date in case this reflects newer, less-settled thinking compared to the rest of the roster.
- **Quest:** A solo boss battle against the **Dark Lord**, a corrupted Viper, in a hellscape arena — win by redirecting beams of light onto him or by stunning and mounting him into one yourself. See `gameplay/boss-battles/dark-lord-battle.md` for the full encounter.
- **Ability:** no traversal/combat ability outside the boss quest is described — the quest's mechanics (sword-deflect, horn-mount) are quest-specific, not a general kit.
- **Quotes:** Character Card — "There shall never be another dawn" / "Legends can be now and forever." Tom (in-battle) — "Love and light may be fragile… but they're stronger than fear."
- **Achievements:** All three tied to the Dark Lord boss battle — see `gameplay/boss-battles/dark-lord-battle.md` for full context on each:
  1. **"Another Dawn"** — defeat the Dark Lord via Win Method 1 (Light Ray).
  2. **"Nothing More Magical"** — defeat the Dark Lord via Win Method 2 (Unicorn Horn + Mount); hidden achievement.
  3. **"Groundhog Day"** — reach the boss battle's 3rd-encounter cutscene variant (i.e., fight the Dark Lord at least 3 times).

### Labyrinth
- **Role:** Thief `[Inferred — source material doesn't state a role explicitly, but Relics are Thief-only (see loot/loot-types.md), and Labyrinth's Spy Glass Orb is a Relic, so the role must be Thief]`
- **Skin:** `[TBD — not described]`
- **Quote:** "It's only forever, not long at all" `[Ref: Labyrinth (1986); Source: hand-written-notes.txt]`
- **Quest — Maze Quest:**
  1. Glass Orb equipment helps you find the quest.
  2. Find a baby on the map to start the quest.
  3. An owl swoops in to steal the baby.
  4. A Labyrinth maze rises out of the ground.
  5. Find your way back to the baby to beat the quest.
  6. Other Vipers and Thieves are still in the maze with you during this.
- **Ability:** `[TBD — no traversal/combat ability beyond the quest is described]`
- **Relic — Spy Glass Orb:** "Tap to cycle through spying on Castle, Town, Swamp. Current one will show an orb on edge of screen pointing the way. Orb has mini icon of destination." Equipped by default while playing Labyrinth, overridable at the Tavern — see `loot/loot-types.md`'s Relics section. Likely the same item as the "Glass Orb Equipment" referenced in step 1 of the quest above.
- **Achievements:** `[TBD]`

---

## Knight Rider / KITT

Not a Character Token — Knight Rider has no skin, ability, or quest of its own, so there's no Fleshed-Out Concepts entry for it. The design lives entirely as a general-pool relic: **Kitt's Watch** (see `loot/loot-types.md`) summons a KITT-styled car-Viper partner whenever the Thief doesn't already have one. No unique abilities on that Viper — its value is guaranteeing an on-demand low-level Viper pairing, not a combat mechanic.

---

## Open Questions

- Each Thief Character Token's unique relic (Auryn, Light Disc, Spy Glass Orb) is part of that character's own equipment — equipped by default while playing that character, overridable with a different relic at the Tavern. See `loot/loot-types.md`'s Relics section for the full rule.
- **Harley Bandana** is a different case: it's a *Consumable* (not a Relic) tied to Kumite Champ, a **Viper** Character Token — and Vipers don't use the Relic/Tavern-loadout system at all. Whether it's exclusive to the Kumite Champ quest or part of the general Consumables pool is still `[TBD]` — see the note on that item in `loot/loot-types.md`'s Consumables table.
