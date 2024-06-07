local PedStatus = 0
local ESX       = nil
Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent("esx:getSharedObject",function(obj) ESX = obj end)
    end
end)

RegisterNetEvent("VCAC:TargetCheck")
AddEventHandler('VCAC:TargetCheck', function()
    TriggerServerEvent("VCAC:CheckBack")
end)

RegisterNetEvent("VCAC:DeleteEntity")
AddEventHandler('VCAC:DeleteEntity', function(Entity)
    local object = NetworkGetEntityFromNetworkId(Entity)
    if DoesEntityExist(object) then
        ESX.Game.DeleteObject(object)
    end
end)

RegisterNetEvent("VCAC:DeletePeds")
AddEventHandler('VCAC:DeletePeds', function(Ped)
    local ped = NetworkGetEntityFromNetworkId(Ped)
    if DoesEntityExist(ped) then
        if not IsPedAPlayer(ped) then
            local model = GetEntityModel(ped)
            if model ~= GetHashKey('mp_f_freemode_01') and model ~= GetHashKey('mp_m_freemode_01') then
                if IsPedInAnyVehicle(ped) then
                    -- vehicle delete
                    local vehicle = GetVehiclePedIsIn(ped)
                    NetworkRequestControlOfEntity(vehicle)
                    local timeout = 2000
                    while timeout > 0 and not NetworkHasControlOfEntity(vehicle) do
                        Wait(100)
                        timeout = timeout - 100
                    end
                    SetEntityAsMissionEntity(vehicle, true, true)
                    local timeout = 2000
                    while timeout > 0 and not IsEntityAMissionEntity(vehicle) do
                        Wait(100)
                        timeout = timeout - 100
                    end
                    Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized(vehicle) )
                    DeleteEntity(vehicle)
                    -- ped delete
                    NetworkRequestControlOfEntity(ped)
                    local timeout = 2000
                    while timeout > 0 and not NetworkHasControlOfEntity(ped) do
                        Wait(100)
                        timeout = timeout - 100
                    end
                    DeleteEntity(ped)
                else
                    NetworkRequestControlOfEntity(ped)
                    local timeout = 2000
                    while timeout > 0 and not NetworkHasControlOfEntity(ped) do
                        Wait(100)
                        timeout = timeout - 100
                    end
                    DeleteEntity(ped)
                end
            end
        end
    end
end)

RegisterNetEvent("VCAC:DeleteCars")
AddEventHandler('VCAC:DeleteCars', function(vehicle)
    local vehicle = NetworkGetEntityFromNetworkId(vehicle)
    if DoesEntityExist(vehicle) then
        NetworkRequestControlOfEntity(vehicle)
        local timeout = 2000
        while timeout > 0 and not NetworkHasControlOfEntity(vehicle) do
            Wait(100)
            timeout = timeout - 100
        end
        SetEntityAsMissionEntity(vehicle, true, true)
        local timeout = 2000
        while timeout > 0 and not IsEntityAMissionEntity(vehicle) do
            Wait(100)
            timeout = timeout - 100
        end
        Citizen.InvokeNative( 0xEA386986E786A54F, Citizen.PointerValueIntInitialized(vehicle) )
    end
end)

local entityEnumerator = {
    __gc = function(enum)
    if enum.destructor and enum.handle then
        enum.destructor(enum.handle)
    end
    enum.destructor = nil
    enum.handle = nil
    end
}

local function EnumerateEntities(initFunc, moveFunc, disposeFunc)
    return coroutine.wrap(function()
    local iter, id = initFunc()
    if not id or id == 0 then
        disposeFunc(iter)
        return
    end

    local enum = {handle = iter, destructor = disposeFunc}
    setmetatable(enum, entityEnumerator)

    local next = true
    repeat
        coroutine.yield(id)
        next, id = moveFunc(iter)
    until not next

    enum.destructor, enum.handle = nil, nil
    disposeFunc(iter)
    end)
end

function EnumerateObjects()
    return EnumerateEntities(FindFirstObject, FindNextObject, EndFindObject)
end

