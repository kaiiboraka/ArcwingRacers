# Music Direction

## Overall Style

Strong retro theme — a mix of retro-sounding instruments with modern twists. **80s period, Electronica/Synth** as the primary direction.

The main theme must be **extremely catchy**. Head-bopping, finger-tapping. Something you can listen to on repeat without it becoming annoying.

Not overly simplified. Multiple repeating harmonic threads that blend, overlap, and come in and out of play. As core tunes repeat, they shift scale or introduce variation as they thread back in.

## Mood

**Primary:**
- Dangerous
- Mysterious
- Determined
- Adventurous
- Speed / Movement

**Secondary:**
- Rogue-ish
- Impish
- Mischievous

## Music Needed

- Title Screen
- Overworld (rotation of Thief songs + Viper songs)
- Boss area themes
- Town theme
- Lockpicking theme (slower, chillwave — let the player think)
- Secret Cave / Retrogasm theme (upbeat, crazy, fast)
- Credits (unique track that adds to the backstory of the player as viper/thief, and the only vocal track in the game) — working title **"Cover Girl"**; see `menu-scenes/credits.md` for the full lyric-synced cinematic staging.

## Reference Tracks

### Action / Overworld
- **Escape From Chinatown — Brennan Green.** Perfect example of rich, complex, and very catchy — multiple elements that repeat, layer, overlap, fade in/out.
- **Stranger Things Theme.** Nailed the retro synth + dangerous mood. Too short. The heartbeat idea: use it when Viper health gets low. Thread into the music by transitioning to a heartbeat+music alternate track version.
- **Tron Legacy Soundtrack.** Instruments, mood, and melody — very close fit for this game.
- **ShadowRun SNES.** Cyberpunk perfection. The mood is everything.
- **ShadowRun Returns OST.** Also solid.

### Chillwave / Lockpicking
- **SPACE TRIP Chillwave Synthwave Retrowave Mix 1.** Slower pace, spot on for the puzzle vibe.
- **Lazerhawk — So Close.** Slow introduction of new instruments throughout, all to a steady beat.
- **Lazerhawk — Activation.**
- Asthenic playlist on Spotify.

### Miscellaneous Inspiration
- **Terminator Theme.** Main synth awesome. Too slow for action, but great reference.
- **Never Ending Story Theme + Falkor's Flight.** For the related character pack.
- **Space Trip Chillwave Mix.** Instrument selection ideas. Sometimes a little bland but good reference sounds.
- **ShadowRun SNES — Song at 4:52.** Dark baseline + high flute — interesting contrast that works.

## Character Music & Unlocks

- Each character (including character skins/Character Tokens) has its own set of music tracks. While playing the main game, the game loops through that character's track set.
- Playing a track for the first time unlocks it permanently in the save file, with a brief (~3 second) popup in the bottom-right corner showing the music icon + track name, faded in/out. `[TBD]` Whether this popup also fires the first time on the title screen is undecided in source material — flagged there as possibly too disorienting for a brand-new player.
- Unlocked tracks become playable anytime in `town-scenes/beats-alley.md`.
- `[Inferred]` When restarting a character's track loop (e.g., re-entering the main map), the design intent was to resume from partway through the next track in sequence rather than always restarting at track 1 — i.e., if you last heard track 1 mid-way through, the next session starts at the beginning of track 2. Source material flags this as a "bonus points" stretch goal, not a committed requirement.

## Heartbeat Low-Health Concept

When the Viper gets low on health, bring in a heartbeat element. Options:
- Transition to a heartbeat + music version of the current track (pre-made alternate)
- Lower the music volume and bring in the heartbeat over it
- Don't let it throw off the beat — sync the heartbeat to the BPM
