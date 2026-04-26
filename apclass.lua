DUOS FlightHUD v0.3 - Dual Universe custom folder layout

Install layout expected by Dual Universe:

custom/
  DUOS_FlightHUD.conf
  DUOS_FlightHUD_GFN.conf
  duos_archhud/

Install steps:
1. Open your Dual Universe autoconf custom folder.
2. Copy the contents of this zip so DUOS_FlightHUD.conf sits directly inside custom/.
3. Keep the duos_archhud folder beside the .conf files.
4. In game, paste/import DUOS_FlightHUD.conf first.

This fork intentionally uses duos_archhud instead of archhud so it does not overwrite the original ArchHUD dependency folder.

v0.3 changes:
- Moved DUOS header/status branding out of the center flight panel area.
- Bottom-left status now reads DUOS // FLIGHT OPERATIONS and Flight Core Online.
- Cleaned BRAKE startup text from BRAKE: ENGAGED-STARTUP to BRAKE: ENGAGED [STARTUP].
- Preserved v0.2 SYS / NAV / RADAR / HIDE labels and DUOS TELEMETRY panel.
