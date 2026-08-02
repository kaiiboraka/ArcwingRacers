import re
import sys

SCOPE = [
    r"Content\Scripts\Resources\audio_bucket.gd",
    r"Content\Scripts\Resources\audio_data.gd",
    r"Content\Scripts\Resources\audio_file.gd",
    r"Content\Scripts\Resources\mana_crystal_resource.gd",
    r"Content\Scripts\starting_line.gd",
    r"Systems\Input\InputCollector.gd",
    r"Systems\Pod\Beam3D.gd",
    r"Systems\Pod\PodController.gd",
    r"Systems\Skybox\sky_preview.gd",
    r"Systems\Skybox\skybox_controller.gd",
    r"Systems\Track\branch_connection.gd",
    r"Systems\Track\spline.gd",
    r"Systems\Track\spline_point_data.gd",
    r"Systems\Track\track_spline.gd",
    r"Systems\Track\track_spline_data.gd",
    r"tests\test_track_branch_reconcile.gd",
    r"addons\arcwing_track_editor\plugin.gd",
    r"addons\arcwing_track_editor\track_spline_gizmo_plugin.gd",
    r"addons\arcwing_track_editor\path_data_dock.gd",
    r"addons\utility_scripts\Debug\debug_logger.gd",
    r"addons\utility_scripts\Debug\debug_manager.gd",
    r"addons\utility_scripts\Debug\property_entry.gd",
    r"addons\utility_scripts\imports\glb_to_scene_generator.gd",
    r"addons\utility_scripts\imports\model-importer_convex_staticbody.gd",
    r"addons\utility_scripts\imports\model-importer_trimesh_staticbody.gd",
    r"addons\utility_scripts\terrain_mesh_combinator.gd",
]

ROOT = r"C:\Projects\ArcwingRacers"


def split_comment(line: str):
    """Return (code, comment) splitting on the first '#' that starts a comment."""
    in_s = None
    i = 0
    n = len(line)
    while i < n:
        c = line[i]
        if in_s:
            if c == "\\":
                i += 2
                continue
            if c == in_s:
                in_s = None
        else:
            if c in ("'", '"'):
                in_s = c
            elif c == "#":
                return line[:i], line[i:]
        i += 1
    return line, ""


def mask_strings(code: str):
    """Replace string literals with \x00<idx>\x00 placeholders; return (masked, strings)."""
    masked = []
    out = []
    i = 0
    n = len(code)
    while i < n:
        c = code[i]
        if c in ("'", '"'):
            q = c
            j = i + 1
            while j < n:
                if code[j] == "\\":
                    j += 2
                    continue
                if code[j] == q:
                    j += 1
                    break
                j += 1
            idx = len(masked)
            masked.append(code[i:j])
            out.append("\x00%d\x00" % idx)
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out), masked


def restore(code, masked):
    for idx, s in enumerate(masked):
        code = code.replace("\x00%d\x00" % idx, s)
    return code


def mask_braces(s: str):
    """Replace balanced {...} spans (dict literals) with \x00D<idx>\x00 placeholders
    so colon-subs never touch dict keys/defaults. Returns (masked, spans)."""
    spans = []
    out = []
    i = 0
    n = len(s)
    while i < n:
        c = s[i]
        if c == "{":
            depth = 1
            j = i + 1
            while j < n and depth > 0:
                if s[j] == "{":
                    depth += 1
                elif s[j] == "}":
                    depth -= 1
                j += 1
            idx = len(spans)
            spans.append(s[i:j])
            out.append("\x00D%d\x00" % idx)
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out), spans


def restore_spans(code, spans):
    for idx, s in enumerate(spans):
        code = code.replace("\x00D%d\x00" % idx, s)
    return code


VAR_RE = re.compile(r"\b(var|const)\s+([A-Za-z_]\w*)\s*:\s*(?![=:])")
FOR_RE = re.compile(r"\bfor\s+([A-Za-z_]\w*)\s*:\s*(?=[A-Za-z_])")
SIG_START_RE = re.compile(r"\b(func|signal)\s+\w+\s*\(")
PARAM_COLON_RE = re.compile(r"\b([A-Za-z_]\w*)\s*:\s*(?=[A-Za-z_])")


def fix_signature_params(code: str, start: int) -> str:
    open_idx = code.index("(", start)
    depth = 0
    i = open_idx
    n = len(code)
    while i < n:
        c = code[i]
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
            if depth == 0:
                break
        i += 1
    if i >= n:
        return None  # unbalanced on this line (multiline signature) — leave alone
    close_idx = i
    params = code[open_idx + 1 : close_idx]
    masked_params, spans = mask_braces(params)
    new_params = PARAM_COLON_RE.sub(
        lambda m: "%s : " % m.group(1), masked_params
    )
    new_params = restore_spans(new_params, spans)
    return code[: open_idx + 1] + new_params + code[close_idx:]


def fix_line(code: str) -> str:
    code = VAR_RE.sub(lambda m: "%s %s : " % (m.group(1), m.group(2)), code)
    code = FOR_RE.sub(lambda m: "for %s : " % m.group(1), code)
    for m in reversed(list(SIG_START_RE.finditer(code))):
        fixed = fix_signature_params(code, m.start())
        if fixed is not None:
            code = fixed
    return code


def main():
    total_edits = 0
    for rel in SCOPE:
        path = ROOT + "\\" + rel
        with open(path, "r", encoding="utf-8", newline="") as f:
            raw = f.read()
        lines = raw.split("\n")
        out_lines = []
        for line in lines:
            code, comment = split_comment(line)
            masked_code, masked = mask_strings(code)
            new_code = fix_line(masked_code)
            new_code = restore(new_code, masked)
            if new_code != code:
                total_edits += 1
            out_lines.append(new_code + comment)
        new_raw = "\n".join(out_lines)
        if new_raw != raw:
            with open(path, "w", encoding="utf-8", newline="") as f:
                f.write(new_raw)
            print("edited: %s" % rel)
    print("lines changed: %d" % total_edits)


if __name__ == "__main__":
    main()
