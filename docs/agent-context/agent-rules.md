# Agent Rules

## Process Compliance

### Always
- When a documented process or standard exists for a category of work (asset licensing, code style, etc.), follow it exactly, every time — don't skip steps because a task feels small or low-risk.
- When a new recurring process is established (a new tracker doc, checklist item, tagging convention), wire it into the relevant rules/checklist file in the same session — a process that isn't enforced anywhere won't get followed later.
- Read `agent-context/context-map.md` at the start of every session before any other file.
- **Any multi-step plan — phases, roadmaps, task lists, agreed follow-ups, or brainstormed alternatives that end in a decision — MUST be written down to a working document file on disk BEFORE any execution begins.** Working plans go in `agent-context/plans/` (`plan-<topic>.md`). Never retain a plan only in conversation memory: context is finite and plans get lost mid-session. The moment an agreement is reached on what steps to take, document it immediately, then start executing. Mark items `✅`/done as they complete and note where the changes landed.
- **Once work on a plan is committed to, mirror its steps into the active todo list** (the session task-tracking tool), each item prefixed with a designation linking it to that plan — e.g. `[LPDE]` for `plans/plan-live-path-data-editor.md`. Keep the todo list as the live execution view of the plan; keep the plan doc as the authoritative design. Both get checked off as work lands.
- **Delegate code research / investigation to sub-agents** (the task tool with `explore` or `general` subagent type) whenever it spans multiple files or needs multi-round synthesis. Doing research inline burns context; sub-agents report back findings instead. Exceptions: anything needing live Godot editor/game access (logs, editor state, running game, `game_eval`) stays with the main agent; trivial single-lookup greps are cheaper done inline. Always give the sub-agent an exact prompt: paths to search, the specific question, and the report format.

---

## Design Docs (`docs/`)

### Always
- When something is implied but unspecified in a `docs/` file, append **`[TBD]`** inline.
- When a system or named concept appears in prose, link it to its doc: `[Movement](../game-design/gameplay/movement.md)`.
- Write in present tense, as design intent — not past tense, not conditional.
- Legacy docs from the previous Elythia project (Fantasy X 2D action-RPG) are marked as legacy in the doc status table. Do not assume their content applies to ArcwingRacers unless explicitly validated.

### Never
- Do not invent game design ideas. Clarify, correct, or organize what you're given — do not add.
- Do not fill in a [TBD] with invented content.
- Do not remove [TBD] or [Ref] or other tags — they are intentional markers.
- Do not leave "Resolution note," "Resolved per user decision," strikethrough history, or other meta-commentary about how a decision was reached once it's settled. Once a conflict or open question is resolved, rewrite the doc to state the current design plainly. Still-open questions and unresolved discrepancies stay flagged, but don't narrate the history once it's closed.
- Do not create a new doc file if an existing doc can absorb the content. Propose additions to existing docs first; only create a new file if there is no reasonable home.

### When to Ask
- Ask when the *intent* behind a design choice is unclear. Do not ask about minor phrasing or grammar — just fix it.
- **If an instruction contradicts standard Godot conventions (e.g., colliders not under PhysicsBody, wrong node relationships), stop and ask — don't reinterpret literally and run with it.** The user may have misspoken; surface the contradiction rather than guessing.
- If a doc is a stub (title only), do not infer its content from the filename. Ask.
- If two docs contradict each other, surface the conflict and ask before editing either.

---

## Coding (`Content/`, `Systems/`, `addons/`, `ui/`)

### Always
- Follow the four-pillar folder architecture: `addons/` (libraries), `systems/` (core mechanics), `ui/` (read-only displays), `content/` (assets, scenes, level scripts).
- Follow naming conventions from `technical/code-standards.md`: `PascalCase` for classes, `snake_case` for variables and functions (GDScript convention).
- Before implementing a new singleton or persistent manager, read `technical/singleton-controllers.md`.
- Before importing or committing any non-original audio asset, add or update its entry in `technical/audio-licensing.md`.
- Before implementing a new Godot system, confirm the Godot version in `technical/code-standards.md` and consult that version's docs.
- UI ↔ gameplay communication routes through the EventBus autoload at `systems/events/event_bus.gd` only: UI reads by subscribing to signals, writes by firing request signals.

### Never
- Do not add packages, dependencies, or plugins without asking first.

### When to Ask
- Ask before introducing a new architectural pattern not already present in `technical/`.
- Ask if the relevant `docs/` file for a system is a stub — don't implement from assumption.
