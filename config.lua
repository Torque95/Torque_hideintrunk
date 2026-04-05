Config = {}

-- Keybind group for leaving trunk (shown only while inside)
Config.LeaveKey = 'E' -- ox_lib key name (used for UI text only; we use IsControlJustReleased native below)

-- Vehicle trunk door index in GTA is 5
Config.TrunkDoorIndex = 5

-- How close you must be to trunk bone to enter (ox_target handles most of this; still used for sanity checks)
Config.MaxEnterDistance = 2.0

-- If true: require the vehicle to be unlocked to enter trunk
Config.RequireUnlocked = true

-- If true: if vehicle becomes locked while inside, still allow leaving (recommended)
Config.AllowExitWhenLocked = true

-- If true: automatically open trunk briefly when entering/exiting
Config.AutoOpenClose = true

-- Time (ms) to keep trunk open on enter/exit when AutoOpenClose = true
Config.AutoDoorDelay = 900

-- Animation played while inside (looped)
Config.AnimDict = 'timetable@floyd@cryingonbed@base'
Config.AnimName = 'base'

-- Default attach offsets (fallback)
Config.AttachOffset = { x = 0.0, y = -2.2, z = 0.45 }
Config.AttachRot    = { x = 0.0, y = 0.0,  z = 0.0 }

-- Optional per vehicle class offsets (tuning improves clipping)
-- Vehicle class list: https://docs.fivem.net/natives/?_0x29439776AAA00A62 (GetVehicleClass)
-- You can adjust these later; the fallback works for most vehicles.
Config.ClassOffsets = {
  -- [class] = { offset = {x=..., y=..., z=...}, rot = {x=..., y=..., z=...} }
  [0] = { offset = { x=0.0, y=-2.15, z=0.40 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- compacts
  [1] = { offset = { x=0.0, y=-2.25, z=0.42 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- sedans
  [2] = { offset = { x=0.0, y=-2.35, z=0.48 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- SUVs
  [3] = { offset = { x=0.0, y=-2.30, z=0.44 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- coupes
  [4] = { offset = { x=0.0, y=-2.40, z=0.44 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- muscle
  [5] = { offset = { x=0.0, y=-2.35, z=0.43 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- sports classics
  [6] = { offset = { x=0.0, y=-2.35, z=0.42 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- sports
  [7] = { offset = { x=0.0, y=-2.45, z=0.40 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- super
  [8] = { offset = { x=0.0, y=-1.40, z=0.30 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- motorcycles (generally no trunk; but harmless)
  [9] = { offset = { x=0.0, y=-2.70, z=0.55 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- off-road
  [10]= { offset = { x=0.0, y=-2.85, z=0.62 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- industrial
  [11]= { offset = { x=0.0, y=-2.70, z=0.58 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- utility
  [12]= { offset = { x=0.0, y=-2.85, z=0.60 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- vans
  [17]= { offset = { x=0.0, y=-3.10, z=0.75 }, rot = { x=0.0, y=0.0, z=0.0 } }, -- service
}

-- Target options
Config.TargetLabelEnter = 'Hide in Trunk'
Config.TargetLabelOpen  = 'Open Trunk'
Config.TargetLabelClose = 'Close Trunk'
Config.TargetIconEnter  = 'fa-solid fa-user-ninja'
Config.TargetIconOpen   = 'fa-solid fa-car'
Config.TargetIconClose  = 'fa-solid fa-car'
