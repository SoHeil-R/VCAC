local ESX        = nil
local BanList    = {}
local ThisPlayer = {}
local charset    = 'abcdefghijklmnopqrstuvwxyz0123456789'
local charTable  = {}

for c in charset:gmatch"." do
    table.insert(charTable, c)
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end
end)

AddEventHandler("onMySQLReady",function()
    loadBanList()
end)

function loadBanList()
        MySQL.Async.fetchAll('SELECT * FROM vcac_ban',{},function (data)
            BanList = {}
            for i=1, #data, 1 do
                table.insert(BanList, {
                        identifier = data[i].identifier,
                        license    = data[i].license,
                        liveid     = data[i].liveid,
                        xblid      = data[i].xblid,
                        discord    = data[i].discord,
                        playerip   = data[i].playerip,
                        reason     = data[i].reason,
                        report_id  = data[i].report_id,
                    })
            end
    end)
end

RegisterCommand('DBanReload', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.permission_level >= 4 then
        if xPlayer.get('aduty') then
            loadBanList()
        else
            TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Shoma nemitavanid dar halat ^1OffDuty ^0az command haye admini estefade konid!")
        end
    else
        TriggerClientEvent('chatMessage', source, "[SYSTEM]", {255, 0, 0}, " ^0Shoma Ejaze in kar ro nadarid!")
    end
end)



