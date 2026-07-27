# Animation Architecture

How animation is driven, structured, and connected to game logic. For character-specific animation states and clip assignments, see the relevant character doc under `game-design/gameplay/player-characters/`.

---

## Tool: Animancer (not Mecanim)

All character animation uses **Animancer** (`AnimancerComponent`) rather than Unity's Animator Controller system. Animator Controllers are never assigned — the `Animator` component's Controller slot stays empty. Animancer uses the `Animator` component internally but bypasses its graph entirely.

This means:
- Clips are played directly in code: `_animancer.Play(clip)` — no parameters, no transition conditions, no graph to maintain
- State machine logic is plain C# (see below), not a visual graph with hidden implicit behavior
- `DirectionalAnimationSet4` assets handle 4-directional clip selection without a blend tree

Do not add Animator Controllers to character prefabs. If one appears (e.g. from an import), remove it.

---

## Prefab Structure

Every character splits into a root (physics and logic) and a `Visual` child (rendering and animation).

```
CharacterName (root)
  ├─ Rigidbody2D
  ├─ GridMoverComponent
  ├─ [CharacterType]Component           ← e.g. ThiefComponent, ViperComponent
  └─ Visual (child GameObject)
       ├─ SpriteRenderer
       ├─ Animator                      ← required by Animancer; Controller slot empty
       ├─ AnimancerComponent
       └─ [CharacterType]AnimancerController
```

The split exists so the Animator can move the `Visual` child's local transform (walk bob, lean offsets) without interfering with `Rigidbody2D` physics interpolation on the root. If `SpriteRenderer` lived on the root, animation-driven position offsets would conflict with `MovePosition()`.

---

## Communicating Logic to Animation

Logic components fire C# events (Tier 3 — see `technical/game-events.md`). The character's `AnimancerController` on `Visual` subscribes in `OnEnable` and drives the Animancer state machine in response.

```
GridMoverComponent  ──OnStopped──────────────►  [Char]AnimancerController
                    ──OnMoverStarted──────────►        │
                    ──OnDirectionChanged──────►        │  drives
                                                       ▼
ThiefComponent      ──OnBribeStarted──────────►  Animancer StateMachine
                    ──OnStealStarted──────────►
```

C# events are appropriate here because the animator controller and its source components are on the same prefab and are explicitly coupled by design. SO events are for cross-system broadcast (coin collected, character died) — not for intra-prefab wiring.

The `[CharacterType]AnimancerController` is the **only** component that calls `_animancer.Play(...)` or transitions animation state. No other component touches Animancer.

---

## State Machine Structure

States implement Animancer's `IState` interface (`CanEnterState`, `CanExitState`, `OnEnterState`, `OnExitState`). The machine is `StateMachine<IState>`, initialized in `Awake` and transitioned with `TrySetState(nextState)`.

Starting states for any grid-moving character:

| State | Entry trigger | Animation source |
|---|---|---|
| `IdleState` | `OnStopped` | `DirectionalAnimationSet4` idle asset |
| `WalkState` | `OnMoverStarted` | `DirectionalAnimationSet4` walk asset |
| (future) ability states | ability events from character component | single `ClipTransition` per action |

Keep states small. A state class over ~50 lines is likely doing too much.

---

## 4-Directional Animation

Use `DirectionalAnimationSet4` ScriptableObject assets for any animation that varies by direction. Each asset holds four `AnimationClip` references (Up, Right, Down, Left) and selects the right one via `set.Get(direction.ToVector2())`.

Create sets in the Project window: **right-click → Create → Animancer → Directional Animation Set → 4 Directions**.

Asset naming: `[CharacterName]-[AnimationName].asset` (e.g. `Thief-Walk.asset`, `Thief-Idle.asset`). Store alongside the character's art under `Art/Characters/[Type]/Standard/`.

---

## Composition vs. Inheritance

Each character type gets its own `[CharacterType]AnimancerController` MonoBehaviour — no shared base class until two concrete characters demonstrate real overlapping logic. Shared **data** (the `DirectionalAnimationSet4` assets) is reused via ScriptableObject references; shared **code** is extracted only when clearly warranted.

---

## No Mecanim Parameters

Animancer replaces Mecanim parameter-based control entirely. There are no `Animator.SetBool`, `SetFloat`, or `SetTrigger` calls in this project. State transitions are explicit `TrySetState(...)` calls. If a pattern seems to require a Mecanim parameter, that is a signal the wrong tool is being used.
