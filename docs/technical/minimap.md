# Minimap

**Location:** `ui/minimap/minimap_panel.gd`, `ui/minimap/position_bars.gd`, `ui/minimap/edge_circling.gd`
**Dependencies:** Spline, EventBus (racer positions)
**Consumed by:** HUD container

---

## Rendering Strategy

Procedural `_draw()` on Control nodes. No pre-baked textures. The 2D spline points are computed once at track load, then transformed per frame for rotation/translation/zoom.

### Pipeline per Frame (Modes 1 & 2)

1. Take the pre-computed 2D points (XZ flattened to XY)
2. Rotate so the player's forward direction points "up"
3. Translate so the player's position is at center of the minimap rect
4. Scale to fit: mode 1 = full track visible, mode 2 = 30% around player
5. `clip_contents = true` on the panel — points outside the rect are culled
6. `draw_rect()` for gradient background
7. `draw_polyline()` for the spline
8. `draw_texture()` for each racer icon at their transformed position

---

## MinimapPanel (Modes 1 & 2)

```gdscript
# minimap_panel.gd
class_name MinimapPanel
extends Control

@export var track_spline: SplineResource
@export var zoomed_out: bool = true   # false = mode 2 (zoomed in)

var _flat_points: PackedVector2Array  # pre-computed at track load
var _bounds: Rect2
var _player_id: int = 0
var _racer_positions: Dictionary = {} # slot_index → spline_t

func _ready():
    _flat_points = track_spline.flatten_to_2d()
    _bounds = _compute_bounds(_flat_points)

func _draw():
    if _flat_points.is_empty():
        return

    var size = get_size()
    var center = size * 0.5

    # 1. Player's position and forward on the spline
    var player_t = _racer_positions[_player_id]
    var player_pos = track_spline.sample(player_t).position
    var player_fwd = track_spline.sample_forward(player_t)

    # 2. Build transform: rotate so forward = up, translate so player = center
    var angle = atan2(player_fwd.x, player_fwd.z)   # 3D forward → 2D angle
    var transform = Transform2D()
    transform = transform.rotated(-angle)
    transform = transform.translated(-Vector2(player_pos.x, player_pos.z))

    # 3. Scale
    var scale_factor: float
    if zoomed_out:
        var track_size = max(_bounds.size.x, _bounds.size.y)
        scale_factor = min(size.x, size.y) * 0.45 / track_size
    else:
        scale_factor = min(size.x, size.y) * 0.45 / (_bounds.size.length() * 0.3)
    transform = transform.scaled(Vector2(scale_factor, scale_factor))

    # 4. Offset to center
    transform = transform.translated(center)

    # 5. Draw background gradient square
    draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.6))
    var gradient_rect = Rect2(center - Vector2(100, 100), Vector2(200, 200))
    draw_rect(gradient_rect, Color(0.1, 0.1, 0.2, 0.4))

    # 6. Draw spline
    var transformed = PackedVector2Array()
    for p in _flat_points:
        transformed.append(transform * p)
    draw_polyline(transformed, Color.WHITE, 2.0)

    # 7. Draw track width as filled polygon
    var left_edge = PackedVector2Array()
    var right_edge = PackedVector2Array()
    for i in range(track_spline.point_count()):
        var s = track_spline.sample(float(i) / track_spline.point_count())
        var flat = Vector2(s.position.x, s.position.z)
        var perp = Vector2(-s.forward.z, s.forward.x).normalized()
        left_edge.append(transform * (flat + perp * s.width))
        right_edge.append(transform * (flat - perp * s.width))
    # Combine left + reversed right for filled polygon
    var polygon = left_edge + right_edge.slice(0, right_edge.size(), 1, true)
    draw_colored_polygon(polygon, Color(1.0, 1.0, 1.0, 0.15))

    # 8. Draw racer icons
    for slot in _racer_positions:
        var t = _racer_positions[slot]
        var pos = track_spline.sample(t).position
        var screen_pos = transform * Vector2(pos.x, pos.z)
        var icon = _get_racer_icon(slot)
        var icon_size = Vector2(8, 8) if slot != _player_id else Vector2(12, 12)
        draw_texture_rect(icon, Rect2(screen_pos - icon_size * 0.5, icon_size), false)
```

### Zoom Toggle

Mode 1 → Mode 2 flips `zoomed_out`:

Mode 3 and 4 are separate Control nodes. `MinimapPanel` hides, `EdgeCircling` shows, etc.

---

## PositionBars (Mode 3)

A vertical bar chart on the right side of the screen. The player is always at the vertical center. Nearby racers appear as horizontal bars whose height and opacity indicate their distance ahead/behind on the spline.

