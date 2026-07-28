# Economy

## Overview

The single-player economy has four interlocking systems: race winnings (primary income), junkyard trading (secondary income/sidegrade), part storage/warehouse (inventory management), and license progression (gate). The goal is a loop where the player races to earn money, spends it on better parts, and unlocks harder races with better payouts.

Two currencies exist: **Losallian Crowns** (general money) and **Elemental Cores** (mod-only currency from Archon Races).

---

## Currency

### Losallian Crowns ("Crowns")
Universal currency for all purchases, repairs, and upgrades. Earned from race winnings, junkyard flipping, and explicit part sales.

### Elemental Cores
Earned only from **Archon Races** (roguelike mode). Used to purchase elemental mods at nation-specific shops. Cores come in typed variants (Fire, Water, Earth, Wind, Lightning, Ice, Wood, Iron). Nation shops stock cores of their native element at a discount; off-element cores cost more.

---

## Income Sources

### Race Winnings
- Based on finishing position and race difficulty (circuit tier).
- Higher difficulty = higher payout spread.
- Prize distribution can be configured per tournament: equal split (default) vs winner-take-all (more risk/reward).
- Archon Races have massive payouts but permadeath.

### Mercenary Races
- Jump into a random race on a random track with random AI opponents with randomized loadouts.
- Pays Losallian Crowns based on performance relative to expectations — beating opponents with better gear pays more.

### Difficulty & Payout
- Difficulty selection controls both AI opponent strength and prize payout — unified into one slider.
- Higher difficulty = stronger AI racers + larger first-place reward.
- Lower difficulty = easier AI + smaller payout.
- Replaces EP1R's Fair/Skilled/WTA system (which only controlled purse split independent of AI).

### Junkyard Flipping (EP1R baseline + expansion)
- Buy used parts cheap, repair them, sell at profit.
- **EP1R limit:** flipping is finite because parts only damage on first-time race wins. Our version retains this limit but adds **explicit selling** so players can liquidate parts without needing a trade-in target.
- Risk: heavily damaged parts may cost more to repair than they are worth.
- Reward: high-end used parts appear in the junkyard at fractions of new cost, even before the tier is unlocked in shops.

### Explicit Part Sales
- **Divergence from EP1R:** Any owned part (equipped or in storage) can be sold directly for its current market value.
- Market value = base tier value × condition percentage.
- Enables liquidating unwanted parts without needing a buyer for trade-in.

---

## Spending

### New Parts (Nation Shops)
- Purchased from nation-specific shops. Each nation's shop specializes in its native element's mod parts.
- Prices scale with tier (see [pod-stats.md](pod-stats.md) for EP1R reference costs).
- **Trade-in subtraction (EP1R rule):** When buying a new part, the shop subtracts the value of the player's current equipped part from the price. The player only pays the difference.
- Parts unlock based on License Rank (not race-count).

### Used Parts (Junkyard)
- Randomized inventory of one part per stat slot.
- Parts appear at random damage levels (never perfect, never destroyed).
- **EP1R rule:** Any part can appear even if not unlocked in shops yet — a lucky find can skip tiers.
- Price = base value × (1 - damage_ratio).
- **EP1R rule:** Inventory resets when leaving the junkyard screen (e.g., going to racer select).
- Must be repaired before equipping or trading in.

### Repairs

**EP1R baseline:** In-race repairs by holding R — repairs the most-damaged segment first, takes the engine briefly offline (pod slows, handles poorly), and only restores to yellow condition (never full green). The pod's **Repair Rate** stat governs how fast this in-race repair cycles. The EP1R garage is view-only (item health bars, pit droid status, shortcut to shop). Pit droids auto-repair between races: each droid fixes one damaged component, targeting the 4 most expensive parts not at full health.

**ArcwingRacers divergence — Garage paid repairs:**
- Pay Losallian Crowns to repair damaged components between races.
- Cost scales with damage severity only. The pod's **Repair Rate** stat does NOT affect garage costs — it only governs in-race repair speed as in EP1R.
- Pit droids still provide free post-race repair (EP1R behavior, retained), but only target **equipped** parts (not stored parts).
- In-race hold-R repair mechanic kept as-is from EP1R.

### Elemental Mod Cores
- Purchased from nation shops using **Elemental Cores**.
- Each mod provides one of three bonuses: **Environmental Resist** (track hazard immunity), **Stat Modifier** (kiss-curse — increases one stat, decreases another), or **Perk** (conditional effect).
- Nations stock their native element's cores at a baseline price; off-element cores have a markup.

### Part Warehouse
- **Divergence from EP1R:** Players can store parts in a warehouse indefinitely, separate from their equipped loadout.
- Stored parts do not degrade.
- Enables collecting multiple loadouts for different tracks without forced carry limits.

---

## License Progression

The player's **Racer License** rank determines:
- Which tournaments/races are available
- What tier of parts can be purchased in shops
- Maximum winnings multiplier

License rank increases by accumulating **license points** from race placements. Winning a race awards the most points; top-half finishes award fewer points but still contribute. Bottom-half finishes award none.

Progression is NOT tied to number of races completed (unlike EP1R's 2/4/6/8/10/12/14/16 race gates). A player who wins hard races early ranks up faster than a player who grinds easy ones.

| License | Requirements | Unlocks |
|---|---|---|
| Novice | Default | Amateur Circuit, Tier 1–2 parts |
| Amateur | Win 3 Amateur races | Semi-Pro Circuit, Tier 3 parts |
| Pro | Win 3 Semi-Pro races + 5 top-half finishes | Galactic Circuit, Tier 4 parts |
| Veteran | Win 3 Galactic races + 10 top-half finishes | Invitationals, Tier 5 parts |
| Champion | Win Invitational + 15 top-half finishes | Archon Races, Tier 6 parts |