function EnumeratePeds()
    return EnumerateEntities(FindFirstPed, FindNextPed, EndFindPed)
end

function EnumerateVehicles()
    return EnumerateEntities(FindFirstVehicle, FindNextVehicle, EndFindVehicle)
end


Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        objst = 0
        for blocked in EnumerateObjects() do
            if
            GetEntityModel(blocked) == GetHashKey("p_crahsed_heli_s") or
            GetEntityModel(blocked) == GetHashKey("prop_rock_4_big2") or
            GetEntityModel(blocked) == GetHashKey("prop_beachflag_le") or
            GetEntityModel(blocked) == GetHashKey("xs_prop_hamburgher_wl")
            then
                objst = objst + 1
                DetachEntity(blocked, 0, false)
                SetEntityAlpha(blocked, 0.0, true)
                SetEntityAsMissionEntity(blocked, true, true)
                SetEntityAsNoLongerNeeded(blocked)
                NetworkRequestControlOfEntity(blocked)

                local timeout = 2000
                while timeout > 0 and not NetworkHasControlOfEntity(blocked) do
                    Wait(100)
                    timeout = timeout - 100
                end
                DeleteObject(blocked)
                DeleteEntity(blocked)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        objst = 0
        for blocked in EnumeratePeds() do
            if
            GetEntityModel(blocked) == GetHashKey("s_m_y_swat_01") or
            GetEntityModel(blocked) == GetHashKey("ig_wade")
            then
                objst = objst + 1
                RemoveAllPedWeapons(blocked, true)
                DeleteEntity(blocked)

            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if VCAC_C.GeneralStuff then
            Citizen.Wait(0)
            SetPedInfiniteAmmoClip(PlayerPedId(), false)
            SetPlayerInvincible(PlayerId(), false)
            SetEntityInvincible(PlayerPedId(), false)
            SetEntityCanBeDamaged(PlayerPedId(), true)
            ResetEntityAlpha(PlayerPedId())
        end

        if VCAC_C.AntiGodMode then
            Citizen.Wait(VCAC_C.AntiGodModeTimer)
            local playerped = PlayerPedId()
            local playerhealth = GetEntityHealth(playerped)
            SetEntityHealth(playerped, playerhealth - 2)
            local TimeR = math.random(10,150)
            Citizen.Wait(TimeR)
            if not IsPlayerDead(PlayerId()) and not ESX.GetPlayerData().IsDead then
                if GetEntityHealth(playerped) == playerhealth and GetEntityHealth(playerped) ~= 0 then
                    TriggerServerEvent("VCAC:BanMySelf", "Infinite Health - DemiGod", true)
                elseif GetEntityHealth(playerped) == playerhealth - 2 then
                    SetEntityHealth(playerped, GetEntityHealth(playerped) + 2)
                end
            end

            if GetEntityHealth(PlayerPedId()) > VCAC_C.MaxPlayerHealth then
                TriggerServerEvent("VCAC:BanMySelf", "Player Health above MAX", false)
            end

            if GetPlayerInvincible(PlayerId()) then
                TriggerServerEvent("VCAC:BanMySelf", "Godmode Activated", true)
                SetPlayerInvincible(PlayerId(), false)
            end
        end

        if VCAC_C.AntiSpectate then
            Citizen.Wait(1000)
            if NetworkIsInSpectatorMode() then
                TriggerServerEvent("VCAC:BanMySelf", "Spectate Player", true)
            end
        end

        if VCAC_C.AntiSpeedHack then
            if not IsPedInAnyVehicle(GetPlayerPed(-1), 1) then
                if GetEntitySpeed(GetPlayerPed(-1)) > VCAC_C.SpeedHackValue then
                    if not IsPedFalling(GetPlayerPed(-1)) then
                        TriggerServerEvent("VCAC:BanMySelf", "Speed Hack Activated", true)
                    end
                end
            end
        end

        if VCAC_C.AntiPlayerBlips then
            Citizen.Wait(1000)
            local IsBlip = 0
            local OnlinePlayers = GetActivePlayers()
            for i = 1, #OnlinePlayers do
                if i ~= PlayerId() then
                    if DoesBlipExist(GetBlipFromEntity(GetPlayerPed(i))) then
                        IsBlip = IsBlip + 1
                    end
                end
                if IsBlip > 0 then
                    TriggerServerEvent("VCAC:BanMySelf", "High Blips", false)
                end
            end
        end

        if VCAC_C.PlayerProtection then
            SetEntityProofs(GetPlayerPed(-1), false, true, true, false, false, false, false, false)
        end
    end
