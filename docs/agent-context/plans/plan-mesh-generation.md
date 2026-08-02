# Plan: Track Mesh Generation (Track Editor Phase 3)

Status: 🔜 DRAFT (2026-08). Cursory plan only — deliberately parked as a rabbit-hole-sized
phase. No execution started. Written so the approach and its uncertainties are captured before
a later session picks it up. Roadmap home: `technical/tracks-and-splines.md` → Track Editor
Roadmap, Phase 3. Design home: ADR 0010 (`TrackMeshGenerator`, `ROAD`/`TUNNEL`).

## Goal

Bake the spline into track geometry: a `ROAD` ribbon (surface + side walls) and `TUNNEL`
(ribbon + walls + roof) as `ArrayMesh`, honoring per-point width, tilt (banking), recipe, and
recipe params. Generated road coexists with modeled `.glb` terrain as a separate physics body
(ADR 0009). Branches get no mesh pass yet (deferred in ADR 0010).

## Reference: PathMesh3D (downloaded 2026-08)

Local copy: `C:\Projects\Godot\Plugins\PathMesh3D` (NOT in this repo). Upstream:
`https://github.com/iiMidnightii/PathMesh3D` — MIT license (`LICENSE`, © 2025 iiMidnightii;
attribution required if code is copied). A GDExtension written in C++ for speed — **no
prebuilt binaries**; needs `godot-cpp` + SCons to compile. Key source reviewed:

- `addons/PathMesh3D/src/path_tools/path_extrude_3d.cpp` — the core extrude algorithm
  (`_rebuild_mesh`, 654 lines): `curve->tessellate(max_stages, tolerance_degrees)` into
  slices → per-slice `curve->sample_baked_with_rotation(offset, cubic, tilt)` Transform3D →
  extrude a 2D cross-section profile between consecutive slices (2 tris per profile edge) →
  transform normals/tangents/UVs by the slice transform → `add_surface_from_arrays`.
  UV: `u = closest_offset / baked_length`, `v` from cross-section chord length
  (`_generate_v`, normalized, clamped `/2.0`). Optional end caps via
  `Geometry2D::triangulate_polygon`.
- `addons/PathMesh3D/src/path_extrude_profile_base.cpp` + `extrude_profiles/path_extrude_profile_rect.cpp`
  — the 2D cross-section (a `Rect2` + subdivisions + `_generate_v` chord-length V coordinates).
  Our ROAD ribbon = a rect profile (width wide × small height); walls/roof = the same extrude
  with a taller/larger rect, or a custom profile.
- `addons/PathMesh3D/src/path_tool_3d.hpp` — `Path3D.curve_changed` wiring + dirty-flag rebuild
  pattern (`queue_rebuild` → internal process). Mirrors how our dock/gizmo already react.
- `addons/PathMesh3D/src/path_modifier_3d.cpp` — per-offset position/rotation/scale/UV modifiers
  with an influence curve. Relevant as inspiration for per-point width/tilt interpolation, NOT a
  requirement.
- `addons/PathMesh3D/src/path_collision_tool_3d.hpp` — trimesh/convex collision via
  `_get_mesh()->create_trimesh_shape()` → StaticBody3D + CollisionShape3D. Matches our
  "generated road = its own StaticBody3D" plan.
- `plugin.gd` + `scenes/path_mesh_3d_options.tscn` — editor toolbar "Bake Mesh" / collision
  button pattern (per README: PathMesh3D and PathExtrude3D both have a plugin bake button).
- `tests/test_pathextrude3d.tscn` — a ready-made test scene showing the extrude node + curve
  in action.

The algorithm itself is portable to GDScript — it is plain math over `Curve3D` baked
sampling, which our `Spline extends Curve3D` already provides (banking lives in native
Curve3D tilt, matching `sample_baked_with_rotation`'s `tilt` flag).

## Approach (bite-sized pieces)

1. **Cross-section profile builder.** GDScript port of the rect-profile cross-section
   generation (chord-length V coordinates + normals). Small, self-contained, testable.
2. **Ribbon extruder.** Port `_rebuild_mesh`'s slice loop to `TrackMeshGenerator` (`@tool`):
   tessellate → per-slice `sample_baked_with_rotation(offset, cubic, tilt)` → quad strip
   between slices from the profile → normals + UVs into `ArrayMesh`.
3. **Width/tilt interpolation.** Replace the static rect profile with a per-slice profile whose
   width lerps between `point_data[i].width` (like the profile's `offset`/`subdivisions`
   affordances, or a custom profile built per slice). Tilt already rides in the slice transform.
4. **ROAD recipe.** Ribbon surface + two side-wall quads (extrude the profile's vertical edges
   upward). UV `u` = distance along spline (texture tiling), `v` = across track.
5. **TUNNEL recipe.** Add roof from `recipe_param` height; walls become tunnel sides.
6. **Physics.** `create_trimesh_shape()` from the generated `ArrayMesh` under a
   `StaticBody3D` + `CollisionShape3D` child, per ADR 0009/0010 (generated sections are their
   own body; modeled terrain is separate).
7. **Editor integration.** A bake button (mirroring PathMesh3D's) or auto-regeneration on
   spline `changed`, honoring the standing rule that the user verifies visually.
8. **Export option (later).** GLTFDocument export of a baked section when it needs DCC polish
   (already noted in `tracks-and-splines.md`).

## Uncertainties to resolve when picked up

- **GDScript port vs compiled GDExtension.** The plugin is C++ (speed), but our whole project
  is GDScript and the algorithm is light enough that a GDScript port is very likely the right
  call. Compiling the GDExtension adds a `godot-cpp` toolchain + platform binaries to the repo —
  heavy for a small racing project. Default lean: GDScript port reusing PathMesh3D as reference
  (MIT attribution in the file header if code is closely followed).
- **Godot version match.** If we DID compile, godot-cpp must be pinned to Godot 4.7
  (project's version) — GDExtension ABI is version-locked.
- **Tilt source.** Our banking is native Curve3D per-point `tilt`; PathMesh3D's `tilt` flag
  feeds `sample_baked_with_rotation`. Verify interpolation matches our `sample_normal` docs
  (`forward × banked lateral`) so generated walls/roof line up with gameplay normals.
- **Branch gaps.** ADR 0010 defers branch mesh; splits/joins will leave open ends at
  connection points. Confirm acceptable (likely: modeled set-pieces fill them).
- **Recipe span semantics.** "Span AFTER the point" + spans infer from trailing point — confirm
  the extruder maps recipe per baked-slice, not per control-point, so interpolation stays smooth
  across recipe changes.
- **Bake cadence + perf.** Regenerate on every `changed` may be heavy for long tracks; a
  manual bake button (or debounce) may be better. Decide in execution.
- **StaticBody3D collision shape.** Trimesh from generated mesh (per PathMesh3D approach) —
  confirm it is fine for hover-raycast gameplay (pod hovers over it), not just AI/obstruction.

## Out of scope (deferred)

- Branch/alternate-path mesh pass (ADR 0010).
- Modelled-terrain stitching (ADR 0009) — coexist only.
- Procedural material/UV atlas generation beyond what the ribbon needs.

## Notes for the exec session

- Stand prior standing rules: plan must be committed to (mirror steps into the todo list tagged
  `[MESH]`) before execution; plugin reloads need the user; assistant does parse + scan + log
  checks only, user verifies visually; code standard = spaced colons + trailing semicolons.
- Reference repo is external (`C:\Projects\Godot\Plugins\PathMesh3D`) — read-only source, do
  not edit it.
