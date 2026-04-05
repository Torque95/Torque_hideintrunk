local inTrunk = false
local trunkVeh = 0
local trunkVehNetId = 0

local function notify(msg, ntype)
    -- ox_lib notify
    lib.notify({
        title = 'Trunk',
        description = msg,
        type = ntype or 'inform'
    })
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return end
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

local function getTrunkBone(veh)
    -- Most vehicles use "boot". Some may use "bumper_r" etc, but boot is standard.
    local boneIndex = GetEntityBoneIndexByName(veh, 'boot')
    if boneIndex ~= -1 then
        return boneIndex
    end
    return -1
end

local function isVehicleUnlocked(veh)
    local lockStatus = GetVehicleDoorLockStatus(veh)
    -- Common: 1 = unlocked, 2 = locked. There are more statuses, treat > 1 as locked.
    return lockStatus == 1 or lockStatus == 0
end

local function getOffsetsForVehicle(veh)
    local class = GetVehicleClass(veh)
    local entry = Config.ClassOffsets[class]
    if entry and entry.offset and entry.rot then
        return entry.offset, entry.rot
    end
    return Config.AttachOffset, Config.AttachRot
end

local function safeDoorOpen(veh)
    if not DoesEntityExist(veh) then return end
    SetVehicleDoorOpen(veh, Config.TrunkDoorIndex, false, false)
end

local function safeDoorShut(veh)
    if not DoesEntityExist(veh) then return end
    SetVehicleDoorShut(veh, Config.TrunkDoorIndex, false)
end

local function detachAndPlaceBehindTrunk(veh)
    local ped = PlayerPedId()

    DetachEntity(ped, true, true)
    SetEntityCollision(ped, true, true)
    SetEntityVisible(ped, true, false)
    ClearPedTasks(ped)

    -- place just behind trunk
    local coords = GetOffsetFromEntityInWorldCoords(veh, 0.0, -2.0, 0.0)
    SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.1, false, false, false, false)
end

local function enterTrunk(veh)
    local ped = PlayerPedId()
    if inTrunk then return end
    if not DoesEntityExist(veh) then return end

    local bone = getTrunkBone(veh)
    if bone == -1 then
        notify('This vehicle does not have a usable trunk.', 'error')
        return
    end

    if Config.RequireUnlocked and not isVehicleUnlocked(veh) then
        notify('Vehicle is locked.', 'error')
        return
    end

    -- sanity distance
    local trunkPos = GetWorldPositionOfEntityBone(veh, bone)
    local ppos = GetEntityCoords(ped)
    if #(ppos - trunkPos) > Config.MaxEnterDistance then
        notify('Too far from trunk.', 'error')
        return
    end

    trunkVeh = veh
    trunkVehNetId = NetworkGetNetworkIdFromEntity(veh)

    -- Server lock (single occupant)
    local resp = lib.callback.await('qbx_trunkhide:server:tryEnter', false, trunkVehNetId)
    if not resp or not resp.ok then
        if resp and resp.reason == 'occupied' then
            notify('Someone is already in the trunk.', 'error')
        else
            notify('Unable to enter trunk.', 'error')
        end
        trunkVeh = 0
        trunkVehNetId = 0
        return
    end

    if Config.AutoOpenClose then
        safeDoorOpen(veh)
        Wait(250)
    end

    local offset, rot = getOffsetsForVehicle(veh)

    loadAnimDict(Config.AnimDict)

    AttachEntityToEntity(
        ped, veh, -1,
        offset.x, offset.y, offset.z,
        rot.x, rot.y, rot.z,
        false, false, false, false, 2, true
    )

    TaskPlayAnim(ped, Config.AnimDict, Config.AnimName, 8.0, -8.0, -1, 1, 0.0, false, false, false)

    SetEntityCollision(ped, false, false)

    -- If trunk is shut, hide ped
    if GetVehicleDoorAngleRatio(veh, Config.TrunkDoorIndex) < 0.15 then
        SetEntityVisible(ped, false, false)
    else
        SetEntityVisible(ped, true, false)
    end

    inTrunk = true

    if Config.AutoOpenClose then
        Wait(Config.AutoDoorDelay)
        safeDoorShut(veh)
    end
end

local function leaveTrunk()
    if not inTrunk then return end

    local ped = PlayerPedId()
    local veh = trunkVeh

    -- best effort server unlock, even if veh is gone
    if trunkVehNetId and trunkVehNetId ~= 0 then
        lib.callback.await('qbx_trunkhide:server:leave', false, trunkVehNetId)
    end

    if DoesEntityExist(veh) then
        if Config.AutoOpenClose then
            safeDoorOpen(veh)
            Wait(250)
        end

        detachAndPlaceBehindTrunk(veh)

        if Config.AutoOpenClose then
            Wait(Config.AutoDoorDelay)
            safeDoorShut(veh)
        end
    else
        -- vehicle missing; just detach safely
        DetachEntity(ped, true, true)
        SetEntityCollision(ped, true, true)
        SetEntityVisible(ped, true, false)
        ClearPedTasks(ped)
    end

    inTrunk = false
    trunkVeh = 0
    trunkVehNetId = 0
