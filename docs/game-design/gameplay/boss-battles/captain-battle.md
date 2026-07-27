# Captain — Boss Battle

The Castle's mid-boss — the **Captain of the Guard**, fought in the Castle Courtyard after entering the castle and before reaching the King's throne room.

## Opening Cutscene

The player enters the inner courtyard and finds the King and the Captain at the top rampart, watching the fight together. The King spots the player, does a surprise-shake animation, then scampers inside the palace as the gate slams behind him. The Captain grins, cracks his fingers/flexes, and jumps down to fight.

## The Battle — 4-Phase AI State Machine

Each phase strips away a piece of the Captain's outfit and changes his "tell" before he attacks, and the guards he calls in for help.

| Phase | Outfit | Dance Move / Tell | Attack | Guards |
|---|---|---|---|---|
| 1 | Red bandana, Heavy Metal Black Spike Jacket, Big hair wig | Moonwalk | Charge | 4 Soldiers |
| 2 | jacket, wig | Spin Splits | Axe Chop | 2-4 Soldiers & 2 Archers |
| 3 | bare chest, wig | Rocker tongue flick | Axe Whirlwind | 4 Soldiers & 2 Archers |
| 4 | bare chest, bald | Head bang | Ballista | 4 Soldiers (guard the rampart key) |


In Phase 2, the archers specifically run out to the sides and up to the top terrace.

**General flow (Phases 1–2):**
1. **Move:** The Captain wanders the field randomly, invulnerable — attacking him here just gets deflected.
2. **Dance/Attack:** After a delay, he telegraphs with his phase's dance move, then immediately attacks.
   - If he hits the player, or his attack misses/times out, the phase resets.
   - If he runs into a pillar, he's stunned for a few seconds — an opening.
3. **Stunned:** Biting him here hits him, strips a piece of his outfit, and sends him up onto the pillar he crashed into. Failing to bite in time resets the phase.
4. **Pillar:** He calls in that phase's guards. Once all guards are dead, he ground-stomps toward the player and the next phase begins.

**Phase 3** plays the same Move → Dance/Attack beat, but the attack is the Axe Whirlwind (avoid until his attack timer expires, leaving him winded instead of stunned). A successful hit during "Winded" strips the last of his outfit. The Captain leaps up to the top rampart, locks the side doors, calls in 4 Soldiers, and mans the ballista — starting Phase 4.

**Phase 4:** The Captain stays at the ballista for the rest of the fight, looping through his attack cycle:
1. **Growl/Taunt:** Enraged growl (on a miss, or the first time in) or a taunting maniacal laugh.
2. **Crank:** Winds up the ballista.
3. **Track:** Briefly tracks the player, lining up a shot.
4. **Shoot:** Fires, then the phase resets to Growl/Taunt.

While he loops through that cycle, the player fights through the 4 Soldiers he called in, dodging ballista shots — the Soldiers double as a welcome food source this late in the fight. The last Soldier killed drops a key. Picking up the key unlocks the side doors, opening a path up to the rampart. With the doors open and the Soldiers dead, the Captain is defenseless — swallowing him whole ends the battle.

`[TBD]` Exact damage values, stun/winded durations, and the player's available attack window during each opening aren't specified in source material — flagged for a future balance pass.

`[TBD]` Open question from the 2019 doc, not addressed by either source: if the player is already up on the archer terrace (from Phase 2) when Phase 2 ends, does the Captain just jump down and wait below, or something else?

## Damage & Healing

- **Damage taken:** static per hit, regardless of the player's Viper size. The ballista hit does more damage than melee attacks. `[TBD]` Whether damage is a flat per-hit value or scales per-segment, and whether segments closer to the head take more damage than segments near the tail, are both open questions in source material — not decided.
- **Hunger drain:** constant during the fight, scaling with the player's Viper size (consistent with the normal hunger-drain rules in `gameplay/experience-and-levels.md`).
- **Healing during the fight:** the Thief's carried consumables, Captives brought into the battle, and eating defeated Soldiers/Archers.

## Courtyard Battle (Before the Captain)

Before reaching the Captain himself, the inner courtyard arena holds 4 Soldiers — 2 by the big door/inner courtyard entrance, 2 along the sides. The door to the Captain's arena auto-opens once all 4 are defeated. The player can flee back out the way they came in at the bottom Castle Portcullis at any point — see `world/levels/castle-courtyard.md`.

## After the Captain Falls

What happens next differs by which character the player is controlling — this is the connective step between the Captain fight and the King/Throne Room sequence in `game-cycle/endings.md` and `gameplay/scripted-encounters/enter-kings-palace.md`.

- **Playing as Viper (Thief is the partner):** Once the Captain is swallowed, the Viper has a huge bulge and can't move. The Thief partner dismounts and runs into the palace alone, returning shortly after wearing a crown. He thanks the Viper for the help and promises a regular tribute of food. The Viper then leaves out the bottom entrance without its Thief partner, and play transitions back to the main map. This is the **Viper Beats King (Optional Boss)** outcome in `game-cycle/endings.md` — the new King-Thief ally afterward sends periodic tribute captives.
- **Playing as Thief (Viper is the partner):** Once the Viper partner swallows the Captain, the Thief dismounts (the Viper has the immobilizing bulge). The palace door opens and the Thief exits through the top, transitioning into the random Throne Room ending cutscene — see `gameplay/scripted-encounters/enter-kings-palace.md`'s Cameo Pool, then the King's defeat in `game-cycle/endings.md`'s **Thief Beats King (Primary Victory)**.

## See Also

- `world/locations/castle.md` — overall Castle location, gate guards, entry requirements.
- `world/levels/castle-courtyard.md` — the courtyard arena itself.
- `gameplay/npcs/king.md`, `game-cycle/endings.md` — the King and the post-Captain scripted sequence.
