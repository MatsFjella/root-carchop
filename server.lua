local QBCore = exports['qb-core']:GetCoreObject()

-- Register server event to give items
RegisterServerEvent('giveItem')
AddEventHandler('giveItem', function(item, quantity)
    local src = source
    -- Use appropriate QBCore function to give items to player
    -- Replace the following line with your own reward logic
    local xPlayer = QBCore.Functions.GetPlayer(src)
    xPlayer.Functions.AddItem(item, quantity)
    TriggerClientEvent('qb-inventory:client:ItemBox', src, QBCore.Shared.Items[item], 'add')
end)

-- Register server event to give money
RegisterServerEvent('giveMoney')
AddEventHandler('giveMoney', function(account, amount)
    local src = source
    -- Use appropriate QBCore function to give money to player
    -- Replace the following line with your own reward logic
    local xPlayer = QBCore.Functions.GetPlayer(src)
    if account == 'cash' then
        xPlayer.Functions.AddMoney('cash', amount)
    else
        -- Replace 'bank' with the desired account type if not 'cash'
        xPlayer.Functions.AddMoney('bank', amount, account)
    end
end)
