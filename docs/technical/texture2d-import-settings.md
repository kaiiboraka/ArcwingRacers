# Texture2D Import Settings

> Reference for Texture2D import settings — chiefly which **Compression Mode** to use for lightmap `.exr` files and ordinary textures. Companion to `model-and-level-setup.md`.

Under Import → **Compress → Mode** (applies per texture resource).

---

## VRAM Compressed (BC6H/BPTC) — for 3D scene textures & lightmaps

- **Where compressed:** stays compressed in VRAM (GPU memory).
- **Memory footprint:** ~**2.6 MiB** for a 2K texture.
- **Performance:** maximum — direct GPU read.
- **Use case:** textures, lightmaps, HDR environment maps. Standard for 3D games.

## Lossy (WebP / JPEG) — NOT for 3D

- **Where compressed:** compressed *on disk* (small `.import` file), but **decompresses into raw uncompressed VRAM** when loaded.
- **Memory footprint:** **32 MiB** in VRAM for a 2K texture (same as uncompressed).
- **Performance:** poor — large VRAM footprint, high bandwidth strain, slow disk load time (decompression CPU overhead).
- **Use case:** UI elements, non-frequent 2D textures where low disk/download size outweighs VRAM and render speed.

**Do NOT use Lossy for 3D scene textures or lightmaps. Use VRAM Compressed.**

---

## Recommended settings by texture role

| Texture | Mode |
|---|---|
| Lightmap `.exr` | **VRAM Compressed** (BC6H/BPTC preserves the HDR range the lightmap needs) |
| 3D albedo/normal/maps | **VRAM Compressed** |
| HDR environment maps / skybox | **VRAM Compressed** |
| UI elements / rare 2D art | Lossy acceptable (disk-first) |