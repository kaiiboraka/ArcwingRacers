# Localization

Scope: all menu/UI text, system messages, and NPC dialogue (the game has some, but it's light — see `systems/dialog.md`). Target language list is **[TBD]**; this doc covers the *system*, not which languages it ships configured for.

---

## Backbone

Use Unity's official **Localization** package (`com.unity.localization`). It provides String Tables (translator-handoff via CSV/Google Sheets), Smart Strings (pluralization), Asset Tables (per-locale font/sprite/audio fallback), and runtime locale switching — don't hand-roll any of this.

**Not installed yet.** Per `agent-context/agent-rules.md`, adding it needs sign-off before implementation — this doc describes the intended architecture.

A String Table Collection is, under the hood, a `ScriptableObject` asset per locale holding key → string entries — the same shared-data-on-an-asset pattern as this project's `Variable<T>`/`GameEvent` assets (`technical/game-events.md`).

Don't write a project-authored `LocalizationManager : MonoBehaviour` with a `static Instance`. Access the package directly through its own static API (`LocalizationSettings.SelectedLocale`, `LocalizationSettings.StringDatabase`) — same as `SceneManager`, `Time`, or `Input`. It's engine-level infrastructure, not a system this project owns, so the `technical/singleton-controllers.md` carve-out doesn't apply and a wrapper singleton would only add a maintenance layer with no benefit.

---

## Architecture

### String Tables

One Table Collection per logical grouping, not one giant table:
- `UI` — menu labels, buttons, system messages, HUD text
- `Dialogue` — NPC lines, keyed per speaker/line ID. One table is enough — this isn't a dialogue-heavy game.
- `ItemNames` — loot/relic display names, if and when those ship localized — **[TBD]**, depends on `game-design/loot/` content decisions not yet made.

### Binding to UI

Never put a raw string directly on a `TMP_Text` in the Inspector for anything player-facing.

- **`LocalizedString` field** — on a `[SerializeField]` field on a MonoBehaviour or a config `ScriptableObject` (e.g., an item's display name); resolves to the active Locale automatically.
- **`LocalizeStringEvent` component** — next to a `TMP_Text`; raises a `UnityEvent<string>` on string change (including locale switch), consumed via a normal Tier 2 handler. Same `UnityEvent` pattern as `technical/game-events.md` — no new event mechanism for localized UI text.

### Reacting to a Locale Change

`LocalizationSettings.SelectedLocale` is the current-locale state — don't wrap it in a project `Variable<T>`; that would create a second source of truth.

If a non-package-driven system needs to react to a language change (custom HUD relayout, a confirmation sound), bridge `LocalizationSettings.SelectedLocaleChanged` into a project Tier 1 `LocaleChanged` `GameEvent` from one thin, bootstrapper-wired adapter — only if more than one decoupled system needs to know. A UI panel reacting to its own `LocalizeStringEvent` doesn't need this.

### Pluralization & Formatting

Use **Smart Strings** for any text with a count (`"{count} coin" : "{count} coins"`) — relevant to `systems/currency-value.md`'s denomination display and any item-count UI. Don't hand-roll plural logic with string concatenation.

### Fonts & Non-Latin Scripts

The project's pixel-art font(s) may not have glyphs for every target script (CJK, Cyrillic, RTL). **[TBD]** — target language list isn't decided, so per-locale font fallback via Asset Tables is unresolved. Flag before adding any non-Latin locale.

---

## What Not to Localize Through This System

Sprites, audio, video — anything that's an asset, not a string — use Asset Tables if they ever need to vary per locale (e.g., a sign with painted-in text), not the String Table system.
