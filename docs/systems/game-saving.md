# Game Saving

Technical implementation rules for save/load. See `technical/testing.md` for the existing test targets (round-trip serialization, corrupted-data handling, coin values surviving a save/load cycle).

## Save Statue Design

Save is triggered by interacting with in-world **Save Statues** — not auto-saved on room transition. Two tiers:

| Tier | Function | Placement |
|---|---|---|
| Silver Statue | Save only | Mid-stage checkpoints |
| Gold Statue | Save + full HP/Mana restore | Before major story bosses |

Statues also serve as **fast-travel nodes** once activated. After completing a stage, a Silver Statue may upgrade to Gold as a post-completion reward. See the Obsidian note [[Save Statues]] for full design detail.

---

## File Format

**Never use `BinaryFormatter`** — it's deprecated by Microsoft and a known arbitrary-code-execution risk when deserializing untrusted or corrupted data. Use `JsonUtility` (or a JSON library) against plain serializable DTO classes instead.

`JsonUtility` cannot serialize: `Dictionary<,>`, top-level arrays (wrap them in a class), polymorphic types, or `null` (fields silently become default values). Design save DTOs around these constraints — flat classes with concrete fields, not collections-of-interfaces.

## Write Safety

Write atomically so a crash or app-kill mid-save can't corrupt the save file:
1. Write the new save to a temp file (`save.tmp`).
2. Replace the real file: `File.Replace(tempPath, path, path + ".bak")` (or `File.Move` if no file exists yet).

This satisfies `technical/testing.md`'s "handles corrupted data gracefully" target by construction — a crash mid-write leaves the old save intact, never a half-written one.

## Mobile Lifecycle

**`OnApplicationQuit` may never fire** when the OS kills a backgrounded mobile app — this is the normal way mobile apps die, not an edge case. Save in `OnApplicationPause(true)` instead, which fires reliably when the app is backgrounded. If `OnApplicationQuit` also fires (desktop, or a clean mobile quit), use **synchronous** file I/O there — an async save may not complete before the process is torn down.

`Application.persistentDataPath` resolves to a different real path per platform — don't hardcode or assume a path shape.

## Versioning

When the save format changes, migrate on the **raw JSON** (e.g. via `Newtonsoft.Json.Linq.JObject`) before deserializing into the current C# type — the old type may no longer exist in code, so you can't deserialize-then-convert. Stamp every save with a version number from day one, even before the first format change happens.
