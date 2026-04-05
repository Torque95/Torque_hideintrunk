# qbx_trunkhide

A FiveM resource for **QBX/Qbox** that lets players hide inside vehicle trunks. Built with `ox_lib` and `ox_target`.

---

## Features

- 🥷 **Hide in trunk** — attach your ped inside any vehicle with a `boot` bone
- 🚗 **Auto open/close** — trunk lid animates on enter and exit (configurable)
- 👁️ **Visibility sync** — ped becomes invisible when the trunk lid is shut
- 🔒 **Lock enforcement** — optionally require the vehicle to be unlocked before entering
- 👤 **Single occupancy** — server-side check prevents two players from occupying the same trunk
- 🎯 **ox_target integration** — context-menu options on trunk bone: *Hide in Trunk*, *Open Trunk*, *Close Trunk*
- 🛠️ **Per-class offsets** — tunable attach positions for each vehicle class to reduce clipping
- 🧹 **Graceful cleanup** — player disconnect and resource stop both clean up state correctly

---

## Dependencies

| Resource | Required |
|---|---|
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ |
| [ox_target](https://github.com/overextended/ox_target) | ✅ |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | ✅ |

---

## Installation

1. Download or clone this resource into your `resources` folder:
   ```
   resources/[qbx]/qbx_trunkhide/
   ```

2. Make sure the folder structure matches:
   ```
   qbx_trunkhide/
   ├── client/
   │   └── main.lua
   ├── server/
   │   └── main.lua
   ├── shared/
   │   └── config.lua
   └── fxmanifest.lua
   ```

3. Add to your `server.cfg`:
   ```
   ensure qbx_trunkhide
   ```

4. Restart your server.

---

## Configuration

All options are in `shared/config.lua`.

### General

| Option | Default | Description |
|---|---|---|
| `LeaveKey` | `'E'` | Key label shown in the 3D prompt while inside the trunk |
| `TrunkDoorIndex` | `5` | GTA door index for the trunk lid |
| `MaxEnterDistance` | `2.0` | Max distance (metres) from trunk bone to enter |
| `RequireUnlocked` | `true` | Only allow entry when vehicle is unlocked |
| `AllowExitWhenLocked` | `true` | Allow player to leave even if the vehicle is locked |

### Auto Door

| Option | Default | Description |
|---|---|---|
| `AutoOpenClose` | `true` | Automatically open/close trunk on enter and exit |
| `AutoDoorDelay` | `900` | Milliseconds to hold trunk open during enter/exit |

### Animation

| Option | Default | Description |
|---|---|---|
| `AnimDict` | `'timetable@floyd@cryingonbed@base'` | Animation dictionary for the crouched/hiding pose |
| `AnimName` | `'base'` | Animation clip name |

### Attach Offsets

Default fallback offset (used when no class-specific offset exists):

```lua
Config.AttachOffset = { x = 0.0, y = -2.2, z = 0.45 }
Config.AttachRot    = { x = 0.0, y = 0.0,  z = 0.0 }
```

Per-class overrides in `Config.ClassOffsets` let you fine-tune positioning for compacts, sedans, SUVs, vans, etc. The table is indexed by the result of `GetVehicleClass()`.

### ox_target Labels & Icons

```lua
Config.TargetLabelEnter = 'Hide in Trunk'
Config.TargetLabelOpen  = 'Open Trunk'
Config.TargetLabelClose = 'Close Trunk'
Config.TargetIconEnter  = 'fa-solid fa-user-ninja'
Config.TargetIconOpen   = 'fa-solid fa-car'
Config.TargetIconClose  = 'fa-solid fa-car'
```

---

## How It Works

### Entering the trunk
1. Player targets a vehicle near the `boot` bone via `ox_target`.
2. A server callback (`qbx_trunkhide:server:tryEnter`) checks that no one else is already occupying that vehicle's trunk.
3. If clear, the ped is attached to the vehicle with `AttachEntityToEntity`, collision is disabled, and the hiding animation loops.
4. If `AutoOpenClose` is enabled the trunk lid opens briefly then closes.

### Visibility
While attached, every frame checks `GetVehicleDoorAngleRatio` on the trunk door. If the lid is nearly closed (`< 0.15`) the ped is set invisible; otherwise visible.

### Leaving the trunk
Pressing **E** (control `38`) triggers `leaveTrunk()`:
1. Server callback releases the occupancy lock.
2. Trunk opens (if `AutoOpenClose`), ped is detached and placed ~2 m behind the vehicle, then the trunk closes.
3. If the vehicle no longer exists, the ped is safely detached in place.

### Server state
`trunkOccupants` is a simple `[vehNetId] = source` table. It is cleaned up on:
- Player disconnect (`playerDropped`)
- `leave` callback
- External event `qbx_trunkhide:server:clearVehicle` (callable from other resources)

---

## Events & Callbacks

### Server Callbacks (ox_lib)

| Name | Arguments | Returns | Description |
|---|---|---|---|
| `qbx_trunkhide:server:tryEnter` | `vehNetId` | `{ ok, reason? }` | Attempt to claim a trunk slot |
| `qbx_trunkhide:server:leave` | `vehNetId` | `{ ok }` | Release a trunk slot |

### Net Events

| Name | Side | Arguments | Description |
|---|---|---|---|
| `qbx_trunkhide:server:clearVehicle` | Server | `vehNetId` | Force-clears occupancy for a vehicle (e.g. on impound) |

---

## Known Limitations

- Only vehicles with a `boot` bone are supported. Motorcycles and some exotics lack this bone and will be rejected.
- Attach offsets are approximate — heavily modded or non-standard vehicles may need manual tuning in `Config.ClassOffsets`.
- Ped visibility is client-side only; other players will see the ped through the trunk lid until a networked solution is added.

---

## License

MIT
