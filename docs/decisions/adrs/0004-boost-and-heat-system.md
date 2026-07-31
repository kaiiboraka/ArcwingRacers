# ADR 0004: Boost and Heat System

## Status
Accepted

## Context
Boost is the core risk-reward mechanic in EP1R and the primary thing players identify with that game's feel. Getting it wrong would undermine the entire project's goal of matching that game's feel. The mechanic has several interlocking parts: a charge-up phase, an activation phase with heat buildup, an overheat penalty, and a repair requirement to recover.

Elemental mods (future content) will modify heat and cool rates as part of the component system.

## Decision
Copy EP1R's boost/heat system, with two documented divergences from EP1R's original — activation (item 2) and the charge hold (item 3):

1. **Charge phase:** Holding the forward input (nose down) while at or near maximum speed fills a boost gauge. The gauge only fills when moving fast enough (above a charge-speed threshold, default 80% of max speed). Releasing forward resets the gauge instantly — each hold starts from empty.
2. **Activation:** When the gauge is full, a single press of the Boost button activates boost (divergence from EP1R's release-and-repress accelerator, which existed because of the N64 controller's limited button count — not a constraint here). Boost immediately adds a flat amount to current speed and accelerates rapidly toward a boost max speed that is additive on top of the pod's normal max speed (`max_speed + boost_speed_bonus`), not a fixed value.
3. **During boost:** The heat gauge rises continuously. Boost continues until: heat gauge maxes out (overheat), the player releases the accelerator, the player brakes, the player's speed drops far below max (a massive speed loss ends boost early), the player crashes, or the pod collides with something significant.
4. **Overheat:** When heat reaches maximum, boost forcibly disengages. One of the pod's wings catches fire. The pod cannot boost again until the fire is extinguished.
5. **Cooling:** Heat drains whenever the pod is not boosting. After boost ends (voluntary or forced), the heat gauge depletes at the Cool Rate. During overheat, the gauge must fully drain before the fire goes out.
6. **Modifiers:** Elemental mods on the engine slot adjust Heat Rate and Cool Rate. Fire mods increase heat rate (boost ends sooner but may add damage-on-contact); Ice mods decrease heat rate (longer boost) but reduce something else per kiss-curse design.

## Stage Lights
The boost HUD shows one of four stages: **OFF** (below charge speed — holding forward does nothing), **GREEN** (at charge speed — gauge fills), **YELLOW** (gauge full — boost primed), **RED** (boost active — heat rising).

## Consequences
- **Positive:** Exact match to EP1R feel for the core risk-reward loop.
- **Positive:** The nose-pitch charge mechanic creates natural skill expression — good players position their camera/pitch while navigating turns.
- **Positive:** Elemental mods have a clean integration point (heat/cool rate modifiers).
- **Tradeoff:** The nose-pitch charge means the camera and pitch controls become a gameplay input, not just a view preference. Players who dislike this may need an alternative control option.
