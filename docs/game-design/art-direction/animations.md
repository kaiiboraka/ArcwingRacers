# Animations

## Framerate

Sprite animation should look **really smooth**. Framerate is a quality bar, not an afterthought.

## Snake Movement

Vipers move like the classic game of Snake — the body follows each turn the head makes (conga line behavior).

**Implementation notes:**
- Each snake image tile needs its own object, with its own position and animation state.
- Each piece follows the one ahead of it.
- As a piece turns to face a new direction, a **transition animation** is needed to connect the two directions smoothly.
- The tail follows the body tiles.
