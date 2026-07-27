# State Machines & NPC Behavior

Technical patterns for structuring decision-making logic — NPC AI, multi-step actions, menu/screen flow. This is architecture, not behavior: it doesn't decide what a Viper or Thief does, only how that decision logic should be structured so it's testable and not glued into Unity components it doesn't need. Game-design intent for specific NPCs lives in `game-design/gameplay/enemies/ai-behavior.md` and the relevant NPC docs.

---

## Choosing a Structure

| State count / complexity | Use |
|---|---|
| 2-3 states, simple transitions | A plain `if`/`else` or `enum` switch — a state machine is overkill |
| 4-8 states, clear transitions | A code FSM (states as plain C# classes) |
| 8+ states or combinatorial transitions | A Behavior Tree |

**Don't use Unity's Animator as a logic state machine.** Animator evaluates every frame even when nothing changes and no animation is visibly playing — real overhead for what should be free when idle. Reserve Animator for what it's for: animation. Drive decision logic with plain C# classes per `technical/code-standards.md`'s script-architecture hierarchy.

## States as Plain C# Classes

Follow the same testability pattern as `technical/testing.md`'s `HungerSystem` example — a state is a plain C# object, constructed with `new`, fed a `Tick(float deltaTime)` call rather than reading `Time.deltaTime` itself. This keeps state logic unit-testable without a running scene and keeps the time source injectable (a test can tick arbitrary deltas without waiting in real time).

## Behavior Trees

If complexity crosses into Behavior Tree territory: cache the currently-running node and resume from there next tick rather than re-evaluating the whole tree from the root every frame — re-evaluating from root on every tick is the most common BT performance mistake.

## Layered NPC Architecture

For NPC AI specifically, separate concerns into independently testable layers:

- **Perception** — what the NPC currently knows (nearby targets, threats). Poll on an interval (e.g. every few frames), not every frame — continuous raycasts/overlap checks for every NPC every frame is wasted CPU on mobile.
- **Decision** — given perception, what the NPC wants to do. Tunable thresholds (aggro range, flee distance) belong on a `ScriptableObject` config asset per NPC type — the same SO-as-shared-config pattern already used elsewhere in this project (`technical/singleton-controllers.md`) — so designers can retune behavior without a code change.
- **Action** — executing the chosen behavior. Model timed actions (Bribe, Steal, Bite — see `systems/action-range.md`) as explicit phases: wind-up → execute → recovery, so an interruption during wind-up correctly cancels the action instead of letting it land anyway.
- **Coordination** (only if needed) — logic that spans multiple NPCs. Keep this as its own layer rather than letting individual NPCs reach into each other directly.

**Anti-pattern:** a shared static "blackboard" that all NPCs read and write. This is the same problem as any other static shared state banned in `technical/code-standards.md` — it bleeds state between NPCs, breaks test isolation, and behaves differently in edit mode vs. play mode. If NPCs need to share information, do it through an explicit reference (a `Variable<T>` asset, or a coordinator object handed to them at spawn) — not a static field.
