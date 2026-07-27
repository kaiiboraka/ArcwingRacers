# Testing

## Philosophy

**Test for confidence, not coverage.** Coverage metrics are vanity. The goal is to sleep well knowing the systems that matter can't silently break.

On a small team, untested code isn't automatically a problem — but *unverified critical logic* is. The question to ask before writing a test isn't "should I test this?" it's "what's the cost if this is wrong and I don't find out until a player hits it?" High cost → test it. Low cost → skip it and move on.

Tests are also code. They need to be read, maintained, and updated when design changes. A test suite full of stale, skipped, or trivially-wrong tests is actively harmful — it creates false confidence and maintenance debt. Only write tests you're committed to keeping correct.

**One practical rule:** if you find yourself manually re-testing the same logic after every change, that logic belongs in a test.

---

## Unity Test Framework

Unity uses **NUnit** via the Unity Test Runner (`Window → General → Test Runner`).

Two modes — know which to reach for:

| Mode | Runs in | Speed | Use for |
|---|---|---|---|
| **EditMode** | Editor, no Play Mode | Fast | Pure C# logic, ScriptableObject state, data validation |
| **PlayMode** | Real Unity scene | Slow | MonoBehaviour integration, scene loading, end-to-end flows |

Default to EditMode. PlayMode tests require scene setup, are an order of magnitude slower, and are more brittle. Only reach for PlayMode when you genuinely need Unity's runtime.

### Assembly Setup

Tests live in their own Assembly Definitions — never in the main runtime assembly:

```
Assets/_Project/Tests/
  EditMode/
    EditModeTests.asmdef    ← references your runtime .asmdef + Unity.TestFramework
  PlayMode/
    PlayModeTests.asmdef    ← same, plus PlayMode flag enabled
```

If tests aren't appearing in the Test Runner, the `.asmdef` setup is wrong — check references first.

### Test Runner Gotchas

- `Debug.LogError` (and `LogException`) **automatically fails the test it's logged in**, even if every `Assert` passes — including errors logged by unrelated code the system under test happens to call. If a test is expected to trigger an error path, wrap the assertion with `LogAssert.Expect(LogType.Error, expectedMessage)` or the test fails for the wrong reason.
- In PlayMode tests, replace hardcoded waits (`yield return new WaitForSeconds(5f)`) with `yield return new WaitUntil(() => condition)` — fixed waits make the suite slow in the common case and brittle in the slow one.
- CI invocation: `Unity -runTests -batchmode -projectPath <path> -testPlatform EditMode -testResults <path>.xml`, with `-testFilter`/`-testCategory` (semicolon-separated, `!` prefix to negate) to scope a run.

---

## What to Test

These are high-confidence, high-value targets. Pure logic with clear inputs and outputs.

### Currency & Economy
- Denomination conversion (silver → gold coins → bars → goblets → crown)
- Carry limit enforcement (max 1000 silver)
- Display threshold logic (which icon tier is shown for a given amount)
- Bribe/steal outcome determination (who has more money, what happens)
- Coin purse minimum protection

### Hunger & Health
- Drain rate calculation per frame/tick
- Satisfied bonus activation and expiry (100% full → 15s no drain)
- Death threshold (meter reaches zero)
- Growth on eat (correct length delta for thief vs. viper vs. captive)
- Digestion slowdown (% of snake length digesting → correct speed penalty)

