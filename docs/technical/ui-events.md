# UI Events

UI wiring is Tier 2 in the project's event model — see `technical/game-events.md` for the full three-tier breakdown. UI elements wire to `UnityEvent`s in the Inspector; they don't hold direct references to gameplay systems.

---

## Avoiding GC in UI Updates

Any UI element that updates frequently (HUD coin count, hunger meter, timers) is a steady-state allocation risk per `technical/code-standards.md`'s zero-allocation target:

- Use `TMP_Text.SetText("Score: {0}", value)` instead of string concatenation (`"Score: " + value`) — `SetText` with format args avoids the intermediate string allocations that `+` and `string.Format` both produce.
- Split static UI (background panels, fixed labels) and frequently-changing UI (HUD counters, animated elements) onto **separate Canvases**. A `Canvas` rebuild batches and re-batches everything under it on any child change — mixing static and dynamic elements on one Canvas means static content gets needlessly re-batched every time a counter ticks. (See `technical/code-standards.md`'s draw call budget section.)

## Lifecycle

UI components that subscribe to `GameEvent`/`Variable` listeners follow the same `OnEnable`/`OnDisable` pairing rule as everything else in `technical/code-standards.md` — a UI panel that gets shown/hidden via `SetActive` will only re-subscribe correctly if subscription happens in `OnEnable`, not `Start`.