```gdscript
# position_bars.gd
class_name PositionBars
extends Control

var _nearby: Array[RacerSlot] = []  # sorted by spline_t descending

func _draw():
    var size = get_size()
    var center_y = size.y * 0.5
    var bar_width = 12.0
    var max_bars = 8
    var spacing = 24.0

    # Draw racers ordered by position
    for i in range(min(_nearby.size(), max_bars)):
        var slot = _nearby[i]
        var y_offset = (i - _player_index_in_list) * spacing
        var bar_height = 6.0
        var alpha = clamp(1.0 - abs(y_offset) / (max_bars * spacing * 0.5), 0.2, 1.0)
        var color = slot.color
        color.a = alpha
        var rect = Rect2(size.x - bar_width - 4, center_y + y_offset - bar_height * 0.5, bar_width, bar_height)
        draw_rect(rect, color)
        # Draw position number
        draw_string(font, Vector2(size.x - bar_width - 20, center_y + y_offset + 4), str(slot.position))
```

The player is fixed at center. A racer 2nd ahead appears above, 1st behind appears below, etc. Opacity drops with distance.

---

## EdgeCircling (Mode 4)

The entire race spline is mapped to the screen perimeter. Each racer's spline t maps to a point on the edge rectangle.

```gdscript
# edge_circling.gd
class_name EdgeCircling
extends Control

func _draw():
    var size = get_size()
    var margin = 4.0   # gap from edge so bars don't clip
    var rect = Rect2(margin, margin, size.x - margin * 2, size.y - margin * 2)
    var perimeter = rect.size.x * 2 + rect.size.y * 2

    for slot in _racer_positions:
        var t = _racer_positions[slot]
        var edge_pos = _t_to_perimeter(t, rect, perimeter)
        var icon = _get_racer_icon(slot)
        var icon_size = Vector2(10, 10)
        # Z-order: further ahead = higher priority
        draw_texture_rect(icon, Rect2(edge_pos - icon_size * 0.5, icon_size), false)

func _t_to_perimeter(t: float, rect: Rect2, perimeter: float) -> Vector2:
    # Map t=0.0 → top-left, clockwise around
    var dist = t * perimeter
    var top = rect.size.x
    var right = rect.size.x + rect.size.y
    var bottom = rect.size.x * 2 + rect.size.y

    if dist <= top:
        return rect.position + Vector2(dist, 0)
    elif dist <= right:
        return rect.position + Vector2(rect.size.x, dist - top)
    elif dist <= bottom:
        return rect.position + Vector2(rect.size.x - (dist - right), rect.size.y)
    else:
        return rect.position + Vector2(0, rect.size.y - (dist - bottom))
```

### Mode 4 HUD Changes

When EdgeCircling is active, the top bar restructures:
- **Position counter** (e.g. "3/16") is hidden — redundant since all positions are visible on the edge
- **Race timer** moves to the top-right corner
- **Top bar background** is hidden so the edge-circling icons are not obscured

```gdscript
# In HUD container:
func _on_mode_changed(mode: int):
    minimap_panel.visible = mode == 1 or mode == 2
    position_bars.visible = mode == 3
    edge_circling.visible = mode == 4
    top_bar.show_background(mode != 4)
    top_bar.show_position(mode != 4)
    if mode == 4:
        top_bar.move_timer_to_right()
```

---

## Racer Icons

Each racer has a small icon — their nation/faction symbol or character portrait thumbnail.

```gdscript
func _get_racer_icon(slot_index: int) -> Texture2D:
    var racer = race_manager.get_racer_data(slot_index)
    return racer.minimap_icon
```

Icons are small (8–12 px squares for minimap dots, ~10 px for edge mode). The player's icon is 1.5× larger and uses a distinct border. Higher position (further ahead) draws last for correct Z-ordering.

---

## Minimap Positioning

```
+------------------------------------------+
| Lap 3      00:42.150          3/16       |  ← TopBar (24px)
|                                  ┌──────┐|
|                                  │      │|  ← MinimapPanel (120×120)
|                                  │ MAP  │|
|                                  │      │|
|                                  └──────┘|
|                                          |
|                                       ┌──┤  ← PositionBars (Mode 3)
|                                       │  │
|                                       └──┤
|                                          |
+------------------------------------------+
```

Minimap panel: 120×120px in the top-right corner, just below the top bar. PositionBars: ~40px wide on the right side, vertically centered.

---

## Data Flow

```gdscript
# RaceManager emits each tick:
EventBus.racer_positions_updated.emit(positions)  # {slot_index: spline_t}

# MinimapPanel listens:
EventBus.racer_positions_updated.connect(_on_positions)

func _on_positions(positions: Dictionary):
    _racer_positions = positions
    queue_redraw()
```

The minimap redraws every physics tick (or every Nth frame if performance is a concern). 200 spline segments × 8–16 racers is trivially fast for `_draw()`.

---

## Multiplayer Considerations

- Minimap rendering is purely local — each client draws based on the authoritative spline t values they receive
- Mode 4 edge position is deterministic from spline t — no network sync needed beyond what the input buffer already provides
- Player icon highlighting works per peer — the local player is always the "player" at center
