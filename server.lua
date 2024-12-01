RegisterServerEvent('hydrant:notifyPlayersInVehicle')
AddEventHandler('hydrant:notifyPlayersInVehicle', function(hydrants, playersInVehicle)
    for _, playerId in ipairs(playersInVehicle) do
        TriggerClientEvent('hydrant:receiveHydrants', playerId, hydrants)
    end
end)
