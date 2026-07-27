# Enemy AI Behavior

NPC Thieves and Vipers populating the world run a priority-ordered behavior list, evaluated against the range tiers defined in `systems/action-range.md` (Vocal Range, Sensor Range) — the same ranges player-driven Bribe/Steal/Bite actions use.

`[TBD]` What makes another Thief/Viper register as "dangerous" to the AI isn't spelled out in source material — likely derived from the same relative-size/wealth comparisons already used for Bribe-eligibility (`gameplay/player-characters/thief-gameplay.md`) and Viper targeting (`gameplay/player-characters/viper-gameplay.md`), but not confirmed.

## Thief AI

### Lone Thief
Evaluated top to bottom; first matching condition wins:

1. **Run-Away** — a dangerous Viper is within Vocal Range
2. **Bribe** — a dangerous Thief is within Vocal Range
3. **Steal** — a steal target is within Action Range
4. **Seek-Pickup-Target** — a lone Viper (potential partner) is within Vocal Range
5. **Seek-Steal-Target** — a target is within Vocal Range, and moving toward it doesn't bring the Thief closer to any Sensor Range threat (the target must end up further from all known threats than the Thief currently is)
6. **Run-Away** — a dangerous Viper or Thief is within Sensor Range
7. **Seek-Pickup-Target** — a lone Viper is within Sensor Range
8. **Seek-Steal-Target** — a steal target is within Sensor Range
9. **Wander-Randomly**

### Paired Thief (has a Viper partner)

1. **Bribe** — a dangerous Thief is within Vocal Range
2. **Steal** — a steal target is within Action Range

A paired Thief leans on its Viper partner to handle threats it would otherwise Run-Away from while lone.

## Viper AI

### Lone Viper

1. **Seek-Bite** — hungry, and food is within Vocal Range
2. **Run-Away** — a dangerous Viper is within Vocal Range
3. **Seek-Pickup** — a lone Thief (potential partner) is within Vocal Range
4. **Seek-Bite** — food is within Vocal Range (even if not hungry)
5. **Seek-Bite** — hungry, and food is within Sensor Range
6. **Run-Away** — a dangerous Viper is within Sensor Range
7. **Seek-Pickup** — a lone Thief is within Sensor Range
8. **Seek-Bite** — food is within Sensor Range

### Paired Viper (has a Thief partner)

Combines the Viper's own desires with its Thief partner's — the Thief's ability to Bribe a threat away may override the Viper's instinct to Run-Away from it. `[TBD: exact merge/priority logic between the two trees beyond this isn't specified]`

## Open Items

Flagged as future work in source material, not yet designed:

- Avoiding multiple simultaneous threats at once
- Reaction-time delay (deliberately imperfect/slower reactions, not instant-perfect play)
- Target persistence — avoiding rapid flip-flopping between goals as conditions change tick to tick
- Terrain movement cost factored into pathing/decision-making
