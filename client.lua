-- Hent QBCore
local QBCore = exports['qb-core']:GetCoreObject()

-- Penger og items variabler
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

-- Velg randome items
local function chooseRandomItem(table)
    local keys = {}
    for key, value in pairs(table) do
        keys[#keys + 1] = key
    end
    return table[keys[math.random(1, #keys)]]
end

-- Oppdater bilkategori vær andre time
local function updateCarCategory()
    local currentTime = GetGameTimer() / 1000
    if lastChangeTime == nil or (currentTime - lastChangeTime >= 2 * 60 * 60) then
        currentCarCategory = chooseRandomItem(carCategories)
        lastChangeTime = currentTime
    end
end

-- PED innstillinger
local pedModel = 'mp_m_waremech_01'
local pedCoord = vector4(-469.44, -1717.56, 17.69, 286.26)

-- Last inn PED
local function LoadModel(model)
    local attempts = 0
    while attempts < 100 and not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(10)
        attempts = attempts + 1
    end
    return IsModelValid(model)
end

-- Spawn PED å gjør han interactable
local function spawnPed()
    if not LoadModel(pedModel) then
        print('Failed to load model ' .. pedModel)
        return
    end
    local ped = CreatePed(4, pedModel, pedCoord.xyz, pedCoord.w, false)
    SetEntityAsMissionEntity(ped, true, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)

    -- QB-target med PED
    exports['qb-target']:AddTargetModel({pedModel}, {
        options = {
            {
                event = 'myResource:interactWithPed',
                icon = 'fas fa-car',
                label = 'Start oppdrag',
            },
        },
        distance = 2.5
    })
end

-- Notifikasjoner
local function interactWithPed()
    updateCarCategory()
    if cooldownEnd ~= nil and GetGameTimer() / 1000 <= cooldownEnd then
        -- Notify player of cooldown
        local remainingTime = math.ceil((cooldownEnd - (GetGameTimer() / 1000)) / 60) -- Remaining time in minutes, rounded up
        QBCore.Functions.Notify("Du må vente på å hente ny bil! ".. remainingTime .." minutt(er)", "error")
    else
        -- Notify player of job assignment
        exports['okokNotify']:Alert("Hent "..currentCarCategory.."", "Biltype du skal stjele", 10000, 'blue')
    end
end

-- Interaksjon med PED
RegisterNetEvent('myResource:interactWithPed')
AddEventHandler('myResource:interactWithPed', function()
    interactWithPed()
end)

-- Start funksjon
Citizen.CreateThread(function()
    Citizen.Wait(1000) -- Vent i ett sekund for å laste inn
    spawnPed()
end)

-- Leveranse lokasjon
local deliveryPoint = vector4(-463.9, -1715.03, 18.67, 301.91)

-- Lever bil
local function deliverCar(player, car)
    if car.category == currentCarCategory then
        -- Gevinst
        local rewardItems = {}

        -- Velg mellom 3 og 6 items fra items tabellen
        local numItems = math.random(3, 6)
        for i = 1, numItems do
            local item = chooseRandomItem(items)
            table.insert(rewardItems, item)
        end

        for _, item in ipairs(rewardItems) do
            local quantity = math.random(6, 16)
            TriggerServerEvent('root_bilchop:server:giveItem', item, quantity)
            -- TriggerServerEvent('root_bilchop:server:giveMoney') 

        end

        -- Slett kjøretøy
        local vehicle = GetVehiclePedIsIn(player, false)
        if vehicle ~= 0 then
            SetEntityAsMissionEntity(vehicle, true, true)
            DeleteEntity(vehicle)
            -- TriggerServerEvent('qb-vehiclekeys:server:RemoveKey', plate)
        end

        currentCarCategory = nil
        lastChangeTime = nil

        -- start cooldown
        cooldownEnd = GetGameTimer() / 1000 + 3 * 60

        if cooldownActive then
            local remainingTime = math.ceil((cooldownEnd - (GetGameTimer() / 1000)) / 60) -- Remaining time in minutes, rounded up
            exports['okokNotify']:Alert("Du skrapa bilen! Du kan hente ny om " .. remainingTime .. " minutter", "Cooldown", 10000, 'blue')
        else
            -- Notifikasjon om leveranse og cooldown
            exports['okokNotify']:Alert("Du skrapa bilen! Du kan hente ny om 3 minutter", "Cooldown", 10000, 'blue')
        end
        
    else
        -- Feil kategori beskjed om du trykker E
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
            QBCore.Functions.Notify("Dette er feil type bil.", "error")
        end
    end
end



-- Thread for å levere bil
Citizen.CreateThread(function()
    local inDeliveryZone = false
    local cooldownActive = false
    local vehicleCategory = nil

    while true do
        Citizen.Wait(0) -- Kjøres vært 3 sekund

        -- Hent spillerens kjøretøy
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local coords = GetEntityCoords(ped)

        -- Sjekk om spilleren er i leveranse sonen
        local isInZone = Vdist(coords, deliveryPoint.xyz) < 15.0

        if isInZone then
            -- Om spilleren er i sonen sjekk type og cooldown
            if not inDeliveryZone then
                inDeliveryZone = true
                cooldownActive = false
                vehicleCategory = GetVehicleCategory(vehicle)
            end

            if vehicle ~= 0 and not cooldownActive and GetVehicleCategory(vehicle) == currentCarCategory then
                DrawMarker(1, deliveryPoint.x, deliveryPoint.y, deliveryPoint.z - 1.0, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 15.0, 15.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)

                if IsControlJustReleased(0, 38) then
                    deliverCar(PlayerId(), {category = currentCarCategory})

                    SetEntityAsMissionEntity(vehicle, true, true)
                    DeleteEntity(vehicle)

                    currentCarCategory = nil
                    lastChangeTime = nil

                    cooldownActive = true
                    Citizen.SetTimeout(3 * 60 * 1000, function()
                        cooldownActive = false
                    end)
                end
            end
        else
            if inDeliveryZone then
                inDeliveryZone = false
                vehicleCategory = nil
            end
        end
    end
end)

