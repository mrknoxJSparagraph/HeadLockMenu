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

AutoWin is visible at the bottom for every account without the Credits checkbox. Its flight,
weapon overrides and survivor skip list are independent of the manual
C Fly and weapon toggles. Owner accounts are always excluded from AutoWin shooting
and Auto Kill targeting, including selected priorities and queued shots.
Local Juggernaut Auto Kill ignores the optional survivor skip list.
The separate Kill First list shuffles selected eligible players once per
round and finishes them before other survivors. AutoWin and Follow Jug
share the exact position function. Existing pistol controllers are located
before firing, including cached mobile handlers when the executor supports
connection/upvalue inspection. Finding a controller does not initialize firing.
AutoWin first attempts the normal game input, preserves normal first-shot setup,
and saves the firing arguments only after a successful observed shot. Subsequent
shots replay those arguments; stale context triggers another startup attempt.
Unavailable automatic input is reported rather than treated as successful firing.
Wall clip and Anti-Fling start OFF. The existing account restriction is a
client menu gate, rather than a server authorization boundary.

Tests compile the full Luau menu and exercise mocked game events and UI.
Actual firing, asset access, server limits, replication and driving still
require verification in Roblox. A 1000% setting requests the existing
menu's shortest firing interval; it cannot guarantee server throughput.
