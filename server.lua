local QBCore = exports['qb-core']:GetCoreObject()

-- Gi items
RegisterServerEvent('root_bilchop:server:giveItem')
AddEventHandler('root_bilchop:server:giveItem', function(item, quantity)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    xPlayer.Functions.AddItem(item, quantity)
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
end)

-- -- Gi penger
-- RegisterServerEvent('root_bilchop:server:giveMoney')
-- AddEventHandler('root_bilchop:server:giveMoney', function()
--     local src = source
--     local xPlayer = QBCore.Functions.GetPlayer(src)
--     local cashamount = math.random(1000, 4500)
--     Player.Functions.AddMoney('cash', cashamount)
-- end)