end)

Citizen.CreateThread(function()
    while true and VCAC_C.BlacklistedWeapons do
        Citizen.Wait(2000)
        for _,theWeapon in ipairs(VCAC_C.BlacklistedWeaponsTable) do
          Citizen.Wait(200)
            if HasPedGotWeapon(GetPlayerPed(-1), GetHashKey(theWeapon), false) then
                RemoveAllPedWeapons(GetPlayerPed(-1), false)
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true and VCAC_C.AntiDamageModifier do
        Citizen.Wait(2500)

        local defaultModifier = 1.0

        local weaponDamageModifier = GetPlayerWeaponDamageModifier(PlayerId())
        if weaponDamageModifier ~= defaultModifier and weaponDamageModifier ~= 0.0 and weaponDamageModifier > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change weapon damage modifier", false)
        end

        local WeaponDefenceModifier = GetPlayerWeaponDefenseModifier(PlayerId())
        if WeaponDefenceModifier ~= defaultModifier and WeaponDefenceModifier ~= 0.0 and WeaponDefenceModifier > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change weapon defence modifier", false)
        end

        local WeaponDefenceModifier2 = GetPlayerWeaponDefenseModifier_2(PlayerId())
        if WeaponDefenceModifier2 ~= defaultModifier and WeaponDefenceModifier2 ~= 0.0 and WeaponDefenceModifier2 > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change weapon defence modifier2", false)
        end

        local VehicleDamageModifier = GetPlayerVehicleDamageModifier(PlayerId())
        if VehicleDamageModifier ~= defaultModifier and VehicleDamageModifier ~= 0.0 and VehicleDamageModifier > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change vehicle damage modifier", false)
        end

        local VehicleDefenceModifier = GetPlayerVehicleDefenseModifier(PlayerId())
        if VehicleDefenceModifier ~= defaultModifier and VehicleDefenceModifier ~= 0.0 and VehicleDefenceModifier > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change vehicle defence modifier", false)

        end

        local MeleeDefenceModifier = GetPlayerMeleeWeaponDefenseModifier(PlayerId())
        if MeleeDefenceModifier ~= defaultModifier and VehicleDefenceModifier ~= 0.0 and MeleeDefenceModifier > 1.0 then
            TriggerServerEvent("VCAC:BanMySelf", "Tried to change melee defence modifier", false)
        end

    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(2000)
        local weaponHash = GetSelectedPedWeapon(GetPlayerPed(-1))
        if VCAC_C.AntiDamageChanger then
            local WeaponDamage = math.floor(GetWeaponDamage(weaponHash))
            if VCAC_C.WeaponDamages[weaponHash] and WeaponDamage > VCAC_C.WeaponDamages[weaponHash].damage then
                local weapon = VCAC_C.WeaponDamages[weaponHash]
                TriggerServerEvent("VCAC:BanMySelf", "Tried to change gun damage", false)
            end
        end
        if VCAC_C.WeaponExplosiveCheck then
            local wgroup = GetWeapontypeGroup(weaponHash)
            local dmgt = GetWeaponDamageType(weaponHash)
            if wgroup == -1609580060 or wgroup == -728555052 or weaponHash == -1569615261 then
                if dmgt ~= 2 then
                    TriggerServerEvent("VCAC:BanMySelf", "Tried to use explosive melee", false)
                end
            elseif wgroup == 416676503 or wgroup == -957766203 or wgroup == 860033945 or wgroup == 970310034 or wgroup == -1212426201 then
                if dmgt ~= 3 then
                    TriggerServerEvent("VCAC:BanMySelf", "Tried to use explosive weapon", false)
                end
            end
        end
    end
end)