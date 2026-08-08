# Plan: Consolidate Project GUI out of `UI/Example_Scenes` (`[CON]`)

Status: ✅ DONE (2026-08-08) + VERIFIED. The project copy of Maaack's example GUI currently
lived inside the plugin's demo folder (`UI/Example_Scenes/`). This plan moved the *used*
project scenes/scripts/assets into project-owned per-feature folders under `UI/`, replaced
path-string constants with `uid://` references, and left the unused template-example content
untouched where it is.

Correction captured mid-task (see "Notes"): Godot's text parser **requires** `path=` on every
`[ext_resource]` tag — `uid=` is an *additional* safety field, NOT a replacement. Removing the
`path=` produced `Missing 'path' in external resource tag` boot failures, so `[ext_resource]`
tags carry BOTH the `uid=` and the corrected `path=` to the new location (exactly what the
editor writes). Path-to-`uid` conversion is for **code-level string constants**
(`ProjectLoader.gd` consts), where the loader accepts uid strings.

User decisions:
- **Target layout**: per-feature folders under `UI/` (`UI/Opening/`, `UI/MainMenu/` +
  `Options/` + `Credits/`, `UI/PauseMenu/`, `UI/LoadingScreen/`, `UI/Shared/` for shared
  scripts + assets) — mirrors how `UI/HUD/` already works.
- **Unused template cruft**: leave it in `UI/Example_Scenes/` — do not move or delete.
- **Path-strings → uids**: change more string paths to `uid://` to prevent breakage.

## Goal

Arrange the GUI scenes the project actually runs so they live under clear project-owned
folders, referenced by uid — not buried inside the plugin's example template and not by
`res://.../Example_Scenes/...` path strings. Runs exactly the same game flow
(boot → opening → menu → New Game → race, HUD + pause) after the move.

## "Used" set = what moves (verified reference graph)

From `Systems/Loading/ProjectLoader.gd` + each scene's `[ext_resource]` graph:

| Feature | Files moved | Scene uid |
| --- | --- | --- |
| Opening | `scenes/opening/opening.tscn`, `opening.gd` (+ `.uid`) | `uid://cgsjsem6im78i` |
| MainMenu | `scenes/menus/main_menu/main_menu.tscn`, `main_menu.gd` (+ `.uid`) | `uid://ctcm8li40gf7s` |
| MainMenu.Windows | `scenes/windows/main_menu_options_window.tscn` | `uid://dvk85b4ev5pw6` |
| MainMenu.Credits | `scenes/windows/main_menu_credits_window.tscn` + `.gd` | `uid://ch3o8f2hxf46b` |
| MainMenu.Credits | `scenes/credits/scrollable_credits.tscn` + `.gd` | `uid://b5yb78ndwalsp` |
| MainMenu.Credits | `scenes/credits/credits_label.tscn` (no script) | `uid://bbllf74y772xe` |
| MainMenu.Options | `scenes/menus/options_menu/master_options_menu_with_tabs.tscn` + `.gd` | `uid://dowjx1dkv4ew5` |
| MainMenu.Options | `options_menu/audio/audio_options_menu.tscn` | `uid://cu4hoyrpj28mr` |
| MainMenu.Options | `options_menu/audio/audio_input_option_control.tscn` + `.gd` | `uid://dtcxperdc4kme` |
| MainMenu.Options | `options_menu/video/video_options_menu_with_extras.tscn` | `uid://cy01ykwl6djg1` |
| MainMenu.Options | `options_menu/game/game_options_menu.tscn` + `.gd` | `uid://cpygclb7i3ngi` |
| MainMenu.Options | `options_menu/game/reset_game_control/reset_game_control.tscn` + `.gd` | `uid://cuf7twhv38r84` |
| MainMenu.Options | `options_menu/input/input_options_menu.tscn` | `uid://kitpnppbmlej` |
| MainMenu.Options | `options_menu/input/input_extras_menu.tscn` | `uid://dngkmsu02hcbf` |
| MainMenu.Options | `options_menu/input/input_icon_mapper.tscn` | `uid://btb8w2stvuuta` |
| PauseMenu | `scenes/windows/pause_menu_layer.tscn` + `.gd` | `uid://bg2ufb71g5oyl` |
| PauseMenu | `scenes/windows/pause_menu.tscn` + `.gd` | `uid://b2oalxg38y0ua` |
| PauseMenu | `scenes/windows/pause_menu_options_window.tscn` | `uid://bvrxaoiub3l34` |
| LoadingScreen | `scenes/loading_screen/loading_screen.tscn` + `.gd` | `uid://dog8vbjbymv3o` |
| Shared | `scripts/game_state.gd` (class_name `GameState`) (+ `.uid`) | — |
| Shared | `ATTRIBUTION.md` | — |
| Shared | `assets/godot_engine_logo/`, `assets/git_logo/`, `assets/plugin_logo/` (png + `.import` + LICENSE) | player |

Retained in place (unused by project flow):
`scenes/game/**` (game.tscn, game_pixel_art_ui.tscn, levels/, tutorials/, scripts/),
`scenes/windows/level_won|level_lost|game_won_window*`, `scenes/end_credits/**`,
`scenes/menus/level_select_menu/**`, `main_menu_with_animations.*`,
`scenes/credits/scrolling_credits.tscn`+`.gd` (referenced only by the cruft end_credits),
`loading_screen_with_shader_caching.*`, `level_loading_screen.tscn`,
`options_menu/mini_options_menu.*`, `video_options_menu.tscn`,
`input_options_menu_with_mouse_.tscn`, `scripts/level_state.gd`,
`scripts/level_and_state_manager.gd`, `resources/themes/**`.

