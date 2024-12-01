local hydrantModels = {
    `prop_fire_hydrant_1`,
    `prop_fire_hydrant_2`,
    `prop_fire_hydrant_4`
}

local feetToMeters = 0.3048
local detectionRadius = 500 * feetToMeters -- 500 feet in meters

RegisterCommand("hydrant", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local hydrants = {}
    local playersInVehicle = {}

    -- Check if player is in a vehicle
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)
    if playerVehicle ~= 0 then

        -- Find all players in the same vehicle
        for i = 0, 255 do -- Loop through all possible players
            if NetworkIsPlayerActive(i) then
                local ped = GetPlayerPed(i)
                if GetVehiclePedIsIn(ped, false) == playerVehicle then
                    table.insert(playersInVehicle, GetPlayerServerId(i))
                end
            end
        end
    else
        -- Player is not in a vehicle, only they will receive hydrants
        table.insert(playersInVehicle, GetPlayerServerId(PlayerId()))
    end

    -- Find nearby hydrants
    local nearbyObjects = GetGamePool("CObject")
    for _, object in ipairs(nearbyObjects) do
        local model = GetEntityModel(object)
        for _, hydrantModel in ipairs(hydrantModels) do
            if model == hydrantModel then
                local hydrantCoords = GetEntityCoords(object)
                local distance = #(playerCoords - hydrantCoords)

                if distance <= detectionRadius then
                    table.insert(hydrants, {coords = hydrantCoords, distance = distance})
                end
            end
        end
    end

    -- Notify players about hydrants
    TriggerServerEvent('hydrant:notifyPlayersInVehicle', hydrants, playersInVehicle)
end, false)

-- Preload hydrant models
Citizen.CreateThread(function()
    for _, model in ipairs(hydrantModels) do
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end)

-- Handle receiving hydrants
RegisterNetEvent('hydrant:receiveHydrants')
AddEventHandler('hydrant:receiveHydrants', function(hydrants)
    if #hydrants > 0 then
        TriggerEvent('chat:addMessage', {
            args = {"^2Found " .. #hydrants .. " fire hydrant(s) nearby!"}
        })

        for i, hydrant in ipairs(hydrants) do
            TriggerEvent('chat:addMessage', {
                args = {"^3Hydrant " .. i .. ": Distance = " .. math.floor(hydrant.distance / feetToMeters) .. " feet"}
            })

            -- Add blip for each hydrant
            local blip = AddBlipForCoord(hydrant.coords)
            SetBlipSprite(blip, 1)
            SetBlipScale(blip, 0.75)
            SetBlipColour(blip, 3)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("Fire Hydrant")
            EndTextCommandSetBlipName(blip)

            -- Remove blip after 10 seconds
            Citizen.CreateThread(function()
                Wait(10000)
                RemoveBlip(blip)
            end)
        end
    else
        TriggerEvent('chat:addMessage', {
            args = {"^1No fire hydrants found nearby."}
        })
    end
end)
