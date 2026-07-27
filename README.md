---
pageType: GameDesign
created: "2026-07-07 07:16PM - Tuesday Jul 7th "
parent Page: 
aliases: 
  - Arcwing Racers
tags:
  - Gameplay/Design
discord: 
Reference Board: 
share: true
banner: "[[Arcwing Blader Rider AI_Generated Concept Art (1).png]]"
banner-y: 10
---
# ArcwingRacers
High-speed low-poly racing game.

> [!Summary]+ Summary of [[Fantasy Pod Racer|ArcwingRacers]]
> LIKE POD RACER... ~~IN SPACE~~ IN ELYTHIA

"Arcwings"
Arc for arcane

Blade or Rig are good too
Arc-rigs maybe?

Chariot/Cockpit: Blade
Engines: Wings
Whole 'pod': Arcwing
Cross beams: Arc-rig
Pilots: BLADE RIDERS, or Arc Riders

"Wings" are like Solar Sails (comprised of energy cells) attached to magical machinery. inspiration from airships across Final Fantasy, Treasure Planet, Stardust etc. 
Blade body's overall shape (on average) like a reverse of a Naboo Starfighter, where the blade comes to a long point. Not a hard rule, just a standard design basis.


# Story

You are a nameless racer person (custom character, at least M/F).
The kingdoms of Elythia are celebrating \["ENERGY SPORTS DAY" (see Fantasy X Calendar)] during the entire month of Taikaran (August), and it's basically Elythian Olympics. The most popular sport, by far, is 

# Game Design of [[Fantasy Pod Racer]]

## Primary differences

Every character gets a weapon or ability of some kind, instead of just Sebulba

A way to earn money outside of racing and trading. Random "Mercenary" Race -- jump into a random race on a random track with random opponents and get paid based on your performance.
perhaps tying winnings allocation to difficulty

More complexity in itemization systems.
More ways to play with Random / procedural / roguelike mode.
More diversity in enemy AI experience, so instead of just bucket flat speed values for all enemy racers, they also get randomized loadouts of a range of quality gear.
More environmental hazards and world mechanics, like in the new Galactic Racer.

MAYBE:
Maybe more goofy / weird modes, like Mirror in Ep1R, like "manual" controls or something. Hyper speed modes. The floor is Ice, or Lava, Or both. Or ND/INS/SP cheats like Big Head/Little Head mode, or Halo Birthday Party, some way to make it goofy.
Include a tertiary Mario Kart party mode with some items or something.
Alternate gameplay objective modes, outside of just plain racing. Teams. Capture the Flag. Rocket League. Halo Zombies. City Trial... Wait this is just Kirby Air Ride. YEAHHH

## Mechanics

Gotta go fast. Must feel the same speed that Ep 1 Racer does.

### Racing
Copy the floaty pod feel
include the nose-tipping mechanic for air control and, most importantly
COPY THE BOOST MECHANIC EXACTLY. Over-abuse will catch you on fire
Copy the base stats from Ep 1 Racer as a baseline.
repair is great, because of itemization
copy the time system, with best lap time records and best overall records. Be measurable per character, as well as overall.


### Level Design

Include environmental hazards, including temperature awareness. Boost overheats you. death trap in hot areas, salvation in cold areas, but be careful because boosting lowers turn response rate, and ice is already slippery enough as is.
Obstacles, more monsters and weird things happening
Underwater

Levels are split between design/geometry/terrain and the features/hazards on top of it, such as the geysters and monsters and even the atmospheric lighting and shaders and particles. 

Elemental Imbalance -- like prankster comets in Mario Galaxy, they remix the level with crazy hard modifiers and spice up the visuals and obstacles--reuse the level design but remix what's on it. Ice level invaded by Fire, will have normally icy cavern shortcut filled with Lava. Any element can invade, and will SYSTEMICALLY change targeted things about the level in predetermined ways. Then you can just swap the "Features" of each Level.

Lots more playing with jumps and skill-based shortcut moments, not gated like later Mario Kart item "shortcuts" (catch-up mechanics).
Secret tunnels through destroyable walls you can boost through to break
off-road alternate paths you have to boost across to make worthwhile
underground lava caves

### Characters  & Elemental Abilities

#### Character agnostic
devise a system of weaponry that mixes and matches between "weapon type" and "element" so you can "plug in" the element you need to the fun weapon mechanic that you want.
"Flamethrower" vs "Breath of Frost/Cone of Cold". "Seed Bomb" vs "Shrapnel Grenade".

