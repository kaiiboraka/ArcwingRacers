# Castle Courtyard

The interior level reached after passing the Castle's gate guards (see `world/locations/castle.md`) — the inner courtyard arena leading to the Captain of the Guard boss fight.

## Layout

- A single fixed battlemap (not procedurally generated), with hand-placed impassable terrain matching the arena's walls/pillars.
- The bottom Castle Portcullis is both the entrance and an open retreat route — the player can flee back out to the main map at any point before or during the courtyard fight.

## Courtyard Battle

- **4 Soldiers** guard the courtyard: 2 positioned by the big inner door (the entrance to the Captain's arena), 2 along the sides.
- The inner door auto-opens once all 4 Soldiers are defeated.
- Clearing the courtyard leads to the Opening Cutscene and the Captain fight — see `gameplay/boss-battles/captain-battle.md`.

Soldier combat behavior is documented in `gameplay/enemies/soldier.md` — note this is a separate, simpler state machine from the Thief/Viper AI in `gameplay/enemies/ai-behavior.md`.
