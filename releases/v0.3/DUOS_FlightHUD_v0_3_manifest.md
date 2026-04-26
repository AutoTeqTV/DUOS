# DUOS FlightHUD v0.3 Manifest

Build: **DUOS FlightHUD v0.3 - Layout Cleanup**

Package file: `DUOS_FlightHUD_v0_3_layout_cleanup.zip`

SHA-256:

```text
b4e9be4e7f31145753cacaf2dcb0ab211838e3031a759fa3435210ac0311036b
```

Expected Dual Universe custom layout:

```text
custom/
  DUOS_FlightHUD.conf
  DUOS_FlightHUD_GFN.conf
  README_DUOS_INSTALL.txt
  DUOS_CHANGELOG_v0_2.txt
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
    blankhudclass.example
    privatelocations.sample
    userclass.example
    custom/userglobals.example
```

Changes from v0.2:

- Moved DUOS header/status branding out of the top-center flight panel area.
- Bottom-left status now shows `DUOS // FLIGHT OPERATIONS` and `FLIGHT CORE ONLINE`.
- Cleaned startup brake text from `BRAKE: ENGAGED-STARTUP` to `BRAKE: ENGAGED [STARTUP]`.
- Kept the `duos_archhud/` dependency folder to avoid overwriting the original ArchHUD folder.

Audit:

- Old dependency path `autoconf/custom/archhud/`: not found.
- Active dependency path: `autoconf/custom/duos_archhud/`.

Status:

- v0.2 in-game screenshot confirmed the DUOS fork loads.
- v0.3 is a layout cleanup pass based on that screenshot.
