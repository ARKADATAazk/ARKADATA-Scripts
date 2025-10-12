# ARKITEKT

**A REAPER toolkit for scoring, game audio, and music design.**  
Specialized workflow scripts + a reusable **ReaImGui** components library with a flexible **theme system**, and production-grade **apps** (e.g., Region Playlist, Theme Adjuster).

Developed by **ARKADATA**.

---

## Install (via ReaPack)

1. Install [ReaPack](https://reapack.com/).  
2. In REAPER: **Extensions → ReaPack → Import repositories…**  
3. Paste this URL and confirm:

```
https://raw.githubusercontent.com/ARKADATAazk/ARKITEKT/master/index.xml
```

4. **Browse packages** → install what you need → **Sync packages** to update.

---

## What’s inside

- **Apps**  
  Turn-key scripts focused on real workflows (e.g., *Region Playlist*, *Color Palette*, theme utilities).
- **ReaImGui Widgets (Library)**  
  A modular UI kit (chips, pads, grids, tiles, status bars, etc.) used across apps.
- **Theme System**  
  Centralized colors/skins with presets and per-app overrides for consistent styling.

> Action names appear as **“ARK: …”** in REAPER. Filenames follow `ARK_<Feature>.lua`.

---

## Requirements

- REAPER (recent build)  
- [ReaImGui](https://forum.cockos.com/showthread.php?t=241418)  
- [SWS](https://www.sws-extension.org/)
- JS_API

---

## Repository Structure

- `apps/` – end-user applications (e.g., `RegionPlaylist/`, `ColorPalette/`, `ThemeAdjuster/`)  
- `arkitekt/` – shared ReaImGui components, widgets, utilities, and helpers  


Packaging follows ReaPack conventions. See the **Packaging Documentation** on the reapack-index wiki for metadata headers and versioning.

---

## Updating

Use **Extensions → ReaPack → Synchronize packages** to pull the latest updates.

---

## Support / Issues

Open an issue on this repository with steps to reproduce and your REAPER/ReaImGui versions.

---

## Credits

Built by **ARKADATA**.  
Thanks to Christian Fillion, the REAPER, ReaImGui, and SWS communities.