#### Character Specific
Elemental characters each have a unique ability on Cooldown?
or a powerful passive.

Fire: Afterburner - ACTIVE - the next boost will be empowered to destroy other pods. Also no slowdown on impact. (BULLET BILL)
Iron: Fortress - ACTIVE - temporarily become immune to damage from racers or collisions (Super star)
Earth:
Wood:

Water: Tidal wave - ACTIVE- knock away surrounding racers, sending them careening into each other and the terrain (Foghorn? sorta)
Lightning: Electron Charge - ACTIVE - Become energy during your next boost, harmlessly passing through racers and hazards as though you'd never hit them
Ice:
Wind:

#### Unlockable Characters

Similar to EP1R, progress through the story-mode or winning certain tournaments will unlock characters to play as for any race (PER RACER LICENSE / file)

SECRET Characters, or strong boss characters, will have unique permanent pod parts that you cannot change replace or disable. Such as a unique booster or turning thing. So they have some strong effect but there's still SOME customization at least. Maybe some secret characters (such as the Archons) get permanent passive versions of the active abilities for normal racers. For instance, permanent boost changing, or on actives like Water knockback, instead of 10sec CD, you have 2 charges at (2-3s) cd instead.


### Systems
singleplayer against self ghost or others

#### pod modularity
returning is the upgradeable part system, but now with:
slots for mod components elemental affinity that can add extra stats and/or effects based on the magic at play
e.g. Fire mod on engine will give you stronger boost with more heat generated

Effects:
Environmental -- resist to specific track weather threats -- fire to keep warm in the cold place, etc.
Stats -- kiss curse. Each element should have an intuitive pairing of a stat that it increases and one it decreases. They can double dip on the stats. There will probably be fewer stats than elements anyway, so that makes it easier.
Perks -- actual powers/effects that activate under specific conditions. Galactic Racer example: "While Surging, protected from Choked." or "On Perfect Landing, refill Afterburner fuel by 50%." or "Upon activating an Ability, gain Shielded for 5s." or "While Surging, Afterburner can burn 75% longer." etc.
You can have multiple orbs or cores of each element, one for each type of bonus.

BIS equipment should have elemental affinities baked in so you have to make tradeoffs at the highest level.

"Equipment Quality/Rarity" -- not explicit. Implicit in the internal rank of its stats. Can also be reflected superficially in the UI with typical color schemes or stars or something, but it's not a hard enforced system. Also means you're not going to find the same item at multiple levels of quality.

#### Economy
The junkyard and item progression is worth copying as a baseline, and see how to expand upon it
being able to make money outside of races by trading for worse parts you can repair is excellent gamification
Repairing pod components after races with purchaseable (and upgradeable?) helpers to make the most of used parts
Would also like a way to store and keep parts, and be able to directly sell in addition to trade-in.

Progression of items is NOT tied to number of races completed, but perhaps some kind of License Rank? Have to win lots more easy races or fewer harder races to progress the same. You can still get some progress from placing top half (i.e. "not first").

#Gameplay/Design/Question  Change the winnings allocation for 1-st place confidence? Or tie that in to base difficulty selection out of the gate? If you bet on yourself more, the game gets harder. If you choose "easy" difficulty from the menu, the winnings are split "Fair."
Also, when do you choose the difficulty? Is it permanent per "racer license"? Perhaps a one-way trip to increasing difficulty. 

How do you get mod parts? There can be a store, but they don't have healthbars so the junkyard doesn't make sense. Do you just buy them outright? Is there a special currency you get for placing that you can trade? Like an empty core... probably specifically "Stat Core" vs "Perk Core". The main world map lets you visit nations and their respective shops, so you can trade your cores for the elemental ones at that nation's shop?

#### roguelike replayability - ARCHON RACES
The upper echelon of racing. Only playable once a secret Archon character has been unlocked. Could pretty early. Maybe after your first tournament. Your first boss is Ashlyn or something. 

Choose an Archon.
Choose between 3 specific regions and do all the races in that area (Elemental advantages at play here). unlike main game where you pick a tournament set that takes you all over.
#Gameplay/Design/Question Harder affinity makes better rewards?  

#Gameplay/Design/Question What are the rewards in Archon Races? Do any transfer? Is this a completely isolated For Fun mode? Could be the elemental mod cores.

The punishment of arcade-hard difficult games has been converted into a feature with the advent of roguelikes
Rogue-lite progression systems and the idea of "new runs" in general make for a perfect match with racing games

