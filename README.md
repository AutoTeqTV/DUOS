# DUOS

**Dual Universe Operating System**

DUOS is a modular Dual Universe HUD and ship operating system project. The first working build is a branded ArchHUD fork that keeps the proven ArchHUD flight backend while we build DUOS-specific visuals, modules, menus, and ship systems on top of it.

## Current Build

**DUOS FlightHUD v0.3 - Layout Cleanup**

This version keeps the v0.2 branding but moves the DUOS identity out of the center flight-data area so it no longer overlaps the `TRAVEL` mode label or top-center HUD instruments.

Current changes include:

- DUOS FlightHUD branding
- DUOS boot/status console messages
- DUOS-style cyan/orange visual palette
- Updated top navigation labels
- `DUOS TELEMETRY` panel label
- Cleaner warning/status text
- Center header overlap removed
- Bottom-left DUOS operations/status strip
- ArchHUD compatibility mode retained

## Dual Universe Install Layout

Dual Universe expects the autoconf file and dependency folders to be placed inside the local `custom` folder.

Expected layout:

```text
custom/
  DUOS_FlightHUD.conf
  DUOS_FlightHUD_GFN.conf
  README_DUOS_INSTALL.txt
  DUOS_CHANGELOG_v0_3.txt
  duos_archhud/
    apclass.lua
    atlasclass.lua
    axiscommandoverride.lua
    baseclass.lua
    controlclass.lua
    globals.lua
    hudclass.lua
    radarclass.lua
    shieldclass.lua
    userclass.lua
```

The fork uses `duos_archhud/` instead of `archhud/` so it does not overwrite a normal ArchHUD install.

## Importing In Game

1. Copy the contents of the package into the Dual Universe `custom` autoconf folder.
2. Confirm `DUOS_FlightHUD.conf` is directly inside `custom/`.
3. Confirm `duos_archhud/` is also directly inside `custom/`.
4. In Dual Universe, use the autoconf paste/import option.
5. Select or paste the DUOS FlightHUD configuration.

## Development Direction

The goal is to grow DUOS into a larger ship operating system, not only a flight HUD.

Planned module path:

```text
DUOS Core
├─ Flight HUD
├─ Navigation
├─ Radar
├─ Shields
├─ Ship Diagnostics
├─ Fuel / Power / Mass Management
├─ Autopilot Helpers
├─ Screen UI
└─ Config / Theme System
```

## Fork Strategy

For now, ArchHUD behavior should stay intact. DUOS changes should be layered carefully so the HUD remains usable while modules are cleaned up over time.

Priority order:

1. Keep the HUD loading in game.
2. Avoid overwriting original ArchHUD files.
3. Keep the ArchHUD backend stable.
4. Add DUOS branding and UI changes.
5. Refactor into cleaner DUOS modules after the branded fork is confirmed stable.

## Notes

- `duos_archhud/baseclass.lua` has already been updated from the newer provided baseclass file.
- The old dependency path `autoconf/custom/archhud/` should not be used in DUOS builds.
- DUOS builds should use `autoconf/custom/duos_archhud/`.
- The sound folder may still reference `archHUD` until a DUOS sound pack is created.

## Status

Early branded fork. Working in-game test screenshots confirm the HUD loads and DUOS messages appear.
