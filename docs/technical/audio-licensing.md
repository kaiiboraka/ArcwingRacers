# Audio Licensing

Tracks the license status of every audio file under `Assets/_Project/Audio/`. Single source of truth for "can we ship this" — every audio asset needs a row here before commit.

Art is not tracked here. If purchased/commissioned art enters the project, create a separate art-licensing tracker.

## Status Legend

| Status | Meaning |
|---|---|
| `Cleared` | License confirmed. Safe to ship. |
| `Pending` | No confirmed license record. Needs verification before ship. |
| `Temporary` | Placeholder — must be replaced before ship even if eventually licensed. |
| `Rejected` | Confirmed unlicensed. Must not ship. |

## Attribution Note

Fill **Attribution** only when the license requires it (e.g. CC BY variants, or packs with explicit credit requirements). CC0 and standard EULA assets need nothing unless noted. Paste the exact credit string the source specifies. This column is the source of truth for the game's licenses/acknowledgements screen — see `game-design/menu-scenes/main-menu.md`.

---

All file paths relative to `Assets/_Project/Audio/`.

## AudioBlocks
**License:** AudioBlocks subscription | **Acquired:** Subscription

| Filename | File Path | Status |
|---|---|---|
| Viper-bbc-051117-8-Bit-Retro-80s-Car-Chase-Game-Music.wav | Music/Characters | `Cleared` |
| Castle_Theme- bbc-051117-Level-1-Push-Start.wav | Music/Level | `Cleared` |
| MacGuyver - rescue-squad-v2_fJj1cUrO.wav | Music/Level | `Cleared` |
| Swamp - bbc-051117-Retro-1980s-Kung-Fu-Fighting-Game-Music.wav | Music/Level | `Cleared` |
| TutorialCave - bbc-051117-The-Mysterious-Baddie-Cave.wav | Music/Level | `Cleared` |
| SC_Credits-Torelli-and-the-Fuse-201608-Cover-Girl.wav | Music/Scenes | `Cleared` |
| CH_Witch_Cackle-Witch-laugh-reverb-1_fyZoDfNO.wav | SFX/Characters/Witch | `Cleared` |
| CH_Witch_Cackle-witch-laugh-evil-reverb_M1-8AL4u.wav | SFX/Characters/Witch | `Cleared` |
| CH_Witch_Die-witch-killer-hit_fyC_gBEd.wav | SFX/Characters/Witch | `Cleared` |

## Freesound.org
**License:** Varies | **Acquired:** Per clip

| Filename | File Path | Status | License | Attribution |
|---|---|---|---|---|
| BB_PowerOn - 160364__godspine__amp-ilo.wav | SFX/Boombox | `Cleared` | CC0 | |
| BB_Pause - 258392__constructabeat__stop-start-tape.wav | SFX/Boombox | `Cleared` | CC BY 4.0 | "Stop Start Tape. Player  by constructabeat -- https://freesound.org/s/258392/ -- License: Attribution 4.0" |
| BB_FastForwardPlay - 362379__kingsrow__cassetteplayer-rwd-fwd-stop.wav | SFX/Boombox | `Cleared` | CC0 | |
| BB_InsertTape - 362379__kingsrow__cassetteplayer-rwd-fwd-stop.wav | SFX/Boombox | `Cleared` | CC0 | |
| BB_Play - BB_FastForwardPlay - 362379__kingsrow__cassetteplayer-rwd-fwd-stop.wav | SFX/Boombox | `Cleared` | CC0 | |
| BB_Eject - 450525__kyles__cassette-tape-deck-open-close-tape-handling.wav | SFX/Boombox | `Cleared` | CC0 | |
| BB_DialSwitch - 457241__aslakhostaker__old-electric-stove-stove-dials.wav | SFX/Boombox | `Cleared` | CC0 | |

## Pro Sound Collection (Unity Asset Store)
**License:** Standard Unity Asset Store EULA | **Acquired:** 6/8/2018
**Attribution:** "Created by GameMaster Audio"

| Filename | File Path | Status |
|---|---|---|
| CH_Viper_Bite-snake_2_attack_hiss_fast_03.wav | SFX/Characters/Viper | `Cleared` |
| EN_WaterSplash-footstep_water_splash_light_wading_08.wav | SFX/Environment | `Cleared` |
| PU_SlidePuzzle-~rock_door_slide_block_move_drag_05.wav | SFX/Puzzle | `Cleared` |
| PU_SlidePuzzle-~rock_door_slide_block_move_drag_loop1.wav | SFX/Puzzle | `Cleared` |
| UI_InventoryIn-sweeping_broom_leaves_stones_06.wav | SFX/UI | `Cleared` |
| UI_InventoryOut-sweeping_broom_leaves_stones_07.wav | SFX/UI | `Cleared` |
| UI_Select-ui_menu_button_click_22.wav | SFX/UI | `Cleared` |
| UI_Select-~ui_menu_button_click_07.wav | SFX/UI | `Cleared` |
| UI_TextPrinting-cartoon_electronic_computer_code_03.wav | SFX/UI | `Cleared` |
| UI_UnpauseGo-retro_simple_beep_03.wav | SFX/UI | `Cleared` |