### Loot & Drops
- Ad reward probability table sums to exactly 100%
- Rarity boundary conditions (verify edge cases don't fall through)
- Chest tier maps to correct loot pool

### Save & Load
- Round-trip serialization: every field that goes in comes back out correctly
- Handles missing or corrupted data gracefully without crashing
- Coin values survive a save/load cycle without rounding errors

### Map Generation & Wrapping
- Given the same seed, generation is deterministic
- Wrapped coordinates are always valid (no out-of-bounds)
- Edge tile transitions are valid (no impassable dead-ends at wrap seams)
- Special locations always spawn (castle, witch's lair) — never missing from a generated map

### Action Range
- Correct target selected when multiple in range (closest wins)
- Bribe range (vocal: 2 tiles) vs. steal range (action: 1 tile) are distinct and correct
- Body range (collision-only) does not trigger from non-collision events

### Viper Chase Logic
- Pursuing viper gains correctly on successful turn-matching
- Target escapes by correct amount on failed turn
- Straight-line gain rule fires at correct interval (every 5 units)
- Half-length growth calculation on successful eat (rounded down)

---

## What Not to Test

Don't waste time here:

- **MonoBehaviour lifecycle.** Unity tests it; you don't need to.
- **Visual output.** Animations, particles, shader effects — untestable meaningfully.
- **Audio playback.** Whether a clip plays is not a unit test.
- **Physics behavior.** Test your *response* to a physics event, not the physics itself.
- **UI layout.** Test the data driving the UI, not the pixel positions.
- **Input handling.** Test what happens *when input is received*, not the input system itself.
- **Anything requiring a full hand-crafted scene.** If setup takes longer than the test, it's probably not worth it.

---

## Architecture for Testability

This is why `code-standards.md` pushes logic into plain C# classes. A `MonoBehaviour` can't be instantiated with `new` in a test — it needs a running scene. A plain C# class can be constructed, fed inputs, and asserted against in milliseconds.

The pattern:
```csharp
// Testable — pure C# logic class
public class HungerSystem
{
    public float DrainPerSecond { get; }
    public float CurrentHunger { get; private set; }

    public void Tick(float deltaTime) { ... }
    public bool IsSatisfied() { ... }
}

// Thin MonoBehaviour — just wires Unity to the logic
public class ViperHungerComponent : MonoBehaviour
{
    private HungerSystem _hunger;
    void Update() => _hunger.Tick(Time.deltaTime);
}
```

`HungerSystem` is fully testable. `ViperHungerComponent` has no meaningful logic to test.

**Avoid static state in testable classes.** Static fields bleed between tests and cause ordering-dependent failures that are miserable to debug.

**Use interfaces for dependencies.** If a system depends on another, inject it as an interface. This lets tests provide simple fakes without mocking frameworks:
```csharp
public interface IMapQuery { bool IsPassable(Vector2Int tile); }

// In tests:
var fakeMap = new AlwaysPassableMap();
var system = new MovementSystem(fakeMap);
```

**ScriptableObjects** can be created in EditMode tests:
```csharp
var config = ScriptableObject.CreateInstance<ViperConfig>();
config.HungerDrainRate = 0.1f;
// test against config...
Object.DestroyImmediate(config);
```

---

## Test Structure & Naming

**Naming pattern:** `Subject_WhenCondition_ExpectedOutcome`

```csharp
[Test]
public void HungerSystem_WhenFullyFed_DoesNotDrainDuringSatisfiedWindow()

[Test]
public void CurrencyConverter_With39Silver_DisplaysOneBarAndTwoCoins()

[Test]
public void ViperChase_WhenTargetGoesStraightFiveTiles_PursuerGainsOneExtraBite()
```

**Arrange / Act / Assert** — every test, no exceptions:
```csharp
[Test]
public void HungerSystem_WhenHungerReachesZero_RaisesDeathEvent()
{
    // Arrange
    bool deathFired = false;
    var hunger = new HungerSystem(drainRate: 1f);
    hunger.OnDeath += () => deathFired = true;

    // Act
    hunger.Tick(deltaTime: 100f);

    // Assert
    Assert.IsTrue(deathFired);
}
```

One logical assertion per test. Multiple `Assert` calls are fine if they're all verifying the same outcome — but if a test needs 10 assertions, it's testing too many things.

**File naming:** `HungerSystemTests.cs`, `CurrencyConverterTests.cs` — matches the class under test, with `Tests` suffix.

---

## PlayMode Tests

Use only when you genuinely need Unity's runtime. Good candidates:

- Save/load round-trip that touches `PlayerPrefs` or the file system
- Scene loading and bootstrapper initialization
- A critical end-to-end gameplay path you've burned debugging twice
- Coroutine sequences running on a `MonoBehaviour` via `StartCoroutine` — EditMode's `[UnityTest]` can step through plain `IEnumerator` logic, but won't exercise Unity's real coroutine scheduler or frame timing

Each PlayMode test gets its own **minimal test scene** — don't reuse production scenes for tests. The scene should contain only what the test needs.

Mark slow PlayMode tests with `[UnityTest]` (returns `IEnumerator`) and keep their count small. A PlayMode suite that takes 5 minutes to run will be skipped.

---

## Maintenance Rules

- **Failing tests get fixed before the next commit.** No exceptions. A codebase with known-failing tests has no test suite — it has noise.
- **Skipped tests get deleted or fixed within one sprint.** `[Ignore]` is a temporary note, not a long-term strategy.
- **When design changes, update the tests.** A test asserting old behavior is worse than no test — it lies.
- **Don't test implementation details.** Test behavior and outcomes. If refactoring internal structure breaks tests without changing behavior, the tests were wrong.
