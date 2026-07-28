# Next Technical Breakdowns

In suggested order:

1. **Spline system** — data format per point (position, banking, width, surface normal), spline traversal, how AI samples it, how the minimap renders from it
2. **Input buffer** — record/replay input buffer that both human and AI write to, consumed each physics tick
3. **Starting grid & race start** — grid positions, 3-2-1 countdown, takeoff boost mechanic
4. **Race manager** — lap counting, finish line detection, race state machine, position tracking
5. **Mana system (technical)** — mana pool implementation, regen tick, pickup spawn/collection, combat drop
6. **Shield system (technical)** — directional blocking detection, parry timing window, mana cost model
7. **Ability system (technical)** — ability cast flow, targeting, cooldowns, mana costs, projectile/effect spawning
8. **AI racer** — spline sampling for target position, steering toward target, boost/brake decisions, path selection on branches, difficulty scaling via randomized loadouts and behavior parameters
9. **Minimap rendering** — the 4 modes (spline zoomed out, spline zoomed in, vertical position comparison, screen-circling progress map), spline → screen-edge rendering, follow-camera orientation
10. **Audio** — engine pitch scaling with speed, boost/heat sounds, collision/scrape SFX, engine fire, music system
