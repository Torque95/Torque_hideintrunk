local trunkOccupants = {} -- [vehNetId] = source

local function isValidVehNetId(vehNetId)
    return type(vehNetId) == 'number' and vehNetId > 0
end

lib.callback.register('qbx_trunkhide:server:tryEnter', function(source, vehNetId)
    if not isValidVehNetId(vehNetId) then
        return { ok = false, reason = 'invalid_vehicle' }
    end

    local current = trunkOccupants[vehNetId]
    if current and current ~= source then
        return { ok = false, reason = 'occupied' }
    end

    trunkOccupants[vehNetId] = source
    return { ok = true }
end)

lib.callback.register('qbx_trunkhide:server:leave', function(source, vehNetId)
    if not isValidVehNetId(vehNetId) then
        return { ok = false }
    end

    if trunkOccupants[vehNetId] == source then
        trunkOccupants[vehNetId] = nil
    end

    return { ok = true }
end)

AddEventHandler('playerDropped', function()
    local src = source
    for vehNetId, occupant in pairs(trunkOccupants) do
        if occupant == src then
            trunkOccupants[vehNetId] = nil
        end
    end
end)

-- Optional: cleanup if a vehicle is deleted. You can call this from other resources if needed.
RegisterNetEvent('qbx_trunkhide:server:clearVehicle', function(vehNetId)
    if not isValidVehNetId(vehNetId) then return end
    trunkOccupants[vehNetId] = nil
end)
