# Audio Overview

## Sound Categories

### 1. Engine & Pod SFX

The pod's continuous audio presence. These are per-pod, spatial, and scale with speed/heat.

| Sound | Source | Behavior |
|---|---|---|
| Engine idle/steady loop | `sfx_pod_steady_hi_a_loop`, `sfx_pod_steady_hi_b_loop`, `sfx_pod_steady_lo_c_loop`, `sfx_pod_steady_lo_comb_loop` | Loops while pod is alive. Pitch scales with `current_speed / max_speed`. Heat adds a secondary pitch blend for the "straining" sound. Multiple layers blended (hi + lo). |
| Engine varipitch | `sfx_pod_varipitch_d_loop`, `sfx_pod_varispeed_comb_loop` | Additional dynamic layer, crossfaded based on speed |
| Thrusters | `sfx_pod_ani_thrusters_a`, `sfx_pod_ani_thrusters_b` | Triggered on boost activation and hard acceleration |
| Jet steady | `sfx_pod_jet_steady_loop` | Underlying thrust presence |
| Maw | `sfx_pod_maw_fast_loop`, `sfx_pod_maw_slow_loop` | "Pressure" layer — blends in at high speed |
| Flaps / shift | `sfx_pod_ani_flaps_a`, `sfx_pod_ani_flaps_b`, `sfx_pod_ani_shift1`–`5` | Mechanical flap sounds on sharp turns and air control |
| Buzzy | `sfx_pod_ani_buzzy_b_loop` | Rattling/vibration at high RPM |
| Airbrakes | `sfx_pod_airbrakes_on`, `sfx_pod_airbrakes_off` | Brake deploy/retract |
| Slide | `sfx_pod_slide_up`, `sfx_pod_slide_down` | Nose pitch up/down mechanical sound |
| Switch | `sfx_pod_switch_a`, `sfx_pod_switch_b` | Toggle sounds for ability equip/cycle |

### 2. Boost & Heat

| Sound | Source | Behavior |
|---|---|---|
| Boost activation | TBD | Short burst on boost engage |
| Boost steady | TBD | Continuous loop during boost, high-energy |
| Boost flame (overheat) | TBD | Wing fire loop — maybe `sfx_flame_burst_01`/`02` or a custom mix |
| Coolant spray | `sfx_pod_coolant_spray_loop`, `sfx_pod_coolant_spray_on` | Triggered when cooling after boost |
| Heat beep slow | TBD — maybe `sfx_beeps_misc_a` | Looped beep at ~50–85% heat, low pitch |
| Heat beep fast | TBD — maybe `sfx_beeps_misc_b` | Looped beep at 85%+ heat, high pitch, faster |

### 3. Collision & Damage

| Sound | Source | Behavior |
|---|---|---|
| Metal collision (large) | `sfx_crash_metal_boomy`, `sfx_crash_metal_med1`, `sfx_crash_metal_med2` | Pod-to-pod or pod-to-wall impacts. Variant picked by impact force. |
| Metal scrape | `sfx_crash_metal_scrape`, `sfx_amb_scrape_metal_01`/`02`/`03` | Continuous scraping along a wall |
| Rock collision | `sfx_crash_rock` | Terrain impact |
| Ice collision | `sfx_crash_ice` | Ice surface impact |
| Jungle crash | `sfx_crash_jungle_a`, `sfx_crash_jungle_b` | Foliage impacts |
| Gate crash | `sfx_crash_gate` | Starting gate destruction |
| Wood crash | `sfx_crash_wood` | Wooden obstacle impacts |
| Firey crash | `sfx_crash_firey_a`/`b`/`c` | High-speed crash resulting in fire |
| Impact mellow | `sfx_impact_mellow` | Minor bumps |
| Impact meteor | `sfx_impact_meteor_fall_01`/`02`/`03` | Large debris hits |
| Impact snow | `sfx_impact_snow` | Snow terrain |

### 4. Pickups & Abilities

