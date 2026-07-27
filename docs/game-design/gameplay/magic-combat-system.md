# Magic Combat System

Full detail lives in the Obsidian Vault: `ProjectFantasyX/Mechanics & Systems/The Magic Combat System/`.

---

## Overview

The magic combat system is the core mechanical expression of Nature Magic and Arcane in gameplay. It is built around three concepts: **Ability Slots**, **Orbs**, and **Spell Types**.

1. Story progression unlocks **Ability Slots** (tied to equipment pieces — see `game-design/gameplay/abilities.md`).
2. Elemental **Orbs** (gemstones) are slotted into those slots to unlock spells.
3. Each slot has a fixed **Spell Type** (Projectile, Melee, Trap, etc.) — the Orb determines the element of that type.

When an ability slot is first unlocked, the character can perform the action but with no effect until an Orb is inserted.

---

## Mana

Mana is the resource powering all magic. It is described lore-wise as the spiritual life-essence of all things in Elythia — elemental, color-coded, and present in all living matter.

**Gameplay resource model — current thinking:**

- Each spell costs 1 Magic Point (MP).
- Each MP = 10 mana units.
- Mana generates by dealing non-elemental (physical) damage — damage dealt = mana gained (1:1).
- Mana also drops from enemies and destructibles as collectible bubbles (1 / 5 / 10 / 20 mana by size).
- Charged spells cost additional MP per charge tier (e.g., Fire = 1 MP, Fira = 2 MP, Firaga = 3 MP) — [TBD: whether this is explicit tiered spells or a charge-hold mechanic].
- Alternative model under consideration: KH2-style auto-regenerating mana bar for Arcane; KH1-style generated mana for Elemental. [TBD — unresolved]

---

## Spell Types

Each Ability Slot has a fixed Spell Type. The Orb inserted determines the element. Spell Types:

| Type | Description |
|---|---|
| Attack 1: Melee | Standard melee combo (Kael: 3-hit sword; Rina: ranged projectiles) |
| Attack 2: Charge Melee | Charged melee attack |
| Cast: Projectile | Ranged elemental projectile |
| Cast: Charge Projectile | Charged ranged projectile |
| Cast: Status Effect | Applies an elemental status ailment |
| Cast: Charge Status Effect | Charged status effect |
| Cast: Status Effect Trap | Places a trap that triggers a status effect on contact |
| Ascent: Up Special | Upward recovery/offensive move |
| Crash: Down Special | Downward offensive/movement move |
| Mobility: Side Special | Horizontal mobility/offensive move |
| Defense: Block | Damage-reducing or nullifying guard |
| Defense: Evade | Evasive movement (roll/dash) |
| Super Attack | Ultimate attack tied to the Super meter |

---

## Elemental Status Effects

Each element applies a unique debuff. Current assignments:

| Element | Status Effect | Description |
|---|---|---|
| Fire | Burn | DoT; flinches target; rolling reduces duration; water douses |
| Earth | Slow (Mud) | Reduces movement speed |
| Iron | Stun (Shockwave) | Hard CC; brief duration |
| Wood | Bleed (Thorn) | DoT triggered by movement and attacks; crouching removes stacks |
| Light | Blind (Flash) | Attacks miss; abilities misfire |
| Life | Heal (Recover) | Channel heal; interrupted by damage |
| Water | Silence (Bubble) | Prevents ability use [TBD: exact scope] |
| Ice | Freeze (Frost) | Full stop; shatter on attack for bonus damage |
| Lightning | Paralyze (Shock) | Every X frames of non-idle action, stuns for 0.5s |
| Wind | Sleep (Drowsy) | Exponentially slows to full sleep; attacked for bonus damage |
| Shadow | Fear (Scare) | Target flees |
| Death | Poison (Toxins) | DoT; reduces damage dealt by % |
| Arcane | Confuse (Befuddle) | Randomizes input directions at intervals |

Full detail: Obsidian Vault → `ProjectFantasyX/Mechanics & Systems/The Magic Combat System/Elements/Elemental Status Effects.md`

---

## Elemental Resistances & Damage Table

Arcane deals 2x damage to physical elements (Fire, Iron, Earth, Wood, Water, Ice, Wind, Lightning) and 0.5x to spiritual elements (Life, Death, Light, Shadow, Arcane).  
Arcane takes 2x damage from spiritual elements (Life, Death, Light, Shadow) and 0.5x from physical elements.

Full resistance table: Obsidian Vault → `ProjectFantasyX/Mechanics & Systems/The Magic Combat System/Elements/Elemental Damage.md`

---

## Kael vs. Rina — Magic Asymmetry

**When playing as Kael:** Kael has Sun-side elemental abilities unlocked from boss crystals (Fire, Earth, Iron, Wood, Light, Life). Rina (the unchosen twin) is sent to the Prison Tower and taught only Arcane — she becomes a powerful Arcane caster with no elemental versatility except her innate Shadow Super.

**When playing as Rina:** Rina collects Moon-side elemental abilities (Shadow, Water, Ice, Wind, Lightning, Death). Kael becomes a spellsword who enhances his attacks with Arcane and gains Arcane-based mobility (e.g., teleport) but no elemental breadth.

This asymmetry means the two playthroughs feel mechanically distinct.
