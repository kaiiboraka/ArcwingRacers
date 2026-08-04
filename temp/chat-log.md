@UI/HUD/Spedometer/spedometer.tscn @UI/HUD/Spedometer/spedometer.gd 

%SpeedText_RichTextLabel needs to have its text updated with the integer of our current speed. I want the color to be cyan (0R 255G 255B) from 0-100mph, and then from there i want it to lerp colors--from cyan to pure green (lose blue), then from green to yellow (gain red), then from yellow to red (lose green), then from red to magenta (gain blue). the lowest color (cyan) goes from 0-100 mph, and the highest color is anything over 1000mph. ignoring 0, i want the floor and ceiling (100,1000) adjustable exports on the spedometer so i can tweak it how i like. the rest should interpolate smoothly between those ranges. the color to change is the font Theme Override "default color".

then the boost light logic:
%LightTexture and its one child (GlassTubes, doesn't really matter what it's called) both change their self-modulate to the color
%PointLight2D also sets its color.
as they change color they should lerp from white to the color, or whatever color they were to the new color (default to white), and while they do that the alpha of the PointLight2D's color also needs to lerp--down to 0 and back up to 1 between each color change.
%LargeIcon_ALPHA also needs to map its self modulate Alpha to 0 during White color and to 1 for any other color, going down to 0 and back up just like the light's does.

make spedometer a tool script and have it so there is an export LightColor that I can tweak the light and see how all of the aforementioned logic reacts to changes. the color I choose there should be what is changed by external input. in other words, this export field will be the source of truth for the current light color, driving the modulates and alphas of all those other components.

remember to abide by the 4 pillars architecture outlined in the docs. this should all be responsive to signals.

### fill bar logic

i traced a multi-segmented pixel line to measure the length of my odd spedometer bar, so we're going to do some programmatic procedural animation of some clipping masks to cover it properly. we're going to be hiding/showing, moving, and rotating several child clipping masks as we progress past certain thresholds of percentage. arriving at a certain percentage should enforce the following:

fill 1 starts at:
-75 189, 0 deg (starting position)
then goes to 
-26 189, 0 deg
from pixels 0 to 49 / 260 (the first 18.46% of progress)

then starts rotating from 
-26 189, 0 deg
to 
-26 189, -20 deg (final position)
from pixels 49 to 60 / 260 (up to 23.077%)

23 %

fill 1 stops moving (still active tho)
fill 2 appears instantly

fill 2 starts at:
53 193, 70 deg (starting position)
then rotates to 
53 193, 45 deg
from pixels 60 to 66 / 260 (up to 25.38%)

then goes from
53 193, 45 deg
and slides to:
137, 110, 45 deg (final position)
from pixels 66 to 150 / 260 (up to 57.7%)

57.7 %

fill 2 stops moving (still active tho)
fill 3 appears instantly

fill 3 starts at
137, 110, 45 deg (starting position)
then rotates to
137, 110, 0 deg
from pixels 150 to 160 / 260 (up to 61.54%)

then goes from
137, 110, 0 deg
then rotates to
137, 111, -45 deg
from pixels 160 to 170 / 260 (up to 65.39%)

then goes from
137, 111, -45 deg
then slides up to
48, 22, -45 deg (final position)
from pixels 170 to 260 / 260 (up to 100%)

100 %

...

large jumps in percentage should instantly hide fills that are outside of that percentage range. for instance, if you go from 100% to 5% instantly, fill 2 and 3 should go down to their starting states where they hide instantly and then reset their transforms to their starting positions. if you jump from 5% to 40%, then fill 1 should instantly jump to its final position, 3 is disabled, and 2 goes to the lerped position/rotation between the 2 surrounding checkpoint positions.

## 
- deceleration is not happening when the accelerator is released. it should be.
- the speed units are all jacked up. 200 is good in meters per second, but the visual change to inflate the numbers to MPH makes it hard to balance. either we need to keep it in MPS and lie and just call it MPH for kicks and giggles, or we need to retool the stats themselves to be in terms of MPH and propagate it out from there. Suggest some potential solutions.
- ramps are still horrid. the sheer forward momentum of my vehicle should be enough to keep me in the air for a while, but instead i just sort of slide off of it and go nowhere. not sure what the answer is there, except maying interrogating the hover casts--am i constantly being turned to orient towards the normal of the surfaces my rays collide with? because if not i should be, constantly.

