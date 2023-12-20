local savedVehicles = {}

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

AddEventHandler("playerDied", function(reason)
    local playerId = source

    -- Request saved vehicle data and respawn the player
    TriggerEvent("requestSavedVehicle", playerId)
end)

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
    local player = source  -- Capture 'source' in a local variable
    local playerIdentifier = GetPlayerIdentifierByLicense(player)
    
    print("Player Identifier:", playerIdentifier)

    MySQL.Async.fetchScalar([[
        SELECT vehicle_data FROM saved_vehicles WHERE player_id = @identifier
    ]], {
        ["@identifier"] = playerIdentifier
    }, function(result)
        local savedVehicle = json.decode(result)

        if savedVehicle and type(savedVehicle) == "table" then
            -- The decoded result is a valid table
            print("Saved Vehicle Data:", json.encode(savedVehicle))

            -- Now you can access individual properties of the savedVehicle table
            local x = savedVehicle.x
            local y = savedVehicle.y
            -- ... (access other properties as needed)

            -- Example: Trigger a client event with the decoded table
            print("Source Player ID:", player)
            TriggerClientEvent("respawnPlayerInVehicle", player, savedVehicle)
        else
            print("Failed to decode saved vehicle data.")
        end
    end)
end)



