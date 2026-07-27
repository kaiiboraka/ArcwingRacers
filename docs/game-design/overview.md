# Fantasy X — Game Design Overview

## Project Identity

**Working Title / Codename:** Fantasy X  
**World / Franchise Name:** Elythia  
**Genre:** 2D action-platformer / RPG  
**Engine:** Godot 4 (C#)  
**Target Platforms:** [TBD]  
**Studio:** [TBD]

---

## Concept

Fantasy X is a story-driven 2D action-platformer/RPG set on the planet Elythia — a world shaped by elemental mythology, ancient gods, and a magic system rooted in the spiritual DNA of all living things.

The player chooses one of two teenage twin protagonists at the start of the game. Each character plays fundamentally differently, has their own story beats and level tracks, and collects a distinct set of abilities — but their stories converge and interweave across the full campaign. The game is designed to be completed twice: once as each twin.

---

## Protagonists

**Kael Losallion** — male, 16, Prince of Losallia, Archon of Light (Sun-side).  
Elemental affinity: Sun (Light, Fire, Earth, Iron, Wood, Life + Arcane).  
Combat style: close-range sword fighter. Collects elemental boss crystals that unlock new elemental spells (MegaMan X / Zero style). Begins as a confident, purpose-driven heir; his outward confidence masks deep grief he doesn't know how to process — what reads as rage is almost always sorrow. His arc is learning that love and personal connection matter more than destiny. Emotional transformation: grief → rage → acceptance → gratitude. Thesis: *"Helping those around you will help save the world. Lift where you stand."*

**Rina Dawson** — female, 16, raised as commoner, Archon of Shadow (Moon-side).  
Elemental affinity: Moon (Shadow, Water, Ice, Wind, Lightning, Death + Arcane).  
Combat style: ranged/arcane caster. Collects moon-side elemental spells. Begins selfishly pursuing her own goals (finding her mother), inadvertently helping hundreds along the way. Her arc is discovering that losing yourself in service to others is how you save yourself. Thesis: *"Losing yourself in service of others is how you save yourself."*

Both twins are the biological children of **King Simon Losallion** and **Viona Dawson** (the court sorceress), separated and raised apart. Kael was raised as the Losallian prince under his stepmother Katalina (deceased); Rina was raised by their adoptive grandmother Julianne Dawson. Garrett Dawson — Viona's biological younger brother and the twins' uncle — lived in isolation near Amolna Valley and was entirely unaware the children existed until Bergen's attack on the village.

---

## Core Design Pillars

- **Story first, mechanics second.** Narrative progression unlocks mechanical progression. You don't earn spells from a shop — you earn them from the world.
- **Two playthroughs, one story.** Playing as both characters is the intended full experience. The game accounts for this: each character's perspective reveals something the other's doesn't.
- **Elemental mastery as identity.** Your element isn't just a damage type — it's who you are. Every character, enemy, location, and system is tied to the elemental hierarchy.
- **Metroidvania-lite progression.** Ability slots unlock in a linear story order; what you slot into them is your customization layer. The world opens up as your moveset does.
- **Earned difficulty.** Combat is designed around the "shock vs. attrition" principle — see `game-design/gameplay/health-and-difficulty.md`. The game should feel tense and punishing but fair.

---

## Magic System Summary

Two types of magic exist:

**Nature Magic** — elemental, color-coded by element, drawn from the mana within the caster. Divided into:
- Sun-side: Fire, Earth, Iron, Wood, Light, Life
- Moon-side: Water, Ice, Lightning, Wind, Shadow, Death

**Arcane** — artificial, volatile, invented by mortals. Colorless raw mana, shackled into crystal form via runic systems. Powerful but morally and physically dangerous. Both protagonists use Arcane as a baseline alongside their elemental abilities.

The gameplay expression of magic is the **Orb system**: elemental gemstone Orbs are slotted into unlocked Ability Slots on the character's equipment to unlock specific spells. Each spell has a type (Projectile, Status Effect, Trap, Melee, Charge, Up Special, Down Special, etc.). See `game-design/gameplay/magic-combat-system.md`.

---

## Ability & Equipment System Summary

Ability Slots are tied to equipment slots (Weapon, Wrist, Chest, Legs, Feet, etc.). Slots unlock through story progression — the act of receiving an item during the story also grants the mechanical ability. What you slot into each piece of equipment determines your active spells. Accessories (Neck, Finger) grant passive elemental resistance and status effect bonuses. See `game-design/gameplay/abilities.md`.

---

## Story Summary

The story takes place in the Kingdom of Losallia and across the wider world of Elythia. The exiled Moon God **Ryla** has spent millennia plotting his return. His vessel is **Viona Dawson** — a proto-human of ancient Moon bloodline, discovered frozen in a glacier, and raised as a human. Ryla slowly possesses her through her vast Moon mana reserves, eventually twisting her into Rina's final antagonist. The twins' quest to find their mother becomes a race to stop Ryla from re-entering the physical world.

The full story of **Elythia 1** spans 5 Acts. The authoritative beat-by-beat structure lives in the Fantasy X Data spreadsheet (**Stages & Elements** tab); the Obsidian Vault under `ProjectFantasyX/Story/` mirrors it but is still incomplete. Act 2 is a parallel hub act (4 elemental stages per twin). Acts 1, 3, and 5 are story-heavy with scripted encounters and boss fights. Act 4 is a hybrid: setup and traversal, then stages, then bosses, then a climactic push toward the capital. The Act 6 Epilogue from earlier planning is deprecated — its content is being retooled for Elythia 2. High-level arc:

| Act | Title | Summary |
|---|---|---|
| 1 | Introductions | Separate twin intro levels. General Bergen's forces destroy Amolna Village. Rina panics when a stranger — Garrett, her unknown uncle — emerges from Julianne's house during the attack; he takes her in as his apprentice. Kael is separately sought out by Ashlyn Yafreya, the Archon of Fire, who has been watching from a distance. Both twins begin training with someone who has close ties to their missing parents. |
| 2 | Complications | Parallel hub act (4 stages). Each twin encounters Archons and uncovers hints of a larger threat. |
| 3 | Revelations | Truths about Viona, Ryla, and the twins' origins come to light. |
| 4 | Convictions | The twins race toward the ruined capital, each blocked by a major geographic obstacle — Kael must breach the Grovewarden elf wall at Wardens' Gate; Rina must cross the Eraxian Desert. **4.2** is the breakthrough stage run. **4.3** is a boss fight (Zenick for Kael; a phantom antagonist for Rina — [TBD]). **4.4** is the home stretch: each twin battles through a massive enemy army, faces a second-to-last boss, and gets to flex the full moveset earned across the campaign before Act 5. |
| 5 | Conclusions | Both twins arrive outside the gates of ruined Dar Losa. **5.1.1 Final Rest** reunites each twin with their mentor (Ashlyn for Kael; Garrett for Rina). **5.1.2** is the final boss (Bergen for Kael; Viona for Rina). **5.1.3** wraps the fight. **5.2 Reunion** is the last story beat in Elythia 1 — Kael and Rina finally meet again — but it stays locked until the player has cleared 5.1 on both campaigns; each twin's progress lives in one shared save file, and both paths must be completed to unlock the ending. |

### Dual-Campaign Save & Ending

Elythia 1 is designed around two full playthroughs in a **single save file**. Kael's and Rina's campaigns each track their own progress through the same world-state. Finishing one campaign surfaces the other on the new-game / campaign-select flow. **5.2 Reunion** does not appear until **5.1** (Final Rest through the wrap-up) has been completed as **both** characters — only then does the true ending unlock.

---

## World Summary

**Elythia** is the planet. It has two continents:

- **Sunside Continent** — home of the Kingdom of Losallia (primary setting), the Oligarchy of Enria, the Imperial States of Dowania, the Triumvirate of Stoldenia, and the United Tribes of Yafrenia.
- **Moonside Continent** — home of Rylaria, Ciephara, Azara, Bjønta, and Taikhana.

The world has 6-day weeks and 18-hour days. Scale reference: ~340 miles from Amolna Village to the capital Dar Losa; ~24 days by slow carriage, ~4–5 days by fast horse.

Full world documentation lives in the Obsidian Vault under `ProjectFantasyX/Locations/`.

---

## Key Characters (Quick Reference)

| Character | Role | Element | Notes |
|---|---|---|---|
| Kael Losallion | Protagonist | Sun / Light | Prince of Losallia, 16, Archon of Losa |
| Rina Dawson | Protagonist | Moon / Shadow | Raised by Julianne, 16, Archon of Ryla |
| Simon Losallion | King / Father | Sun / Light | Deceased; framing device for both twins |
| Viona Dawson | Mother / Antagonist | Moon / Shadow | Ryla's vessel; Rina's final boss (5.1.2) |
| Garrett Dawson | Rina's mentor / uncle | Wood / Arcane | Viona's biological younger brother; a stranger to Rina until Bergen's attack. Takes her in as his apprentice. Later possessed by Ryla (The Warlock). |
| Ashlyn Yafreya | Kael's mentor / Archon of Fire | Fire | Former general in the Losallian Royal Army; career blacksmith. Sought Kael out after Amolna's destruction to train him. |
| Julianne Dawson | Adoptive grandmother | — | Raised Viona and Garrett; raises Rina |
| Ryla | Primary antagonist | Moon / Shadow | Exiled Moon God; incorporeal schemer |
| Losa | Patron deity of Losallia | Sun / Light | Simon's divine patron; largely off-stage |
| The Archons | Ensemble cast | All 12 elements | One per element; recruited over the campaign |

Full character documentation lives in the Obsidian Vault under `ProjectFantasyX/Characters & People/`.

---

## Inspirations

- **MegaMan X / Zero series** — elemental ability collection from bosses; dual-protagonist design.
- **Kingdom Hearts 1 / 2** — magic system resource model; narrative scope and emotional register.
- **Avatar: The Last Airbender** — elemental identity, Archon power awakening (Sharingan-style).
- **Metroid / Hollow Knight** — ability-gated world exploration; equipment-as-progression.
- **Celeste** — ability unlock moment (freeze + input prompt).
- **Shovel Knight** — level-select structure with linear-preferred but non-linear-available ordering.

---

## Scope Targets

### Per-Character Game Length (Elythia 1)

| Act | Target Length |
|---|---|
| Act 1 | ~1 hour |
| Act 2 | ~1 hour (4 stages × ~15 min) |
| Act 3 | ~30 minutes |
| Act 4 | ~1 hour (4 stages × ~15 min) |
| Act 5 | ~45 minutes |
| **Total (1 campaign)** | **~4.25 hours** |

**Total for both campaigns:** ~8.5 hours, not counting side content or completion bonuses.

**Stage length target:** 5–10 minutes each (7.5 min average). 4 stages per hub act = ~30 min of stage content per act.
