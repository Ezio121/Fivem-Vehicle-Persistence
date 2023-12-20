-- client.lua
Config = {
    SaveVehicleKey = 37,   -- Key code for 'L'
    DeleteVehicleKey = 39, -- Key code for '['
}

local hasVehicleSaved = false
local playerLicense = nil

-- Function to save the vehicle
function SaveVehicle()
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1), false)

    if DoesEntityExist(vehicle) then
        local pos = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        local health = GetEntityHealth(vehicle)
        local fuel = DecorGetFloat(vehicle, "fFuel")
        local model = GetEntityModel(vehicle)
        local vehicleData = { x = pos.x, y = pos.y, z = pos.z, heading = heading, health = health, fuel = fuel , model = model }

        TriggerServerEvent("saveVehicleToDatabase", vehicleData)
        hasVehicleSaved = true
        notify("Vehicle saved!")
    else
        notify("You are not in a vehicle.")
    end
end

-- Function to respawn the player in the saved vehicle
function RespawnPlayerInVehicle(vehicleData)
    if vehicleData then
        local vehicleHash = vehicleData.model

        RequestModel(vehicleHash)
        while not HasModelLoaded(vehicleHash) do
            Wait(500)
        end

        local vehicle = CreateVehicle(vehicleHash, vehicleData.x, vehicleData.y, vehicleData.z, vehicleData.heading, true, false)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)

        SetEntityHealth(vehicle, vehicleData.health)
        DecorSetFloat(vehicle, "fFuel", vehicleData.fuel)
        notify("Respawned in saved vehicle!")
    else
        notify("No vehicle saved.")
    end
end

-- Function to display notifications
function notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentString(msg)
    local notification = DrawNotification(false, false)
    
    Citizen.Wait(2000)
    RemoveNotification(notification)
    
end

-- Function to get the player's license and trigger the server event
function GetPlayerLicense()
    local serverId = GetPlayerServerId(PlayerId())
    
    if serverId then
        TriggerServerEvent("getPlayerLicense", serverId)
    end
end

-- Event to trigger saving the vehicle when the configured key is pressed
RegisterCommand("savevehicle", function()
    if IsControlReleased(0, Config.SaveVehicleKey) then
        SaveVehicle()
    else
        notify("Press the configured key to save the vehicle.")
    end
end, false)

-- Event to trigger deleting the vehicle entry from the database when the configured key is pressed

RegisterCommand("deletevehicle", function()
        TriggerServerEvent("deleteVehicleFromDatabase", GetPlayerServerId(PlayerId()))
        notify("Vehicle entry deleted from the database.")
end, false)


local isDeleteKeyPressed = false

-- Function to handle the key press
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if IsControlJustReleased(0, Config.DeleteVehicleKey) then
            isDeleteKeyPressed = true
        end
    end
end)

-- Event to check for the key press and trigger the server event
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if isDeleteKeyPressed then
            isDeleteKeyPressed = false  -- Reset the flag

            -- Trigger the server event to delete the vehicle entry
            TriggerServerEvent("deleteVehicleFromDatabase", GetPlayerServerId(PlayerId()))

            -- Display a notification
            notify("Vehicle entry deleted from the database.")
        end
    end
end)




-- Event to request the saved vehicle data when player joins
AddEventHandler("playerSpawned", function()
    GetPlayerLicense()  -- Trigger the request for player license
end)

-- Event to receive the license from the server
RegisterNetEvent("receivePlayerLicense")
AddEventHandler("receivePlayerLicense", function(license)
    playerLicense = license
    print("Player License: " .. tostring(playerLicense))

    if playerLicense then
        TriggerServerEvent("requestSavedVehicle", playerLicense)
    end
end)

-- Event to respawn the player in the saved vehicle
RegisterNetEvent("respawnPlayerInVehicle")
AddEventHandler("respawnPlayerInVehicle", function(vehicleData)
    RespawnPlayerInVehicle(vehicleData)
end)
