# DUOS FlightHUD v0.2 Manifest

Build: **DUOS FlightHUD v0.2 - Visual Identity Pass**

Package file: `DUOS_FlightHUD_v0_2_visual_identity.zip`

SHA-256:

```text
9eb12cf4a510efe90b65489b61af5afcea992b230a401fa2ae2d1ac7d2661588
```

Expected Dual Universe custom layout:

```text
custom/
  DUOS_FlightHUD.conf
  DUOS_FlightHUD_GFN.conf
  README_DUOS_INSTALL.txt
  DUOS_CHANGELOG_v0_2.txt
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

Notes:

- Uses `duos_archhud/` instead of `archhud/` to avoid overwriting a normal ArchHUD install.
- Dependency paths were audited for `autoconf/custom/duos_archhud/`.
- The old dependency path `autoconf/custom/archhud/` should not appear in DUOS v0.2 files.
- The bundled GFN config is included for compatibility testing.

Status:

- In-game screenshot confirmed the DUOS fork loads.
- DUOS console messages appear.
- DUOS visual identity pass is active.
