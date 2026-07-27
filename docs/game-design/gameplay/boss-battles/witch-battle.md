# Witch — Boss Battle

1. **Find the entrance.** On the main world map, the Witch's swamp area isn't obviously marked — the player has to spot a neck of swamp water at the edge of a larger swamp tile cluster. That water channel is the only way in, and only a Viper can cross it; a lone Thief cannot enter. See `world/locations/swamp-entrance.md`'s Map Structure section.
2. **Outer trap maze.** Crossing the channel transitions into the Swamp Maze level — a maze of Spike and Arrow traps, possibly with a couple of Horned Vipers roaming this outer section as well (not just guarding the entrance). See `world/levels/swamp-maze.md`.
3. **The Cloister.** Clearing the outer maze leads to the Witch's Cloister — a second, smaller semi-maze (the thorn-bramble/three-cauldron arena described below) with its own distinct challenges, culminating in the boss fight itself.

## Intro Cutscene

On first arrival at the Cloister, the camera pans to the Witch deep in the maze, stirring her cauldron:

> "What kind of magic spell to use...slime and snails? Or puppy dog tails? Eh?"

She dashes something into the pot — after a poof of smoke, out comes a new **Horned Viper**. This is the first sighting of the same cauldron-summon mechanic she uses throughout the fight itself (see The Battle, below). The camera then returns to the player's position at the Cloister entrance, who must reach her, avoiding obstacles and Horned Vipers along the way.

On repeat visits (any playthrough), her dialogue instead becomes a random snippet from a set of lines from David Bowie's "Magic Dance." `[Ref: Labyrinth (1986)]`

A helmeted guard head sits in the pot before she creates the Viper — an intentional plot clue, foreshadowing that Horned Vipers transform back into humans (see `gameplay/enemies/viper-guardian.md` and `world/locations/swamp-entrance.md`'s "Defeating the Witch" section).

## The Battle

**Environment:** Three cauldrons — top, left, right. A thorn-bramble maze leads to the left and right cauldrons; the top cauldron is reachable only by a one-way cliff drop, or by facing oncoming Horned Vipers head-on.

**Sequence:** The Witch alternates, on a timer, between summoning **two Horned Vipers** (top cauldron — see `gameplay/enemies/viper-guardian.md`), a Poison Cloud Potion, and a Fireball Potion. When the timer runs out, she teleports to one of the other two cauldrons. Once one side cauldron is knocked over, she alternates only between the top and the remaining side cauldron — and only returns to the top once the Horned Vipers are dead or both side cauldrons are down.

**Maze:** Players can clear the Poison and Fire side paths in either order, but must eventually clear both. It's a big loop with U-shaped paths, dead-end safe-zone pockets, and certain paths the Horned Vipers won't follow into.

**Win condition:** Catch the Witch at a side cauldron before the Horned Vipers corner you, forcing her back to the top and unlocking that path. Biting her there knocks the cauldron over, which poisons/burns down part of the maze. Biting her also has a cosmetic effect — burning makes her hat disappear, poison melts her face. With both side paths cleared, the top becomes reachable to finish her.

`[TBD]` Do we need baby (3-tile) Vipers as a food source during the battle?

## Defeating the Witch

Once the top cauldron is reached and the Witch is cornered there, the player swallows her. **She dies with a loud cackle.**

Her death immediately transforms all Vipers in the area back into humans, including the Thief's own paired/ridden Viper. A Thief player is left stranded in the Cloister — their partner can no longer be ridden. To escape, the Thief must drag their now-human partner to one of the battle's own cauldrons (top, left, or right — whichever is still standing) and dunk him, reverting him back into a Viper so the Thief can mount up and ride out. See `decisions/adrs/0003-witch-victory-transformation-all-vipers.md` for the rationale.

For what happens to surviving Horned Vipers and the post-battle outcomes for each player type, see `world/locations/swamp-entrance.md` ("Defeating the Witch") and `game-cycle/endings.md`.