| Sound | Source | Behavior |
|---|---|---|
| Pickup collect | TBD | Ding/chirp on mana crystal or item grab |
| Flamethrower (generic) | `sfx_pod_flamethrower_loop`, `sfx_pod_flamethrower_on` | Ability: fire weapon |
| Flamethrower (unused) | `sfx_pod_seb_sdb_loop`, `sfx_pod_seb_flame` | EP1R Sebulba's weapon — not used in ArcwingRacers |
| Flare fire | `sfx_pod_flare_fire` | Ability: flare projectile |
| Binder | `sfx_pod_binder_activate_a`, `sfx_pod_binder_start_b`, `sfx_pod_binder_idle_loop`, `sfx_pod_binder_steady_loop` | Ability: binding/tether |
| Chop | `sfx_pod_chop_a_loop`, `sfx_pod_chop_a_combo_loop`, `sfx_pod_chop_b_loop`, `sfx_pod_chop_b_combo_loop` | Ability: melee slash |

### 5. Hazards & Environment

| Sound | Source | Behavior |
|---|---|---|
| Lava | `sfx_amb_lava_flow_loop`, `sfx_amb_lava_flow2_loop`, `sfx_amb_lava_bubbl_loop`, `sfx_lake_ignite` | Hazard zone loop + ignite trigger |
| Wind | `sfx_amb_wind_howling_loop`, `sfx_amb_wind_metal_loop`, `sfx_amb_wind_tat_a_loop` | Ambient wind layers |
| Avalanche | `sfx_amb_avalance_loop` | Falling debris hazard |
| Earthquake | `sfx_amb_earthquake_loop` | Hazard rumble |
| Thunder | `sfx_thunder_07`/`08`/`09` | Storm hazard |
| Geyser | `sfx_geyser_vent` | Geyser hazard trigger |
| Glacier rumble | `sfx_glacier_rumble` | Ice hazard |
| Welding torch | `sfx_welding_torch_a`/`b`/`c`/`_loop` | Ambient workshop |

### 6. Ambience

~70 ambience loops covering: jungles, cities/urban, lava/volcanic, underwater, caves/tunnels, industrial/factories, crowds, wind, water/surf, rain, space/deathstar, scrap yards, hangars, temples, bazaars. These are **locale-tagged** and assigned per track section via the spline's segment data.

### 7. UI & Menus

| Sound | Source |
|---|---|
| Start beep | `sfx_start_beep` |
| Start game | `sfx_start_game` |
| Button confirm | `sfx_button_yes` |
| Button cancel | `sfx_button_no` |
| Select pulse | `sfx_select_pulse1` |
| Soft switch | `sfx_select_softswitch1`/`2`/`3`/`4` |
| Buzzer | `sfx_buzzer_misc_t`, `sfx_buzzer_misc_t_loop` |
| Payoff bell | `sfx_payoff_bell` |
| Coin roll | `sfx_coin_roll`, `sfx_coin_roll_short` |

### 8. Music

EP1R-style: energetic orchestral/electronic hybrid. No dynamic layer system (contrast with the old game-design doc which references hub-act layering — that was for a different project). Music plays per-track, selected by track data.

### 9. Crowd / Announcer

| Sound | Source |
|---|---|
| Crowd huge | `sfx_amb_crowd_huge_loop` |
| Crowd big | `sfx_amb_crowd_big_loop` |
| Crowd distant | `sfx_amb_crowd_distant_loop` |
| Crowd cheer | `sfx_amb_crowd_cheer_a`, `sfx_amb_crowd_cheer_sky` |
| Crowd boos | `sfx_amb_crowd_boos` |
| Crowd bazaar | `sfx_amb_crowd_bazaar_loop` |
| Chorus | `sfx_chorus_01`/`01a`/`01b`/`01c`/`02`/`full` |

Crowd intensity scales with race progress — louder and more energetic near finish.

## Per-Track Ambience Assignment

Each track segment (spline span) carries an `ambience_id` that maps to the appropriate ambience loop. For example:

| Ambience ID | Loop(s) |
|---|---|
| `jungle` | `sfx_amb_jungle_a_loop`, `sfx_amb_jungle_h_loop`, `sfx_amb_jungle_mix_loop` |
| `lava` | `sfx_amb_lava_flow_loop`, `sfx_amb_lava_bubbl_loop` |
| `city` | `sfx_amb_city_aquil_loop`, `sfx_amb_city_cor_loop` |
| `underwater` | `sfx_amb_underwater_loop`, `sfx_amb_waterpipe_loop` |
| `wind` | `sfx_amb_wind_howling_loop`, `sfx_amb_wind_metal_loop` |
| `tunnel` | `sfx_amb_tunneltram_loop`, `sfx_amb_submarine_loop` |
| `crowd` | `sfx_amb_crowd_huge_loop`, `sfx_amb_crowd_distant_loop` |
