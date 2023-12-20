-- client.lua
Config = {
    SaveVehicleKey = 37,   -- Key code for 'L'
    DeleteVehicleKey = 39, -- Key code for '['
}

local hasVehicleSaved = false
local playerLicense = nil
local isAutoSaveEnabled = true  -- Variable to track whether auto save is enabled
local isInVehicle = false

-- Function to save the vehicle
function SaveVehicle()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if DoesEntityExist(vehicle) then
        local pos = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        local health = GetEntityHealth(vehicle)
        local fuel = DecorGetFloat(vehicle, "fFuel")
        local model = GetEntityModel(vehicle)
        local color1,color2 = GetVehicleColours(vehicle) 
        local vehicleData = { x = pos.x, y = pos.y, z = pos.z, heading = heading, health = health, fuel = fuel , model = model, color1 = color1, color2 = color2 }

        TriggerServerEvent("saveVehicleToDatabase", vehicleData)
        notify("Vehicle saved!")
    else
        notify("You are not in a vehicle.")
    end
end

function updateServer()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if DoesEntityExist(vehicle) then
        local pos = GetEntityCoords(vehicle)
        local heading = GetEntityHeading(vehicle)
        local health = GetEntityHealth(vehicle)
        local fuel = DecorGetFloat(vehicle, "fFuel")
        local model = GetEntityModel(vehicle)
        local color1,color2 = GetVehicleColours(vehicle) 
        local vehicleData = { x = pos.x, y = pos.y, z = pos.z, heading = heading, health = health, fuel = fuel , model = model, color1 = color1, color2 = color2 }
        return vehicleData
    else
        return nil
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
        SetVehicleColours(vehicle, vehicleData.color1, vehicleData.color2)
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
    local player = PlayerId()
    local playerServerId = GetPlayerServerId(player)

    TriggerServerEvent("getPlayerLicense", playerServerId)
end

-- Function to check if the player is in a vehicle
function CheckInVehicle()
    local playerPed = PlayerPedId()
    local inVehicle = IsPedInAnyVehicle(playerPed, false)
    if inVehicle then
        if not isInVehicle then
            isInVehicle = true
            -- Player has entered a vehicle, trigger your custom event here
            local vehicleData = updateServer()
            TriggerServerEvent("CurrentVehicle", vehicleData)
        end
    else
        TriggerServerEvent("CurrentVehicle", nil)
        isInVehicle = false
    end
end

-- Main loop to check for being in a vehicle
Citizen.CreateThread(function()
    while isAutoSaveEnabled do
        Citizen.Wait(500)  -- Adjust the interval as needed
        CheckInVehicle()
    end
end)

-- Event to trigger saving the vehicle when the configured key is pressed
RegisterCommand("savevehicle", function()
    if IsControlReleased(0, Config.SaveVehicleKey) then
        SaveVehicle()
    else
        notify("Press the configured key to save the vehicle.")
    end
end, false)

-- Event to toggle auto save when the configured key is pressed
RegisterCommand("toggleautosave", function()
    isAutoSaveEnabled = not isAutoSaveEnabled
    local status = isAutoSaveEnabled and "enabled" or "disabled"
    notify("Auto vehicle saves are now " .. status .. ".")
    TriggerServerEvent("updateAutoSaveStatus", isAutoSaveEnabled)
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

-- Event to request the saved vehicle data when the player joins
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




