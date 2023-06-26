-- Get the QBCore object
local QBCore = exports['qb-core']:GetCoreObject()

-- Initialize variables
local carCategories = {"Compacts", "Coupes", "Muscle", "Off-road", "Sedans", "Sports", "Sports Classics", "SUVs"}
local items = {"plastic", "metalscrap", "copper", "aluminum", "iron", "steel", "rubber", "glass"}

local currentCarCategory = nil
local lastChangeTime = nil
local cooldownEnd = nil

local classToCategory = {
    [0] = "Compacts",
    [1] = "Sedans",
    [2] = "SUVs",
    [3] = "Coupes",
    [4] = "Muscle",
    [5] = "Sports Classics",
    [6] = "Sports",
    [7] = "Super",
    [8] = "Motorcycles",
    [9] = "Off-road",
    [10] = "Industrial",
    [11] = "Utility",
    [12] = "Vans",
    [13] = "Cycles",
    [14] = "Boats",
    [15] = "Helicopters",
    [16] = "Planes",
    [17] = "Service",
    [18] = "Emergency",
    [19] = "Military",
    [20] = "Commercial",
    [21] = "Trains"
}

local function GetVehicleCategory(vehicle)
    local class = GetVehicleClass(vehicle)
    return classToCategory[class]
end

-- Function to choose a random item from a table
local function chooseRandomItem(table)
    local keys = {}
    for key, value in pairs(table) do
        keys[#keys + 1] = key
    end
    return table[keys[math.random(1, #keys)]]
end

-- Check and update car category every 2 hours
local function updateCarCategory()
    local currentTime = GetGameTimer() / 1000
    if lastChangeTime == nil or (currentTime - lastChangeTime >= 2 * 60 * 60) then
        currentCarCategory = chooseRandomItem(carCategories)
        lastChangeTime = currentTime
    end
end

-- Define the PED model and location
local pedModel = 'mp_m_waremech_01'
local pedCoord = vector4(-469.44, -1717.56, 17.69, 286.26)

-- Function to load the PED model
local function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

-- Function to spawn the PED and make it interactive
local function spawnPed()
    if not LoadModel(pedModel) then
        print('Failed to load model ' .. pedModel)
        return
    end
    local ped = CreatePed(4, pedModel, pedCoord.xyz, pedCoord.w, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    -- Register ped with QB-Target
    exports['qb-target']:AddTargetModel({pedModel}, {
        options = {
            {
                event = 'myResource:interactWithPed',
                icon = 'fas fa-car',
                label = 'Retrieve Car',
            },
        },
        distance = 2.5
    })
end

-- Job interaction
local function interactWithPed()
    updateCarCategory()
    if cooldownEnd ~= nil and GetGameTimer() / 1000 <= cooldownEnd then
        -- Notify player of cooldown
        QBCore.Functions.Notify("Du må vente på å hente ny bil!", "error")
    else
        -- Notify player of job assignment
        exports['okokNotify']:Alert("Hent "..currentCarCategory.."", "Biltype du skal stjele", 10000, 'blue')
    end
end

-- Event for interacting with the PED
RegisterNetEvent('myResource:interactWithPed')
AddEventHandler('myResource:interactWithPed', function()
    -- Call your function to interact with the ped
    interactWithPed()
end)

-- Call the function when the resource is started
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- wait 1 second to allow everything to load
    spawnPed()
end)

-- Define the delivery point
local deliveryPoint = vector4(-463.9, -1715.03, 18.67, 301.91)

-- Deliver car
local function deliverCar(player, car)
    if car.category == currentCarCategory then
        -- Reward player
        local cash = math.random(1000, 4500)
        local rewardItems = {}

        -- Select 3 to 5 random items from `items`
        local numItems = math.random(3, 6)
        for i = 1, numItems do
            local item = chooseRandomItem(items)
            table.insert(rewardItems, item)
        end

        for _, item in ipairs(rewardItems) do
            local quantity = math.random(6, 16)
            -- Use appropriate QBCore function to give items to player
            -- Replace the following line with your own reward logic
            TriggerServerEvent('giveItem', item, quantity)
        end





        -- Despawn the vehicle
        local vehicle = GetVehiclePedIsIn(player, false)
        if vehicle ~= 0 then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteEntity(vehicle)
            TriggerServerEvent('qb-vehiclekeys:server:RemoveKey', plate)
        end

        -- Reset currentCarCategory and lastChangeTime
        currentCarCategory = nil
        lastChangeTime = nil

        -- Set cooldown
        cooldownEnd = GetGameTimer() / 1000 + 3 * 60

        if cooldownActive then
            -- Notify player of successful delivery
            exports['okokNotify']:Alert("Du skrapa bilen! Du kan hente ny om 3 minutter", "Cooldown", 10000, 'blue')
        else
            -- Notify player of successful delivery and cooldown
            exports['okokNotify']:Alert("Du skrapa bilen! Du kan hente ny om 3 minutter", "Cooldown", 10000, 'blue')
        end
    else
        -- Notify player about wrong category when 'E' key is pressed
        if IsControlJustReleased(0, 38) then
            local vehicle = GetVehiclePedIsIn(player, false)
            if vehicle ~= 0 then
                local modelHash = GetEntityModel(vehicle)
                local modelName = GetDisplayNameFromVehicleModel(modelHash)
                local vehicleCategory = GetVehicleCategory(vehicle)
                if vehicleCategory == currentCarCategory then
                    -- Deliver the vehicle and reward the player
                    deliverCar(player, {category = vehicleCategory})
                    return
                end
            end
            QBCore.Functions.Notify("This is not the correct type of vehicle.", "error")
        end
    end
end



-- Create a thread to handle vehicle delivery
Citizen.CreateThread(function()
    local inDeliveryZone = false
    local cooldownActive = false

    while true do
        Citizen.Wait(0) -- We run this loop every frame

        -- Get the player's vehicle
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local coords = GetEntityCoords(ped)

        -- Draw a marker at the delivery point, but only if the player is in a vehicle
        if vehicle ~= 0 then
            DrawMarker(1, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 15.0, 15.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
        end

        -- Check if the player is in the delivery zone
        local isInZone = Vdist(coords, deliveryPoint.xyz) < 15.0

        if isInZone then
            -- If the player enters the delivery zone, enable the delivery check and cooldown
            if not inDeliveryZone then
                inDeliveryZone = true
                cooldownActive = false
            end

            -- If the player is in a vehicle and the correct category
            if vehicle ~= 0 and not cooldownActive then
                local category = GetVehicleCategory(vehicle)
                if category == currentCarCategory then
                    -- If 'E' key is pressed
                    if IsControlJustReleased(0, 38) then
                        -- Deliver the vehicle and reward the player
                        deliverCar(PlayerId(), {category = category})

                        -- Despawn the vehicle
                        SetEntityAsMissionEntity(vehicle, true, true)
                        DeleteEntity(vehicle)

                        -- Once done, reset currentCarCategory and lastChangeTime
                        currentCarCategory = nil
                        lastChangeTime = nil

                        -- Activate cooldown
                        cooldownActive = true
                        Citizen.SetTimeout(3 * 60 * 1000, function()
                            cooldownActive = false
                        end)
                    end
                else
                    -- If 'E' key is pressed
                    if IsControlJustReleased(0, 38) then
                        -- Notify player about wrong category
                        QBCore.Functions.Notify("This is not the correct type of vehicle.", "error")
                    end
                end
            end
        else
            -- If the player exits the delivery zone, disable the delivery check
            if inDeliveryZone then
                inDeliveryZone = false
            end
        end
    end
end)