## Target structure

```
UI/
├── Opening/            opening.tscn / opening.gd
├── MainMenu/           main_menu.tscn / main_menu.gd
│   ├── main_menu_options_window.tscn
│   ├── Credits/        main_menu_credits_window.(tscn|gd), scrollable_credits.(tscn|gd),
│   │                   credits_label.tscn
│   └── Options/        master_options_menu_with_tabs.(tscn|gd)
│       ├── audio/  (audio_options_menu.tscn, audio_input_option_control.*)
│       ├── video/  (video_options_menu_with_extras.tscn)
│       ├── game/   (game_options_menu.*, reset_game_control/reset_game_control.*)
│       └── input/  (input_options_menu.tscn↝, input_extras_menu.tscn, input_icon_mapper.tscn)
│   (split `dial` carried at chosen, Options holds the submenus)
├── PauseMenu/          pause_menu_layer.(tscn|gd), pause_menu.(tscn|gd),
│                       pause_menu_options_window.tscn
├── LoadingScreen/      loading_screen.tscn / loading_screen.gd
└── Shared/             scripts/game_state.gd, ATTRIBUTION.md, assets/** (logos)
```

All moved `.gd` files carry their `.uid` sidecars; `.png` carry `.png.import`.

## What becomes uid-driven

- `ProjectLoader.gd` consts → `uid://` strings: `MAIN_MENU_SCENE`, `OPENING_SCENE`,
  `OPTIONS_WINDOW_SCENE`, `CREDITS_WINDOW_SCENE`, `LOADING_SCREEN_SCENE`, `PAUSE_SCENE`
  (alignment with existing `HUD_SCENE_UID`). `DEFAULT_TRACK_SCENE` stays a res:// path (not
  moving).
- Cross-scene `[ext_resource]` references carry `uid=` AND `path=` (Godot requires the path;
  uid is a move-safety fallback). Permitted `.tscn` paths were rewritten to the NEW location
  after the move so the fallback never dangles.
- `scene_loader.tscn` + `app_config.tscn` (plugin autoload defaults): update their
  `res://...Example...` values to uid/`res://` of the NEW location so the plugin fallback
  doesn't dangle. (`game_scene_path`/`ending_scene_path` point at cruft we leave in place —
  update to the new main menu only.)

## Implementation Steps

1. **Create target dirs** — `godot-ai_filesystem`/PowerShell: `UI/Opening`,
   `UI/MainMenu/{Options/{Audio,Video,Game,Input},Credits}`, `UI/PauseMenu`,
   `UI/LoadingScreen`, `UI/Shared/{scripts,assets,attributions?}`. ✅
2. **Move files** with `.uid`/`.import` sidecars (`git mv` where tracked) per the table. ✅
3. **ProjectLoader.gd** — replace the six consts with `uid://` strings above (+ a
   `_path_from_uid()` helper for `@export_file`/`load_threaded_request`, which need real paths). ✅
4. **Ed check every moved script** for `res://UI/Example_Scenes/...` strings (expected:
   `game_state.gd` `FILE_PATH`) and every moved `.tscn` for asset paths (expected:
   `credits_label.tscn` bb-code `[img]` → `res://UI/Shared/assets/...`) — update. ✅
5. **Plugin defaults** — `scene_loader.tscn` `loading_screen_path` + `app_config.tscn`
   `main_menu_scene_path` → point at new locations. ✅
6. **Scan + static verify** — `filesystem_manage(op="scan")`, then launch for boot errors;
   clear stale `user://global_state.tres` (`game_state.gd` old path) so it regenerates. ✅
   Verified: game boots to live, no parse errors, scene swap path OK.
7. **Docs** — update `plan-game-flow-and-scene-management.md` file list (✅ done) and this
   plan (this status block); follow-up-tasks.md `[GFT]` line updated. ✅

## Uncertainties / Notes

- **In-motion correction (uid vs path).** An early pass stripped `path=` from moved .tscn
  `[ext_resource]` tags to make them uid-only — wrong, and it broke boot
  (`Missing 'path' in external resource tag`). Godot's text parser requires `path=`; `uid=`
  is an *additional* move-safety field, not a replacement. Safest pattern: `uid=` + correct
  `path=` in .tscn bodies; `uid://` strings only in code constants (`ProjectLoader.gd`), where
  the loader accepts them. Fix recovered all 15 moved scenes (restore from index + re-path to
  new locations), re-scanned, and re-verified a clean boot.
- The template plugin (`plugin.gd`) rewrites autoload path defaults when installing in a
  fresh project, but our move does not match the premade: `UI/Example_Scenes/` still exists
  (cruft remains) so copy-path detection isn't disturbed.
- `pause_menu.gd` & `opening.gd` fall back to `AppConfig.main_menu_scene_path` when their
  own export is empty — our ProjectLoader always sets the export, so the fallback path is
  only relevant for the plugin; keep it valid by pointing at the new main menu.
- `.png` move requires a re-`scan` (ran) so `.godot` reasserts the new path; verified with a
  clean boot, not gameplay.