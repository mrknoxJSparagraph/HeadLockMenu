# HeadLockMenu

The launcher is `HeadLockMenu_Shuffled.lua`. It downloads the single-file
`HeadLockMenu_Core.lua`, with startup diagnostics and a recovery version.

The Vehicles and AutoWin installers are readable in their own Lua files and
embedded in the core, so they require no extra download while playing.
After editing either installer, run `npm run build` and `npm test`.
`npm run test:physics` exercises real vehicle callbacks and acceleration
math in a small mock host; this optional check requires `liblua5.4`.

Vehicles preserves the separate character physics assembly, world-space
follow constraints, touch layout, suspension probes and avatar collision
exclusions. It tries nearby front/right/left/rear spawn slots and reports
when all are occupied. Imported model scripts are removed before parenting.

AutoWin is hidden until an owner enables the Credits checkbox. Its flight,
weapon overrides and survivor skip list are independent of the manual
C Fly and weapon toggles. Local Juggernaut Auto Kill ignores that skip list.
Wall clip and Anti-Fling start OFF. The existing account restriction is a
client menu gate, rather than a server authorization boundary.

Tests compile the full Luau menu and exercise mocked game events and UI.
Actual firing, asset access, server limits, replication and driving still
require verification in Roblox. A 1000% setting requests the existing
menu's shortest firing interval; it cannot guarantee server throughput.
