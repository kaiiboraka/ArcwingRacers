# Viper Gameplay

## Core Identity

Vipers are the movement and combat powerhouse. They grow by eating, have a hunger/health meter, and can partner with a Thief riding on their back. Speed, size, and timing are everything.

## Hunger & Health

- Vipers have a slowly draining hunger meter. If it runs out, the Viper dies.
- The hunger meter **is** the health meter. Larger snakes get more health, but hunger decreases at a flat percentage rate over time — so large Vipers need to eat more just to stay alive.
- Eating enough to reach 100% full gives a **"Stuffed" bonus** for 15 seconds where the hunger meter doesn't drain, plus a +15% speed boost. See `gameplay/experience-and-levels.md`'s Status Effects section for the full writeup, and the separate **Retrogasm** status triggered by eating a same-length Viper.
- See `gameplay/experience-and-levels.md` for full leveling rules, exact drain-rate-per-level numbers, food values, and the **Retrogasm** and **Hungry** status effects (not detailed here).
- **Hungry override:** Below 25% health, all Pickup/Steal decision logic below is skipped — a Hungry Viper always eats an available target outright.

**When a paired Viper dies:** if the player is controlling the Thief and their partner Viper dies (hunger reaches 0), the Thief is not eliminated — they keep playing solo. The Viper plays a purple death-fade animation and the Thief hops off (reusing the same dismount logic as the Drop/Boot Viper action), then the Thief's state resets to normal solo movement (no partner, not currently mounted, etc.).

## Eating

### Eating Thieves or Captives
- Moving over a lone Thief eats them, filling hunger and growing the Viper by 1 length unit.
- Crossing paths with a Thief on another snake's back snatches them up off their back.
- Eating a snake down to the last neck tile (where the riding Thief sits) eats the Thief; one more tile eats the snake's head.

### Eating Vipers
Eating other Vipers is very tricky but rewarding — you grow by half their length (rounded down).

You can only target a Viper whose length is **≤ your own** — a longer Viper can't be tail-locked or eaten at all (matches the archive's `CanLockOnTail` size check). Eating one of **exactly** your own length triggers the **Retrogasm** status instead of a normal kill — see `gameplay/experience-and-levels.md`.

A Viper can make its own tail untouchable by driving a head or body segment over it — see `gameplay/movement.md`'s Self-Tail Protection.

1. Move your head onto the tail of the target Viper and hit the **Bite** button. You lock on to their tail.
2. The targeted Viper will try to flee. If you follow each turn, you gain on it — eating one additional unit per successful turn.
3. If you fail to turn at the right time, they escape by 2 units (or a balanced amount) and you get jerked in their direction.
4. The pursued Viper cannot avoid making turns — every 5 units traveled straight allows the pursuer to gain 1 additional bite.
5. A pursuing Viper can release the bite at any time to give up the chase.
6. Eating the head ends the chase. You grow by half the target's length, rounded down.

### Digestion
- Eating creates a visible **bulge** that travels down the snake as it digests.
- You are slowed by the percentage of your snake length that is digesting. Swallowing a large snake leaves you very vulnerable.

## Viper Buttons

**[Update]** Goal: consolidate to a single Viper button slot. Context changes to fit the best available action for the target/situation, streamlining the interface.

`[TBD]` The "Vipers and Thieves Notes" Google Doc (2019) names two abilities — **Coil Up** and **Coil Strike** — under a "Viper Abilities" heading, with no further description. Not reflected in the buttons below since no mechanic is specified; flagging the names in case they're meant to be a third Viper action distinct from Bite/Release and Drop/Pick Up below.

### Bite / Release
Time your bite to clamp down on a Thief or Viper's tail. Hitting Bite again releases.

- **[Optional / Save for console]** Hold Bite to open mouth for faster reaction; release to snap shut. Requires reacting when the action is truly available instead of preemptively biting.

**Attackable NPCs:**
- **Hermit:** Side-steps the attack, whacks you on the head for minor damage.
- **Castle Gate Guards:** Eating one causes the other to pursue and attack. They give up if they get too far from the castle. Eating both guards triggers a squad of soldiers dispatched to hunt you indefinitely. Guards respawn over time.

### Drop / Pick Up Captive
Drops the last captive on your back (farthest from the head). The Viper bumps the Captive off its back; it flies through the air to land where the head would have gone straight.

- [Option] Hit Bite while the Captive is mid-air to snatch it back up.
- If you don't eat it, the Captive stays on the ground.

**If you have no Captives:** This becomes the **Betray Thief** action.
- Hit the flashing red Betray button on the Thief side first to confirm.
- On confirmation, the Thief is bumped off your back. You can then eat them.
- While waiting for confirmation, Drop/Pickup becomes Cancel.

**Upgrading your Thief:**
You cannot swap to a better Thief without first dropping all captives, then betraying your current Thief. However, Thieves can actively try to recruit you (and betray their weaker snake). If this happens to you as a player, a UI offer appears with two choices: accept the alliance or cancel. [TBD: UI details]

## Special Characters

### Grand Viper (Unlockable)
Unlocked by beating the game as any Thief character. Replaces player Vipers with the Grand Viper.

- **Appearance:** Blue Pit Viper (aquamarine). Normal Vipers are Green Pit Vipers. *(See: Trimeresurus albolabris)*
- **Ability — Strike:** Increased bite range. All bites have a super-fast snap motion to the target position.
- **Rarity:** Legendary (Tier 5) — a permanent unlock, exempt from the Character Token spend/consume economy. See `loot/item-rarity.md`.

## Pairing with a Thief

- Thieves sit on the Viper's back just behind the head tile.
- Small Vipers start at just 3 tiles in length.
- Captives ride behind the Thief, down the line, up to the length of the Viper.
- **Captive slot capacity:** every body tile past the first neck position (i.e., excluding head and the Thief's own seat) is a potential Captive slot. You can't pick up a new Captive if you have no open slots.
- Vipers are faster than lone Thieves and grow faster as they grow bigger.
- The Viper's tongue flicks in warning when something approaches just off-screen — a subtle danger cue. `[TBD: open idea, not confirmed — giving Threats (other Vipers) a different flick animation than Food (Thieves/Captives).]`

## Other NPC Interactions

- **Soldiers / Captains:** A bite does 1 damage (the target flashes red and is bumped away if they survive). The Viper swallows the target once their health reaches 0, rather than a single instant kill.
- **Captives:** Captives are never actively "picked up" the way a Thief is — a Prison Guard places one on your back at time of purchase (see `thief-gameplay.md`'s Purchase Captive bribe action). Once dropped, a Captive just sits on the ground until eaten — there's no pickup-and-replace action. **Horned Vipers have a special affinity for loose Captives** and will aggro toward one as a distraction until it's eaten by someone.
- **Release Tail (swipe back):** Mid-chase on another Viper's tail, swiping backward stops your movement and gives up the chase — you remain unable to move away until the target's tail exits your mouth.
