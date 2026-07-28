# Pod Collision Response

## Wall / Terrain Collisions

Behavior depends on approach angle and speed:

### Scrape (near-parallel)
- Pod slides along the wall at reduced speed
- Damage over time applied to the contacting segment (VFX sparks + SFX scrape)
- Speed loss proportional to angle — shallower scrape = less slowdown
- No bounce

### Crash (near-perpendicular, high speed, steep angle)
- Pod stops abruptly, takes heavy damage to the contacting segment
- If the segment's HP is depleted → destruction → death spin
- Can one-shot a wing at extreme speeds
- No bounce — pod does not ricochet off walls

### Intentional Bounce
- Not in the default collision model. May be added as a deliberate mechanic (specific hazard, ability, or track feature) if desired.

---

## Pod-on-Pod Collisions

Both parties take damage and are shoved. Damage calculation:

```
damage_to_other = (relative_speed * impact_angle_factor) * attacker_bump_mass
damage_to_self = damage_to_other * 0.5  # scaled down for attacker
```

### Factors
- **Relative speed** — faster impact = more damage to both
- **Impact angle** — perpendicular broadside = max transfer. Glancing scrape = minimal.
- **Bump Mass** — heavier pods deal more damage and shove lighter pods harder
- **Attacker advantage** — the pod striking from the side deals more damage to the target than it receives (reward for positioning)
- **Wall pinning** — shoving an opponent into a wall compounds damage (pod takes collision damage from both the shove and the wall impact)

### Scraping
Side-by-side contact at similar speeds causes light damage over time to both — like EP1R side-swiping. Neither pod loses significant speed.

---

## Damage and Segment Destruction

### Gradual Damage
Each collision applies damage to the specific collision shape segment hit (detected via `get_local_shape()`). Damage amount depends on collision force and segment type (blade vs wing).

### One-Shot Destruction
A sufficiently hard hit (crash, high-speed ram, obstacle at speed) can destroy a segment instantly. When this happens:

1. Segment HP reaches 0
2. Associated visual detaches (or plays destruction animation)
3. **Death spin begins**

### Death Spin

On wing destruction:
- Pod enters a brief uncontrolled spin (reduced control authority)
- Pod drifts toward the ground
- If the ground is hit during the spin → **explosion + respawn**
- If the player regains control before ground impact → continues with reduced performance (one engine)

The death spin lasts only a few seconds. It's a time punishment — no lives lost, but opponents gain distance while the player recovers.

### Full Crash (Explosion)

Conditions that trigger an explosion + respawn:
- Hitting terrain during death spin (spin → ground → boom)
- Extreme perpendicular collision at max speed
- Falling out of bounds

Respawn mechanics (exact timer, position, invulnerability window) are a separate design topic — deferred.

---

## Respawn

Respawn brings the pod back onto the track at reduced speed with brief invulnerability. Exact respawn rules (timer, position selection, invulnerability duration, penalty) are deferred — to be designed alongside race structure.