## Advanced Game Sounds (Unity Asset Store)
**License:** Standard Unity Asset Store EULA | **Acquired:** 6/12/2018
**Attribution:** "Created by Epic Stock Media"

| Filename | File Path | Status |
|---|---|---|
| CH_Enemy_Hit~Game Item Hit 2.wav | SFX/Characters/Castle | `Cleared` |
| CH_Guard_PikeThrust~Jump 3.wav | SFX/Characters/Castle | `Cleared` |
| CH_King_ShoutForGuards-Simple fanfare horn.wav | SFX/Characters/Castle | `Cleared` |
| CH_Soldier_SwordSwing~Throw Weapon 4.wav | SFX/Characters/Castle | `Cleared` |
| CH_Thief_Robbed-Correct Jewel Sound 7.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_Robbed-Correct Jewel Sound 9.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_Robbed-Negative Game Hit Sound.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealA1-Retro Arcade Game Coin 1.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealA2-Retro Arcade Game Coin 4.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealA3-Retro Arcade Game Coin 6.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealA4-Retro Arcade Game Coin 13.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealB1-Game Coin.wav | SFX/Characters/Thief | `Cleared` |
| CH_Thief_StealB3-Game Coin Blip.wav | SFX/Characters/Thief | `Cleared` |
| CH_Viper_Gulp-Arcade Game Jump 21.wav | SFX/Characters/Viper | `Cleared` |
| CH_Viper_Heartbeat-LFE Heart Beat Loop Fast.wav | SFX/Characters/Viper | `Cleared` |
| CH_Viper_LevelUp-Game Booster 4.wav | SFX/Characters/Viper | `Cleared` |
| EN_ForestRustle-Paper Scroll 2.wav | SFX/Environment | `Cleared` |
| EN_HitImpassableTile-Bow_Release_2.wav | SFX/Environment | `Cleared` |
| EN_HitImpassableTile-~Dub Game Mellow Item.wav | SFX/Environment | `Cleared` |
| EN_PrisonCageOpen-Floor Spikes Release 6.wav | SFX/Environment | `Cleared` |
| EN_SwampSplash-Mud Plop 3.wav | SFX/Environment | `Cleared` |
| EV_BankDeposit-Coin Swipe.wav | SFX/Events | `Cleared` |
| EV_BankDeposit-~Coin Jingle.wav | SFX/Events | `Cleared` |
| EV_ChestRewardA1-Game Achievement Bling 1.wav | SFX/Events | `Cleared` |
| EV_ChestRewardA2-Game Achievement Bling 2.wav | SFX/Events | `Cleared` |
| EV_ChestRewardA3-Game Achievement Bling 3.wav | SFX/Events | `Cleared` |
| EV_ChestRewardA4-Game Achievement Bling 11.wav | SFX/Events | `Cleared` |
| EV_ChestRewardB0-Positive Correct Bling v4.wav | SFX/Events | `Cleared` |
| EV_ChestRewardB1-Positive Correct Bling v2.wav | SFX/Events | `Cleared` |
| EV_ChestRewardB2-Positive Correct Bling v3 +.wav | SFX/Events | `Cleared` |
| EV_ChestRewardB3-Positive Correct Bling.wav | SFX/Events | `Cleared` |
| EV_GameOver-~Game Over Robot Hit 2.wav | SFX/Events | `Cleared` |
| EV_GameOver-~Retro Game Over 2.wav | SFX/Events | `Cleared` |
| EV_PurchaseIAP-Positive Correct Bling v3 +.wav | SFX/Events | `Cleared` |
| EV_SecretUncovered-~Horror Bell Transition.wav | SFX/Events | `Cleared` |
| PU_UnlockPuzzleFail-~Negative low tone.wav | SFX/Puzzle | `Cleared` |
| PU_UnlockPuzzleGreen-~Correct Shingdown.wav | SFX/Puzzle | `Cleared` |
| PU_UnlockPuzzleSolved-Achievement Sound.wav | SFX/Puzzle | `Cleared` |
| UI_AudioOff-Negative alert 3.wav | SFX/UI | `Cleared` |
| UI_AudioOn-Positive Casino Arcade Game Coin 1.wav | SFX/UI | `Cleared` |
| UI_CloseCancel-Arcade Game Coin 8.wav | SFX/UI | `Cleared` |
| UI_CloseCancel-Run Counter One Shot 3.wav | SFX/UI | `Cleared` |
| UI_InventoryIn-Health Pack 2.wav | SFX/UI | `Cleared` |
| UI_ItemEquip-Land 1 +.wav | SFX/UI | `Cleared` |
| UI_PressStart-Game Item or Coin15.wav | SFX/UI | `Cleared` |
| UI_PressStart-~Achievement Sound2 +.wav | SFX/UI | `Cleared` |

## Chiptunes — Music & SFX Pack (Unity Asset Store)
**License:** Standard Unity Asset Store EULA | **Acquired:** 6/12/2018
**Attribution:** "Created by Andrea 'bluegestalt' Baroni from Cyberleaf Studio"

