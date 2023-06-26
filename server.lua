local QBCore = exports['qb-core']:GetCoreObject()

-- Gi items
RegisterServerEvent('giveItem')
AddEventHandler('giveItem', function(item, quantity)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    xPlayer.Functions.AddItem(item, quantity)
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
end)

-- Gi penger
RegisterServerEvent('giveMoney')
AddEventHandler('giveMoney', function(account, amount)
    local src = source
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if account == 'cash' then
        xPlayer.Functions.AddMoney('cash', amount)
    else
        xPlayer.Functions.AddMoney('bank', amount, account)
    end
end)
