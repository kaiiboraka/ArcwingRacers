# AI Opponents

## Overview

AI opponents fill empty racer slots in every game mode. They use the same input buffer as human players — the AI decision system writes steering, boost, brake, shield, and ability inputs each tick, and the pod physics reads them identically.

AI behavior is built on three layers:

```
AIPersonality (preset resource)
  └── Difficulty multiplier (harder = amplified)
       └── Character trait overrides (1-2 specific stats hard-coded per racer)
            └── Result: drives steering, boost, combat, ability decisions
```

---

## Three-Layer Model

### 1. Personality Preset

A data resource defining an AI's baseline behavior. Named presets that can be assigned to any racer.

| Preset | Lookahead | Boost Aggression | Ram | Ability Use | Shield Use |
|---|---|---|---|---|---|
| Balanced | Medium | Medium | Low | Medium | Medium |
| Aggressive | Short | High | High | High | Low |
| Precision | Short | Medium | Low | Medium | High |
| Reckless | Long | Very High | High | Low | Low |
| Defensive | Medium | Low | Low | Low | High |
| Cautious | Long | Low | Very Low | Medium | Medium |
| Hot-Headed | Short | High | High | Very High | Low |

New presets can be added by creating a new `.tres` file.

### 2. Character Trait Overrides

Each racer has 1-2 permanent personality overrides that always apply, no matter which preset they're assigned. For example:

- A Fire Nation racer might always have high `ability_usage` regardless of preset
- An Earth Kingdom racer might always have high `ram_aggression`
- An Ice Nation racer might always have high `shield_usage`

These are stored in each racer's character data and are immutable. They represent the racer's innate tendencies.

### 3. Difficulty Multiplier

The difficulty setting (Easy/Medium/Hard/Expert) multiplies all AI personality values. Higher difficulty = amplified traits:

| Setting | Multiplier | Effect |
|---|---|---|
| Easy | 0.6 | Subdued personalities — less aggressive, less precise |
| Medium | 1.0 | Baseline — presets as designed |
| Hard | 1.3 | Sharper — more aggressive, more precise, more ability usage |
| Expert | 1.6 | Max — every trait is strongly expressed |

---

## Tournament AI Persistence

Each tournament save locks in its AI opponents from start to finish. The same characters, personalities, and loadouts appear in every race — creating memorable rivalries ("that Fire Nation racer always rams me on the last lap").

At the start of a new tournament save:
1. Each slot gets a **random character** from the unlocked roster (excluding the player's choice)
2. That character gets a **random personality preset** assigned
3. They get a **randomized component loadout** within the difficulty tier's quality range, drawing from generic, element-less, and element-matching components

Characters themselves have fixed identities (favorite chassis, wielded element, preferred tracks) that never change. Only the personality preset and component loadout re-roll between tournament saves.

### Track Affinity

Each racer has a small number of tracks they excel at (their "favorite" or "home" tracks). On those tracks, all their effective AI stats get a ×1.15 multiplier — they steer sharper, boost more often, react faster. This is baked into the character and never changes.

Affinities create natural spread without a random parameter: an aggressive racer on their home track is a serious threat; the same racer on a neutral track is simply aggressive. Players learn which opponents to watch out for on each track.

(TODO: Affinity data will use a proper track resource reference once the track data model is defined — not a fragile string array.)

---

## Difficulty & Loadouts

Higher difficulty tiers allow higher-quality components in the randomized loadout:

| Setting | Component Tier Range | AI Level Equivalent |
|---|---|---|
| Easy | Tiers 1–3 | Low |
| Medium | Tiers 2–5 | Medium |
| Hard | Tiers 3–6 | High |
| Expert | Tiers 4–6+ | Very High |

Each AI racer gets a randomized mix of components within their tier. Two AI racers at the same difficulty will have different stats, creating variety.

---

## Combat Behavior

AI racers can:
- **Ram:** Intentionally steer toward nearby opponents. Higher ram_aggression = harder swerve.
- **Avoid:** Dodge incoming collisions (races with high avoidance). Not mutually exclusive with ramming — a racer with both high ram and high avoidance will ram targets but dodge when being rammed.
- **Shield:** Raise shield when an opponent is nearby and using an ability. Higher shield_usage = more reactive.
- **Parry:** If shield is raised, chance to parry based on parry_ability stat.
- **Abilities:** On each tick where an ability is available (off cooldown, enough mana), roll a chance check. Higher ability_usage = more likely to fire.

---

## Slot Filling

**Campaign/Tournament:** Always 16 racers. AI fills all slots not taken by human players.

**Multiplayer lobbies:** Configurable slot count. Players can manually assign human or bot to each slot.

**Single Race (offline):** Same lobby structure — local players (split-screen) vs bots. Slot count and bot count are configurable.

AI never uses a character the human player has selected. Bot characters are randomly picked from the unlocked roster minus player selections.
