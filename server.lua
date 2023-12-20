local currentVehicles = {}
local isAutoSaveEnabled = true
function GetPlayerIdentifierByLicense(playerId)
    local identifiers = GetPlayerIdentifiers(playerId)
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "license:") then
            return identifier
        end
    end
    return nil
end

MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS saved_vehicles (
            player_id VARCHAR(255) PRIMARY KEY,
            vehicle_data TEXT
        )
    ]])
end)

-- AddEventHandler("playerDied", function(reason)
--     local playerId = source

--     -- Request saved vehicle data and respawn the player
--     TriggerEvent("requestSavedVehicle", playerId)
-- end)

-- Event to save the vehicle data to the database

RegisterServerEvent("saveVehicleToDatabase")
AddEventHandler("saveVehicleToDatabase", function(vehicleData)
    local playerIdentifier = GetPlayerIdentifierByLicense(source)

    if playerIdentifier then
        MySQL.Async.execute([[
            REPLACE INTO saved_vehicles (player_id, vehicle_data)
            VALUES (@identifier, @vehicleData)
        ]], {
            ["@identifier"] = playerIdentifier,
            ["@vehicleData"] = json.encode(vehicleData)
        })
    end
end)

-- Event to update the auto save status
RegisterServerEvent("updateAutoSaveStatus")
AddEventHandler("updateAutoSaveStatus", function(newStatus)
    isAutoSaveEnabled = newStatus
    print("Auto vehicle saves status updated:", isAutoSaveEnabled)
end)



-- Event to update the auto save status
RegisterServerEvent("updateAutoSaveStatus")
AddEventHandler("updateAutoSaveStatus", function(newStatus)
    isAutoSaveEnabled = newStatus
    print("Auto vehicle saves status updated:", isAutoSaveEnabled)
end)

-- Event to handle the current vehicle data from the client
RegisterServerEvent("CurrentVehicle")
AddEventHandler("CurrentVehicle", function(vehicleData)
    local player = source

    -- Store the current vehicle data in the table using the player's server ID as the key
    currentVehicles[player] = vehicleData
end)

-- Event to save the vehicle data to the database on player disconnect
AddEventHandler("playerDropped", function(reason)
    local playerServerId = source
    print(playerServerId)
    if currentVehicles[playerServerId] and isAutoSaveEnabled then
        local vehicleData = currentVehicles[playerServerId]
        local playerIdentifier = GetPlayerIdentifierByLicense(playerServerId)
        print(playerIdentifier)
        if playerIdentifier then
            MySQL.Async.execute([[
                REPLACE INTO saved_vehicles (player_id, vehicle_data)
                VALUES (@identifier, @vehicleData)
            ]], {
                ["@identifier"] = playerIdentifier,
                ["@vehicleData"] = json.encode(vehicleData)
            })
            print("Save Success")
        end
        currentVehicles[playerServerId] = nil  -- Clear the stored data after using it
    else
        print("AutoSave Disabled")
    end
end)


RegisterServerEvent("getPlayerLicense")
AddEventHandler("getPlayerLicense", function(playerServerId)
    local player = GetPlayerIdentifiers(playerServerId)

    if player and #player > 0 then
        for _, identifier in pairs(player) do
            if string.find(identifier, "license:") then
                TriggerClientEvent("receivePlayerLicense", source, identifier)
                return
            end
        end
    end

    -- If no license found, send nil
    TriggerClientEvent("receivePlayerLicense", source, nil)
end)

RegisterServerEvent("requestSavedVehicle")
AddEventHandler("requestSavedVehicle", function()
    local player = source  
    local playerIdentifier = GetPlayerIdentifierByLicense(player)
    
    MySQL.Async.fetchScalar([[
        SELECT vehicle_data FROM saved_vehicles WHERE player_id = @identifier
    ]], {
        ["@identifier"] = playerIdentifier
    }, function(result)
        local savedVehicle = json.decode(result)

        if savedVehicle and type(savedVehicle) == "table" then
            TriggerClientEvent("respawnPlayerInVehicle", player, savedVehicle)
        else
            print("Failed to decode saved vehicle data.")
        end
    end)
end)

-- Event to delete the vehicle entry from the database
RegisterServerEvent("deleteVehicleFromDatabase")
AddEventHandler("deleteVehicleFromDatabase", function(playerServerId)
    local playerIdentifier = GetPlayerIdentifierByLicense(playerServerId)

    if playerIdentifier then
        MySQL.Async.execute([[
            DELETE FROM saved_vehicles WHERE player_id = @identifier
        ]], {
            ["@identifier"] = playerIdentifier
        })
    end
end)