end

local function openTrunk(veh)
    if not DoesEntityExist(veh) then return end
    if Config.RequireUnlocked and not isVehicleUnlocked(veh) then
        notify('Vehicle is locked.', 'error')
        return
    end
    safeDoorOpen(veh)
end

local function closeTrunk(veh)
    if not DoesEntityExist(veh) then return end
    safeDoorShut(veh)
end

-- While-in-trunk management loop (visibility, re-play anim, exit prompt)
CreateThread(function()
    while true do
        if not inTrunk then
            Wait(500)
        else
            Wait(0)

            local ped = PlayerPedId()
            local veh = trunkVeh

            if not DoesEntityExist(veh) or IsPedDeadOrDying(ped, true) then
                leaveTrunk()
                goto continue
            end

            -- Keep anim playing
            if not IsEntityPlayingAnim(ped, Config.AnimDict, Config.AnimName, 3) then
                loadAnimDict(Config.AnimDict)
                TaskPlayAnim(ped, Config.AnimDict, Config.AnimName, 8.0, -8.0, -1, 1, 0.0, false, false, false)
            end

            -- Visibility tied to trunk state
            if GetVehicleDoorAngleRatio(veh, Config.TrunkDoorIndex) < 0.15 then
                SetEntityVisible(ped, false, false)
            else
                SetEntityVisible(ped, true, false)
            end

            -- Simple 3D text at trunk bone position
            local bone = getTrunkBone(veh)
            if bone ~= -1 then
                local coords = GetWorldPositionOfEntityBone(veh, bone)
                DrawText3D(coords, ('[%s] Leave Trunk'):format(Config.LeaveKey))
            end

            -- E key (control 38) to exit
            if IsControlJustReleased(0, 38) then
                -- If locked while inside: optionally block leaving (not recommended)
                if not Config.AllowExitWhenLocked and not isVehicleUnlocked(veh) then
                    notify('Vehicle is locked.', 'error')
                else
                    leaveTrunk()
                end
            end

            ::continue::
        end
    end
end)

-- ox_target integration: add options to vehicles near trunk bone
CreateThread(function()
    -- Add options to ALL vehicles
    exports.ox_target:addGlobalVehicle({
        {
            name = 'qbx_trunkhide_enter',
            icon = Config.TargetIconEnter,
            label = Config.TargetLabelEnter,
            bones = { 'boot' },
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                if inTrunk then return false end
                if not DoesEntityExist(entity) then return false end
                if getTrunkBone(entity) == -1 then return false end
                if Config.RequireUnlocked and not isVehicleUnlocked(entity) then return false end
                return true
            end,
            onSelect = function(data)
                enterTrunk(data.entity)
            end
        },
        {
            name = 'qbx_trunkhide_open',
            icon = Config.TargetIconOpen,
            label = Config.TargetLabelOpen,
            bones = { 'boot' },
            distance = 2.0,
            canInteract = function(entity)
                if not DoesEntityExist(entity) then return false end
                if getTrunkBone(entity) == -1 then return false end
                if GetVehicleDoorAngleRatio(entity, Config.TrunkDoorIndex) >= 0.15 then return false end
                if Config.RequireUnlocked and not isVehicleUnlocked(entity) then return false end
                return true
            end,
            onSelect = function(data)
                openTrunk(data.entity)
            end
        },
        {
            name = 'qbx_trunkhide_close',
            icon = Config.TargetIconClose,
            label = Config.TargetLabelClose,
            bones = { 'boot' },
            distance = 2.0,
            canInteract = function(entity)
                if not DoesEntityExist(entity) then return false end
                if getTrunkBone(entity) == -1 then return false end
                if GetVehicleDoorAngleRatio(entity, Config.TrunkDoorIndex) < 0.15 then return false end
                return true
            end,
            onSelect = function(data)
                closeTrunk(data.entity)
            end
        },
    })
end)

-- Basic DrawText3D helper (same as your original concept)
function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextEntry("STRING")
    SetTextCentre(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()

    AddTextComponentString(text)
    DrawText(_x, _y)
end

-- Safety: if resource stops while player is in trunk, clean up
AddEventHandler('onResourceStop', function(resName)
    if resName ~= GetCurrentResourceName() then return end
    if inTrunk then
        leaveTrunk()
    end
end)
