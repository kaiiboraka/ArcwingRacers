# Code Review Checklist

Run this before marking any coding task complete, and use it when reviewing a PR. It does not restate technical rules — those live in `docs/technical/`. It exists to confirm those rules were actually followed, and that the code matches design intent.

---

## 1. Design Alignment

- [ ] The file header links to the relevant `game-design/` and/or `systems/` doc(s), per the header format in `technical/code-standards.md`.
- [ ] You've actually read the linked doc(s) — not just confirmed they're linked. Behavior should match stated design intent.
- [ ] Nothing in the code makes a design decision the docs don't already make. If a referenced doc is a stub or has a `[TBD]` the code is now resolving, stop — surface it instead of silently filling it in (see `agent-rules.md`).
- [ ] Named entities in code (classes, asset names, constants) match the canonical names used in the docs — no silent renaming drift between design and implementation.
- [ ] If the implementation reveals the design doc is wrong, incomplete, or ambiguous, that gets fixed or flagged in the same PR — not left as a silent mismatch.

## 2. Technical Standards Compliance

- [ ] **Start with `technical/code-standards.md`.** It's the master reference for this project — naming, file/folder structure, script-type choice (plain C# / Resource / Node), Godot lifecycle patterns, scene organization, 2D physics & rendering, timers/tweens, process vs signal updates, inspector conventions, and file header format. Every PR is checked against it in full, not just the line items below.

The docs below expand specific sections of `code-standards.md` in more depth — check the diff against these too:

- [ ] Event wiring uses the correct tier and follows naming conventions — `technical/game-events.md`
- [ ] No new singleton introduced without justification; shared state goes through Resource variables or bootstrapper wiring, not `.Instance` discovery — `technical/singleton-controllers.md`
- [ ] Most anything spawned/destroyed frequently at runtime is pooled correctly separated — `technical/object-pooling.md`

If a rule was deliberately broken, that needs an ADR (`decisions/adrs/`), not a silent exception.

## 3. Scope & Hygiene

- [ ] The PR does one thing. Unrelated fixes, refactors, or cleanup are split into their own PR.
- [ ] Unless explicitly specified in the comments, no commented-out dead code (git has history — delete it).
- [ ] No new package or dependency was added without prior approval (per `agent-rules.md`).
- [ ] Files under `decisions/adrs/` are untouched. A changed architectural decision gets a new ADR, not an edit to an old one.
- [ ] Any new non-original audio asset has a corresponding entry in `technical/audio-licensing.md`.

## 4. Before Marking Complete

- [ ] Every box above has actually been checked against the diff, not assumed.
- [ ] Any open question, ambiguity, or `[TBD]` surfaced during implementation has been raised with the user — not resolved by guessing.