| Filename | File Path | Status |
|---|---|---|
| CH_Viper_Die~SFX_flame.wav | SFX/Characters/Viper | `Cleared` |
| EV_ChestRewardC4_Laser-Stinger_Success4.wav | SFX/Events | `Cleared` |

## Super Retro Audio Bundle (Unity Asset Store)
**License:** Standard Unity Asset Store EULA | **Acquired:** 6/12/2018
**Attribution:** "Created by Tao and Sound"

| Filename | File Path | Status |
|---|---|---|
| CH_Enemy_Hit~Kick 3.mp3 | SFX/Characters/Castle | `Cleared` |
| CH_Viper_Drop-Sky Float 3.mp3 | SFX/Characters/Viper | `Cleared` |
| CH_Viper_Hit~Hit 2 ++.mp3 | SFX/Characters/Viper | `Cleared` |
| CH_Viper_Pickup-Sky Float 1 +.mp3 | SFX/Characters/Viper | `Cleared` |
| EN_CaveEnter-Ladder 1.mp3 | SFX/Environment | `Cleared` |
| UI_PressStart-Coin 14.mp3 | SFX/UI | `Cleared` |
| UI_PressStart-~Get item 2.mp3 | SFX/UI | `Cleared` |
| UI_Select-~Button 13.mp3 | SFX/UI | `Cleared` |
| UI_TextPrinting-Points-Text Sound 3.mp3 | SFX/UI | `Cleared` |
| UI_UnpauseReadySet-~Button 12.mp3 | SFX/UI | `Cleared` |

## Retro Game (Unity Asset Store)
**License:** Standard Unity Asset Store EULA | **Acquired:** 6/12/2018
**Attribution:** "Created by Epic Stock Media"

| Filename | File Path | Status |
|---|---|---|
| UI_Select-Retro Game UI Select 20.wav | SFX/UI | `Cleared` |
| UI_Select-Retro Game UI Select 21.wav | SFX/UI | `Cleared` |
| UI_UnpauseGo-Retro Game UI Select 6.wav | SFX/UI | `Cleared` |
| UI_UnpauseReadySet-Retro Game UI Select 9.wav | SFX/UI | `Cleared` |

## Rejected / Placeholder
Do not ship. Replace or cut before release.

| Filename | File Path | Status | Notes |
|---|---|---|---|
| SC_Title-04 - Recognizer.mp3 | _Reference-NotLicensed/Music/Scenes | `Rejected` | Placeholder for title screen; not licensable |

| Thief-20720486_arcade-video-game_by_airportmusic_preview.mp3 | _Reference-NotLicensed/Music/Characters | `Temporary` | Available for $99: https://audiojungle.net/item/arcade-game/20720486 or for $155: https://audiojungle.net/item/8bit-music-pack/21795259 |
| Thief-21418954_8-bit-adventure_by_airportmusic_preview.mp3 | _Reference-NotLicensed/Music/Characters | `Temporary` | Available for $99: https://audiojungle.net/item/8bit-arcade/21418954 or  for $155: https://audiojungle.net/item/8bit-music-pack/21795259 |
| Viper-16798632_8-bit-video-game_by_airportmusic_preview.mp3 | _Reference-NotLicensed/Music/Characters | `Temporary` | Available for $99: https://audiojungle.net/item/8bit-video-game/16798632 or for $155: https://audiojungle.net/item/8bit-music-pack/21795259 |

| Thief-19751686_8bit-upbeat_by_milkyrourke_preview.mp3 | _Reference-NotLicensed/Music/Characters | `Temporary` | Available for $49 for 10k downloads or $766 unlimited: https://audiojungle.net/item/8bit-dance-background/19751686 |
| Viper-19442869_8-bit-game-video_by_tau_music_preview.mp3 | _Reference-NotLicensed/Music/Characters | `Temporary` | Available for $56: https://audiojungle.net/item/8-bit-game-video/19442869 |
| Crazy Mode - 18708674_8-bit_by_lynxstudio_preview.mp3 | _Reference-NotLicensed/Music/Events | `Temporary` | Available for $68: https://audiojungle.net/item/8-bit/18708674 |

| EN_GateOpen-21465318_large-gear-wheels-1_by_przemyslawkepa_preview.mp3 | _Reference-NotLicensed/SFX/Environment | `Rejected` | No longer available |

## Interested
These tracks are under consideration before purchase.

| | | `Temporary` | Available for $80: https://audiojungle.net/item/night-vibe/41771637 | 
| | | `Temporary` | Available for $56: https://audiojungle.net/item/synthwave-80s-retro-game/32772230 | 
| | | `Temporary` | Available for $56: https://audiojungle.net/item/retro-80s-cyberpunk/32723233 |
| | | `Temporary` | Available for $88 in Tao pack: https://audiojungle.net/item/video-game-pack/20933791 |
| | | `Temporary` | Available for $99: https://audiojungle.net/item/80s-vibe/62575028 |