### ANIMATIONS BACKWARDS

I'm faced with an agonizing dilemma. I have two wings in my arcwing scene. one is just fine. the left wing. it's great. the right wing situation is kind of a nightmare. ideally, i'd be able to just take my left wing, duplicate, and mirror it, and all would be hunkydory. except for some insane reason, the material used on one of the parts of the machine has a psycho problem with being scaled like that and turns inside out and it's really distracting. for almost certainly related reasons, the tether to the rig-marker does not work on the mirrored one. originally i was just using a mirrored right mesh, but everything changed when i decided to finally animate these things. so i have been battling with Autodesk Maya trying to figure out the simplest way to model rig and animate these things, especially the right-side mirror, and I finally got it to a point I think I can handle. I make the first model and the first joint skeleton, and I mirror both. Then I go through the binding and skin weight painting for each, as unfortunately the weights do not mirror intelligently. so then they're weighted, great. now i export them. one small problem: i already animated a bunch of stuff on the old version that had a differently named bone hierarchy. no problem, right, just retarget. that's fine. we did that for the left wing, still works great. but now retargeting the right side, plays the same animation exactly as written... but the problem is that the animations are made for left side wings, not right side. now my right wing is flipping upside down and opening at the same angle in the same way as the left side, and everything is wrong and backwards here. i have an option to write a script that will mirror the animation tracks inside the animation library, but i don't know if that's going to work to be honest. i haven't had consistent results so far. I have Content/Animations/mirror_animations.gd editor script, but that doesn't seem like the right answer. so that means, going forward, I would model rig and animate the one left side as excpected, then mirror it in engine, and run this script to mirror the animations? i guess that doesn't sound so bad saying it that way... I guess we could make this simpler, too: what if instead of adding tracks to existing animations, is it so painful to just make a new animation in the library that is the mirrored version? just suffix each one with _flipped or _mirror or something. I would need to make sure that if i make changes to the left side animations, that if I run the script again, it would be able to overwrite the existing mirrors if they exist. then in code, we just need to play the mirror track for the mirrored wing, since we have internal reference to them both, right? so i'll just always have to make th left wing first. so that was a lot... what do you think of my dilemma? is my solution okay? what are industry standard techniques and processes for making animations of reversed objects like this? i have no idea what i'm doing and i'm making it up as i go. can you help me? not sure if i even want to go down the mirror animations path. i have no idea what the best way forward is. if i could just figure out what was wrong with the material i wouldn't need a second object altogether and i'd just have one which would be SO EASY. but the dumb material (which has a bunch of stuff to make it glassy and clear: zero roughness, clearcoat, backlighting, alpha, etc.) keeps facing backwards/inside out, and idk what was wrong with that joint bug. so annoying. what should i do? which way to proceed? HELP


The user has a genuine 3D pipeline dilemma. Let me understand the problem fully:

1. They have two wings in their arcwing scene. Left wing is fine. Right wing is a nightmare.
2. They tried mirroring the left wing mesh in-engine (scale -1 on X), but the material (glassy material with zero roughness, clearcoat, backlighting, alpha) has a "psycho problem" — turns inside out (normals flip).
3. The tether to the rig-marker doesn't work on the mirrored one.
4. They moved to Maya: model + rig left side, mirror both, bind + skin weight each side manually.
5. They animated on the old version with a differently-named bone hierarchy. Retargeted to the left wing fine. Retargeting the right side plays the animation "exactly as written" — but animations are made for left wings, so the right wing flips upside down, opens at the same angle as the left, everything is backwards.
6. They have Content/Animations/mirror_animations.gd editor script, but aren't confident it works.
7. They're considering: model/rig/animate left side, mirror in engine, run a script to mirror animation tracks. Or simpler: create mirrored animations in the library (suffix _flipped/_mirror), overwrite existing on re-run, and code plays the mirror track for the mirrored wing.
8. They're asking: what are industry-standard techniques for animating reversed/mirrored objects? Is their solution okay? What's the best way forward?

This is a consulting/advice question. The user explicitly says "can you help me?" and "what should I do? which way to proceed?" They want guidance, not necessarily code right now.

Let me think about the actual technical issues and the best industry-standard solutions.

The core problems:

