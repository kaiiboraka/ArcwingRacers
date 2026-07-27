# Art Direction

Visual design decisions for Fantasy X.

---

## Rendering Resolution

Internal resolution: **640×360**. Scaled 2× to 1280×720 or 3× to 1920×1080. Character portraits are 112×112 px at 360p (336px at 1080p). See `technical/code-standards.md` for full spec and the TODO to write a resolution ADR.

---

## Dialog Portraits

Portraits appear **in-scene** — no full-screen dialog takeover. They are positioned in the ~5-tile "unimportant" border region of the screen, chosen so the main actors and gameplay are never obscured.

A **black gradient** sits behind each portrait box to prevent art from blending into the environment background.

This is a confirmed design decision.
