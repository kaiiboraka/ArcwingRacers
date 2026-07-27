# Experience and Levels

Leveling applies to the **Viper** specifically — Thieves don't level up in the same sense (their power comes from coin, not XP; see `gameplay/player-characters/thief-gameplay.md`).

## Gaining Experience

- If the health gained from eating would exceed your max health, the **excess is converted to experience** instead of being wasted.
- Once your experience "orb" fills, you level up and grow by 1 length unit. Any food value left over after that carries forward as experience toward the next level.
- `[TBD]` Eating may also grant a small amount of experience even when not overflowing past max health (a minimum or small % of food value) — this is an open design question about whether to allow players to indefinitely maintain their current level through eating alone, or to force a slow decline without overflow-eating.

## Per-Level Effects

- **Viper speed** increases by a small amount with each level.
- **Hunger drain rate** decreases by a set amount each level — see Hunger below.

## Hunger (= Health)

The hunger meter doubles as the Viper's health meter.

- **Drain rate:** A steady drain, expressed as a fixed % of max health per second. At Level 1, a full meter drains in 60 seconds. Each level adds 6 seconds to that duration, up to Level 15 (max), where a full meter takes 2.4 minutes to drain.
- Because max health also increases with level, a higher-level Viper needs to eat substantially more food to stay fed, even though the drain *rate* (in seconds-to-empty) has improved.
- No hunger drain occurs while **Satisfied**, **Stuffed**, or actively **Digesting** (health/experience increasing).

## Eating — Food Values

- **Eating a human** (Thief or Captive) restores 1 unit of food, worth 100 health. At Level 1, this is enough to level up from a single bite.
- **Eating a Viper** restores food value based on the eaten Viper's length: roughly `length / 3 + 1` units.

## Status Effects

### Stuffed

Triggered on reaching max health from eating anything (Thief, Captive, or Viper) — your health is always slowly draining, and eating restores it, so filling past 100% just plateaus you here instead of wasting the excess.

- Grants **15 seconds** of no hunger drain, plus a **+15% speed boost** (playtesting may remove the speed boost later if it doesn't feel right).

### Retrogasm

Triggered by eating a Viper of **exactly your own current length**.

- A Viper's own length is both the **upper limit of what it can eat** (you cannot target/eat a Viper longer than yourself — see the matching rule in `player-characters/viper-gameplay.md`'s Eating Vipers section) and the **trigger condition** for Retrogasm, when the eaten Viper's length matches your own exactly.
  - Minimum length **5** is required on the eaten Viper for Retrogasm to trigger — below that, eating a same-length Viper just gives normal Stuffed status instead.
- **Duration: 60 seconds** of no hunger drain. This is also the window to find the **Secret Treasure Cave** — see `world/locations/secret-cave.md`.
- **25% speed penalty**, and you stagger/turn randomly, out of full player control, with stars floating above your head.
- **No distinct Viper visual:** Vipers never have a separate "adult" vs. "baby" appearance at any length. A Viper's size is only ever expressed as its body length (head + 1–n body segments + tail); there's no alternate skin/sprite tied to size or to entering Retrogasm.
- `[TBD]` If you grow further during the Retrogasm window by also eating the digested Viper's Thief/Captives, do you fall out of the "exactly the same length" condition retroactively?

See `world/locations/secret-cave.md` for the cave's interior, music, and the "Retrogasm" achievement.

### Hungry
Triggered when health drops below 25% of max health.

- All pickup/steal options are skipped — you will **always eat** an available target instead (overrides the normal Pickup/Bite/Steal decision logic in `viper-gameplay.md` and `thief-gameplay.md`).
- 25% speed penalty.
- Health vial flashes red.

## Sensing

Vipers can sense an approaching character slightly off-screen, before it's visible, via a tongue-flick animation. `[TBD: source material raises the idea of distinguishing the flick animation for threats (other Vipers) vs. food (Thieves/Captives), but doesn't confirm it as final.]`