Problem A: Mirroring a mesh in-engine via negative scale flips normals.
When you mirror a mesh by scaling -1 on an axis, the winding order of triangles flips, which makes backfaces front-facing. In Godot, the "material inside out" symptom. There are several ways to handle:
- The proper fix: don't mirror the mesh via negative scale. Instead, create a properly mirrored mesh. In Godot, you can't easily flip winding in-engine without double-sided material or flipping normals in a shader.
- Actually, the glassy material with alpha is likely double-sided-off. A mirrored mesh's faces are inverted, so the glass material's front faces become back faces.
- Industry standard: you mirror geometry in the DCC (Maya), where you can flip normals properly. Which they've now done. Good.

Actually wait — they've already moved to Maya and mirrored the geometry there properly. So Problem A is mostly solved by their new pipeline. But they mention "if I could just figure out what was wrong with the material i wouldn't need a second object altogether". So there's still an allure to just having one object mirrored in engine.

The material problem: a mirror-scaled mesh has flipped winding. Fixes:
1. Enable cull_mode = CULL_DISABLED (double-sided) on the material. For a glassy material this is common anyway (glass often double-sided). But it doubles fill rate and can look wrong with backlighting/alpha.
2. In the shader, flip the winding via front-face detection: if (not gl_FrontFacing) { normal = -normal; } — the standard fix. In a Godot shader you can do FRONT_FACING — Godot has FRONT_FACING built-in? Godot 4 has FRONT_FACING in spatial shaders. Yes: FRONT_FACING boolean in Godot 4 spatial shaders (bool FRONT_FACING). So you can negate the normal when not front-facing.
3. Actually, the real answer: for a single mirrored mesh, negative scale flips winding; the correct engine-side fix is to flip the triangle winding. Godot doesn't expose "flip winding" per mesh at import easily... Actually there's no direct "mirror" import option. You'd regenerate the mesh. So double-sided material or FRONT_FACING normal flip in shader.

But honestly, the cleaner industry answer: mirror in the DCC. Which they're doing.

Problem B: The rig-marker tether doesn't work on the mirrored one.
This is about their tether system. The left wing is tethered to a "rig-marker" — presumably a Node3D marker that drives position/rotation. When the right wing is a mirrored copy, the tether expects mirrored space, but if the marker is shared or the mirrored node's transform handling differs... Actually the tether probably drives a bone or node via transform. If the right wing is a negative-scaled copy, its local space is mirrored, so a transform that works for the left tether appears mirrored/inverted on the right. This is a symptom of the mirrored-negative-scale approach. Once they have a properly-mirrored mesh with its own skin, the tether (with mirrored bone hierarchy) should work if the tether logic accounts for the mirrored hierarchy, or if the rig itself is mirrored.

Hmm, "tether to the rig-marker" — let me look at what they have. There might be a rig-marker concept in their scene. Let me search the codebase. Actually, this is a big consulting question. Let me investigate the actual project to give grounded advice. Let me look at:
- The wing scenes and rig setup
- Content/Animations/mirror_animations.gd — their existing script
- The Arcwing scene structure, wing nodes
- How the wing animation/tether works (PodController _play_wing_anim? wing nodes?)

Let me explore the repo to ground my advice. This is worth doing because the user says "we did that for the left wing, still works great" and mentions retargeting. There's _play_wing_anim in PodController which plays wing animations. And _drive_wing_open. And the wing library Arcwing.res.

Let me think about what to actually answer. The user wants:
1. Validation of their plan.
2. Industry-standard techniques for mirrored/opposite-side animation.
3. Recommendation on the mirror-animations-in-library approach vs engine-script approach vs trying to fix the material.

Let me think hard about the correct technical solution for animation of a mirrored character/vehicle part.

Industry standard for mirrored animation:

The classic problem: humanoid rigs. Industry standard = mirror the skeleton (bone transforms) and retarget with mirrored name mapping (e.g., Left_Arm ↔ Right_Arm). For a vehicle with left/right symmetric parts, the same applies: the rigs are mirror images, animations authored on the left must be mirrored for the right.

Two main approaches:

Approach 1: Bone-name mirror mapping in the animation player / retargeter.
Standard retargeting maps bones by name with a mirror convention. For the right wing, you mirror the animation by swapping bone names (and negating the mirrored rotation axis). This is what their mirror_animations.gd script tries to do in-engine.

Approach 2: Author animations twice (left + right) in the DCC.
Actually no — nobody hand-animates both sides. You animate the left, then mirror in the DCC to get the right animation. In Maya there's a "Mirror Deformer Weights" and you can mirror animation curves via the Animation/Mirror tool. But retargeting...