PROCEDURAL TRACK GENERATION? Dead Cells, Hades, Scourge Bringer: All have distinct chunked bespoke ROOMS that you connect differently each time. In EP1R, the tracks on the same planet are already designed this way, at the largest most interconnected first, and then ripped apart into reusable pieces you can chain together in unique ways to make shorter/easier versions of. Modular track building. So, you can have "infinite" races if you just make more modular racetrack pieces.

main mode has long-term investing, planning, building, tweaking, adjusting. This one is big choices, big commitments, it's not going to last long. High risk/reward ratio.

Immunities from Hazards
Stat Sticks
Some mod perks from the main game
 > a unique gameplay mechanic that doesn't exist in the main story progression, like a crazy Super Attack or something. just to up the ante in this Arcade mode. Maybe like, "Archon Mode" lol. 

Race until you crash, at all, ever. (or like... 3 strikes, maybe). 
Or like the Elimination races from Burnout/GR (last place+ kicked out). 

Elemental Imbalance happens FREQUENTLY

Potentially Slay the Spire style map progression. choose between randomized selection of encounters: Rest/Repair shop, vs Parts Shop, vs race. Could be multiple race types: normal; Ring-race -- make it through all of the checkpoint rings; Quick-Run: up to 3 laps to beat the fastest lap time with better rewards the fewer it takes you; Last Racer Running -- combat, must eliminate certain number of targets (this is where Mario Kart item implementation should definitely exist); Hyper-hazard -- all hazards are on all the time instead of popping out periodically; and more we come up with. Incursions can happen on pretty much any race, regardless of mode (probably). 

# Aesthetic Design of [[Fantasy Pod Racer]]

low-poly 3d.
Simple textures.
Immersive UI.
Charming character models, with expressive quirky animations. (Male Fire racer is Maui)


first people to create

## Characters / "Pods" 

Punch-Out Stereotypes from each nation in Elythia, one from each country.
2 from each, M / F . maybe identical stats, just for visuals? maybe?
Main cast as secret / boss characters. For instance, all the Archons can be tournament winners

## Environment
at least one in each country, minimum. gotta get that biome diversity
Go through levels from the main game
use actual pod racer as inspiration obvs. Pay closest attention to when it's NOT just roads. What do they do to break sightlines and introduce verticality and strong silhouettes?

Gotta go fast. Must feel the same speed that Ep 1 Racer does. Tiling and stretched textures in addition to ACTUAL SPEED create natural motion blur.

## UI
honestly i just really like the speed gauge
health is cool as an in-universe semi-diegetic approximation of the pod itself, instead of a bar or anything.

singleplayer against self ghost or others

# AI Generated Concept art

Generate an image: draw highly stylized concept art for the "Arcwing", a magic-powered hovercraft for a fantasy racing game.

Chariot/Cockpit: Blade
Engines: Wings
Whole 'pod': Arcwing
Cross beams: Arc-rig
Pilots: BLADE RIDERS, or Arc Riders?

"Wings" are like Solar Sails (comprised of energy cells) attached to magical machinery. inspiration from airships across Final Fantasy, Treasure Planet, Stardust etc.
Blade body's overall shape (on average) like a reverse of a Naboo Starfighter, where the blade comes to a long point. Not a hard rule, just a standard design basis.

Somewhere between an airship, the solar sailer hoverboard from Treasure Planet, the pod racers from Star Wars, with the main body (the "blade") about the size of an ATV, with the back side being like the bucket of a chariot for someone to step up onto and stand at to pilot the machine. 
Arcwings have separated floating arcane engines (or "wings") alongside the vehicle lashed to the chariot part via beams of pink arcane energy, much like the "energy binders" of a Star Wars Pod Racer. But unlike a pod racer whose energy binder pulls the two engines together in suspension, with cables from the engines that connect them to the seat, these arcane connections are straight from engine to chariot with no physical bindings.  
in addition to the "Wings" being lashed to the "Blade" by arcane beams of light, the chariot part should allow for standing like a real chariot bucket.

present 2-3 unique designs you have to contrast with each other.

![[Arcwing Blader Rider AI_Generated Concept Art (2).png]]
![[Arcwing Blader Rider AI_Generated Concept Art (1).jpg]]
![[Arcwing Blader Rider AI_Generated Concept Art (3).png]]

![[Arcwing Blader Rider AI_Generated Concept Art (1).png]]
