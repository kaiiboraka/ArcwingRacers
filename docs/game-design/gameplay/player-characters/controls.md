# Controls

## Movement

**Swipe left, right, up, or down** to turn in that direction.

- **Vipers** cannot turn backwards — they must U-Turn (turn left twice or right twice).
- **Thieves** can make immediate reversals.

## Action Buttons

At any time there are either:
- **2 buttons** if playing solo
- **4 buttons** if paired (Thief button + Viper button, each side)

When an action is available, the button **brightens** to prompt you. The button icon may also **change automatically** with context to show the best available action for the current target/situation.

See `systems/action-range.md` for how targets are selected and range rules.

## Thief Button (Bottom Left)
- **Bribe / Steal** — context-dependent based on target's wealth relative to yours
- See `gameplay/player-characters/thief-gameplay.md` for full action details

## Viper Button (Bottom Right)
- **Bite / Release** — Eat a Thief or human npc or latch onto a Viper tail. Once attached to a viper you are trying to eat, hitting the button again releases your quarry and frees your movement again.
- **Drop / Pick Up** — manage captives; becomes Betray Thief if no captives
- See `gameplay/player-characters/viper-gameplay.md` for full action details

## Touch Input Summary

- **Swipe** — turn the character (see Movement above).
- **Tap** — HUD button clicks, opening chests (see `loot/chests.md`), and triggering context/target actions.
- Both **landscape and portrait** orientation must be supported — see `gameplay/pause.md`.