Actually, let me think about what's REALLY the best here. The key insight:

Their rigs are mirror images. If they mirror both the mesh and the skeleton in Maya (as they're doing), then the right wing's bone hierarchy is named Right_* or mirrored with _L/_R suffixes. The left animation authored for Left_* bones. To play on the right, you need to either:
1. Rename bones so both sides share names, and negate rotations — no.
2. Mirror the animation data: swap left/right bone tracks and negate the appropriate axis.

The fundamental question: negating the mirrored axis.

When you mirror a rotation animation across X (the left-right plane), yaw flips sign. So every rotation keyframe needs one axis negated (the mirror axis component). And the track target bone path changes to the mirrored bone name.

Their script mirror_animations.gd likely tries this. The user says "i haven't had consistent results so far."

The cleanest solution the user proposes: pre-baked mirrored animations in the library, suffix _flipped/_mirror.

Is this good? Let me evaluate:
- Pro: simple to reason about. The right wing plays a distinct clip. Code picks the clip by wing side. Changes to left animation → re-run the mirror script to regenerate (overwrite). 
- Pro: no runtime mirroring cost, no risk of bone-name mismatch if you bake track paths.
- Con: doubles animation library size (minor for a small set of clips). 
- Con: you must remember to re-run the mirror script after editing left animations. 
- Con: the mirror script must correctly negate the mirror axis AND swap left/right bone names AND handle Euler vs quaternion representation.

Actually, baking a mirrored clip is a completely legitimate, standard technique. In AAA, this is often how vehicle parts and symmetric props are handled — pre-mirrored animation data, or runtime mirroring in the animation system.

Alternative runtime approach: A runtime AnimationPlayer that plays mirrored data. In Godot, Animation is a Resource; you can mirror it at load time in code and play the mirrored copy for the right wing. The AnimationLibrary could hold mirrored variants generated at _ready. This avoids an editor script entirely — generate mirror clips at runtime.

But wait — the user already animates via the _play_wing_anim function in PodController with the library. Let me look at how the wings are actually driven. The Arcwing.res library with idle/turn/transition animations, per-wing. Let me examine.

Actually, I should explore the codebase before giving concrete advice. Let me look at:
1. The wing node structure in Arcwing.tscn
2. mirror_animations.gd
3. How _play_wing_anim and the library work
4. The material that's causing problems
5. The "rig-marker" / tether system

Let me search. Given the complexity, I should use the explore agent or direct searches. Let me do targeted searches.

Let me think about what the actual best answer will be, then verify against the code.

My recommendation synthesis:

1. Don't fix the material problem by fighting the mirror. The mirrored-negative-scale mesh approach is fundamentally broken for a glassy double-sided material unless you do shader-level normal flipping. But honestly the cleanest path is what they're already doing: properly mirrored geometry + rig in Maya. The material issue is a strong argument FOR the two-object pipeline, not against it. However — I can offer the shader fix if they really want one object. The FRONT_FACING normal-flip in the glass shader is the standard engine-side fix.

2. The mirror-animation approach is correct and standard. Industry practice for symmetric parts:
   - Author on one side (left).
   - Mirror the skeleton weights in the DCC (they do).
   - Mirror the animation curves to produce the right-side animation. In-engine or in-DCC.
   
3. Between the two engine options (mirror tracks in-place vs bake separate _flipped clips): Baking separate clips is the more robust choice because:
   - It's idempotent and auditable.
   - You can regenerate/overwrite on re-run.
   - The code just picks the clip by side — no bone-path remapping at runtime.
   - It isolates mirroring bugs to one script + generated data.

4. The bone-name problem is the crux. The reason retargeting the right side plays "exactly as written" (upside down) is that the right wing's bone hierarchy has mirrored NAMES (or the retarget mapped to same-named bones without negating the mirror axis). The mirror script must handle:
   - Track path remapping (left bones → right bones).
   - Rotation negation across the mirror plane.
   
5. Actually, wait — I should understand their current setup better. "i already animated a bunch of stuff on the old version that had a differently named bone hierarchy. no problem, right, just retarget. that's fine. we did that for the left wing, still works great. but now retargeting the right side, plays the same animation exactly as written... but the problem is that the animations are made for left side wings, not right side."

So the retargeter (their retargeting system?) maps animations from old bone names to new bone names. For the right wing, the target bone hierarchy is the right-side mirrored skeleton. If the retarget maps by name pattern and the right side has mirrored names, then... the animation plays the left-authored rotations on right-named bones, giving mirror-flipped result.

The fundamental fix: negate the mirror-axis rotation component on every rotation keyframe when mapping to the right side.

So the mirror script must do:
- For each track: remap bone path from left naming to right naming.
- For each rotation keyframe: negate the axis perpendicular to the mirror plane (the yaw component), e.g., if mirroring across X, negate rotation Y (or the appropriate Euler component / quaternion axis).
- For position tracks: negate the X position component.
- For scale: negate X (if the mesh itself is also mirrored) — but if geometry is pre-mirrored in Maya, scale stays positive.

Now — the mirrored geometry is already done in Maya with correct normals (so the glass material is fine on the second object). So the scale-negation concern is moot. Good.

Let me also consider: do they even need two rigs? Alternative: ONE rig, mirrored animation handling. Some engines use a single rig and mirror at the animation level. But with two separate meshes (left + right geometry), two separate skins, they need two skeletons. Their current pipeline: mirror the skeleton in Maya, skin each side. So two skeletons with mirrored bone hierarchies.

Actually, here's a cleaner industry option they might not have considered: Mirror the animation in Maya and export the right-side animation as separate clips. I.e., in Maya, use the animation mirroring (in Maya 2022+, "Mirror" in Animation: you can mirror character animation curves) to author the right-side animation, then export right-side clips. Then no engine mirroring at all. But the user seems to want to author on one side and get both. The engine-script approach (bake mirrored clips) is fine and standard too.

Let me also address the material "turns inside out" more concretely since they said "if I could just figure out what was wrong with the material i wouldn't need a second object altogether." I should explain WHY: negative scale flips triangle winding → normals point inward → a one-sided glassy material (cull backfaces) renders the backfaces which look inside-out. And alpha/clearcoat/backlighting make it worse. The fix if they wanted one object:
- Double-sided material (cull_mode = CULL_DISABLED in StandardMaterial3D, or cull_disabled = true), OR
- Shader: negate normal when !FRONT_FACING.
- Also the light-shading on flipped winding is wrong; for a mirror, you'd want to flip winding at mesh level, which Godot can't easily do post-import without regenerating.

But honestly: even with the material fixed, the rig-tether on a negative-scaled object is still problematic (Problem B — the tether likely drives bones/transforms in mirrored space). So the mirrored-negative-scale route is a dead end for the animated wing. The two-object route is right.

Now, let me investigate the codebase to ground the answer. Key things to find:
- Content/Animations/mirror_animations.gd — what it does now, why it might not work.
- The wing structure & how animations are played (_play_wing_anim, _drive_wing_open).
- The "rig-marker" tether — search for rig-marker / tether.
- The glass material on the wing part.

Let me do the exploration. I'll launch parallel searches. Actually let me use grep/glob and read files directly since I know the project.

Let me search for:
- "rig-marker", "rigmarker", "rig_marker", "tether"
- mirror_animations.gd read
- Arcwing.res / wing animation library
- The material used on the wing parts

Given the scale, let me use the explore agent? Or direct. I'll do direct searches in parallel. Let me start.

Actually, I realize I should be careful about scope. The user asked a big advice question. They might appreciate: (1) a clear recommendation, (2) grounded in their actual code (I should look at the script they mentioned), (3) maybe offer to fix/rewrite the mirror script. But I shouldn't write code unless they want. The message is asking for advice/direction. Let me investigate enough to give grounded advice, then present options and ask what they want me to do (e.g., rewrite the mirror script to bake _flipped clips).

Let me explore. I'll look at:
1. Content/Animations/mirror_animations.gd
2. How wings are structured + animations played
3. The tether/rig-marker
4. The glassy material

Let me run parallel glob/grep/read.

For finding the wing animation stuff: PodController _play_wing_anim at line 860. Let me read that region. Also _drive_wing_open at 835.

Let me search for the rig-marker tether concept.

I'll launch several searches in parallel.
Let me look at your actual setup before advising — the mirror script, how the wings are animated, and that tether/material:
Glob "**/mirror_animations.gd" (1 match)
Grep "rig.?marker|tether|RigMarker|rig_marker" in . (2 matches)
Grep "_play_wing_anim|_wing_lib|AnimationPlayer|_drive_wing_open|_wing_left|_wing_right|AnimationLibrary" in Systems\Pod\PodController.gd (38 matches)

The user's already using Godot's retargeting (BoneMap + SkeletonProfile) with separate left/right bone maps. Let me read those — they're the key to the diagnosis:
Read Content\Animations\pod_L-wing_bone-map.tres 
Read Content\Animations\pod_R-wing_bone-map.tres 
Read Content\Animations\pod_wing_skeleton-profile.tres 


Okay, I dug through your actual setup — and I have good news: your instinct is right, it's the industry-standard approach, and the reason it "hasn't worked" is two concrete bugs, both fixable. Here's the full picture.
What's actually going on
1. The mirror script has been a silent no-op on the wrong file.
- Your live library is Arcwing.res (Arcwing.tscn:9 loads it; PodController.gd:362 preloads uid://cgtuava0eboh0 = the .res).
- mirror_animations.gd edits Arcwing.tres — a stale duplicate (last saved 8/2 vs .res 8/4). Even a perfect script would edit a file nobody loads.
- Worse: _mirror_path only rewrites bone names that start with L_, but the library tracks use generic profile names — Skeleton3D:wing_root, sail_root, etc. — with no L_ prefix. So mirror_path == src_path → continue on every track. Zero tracks mirrored, every run.
2. Your retargeting only renames bones, never mirrors values. Your retarget uses pod_wing_skeleton-profile.tres (35 generic bones) + pod_L-wing_bone-map.tres / pod_R-wing_bone-map.tres (generic → L_* / R_*). Godot's retarget remaps track paths by name and nothing else — it plays the left-authored rotations verbatim on the right rig. That is exactly "plays the same animation as written... right wing flipping upside down." Not a Maya problem. A missing-mirror problem.
3. Your script's math is actually correct. Positions negate x; quaternion (-x, y, z, -w) is the correct sagittal-plane reflection (I verified the quaternion algebra). The _mirror_basis (M·B·M) is right too. The machinery is fine — it just never gets invoked.
Your proposed solution is the right one
"Author the left wing, mirror it in engine, bake _flipped clips that overwrite on re-run, and play the mirror clip on the right wing" — yes, this is the standard technique. The industry term is mirrored/opposite-side animation data: symmetric rigs are authored on one side, and the opposite side consumes mirrored curves (UE has mirror nodes, Unity humanoids mirror automatically; Godot has no value-mirroring retarget, so baking mirrored clips is the idiomatic equivalent). Nobody hand-animates both sides.
The corrected plan, concretely:
1. Keep authoring left-only in Maya (keep your retarget as-is).
2. Rewrite the script to target Arcwing.res and, for each of the 6 animations, create/replace a _flipped twin: same generic track paths, mirrored key values only. It's idempotent — re-run regenerates. It works with your retarget because the flipped clips still use generic bone names, so the right skeleton's R_ BoneMap remaps them as today.
3. In code, _play_wing_anim(player, idx, anim) uses anim + "_flipped" when idx == 1, and the right player's autoplay becomes Arcwing/Idle_Open_flipped.
(The one thing to validate by eye: which axis is "the mirror axis." Start with X — it matches your script's assumption and the wings sit at ±2.963 on X. If the right wing still moves mirror-backwards, it's a Y/Z swap — a 1-line tweak.)
Don't chase the material — it's a trap
Negative scale flips triangle winding, so a one-sided glassy material renders its backfaces — that's the "inside out." You can force it (double-sided material, or flip the normal when !FRONT_FACING in the shader), but it only fixes rendering: the skeleton transforms, the rig-marker tether, and the animation would still all be mirrored-wrong, so you'd still need all of this mirroring work. Two properly-mirrored meshes from Maya is the correct architecture, and your current right wing isn't even negative-scaled (its scene transform is a 180° rotation, det=+1) — so the material isn't broken right now.
Bonus: I found your tether bug
Beam_Right.point_b (Arcwing.tscn:291) points at Wing_Right_old — the disabled leftover wing — not the live Wing_Right. That's literally why the right rig-marker tether doesn't work. One NodePath fix, and there's a dead Wing_Right_old node to delete while we're in there.
So the way forward: fix the script's two bugs (right file + no-path-change mirroring), bake _flipped clips, play them on the right wing. Want me to do it? I can: rewrite mirror_animations.gd to regenerate _flipped twins in Arcwing.res, wire PodController to pick the flipped clip for the right wing, and fix the Beam_Right tether + remove the dead old wing.