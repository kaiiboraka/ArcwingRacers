# Thief Gameplay

## Core Identity

As a Thief, money is your power and your protection. Collect as much coin as possible — it determines who you can bribe, who you can steal from, and ultimately whether you can reach the King. You really need a paired Viper to get around fast and take on powerful enemies.

Be prepared to switch loyalties and get a better Viper if you have the chance — your "pet" is doing the same, always looking for the best Thief to pair with. Failing to stay competitive may make you look like a tasty snack, even to your own Viper.

## Strategy Note

If you lose most of your money, you can no longer steal effectively — but you likely still have a large Viper by that point, so you can still extract large bribes from other Thieves instead.

## Coin Purse

- Default coin purse: minimum 1 silver, maximum 1,000 silver.
- The minimum is what the purse protects from other thieves (can be improved with the right relic).
- If you max out at 1,000 silver, return to town and deposit at the Bank.
- See `systems/currency-value.md` for full coin denomination rules.

## Thief Buttons

**[Update]** Goal: consolidate to a single Thief button slot. The button's icon and action change based on target/context.

### Bribe / Steal
Targets opponent Thieves, Castle Gate Guards, or Hermits.

- **Bribe** is available when the target Thief has a paired Viper **bigger than yours** (or has a Viper while you have none). Lone Thieves, and Thieves whose Viper is the same size or smaller than yours, cannot be bribed at all — Steal is the only option against them.
- **Steal** is available when the target has **less money than you**, regardless of Viper size, subject to the range rules below — though you cannot land a *successful* steal against a bigger-Viper target even within range (see Steal detail).
- These are two independently-triggered systems, not opposite ends of the same toggle: a target can be Bribe-eligible (bigger Viper) while simultaneously being Steal-proof (that same bigger Viper blocks a successful steal).

**Bribe:**
- **Cost:** the target's Viper **size (body length)** × a flat **5 silver per unit of length** (per the archive's `BRIBE_PRICE_PER_BODY_LENGTH` constant — a starting balance value, not necessarily final). This is based on Viper **size**, not Viper **level** — the two roughly track together (a Viper grows 1 length unit per level-up), but aren't strictly identical, since Vipers start at 3 length before reaching Level 1.
- Paying the bribe makes the target (and their Viper, if any) leave you alone for **60 seconds** (`BRIBE_SECONDS` in the archive). Can't be repeated on the same target until that timer expires.
- A blue silhouette glow indicates bribed Vipers/Thieves. The action icon shows the bribe cost as currency icons above an open hand.
- If you don't have enough silver, the bribe action is still offered (so the threat is visible), but the target reacts with a "not enough money" emote instead of leaving you alone.

**Steal:**
- Requires you to have **≥ the target's money**, and the target must have some stealable amount above their protected minimum.
- Steals **10–25% of the target's money** (matches the archive's `STEAL_PERCENT_MIN`/`STEAL_PERCENT_MAX` constants).
- The victim shows a floating "hit damage"-style currency readout with a red minus sign as the stolen amount is taken.
- **Two range tiers:** at **Body Range** (1 adjacent tile, collision), Steal triggers automatically — no tap needed (the bump-into-a-thief auto-steal/auto-be-stolen-from case, decided by who has more money). At the larger **Action Range** (the 2×3 zone described below), Steal is something you can proactively trigger with the action button while in range — including while just passing the target, or while mounted on a Viper. See `systems/action-range.md`.
- If two colliding Thieves have equal money, **both** trigger a steal on each other and both get knocked back (the random stolen-amount roll may still favor one of them).
- **Lone Thief target:** steal radius is roughly a 2×3 tile zone in front of/beside the Thief. After a successful steal, the victim is knocked back and briefly invulnerable to further stealing (~0.5s), then can be stolen from again once you catch back up.
- **Target riding a Viper:** the steal radius extends to cover either the Thief or the Viper's head. You **cannot** successfully steal from a Thief whose Viper is bigger than yours (their Viper snaps at yours and damages you if you try) — the same Viper-size check that makes them Bribe-eligible above. Whether you can steal from a Viper-mounted Thief at all while on foot (vs. needing your own Viper) remains uncertain in source material. A successful steal here has **no knockback delay**, but the target Viper auto-redirects away from you, so you have to chase it down to steal again.

**Bribing a Castle Gate Guard (Vocal Range):**
- If you have enough money for the monumental bribe, you're granted entrance to the castle.
- If not, the guard shakes his head and asks for more (coin jingle animation).

**Bribing the Hermit:**
- Gets him to share a hint. Hints come in 4 tiers: Beginner, Intermediate, Advanced, Top Secret.
- Each tier increases in value and cost (1sc, 1gc, 1gb, 1gob).
- You start with all the lowest-tier hints unlocked.
- If you can't afford the next tier, he jokes about inflation.
- If you're destitute (coin = minimum purse), he gives you 3 silver coins and a comment instead of a hint — so you're never completely stuck, and can grind T1 hints for free.

### Ally / Betray
Pairing is automatic: a Thief and Viper pair whenever they intersect on the same tile (e.g., running into the Viper's head) and neither already has a partner — no button needed. May be implemented as a Viper-side pickup action rather than Thief-side logic.

Betrayal and other targeted outcomes trigger by overlapping a tile with another Thief, Viper, or Guard that already has a partner.

**Targeting a Viper:**
- Viper has a Thief with less money than you → Viper betrays its Thief (eats them) and takes you on. You hop off your current Viper.
- Viper has a Thief with more money than you → Viper ignores you.

**Targeting an allied Viper (wingman, not your paired Viper):**
- Marks it for betrayal. You can now eat it by moving over its tail (ally tails are normally passthrough).

**Touching a Prison Guard:**
- Button becomes **Purchase Captive** action.
- Requires a paired Viper with an open Captive slot (see `viper-gameplay.md`'s slot capacity rule) — a lone Thief with no Viper cannot purchase a Captive at all.

## Outlaw Bounties

`[Source: iphone-notes.txt; TBD — sketched in source, not fully specified]` When an NPC Thief (see `gameplay/enemies/ai-behavior.md`'s Thief AI) maxes out their coin purse (1,000 silver — see Coin Purse above), an Outlaw wanted sign is hammered into the ground outside town. Killing that Thief out in the world and returning to the sign claims a bounty reward.

`[TBD]` Not specified in source: how the player identifies which NPC Thief the sign refers to out in the world, what "killing" them means mechanically for a Thief target (presumably a successful Steal/Betray-equivalent rather than a Viper bite, since this is Thief-on-Thief, but unconfirmed), the bounty reward amount, and whether multiple signs/bounties can be active at once.

## Special Characters

### Thief Lord (Unlockable)
Unlocked by beating the game as any Viper character. Replaces player Thieves with the Thief Lord.

- **Ability — Coin Purse:** The first 10 gold coins earned are held in reserve in the Coin Purse and are not stealable by other Thieves.
- **Rarity:** Legendary (Tier 5) — a permanent unlock, exempt from the Character Token spend/consume economy. See `loot/item-rarity.md`.
- `[Source: iphone-notes.txt; speculative — posed as a "?" in source, not committed design]` **Possible extra hideout:** an additional, Thief-Lord-exclusive tavern-only town that doesn't trigger a map regeneration when entering/exiting (unlike normal town visits — see `world/locations/town.md`). `[TBD]` What this hideout would actually offer beyond skipping map regen isn't specified.