function string.random(length)
    local randomString = ""
    for i = 1, length do
        randomString = randomString .. charTable[math.random(1, #charTable)]
    end
    return randomString
end

if VCAC_A.TriggerDetection then
    for i=1 , #VCAC_B.Events do
        RegisterServerEvent(VCAC_B.Events[i])
            AddEventHandler(VCAC_B.Events[i], function()
                local src = source
                sendToDiscord(DiscordVCAC,src,"[EXECUTER]","**Executer Name: **"..GetPlayerName(src).."\n\n**Event Name: **"..VCAC_B.Events[i],3447003)
                TriggerEvent('VCAC:Ban1FuckinCheater', src,"Tried to use detected events!")
                return CancelEvent()
        end)
    end
end

Citizen.CreateThread(function()
    while true and VCAC_A.ConnectionCheck do
        updateCheck()
        Citizen.Wait(10000)
        TriggerClientEvent("VCAC:TargetCheck", -1)
    end
end)

Citizen.CreateThread(function()
    while true and VCAC_A.ConnectionCheck do
        Citizen.Wait(45000)
        RemToCheck()
    end
end)

PlayerCheck = {}
PlayerWarning = {}
function AddToCheck(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if not PlayerCheck[xPlayer.identifier] then
                PlayerCheck[xPlayer.identifier] = {Name = xPlayer.name}
            end
        end
    end
end

function WarnPlayer(xPlayer)
    if PlayerWarning[xPlayer.identifier] then
        if PlayerWarning[xPlayer.identifier].Warn >= 3 then
            PlayerWarning[xPlayer.identifier] = nil
            sendToDiscord(VCAC_A.DiscordVCACWarn,xPlayer.source,"[Not Connect to anticheat]","**Name: **"..GetPlayerName(xPlayer.source),12370112)
            DropPlayer(xPlayer.source, "[VCAC]: You are not connected to ANTI-CHEAT.")
        else
            PlayerWarning[xPlayer.identifier].Warn = PlayerWarning[xPlayer.identifier].Warn + 1
            print("Player Disconnected! | "..xPlayer.name.." | "..PlayerWarning[xPlayer.identifier].Warn.."/4")
        end
    else
        PlayerWarning[xPlayer.identifier] = {Warn = 0}
    end
end

function RemToCheck()
    if ESX then
        for _,v in pairs(GetPlayers()) do
                local xPlayer = ESX.GetPlayerFromId(v)
            if xPlayer then
                if PlayerCheck[xPlayer.identifier] then
                    PlayerCheck[xPlayer.identifier] = nil
                    PlayerWarning[xPlayer.identifier] = nil
                else
                    print("Not Player To List!")
                end
            end
        end
    end
end

function updateCheck()
    if ESX then
        for _,v in pairs(GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(v)
            if xPlayer then
                if not PlayerCheck[xPlayer.identifier] then
                    WarnPlayer(xPlayer)
                end
            end
        end
    end
end

AddEventHandler('playerDropped', function()
        local _source = source
    if _source ~= nil then
        local identifier = GetPlayerIdentifier(_source)
        PlayerCheck[identifier] = nil
        PlayerWarning[identifier] = nil
    end
end)


AddEventHandler('explosionEvent', function(sender, ev)
    if VCAC_A.DetectExplosions then
        CancelEvent()
        if VCACExplosion.ExplosionsList[ev.explosionType] then
            if VCACExplosion.ExplosionsList[ev.explosionType].ban then
                sendToDiscord(VCAC_A.DiscordVCACexplosion,sender,"[CREATE BLOCKED EXPLOSION]","**Creator Name: **"..GetPlayerName(sender).."\n\n**Explosion Name: **"..VCACExplosion.ExplosionsList[ev.explosionType].name,1752220)
                TriggerEvent('VCAC:Ban1FuckinCheater', sender,"Tried to create block list Explosions")
            else
                sendToDiscord(VCAC_A.DiscordVCACexplosion,sender,"[CREATE BLOCKED EXPLOSION]","**Creator Name: **"..GetPlayerName(sender).."\n\n**Explosion Name: **"..VCACExplosion.ExplosionsList[ev.explosionType].name,1752220)
            end
        else
            sendToDiscord(VCAC_A.DiscordVCACexplosion,sender,"[CREATE UNKNOWN EXPLOSION]","**Creator Name: **"..GetPlayerName(sender).."\n\n**Explosion TYPE: **"..ev.explosionType,1752220)
        end
    end
end)

RegisterServerEvent('VCAC:BanMySelf')
AddEventHandler('VCAC:BanMySelf', function(reason,checkadmin)
    local xPlayer = ESX.GetPlayerFromId(source)
    if checkadmin then
        if xPlayer.permission_level >= 10 then return false end
    end
    if not xPlayer.get('aduty') then
        TriggerEvent('VCAC:Ban1FuckinCheater', source,reason)
    end
end)

RegisterServerEvent('VCAC:CheckBack')
AddEventHandler('VCAC:CheckBack', function()
    AddToCheck(source)
end)


AddEventHandler('entityCreated', function(entity)
    local entity = entity
    if not DoesEntityExist(entity) then
        return
    end
    local src = NetworkGetEntityOwner(entity)
    local entID = NetworkGetNetworkIdFromEntity(entity)
    local model = GetEntityModel(entity)
    local hash = GetHashKey(entity)
    local SpawnerName = GetPlayerName(src)

    -- Check Blocked Vehicles
    if VCAC_A.AntiSpawnVehicles then
        for i, objName in ipairs(VCAC_E.AntiNukeBlacklistedVehicles) do
            if model == GetHashKey(objName.name) then
                    TriggerClientEvent("VCAC:DeleteCars", -1,entID)
                    Citizen.Wait(800)
                    if objName.log then
                        sendToDiscord(VCAC_A.DiscordVCACObject,src,"[SPAWN BLOCKED VEHICLE]","**-Spawner Name: **"..SpawnerName.."\n\n**-Object Name: **"..objName.name.."\n\n**-Spawn Model:** "..model.."\n\n**-Entity ID:** "..entity.."\n\n**-Hash ID:** "..hash,15105570)
                    end
                    if objName.ban then
                        TriggerEvent('VCAC:Ban1FuckinCheater', src,"Tried to spawn block list vehicles")
                    end
                break
            end
        end
    end

    -- Check Blocked Peds
    if VCAC_A.AntiSpawnPeds then
        for i, objName in ipairs(VCAC_E.AntiNukeBlacklistedPeds) do
            if model == GetHashKey(objName.name) then
                TriggerClientEvent("VCAC:DeletePeds", -1, entID)
                Citizen.Wait(800)
                if objName.log then
                    sendToDiscord(VCAC_A.DiscordVCACObject,src,"[SPAWN BLOCKED PEDS]","**-Spawner Name: **"..SpawnerName.."\n\n**-Object Name: **"..objName.name.."\n\n**-Spawn Model:** "..model.."\n\n**-Entity ID:** "..entity.."\n\n**-Hash ID:** "..hash,15105570)
                end
                if objName.ban then
                    TriggerEvent('VCAC:Ban1FuckinCheater', src,"Tried to spawn block list peds")
                end
                break
            end
        end
    end

    -- Check Blocked Nuke
    if VCAC_A.AntiNuke then
        for i, objName in ipairs(VCAC_E.AntiNukeBlacklistedObjects) do
            if model == GetHashKey(objName) then
                    TriggerClientEvent("VCAC:DeleteEntity", -1, entID)
                    Citizen.Wait(800)
                    if objName.log then
                        sendToDiscord(VCAC_A.DiscordVCACObject,src,"[SPAWN BLOCKED OBJECT]","**-Spawner Name: **"..SpawnerName.."\n\n**-Object Name: **"..objName.name.."\n\n**-Spawn Model:** "..model.."\n\n**-Entity ID:** "..entity.."\n\n**-Hash ID:** "..hash,15105570)
                    end
                    if objName.ban then
                        TriggerEvent('VCAC:Ban1FuckinCheater', src,"Tried to spawn block list objects")
                    end
                break
            end
        end
    end

end)

AddEventHandler("chatMessage",function(source, n, message)
    for i=1 , #VCAC_BWords.Words do
        if string.match(message:lower(),VCAC_BWords.Words[i]:lower()) then
                TriggerEvent('VCAC:Ban1FuckinCheater', source,"Send block word to chat")
                return CancelEvent()
        end
    end
end)

AddEventHandler('VCAC:Ban1FuckinCheater', function(source,reason)
    local identifier
    local license
    local liveid    = "no info"
    local xblid     = "no info"
    local discord   = "no info"
    local playerip
    local sourceplayername = GetPlayerName(source)
    for k,v in ipairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            identifier = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            liveid = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            xblid  = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            discord = v
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            playerip = v
        end
    end
    ban(source,identifier,license,liveid,xblid,discord,playerip,sourceplayername,reason)
end)

function ban(source,identifier,license,liveid,xblid,discord,playerip,sourceplayername,reason)
    if not ThisPlayer[identifier] then
        local report_id = string.random(7).."-"..string.random(7).."-"..string.random(7).."-"..string.random(7)
        ThisPlayer[identifier] = true
        table.insert(BanList, {
            identifier = identifier,
            license    = license,
            liveid     = liveid,
            xblid      = xblid,
            discord    = discord,
            playerip   = playerip,
            reason     = reason,
            report_id  = report_id,
        })
        MySQL.Async.execute('INSERT INTO vcac_ban (identifier,license,liveid,xblid,discord,playerip,sourceplayername,reason,report_id) VALUES (@identifier,@license,@liveid,@xblid,@discord,@playerip,@sourceplayername,@reason,@report_id)',{
            ['@identifier']       = identifier,
            ['@license']          = license,
            ['@liveid']           = liveid,
            ['@xblid']            = xblid,
            ['@discord']          = discord,
            ['@playerip']         = playerip,
            ['@sourceplayername'] = sourceplayername,
            ['@reason']           = reason,
            ['@report_id']        = report_id,
        },nil)
        TriggerClientEvent('chatMessage', -1, "[VCAC Detected]", {255, 0, 0}, sourceplayername.." permanent Ban from server." )
        DropPlayer(source, 'You have been automatically banned from VCAC. This ban never will expire. Please do note that the ViceCity staff is unlikely to assist you with this ban.\nYour ban ID is '..report_id)
        sendToDiscord(VCAC_A.DiscordVCACBan,source,"[CHEATER BAN]","**Name :**"..sourceplayername.."\n\n**"..identifier.."**\n\n**"..license.."**\n\n<@!"..string.gsub(discord, "discord:", "")..">\n\n**"..playerip.."**\n\n**Reason :**"..reason.."\n\n**Report ID :**"..report_id.."\n\n Enjoy ban xD",15158332)
    end
end

function sendToDiscord(DiscordLog,source,title,des,color)
    if VCAC_A.DiscordLog then
        local nick = GetPlayerName(source) or "None"
        local embed = {
            {
                ["color"] = color,
                ["title"] = title,
                ["description"] = des,
                ["footer"] = {
                ["text"] = "ViceCity AntiCheat | Dev: SoHeil#4935",
            },}}
        Wait(100)
        PerformHttpRequest(DiscordLog, function(err, text, headers) end, 'POST', json.encode({username = nick, embeds = embed}), { ['Content-Type'] = 'application/json' })
    end
end

AddEventHandler('playerConnecting', function (playerName,setKickReason)
    local steamID  = "empty"
    local license  = "empty"
    local liveid   = "empty"
    local xblid    = "empty"
    local discord  = "empty"
    local playerip = "empty"

    for k,v in ipairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("steam:")) == "steam:" then
            steamID = v
        elseif string.sub(v, 1, string.len("license:")) == "license:" then
            license = v
        elseif string.sub(v, 1, string.len("live:")) == "live:" then
            liveid = v
        elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
            xblid  = v
        elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
            discord = v
        elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
            playerip = v
        end
    end

    if (Banlist == {}) then
            Citizen.Wait(1000)
    end

    for i = 1, #BanList, 1 do
        if
            ((tostring(BanList[i].identifier)) == tostring(steamID)
            or (tostring(BanList[i].license)) == tostring(license)
            or (tostring(BanList[i].liveid)) == tostring(liveid)
            or (tostring(BanList[i].xblid)) == tostring(xblid)
            or (tostring(BanList[i].discord)) == tostring(discord)
            or (tostring(BanList[i].playerip)) == tostring(playerip))
        then
            setKickReason(VCAC_A.BanMassage..'\nYour ban ID is '..BanList[i].report_id)
            CancelEvent()
        end
    end
end)