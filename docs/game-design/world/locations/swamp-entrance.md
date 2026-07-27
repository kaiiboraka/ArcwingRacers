# Witch's Lair (Swamp Entrance)

## Overview

The Witch's Lair is surrounded by mostly impassable swamp trees. It is the primary goal location for Viper players, and an optional boss encounter for Thief players.

## Map Structure

On the world map, the Witch's area is an enclosed, bramble-walled-off zone with exactly **one entrance** — a neck of swamp water at the bottom of a larger swamp tile cluster. That entrance requires a Viper to pass — a lone Thief cannot enter. Entering that neck triggers a transition into the **Swamp Maze** level (see `world/levels/swamp-maze.md`), a much larger, separate playing field than the small enclosed area shown on the world map. See `gameplay/scripted-encounters/enter-witch-cloister.md` for the transition trigger itself.

A Viper Spawner inside the inner grove releases the baby Vipers described below.

## Spawning Vipers

New baby Vipers are released regularly from the Witch's Lair, populating the map with competition.

## Approaching the Lair

The entrance is guarded by a powerful **Horned Viper** (see `gameplay/enemies/viper-guardian.md`). Strategies:

- **Direct assault:** Only viable with a very powerful Viper. High risk — multiple large, aggressive Vipers will come at you at once deeper in the lair.
- **Captive distraction:** Bring captives and drop them on the ground near the entrance. Horned Vipers will go for captives inside their lair. Eating a captive pacifies them until they get hungry again. Bring enough captives for all of them!

## Defeating the Witch

- **If playing as a Viper:** Upon eating the Witch, the Viper spits out her hat and turns back into a human. Game restarts as a Thief Lord.
- **If playing as a Thief:** Defeating the Witch turns any remaining Horned Vipers into Castle Guards, including the Thief's own paired/ridden Viper — who turns human and can no longer be ridden, stranding the Thief in the swamp. To escape, the Thief must betray their now-human partner: drag him to the Witch's cauldron and dunk him, turning him back into a Viper so the Thief can ride out. Castle Guards (other than the partner, once reverted) can be picked up like captives — delivering one to the Castle grants one free entry (still must deal with soldiers inside). No new Vipers spawn after the Witch is defeated. See `decisions/adrs/0003-witch-victory-transformation-all-vipers.md` for the rationale.

For the first-sighting intro cutscene (Witch stirring her cauldron, summoning a Horned Viper, Bowie "Magic Dance" repeat-visit dialogue) and the full boss fight, see `gameplay/boss-battles/witch-battle.md`.
