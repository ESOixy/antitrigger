local spawned = false
local isDetected = false
local OCR = {
    Webhook = nil
}


RegisterNetEvent('ATLAS:WF0OnJlcXVlc3R')
AddEventHandler('ATLAS:WF0OnJlcXVlc3R',function (ocr) --atlas_anticheat:receiveOCRWebhook
    OCR.Webhook = ocr
end)

Citizen.CreateThread(function ()
    while OCR.Webhook == nil do
        Citizen.Wait(500)
        TriggerServerEvent('ATLAS:YXRsYXNfYW50aWNoZ')
    end
end)

AddEventHandler('playerSpawned', function()
    if not spawned then
        spawned = true
    else
        return
    end
end)

---------------------------
-- Base64 encoding function for obfuscation
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function base64Encode(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function generateObfuscatedEventName(baseName)
    local randomSuffix = tostring(math.random(10000, 99999))
    return base64Encode(baseName .. randomSuffix)
end

-- Function to log the ban with some obfuscation
function logBan(playerName, reason, result)
    local eventName = generateObfuscatedEventName('atlas_anticheat:addLog') -- Dynamic event name
    local obfuscatedPlayer = base64Encode(playerName)  -- Base64 encode player name
    local obfuscatedReason = base64Encode(reason)  -- Base64 encode reason
    local obfuscatedResult = base64Encode(result)  -- Base64 encode result

    -- Log the ban
    TriggerServerEvent(eventName, "V2AntiCheat", obfuscatedPlayer .. " for " .. obfuscatedReason, obfuscatedResult)
end

-- Modified BanPlayer function with improved logging
function BanPlayer(reason, punish, retryCount)
    retryCount = retryCount or 0
    punish = punish or atlas.punishType
    print(punish)

 
    exports[atlas.screenshotModule]:requestScreenshotUpload(OCR.Webhook, 'files[]', function(data)
        local resp = json.decode(data)
        if resp ~= nil and resp.attachments ~= nil and resp.attachments[1] ~= nil and resp.attachments[1].proxy_url ~= nil then
            SCREENSHOT_URL = resp.attachments[1].proxy_url
            TriggerServerEvent("AT:LOKOMOTIVA", reason, SCREENSHOT_URL, punish)
        else
            if retryCount < 5 then
                Citizen.Wait(500)
                BanPlayer(reason, punish, retryCount)
            else
                TriggerServerEvent("AT:LOKOMOTIVA", reason, nil, punish)
            end
        end
    end)
end
    


-----------------


RegisterNetEvent('atlas_anticheat:detectclient')
AddEventHandler('atlas_anticheat:detectclient',function (reason)
    BanPlayer(reason)
end)

-- Define a threshold for accurate aiming (you can adjust this based on your preferences)
local aimingThreshold = 0.55

if atlas.antiMagicBullet then
    function CheckMagicBullet(attacker, victim)
        local attempt = 0
        for i=0,3,1 do
            if not HasEntityClearLosToEntityInFront(attacker, victim) and not HasEntityClearLosToEntity(attacker, victim, 17) and HasEntityClearLosToEntity_2(attacker, victim, 17) == 0 then
                attempt = attempt + 1
            end
            Wait(1500)
        end
    
        if (attempt >= 3) then
            BanPlayer("Magic Bullet")
        end
    end
    AddEventHandler('gameEventTriggered', function(event, data)
        if event ~= 'CEventNetworkEntityDamage' then return end
        local victim, victimDied = data[1], data[4]
        if not IsPedAPlayer(victim) then return end
        local player = PlayerId()
        local playerPed = PlayerPedId()
        if victimDied and NetworkGetPlayerIndexFromPed(victim) == player and (IsPedDeadOrDying(victim, true) or IsPedFatallyInjured(victim))  then
            local killerEntity, _ = GetPedSourceOfDeath(playerPed), GetPedCauseOfDeath(playerPed)
            local killerClientId = NetworkGetPlayerIndexFromPed(killerEntity)
            if killerEntity ~= playerPed and killerClientId and NetworkIsPlayerActive(killerClientId) then
                CheckMagicBullet(GetPlayerPed(killerClientId), victim)
            end
        end
    end)
end

if atlas.fakeTriggers then
    for k, v in pairs(atlas.triggerList) do
        if string.lower(v.type) == 'client' then
            RegisterNetEvent(k)
            AddEventHandler(k, function()
                BanPlayer(Locale.Trigger:format(k))
            end)
        end
    end
end

InChecks = {
    [1] = true,
    [2] = true,
    [3] = true,
    [4] = true
}
local executorCount = 0
local executorFlagss = 0
local spam = false

if atlas.antiOverlay then
    CreateThread(function()
        local SavedX, SavedY = GetNuiCursorPosition()
        local SavedCamCoords = GetGameplayCamCoord()
        while (true) do
            Wait(0)
            local Neatlas, NewY = GetNuiCursorPosition()
            local NewCamCoords = GetGameplayCamCoord()
            local ResX, ResY = GetActiveScreenResolution()
            if (Neatlas <= ResX and NewY <= ResY) then
                if (InChecks[1] == true) then
                    if IsControlJustPressed(0, 121) or IsControlJustPressed(0, 208) or IsControlJustPressed(0, 316) or IsControlJustPressed(0, 10) or IsControlJustPressed(0, 207) then
                        InChecks[4] = true
                        CreateThread(function()
                            while (InChecks[4] == true) do
                                Wait(0)
                                if (Neatlas ~= SavedX or NewY ~= SavedY) then
                                    if (not IsNuiFocused()) then
                                        executorCount = executorCount + 1
                                        if executorCount > 2 then
                                            if not spam then
                                                spam = true
                                                executorCount = 0
                                                if executorFlagss > 2 then
                                                    executorFlagss = 0
                                                    BanPlayer("Cheat Overlay Detected")
                                                else
                                                    executorFlagss = executorFlagss + 1
                                                end
                                            end
                                        end
                                    end
                                elseif (NewCamCoords ~= SavedCamCoords) then
                                    InChecks[4] = false
                                end
                            end
                            Wait(500)
                            TerminateThisThread()
                        end)
                    end
                end
            end
            SavedX, SavedY = Neatlas, NewY
            SavedCamCoords = NewCamCoords
        end
    end)
    
    CreateThread(function()
        local SavedX, SavedY = GetNuiCursorPosition()
        local SavedCamCoords = GetGameplayCamCoord()
        while (true) do
            Wait(0)
            local Neatlas, NewY = GetNuiCursorPosition()
            local NewCamCoords = GetGameplayCamCoord()
            local ResX, ResY = GetActiveScreenResolution()
            local Sent = 0
            if (Neatlas <= ResX and NewY <= ResY) then
                if (InChecks[1] == true) then
                    if (Neatlas ~= SavedX or NewY ~= SavedY) then
                        if (NewCamCoords ~= SavedCamCoords) then
                            if (not IsNuiFocused()) then
                                InChecks[1] = false
                                InChecks[2] = true
                            end
                        end
                    end
                elseif (InChecks[2] == true) then
                    if IsControlJustPressed(0, 121) or IsControlJustPressed(0, 208) or IsControlJustPressed(0, 316) or IsControlJustPressed(0, 10) or IsControlJustPressed(0, 207) then
                        InChecks[2] = false
                        InChecks[3] = true
                    else
                        if (Neatlas ~= SavedX or NewY ~= SavedY) then
                            if (NewCamCoords == SavedCamCoords) then
                                InChecks[1] = true
                                InChecks[2] = false
                            end
                        end
                    end
                elseif (InChecks[3] == true) then
                    for i = 1, 5 do
                        if IsControlJustPressed(i, 240) then
                            Sent = Sent + 1
                        end
                    end
                    if (Sent == 5) then
                        InChecks[2] = true
                        InChecks[3] = false
                    end
                    if (Neatlas ~= SavedX or NewY ~= SavedY) then
                        if (NewCamCoords == SavedCamCoords) then
                            InChecks[1] = true
                            InChecks[2] = false
                            InChecks[3] = false
                            executorCount = executorCount + 1
                            executorCount = executorCount + 1
                            if executorCount > 2 then
                                if not spam then
                                    executorCount = 0
                                    if executorFlagss > 2 then
                                        executorFlagss = 0
                                            BanPlayer("Cheat Overlay Detected")
                                    else
                                        executorFlagss = executorFlagss + 1
                                    end
                                end
                            end
                        end
                    end
                end
            end
            SavedX, SavedY = Neatlas, NewY
            SavedCamCoords = NewCamCoords
        end
    end)
end


if atlas.antiGiveWeapons then
    CreateThread(function()
        while true do
            Wait(2500)
            local w, s = GetCurrentPedWeapon(PlayerPedId())
            if w == 1 and GetSelectedPedWeapon(PlayerPedId()) == -1569615261 then
                BanPlayer("Attempted to spawn a weapon")
            end
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if atlas.antiBlacklistedWeapon then
            Wait(250)
            for weaponname, weaponmodel in pairs(atlas.Weapons) do
                if HasPedGotWeapon(PlayerPedId(), GetHashKey(weaponmodel), false) == 1 then
                    RemoveAllPedWeapons(PlayerPedId(), true)
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        
                        BanPlayer(Locale.BlacklistedWeapon:format(weaponname))
                    end
                end
            end
        end
        if atlas.antiBlacklistedVehicles then
            Wait(100)
            for k, v in pairs(atlas.vehicleBlacklist) do
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    local veh = GetEntityModel(vehicle)
                    if string.lower(GetDisplayNameFromVehicleModel(veh)) == k and v then
                        DeleteEntity(vehicle)
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            BanPlayer(Locale.BlacklistedVeh:format(k))
                        end
                    end
                end
            end
        end
        if atlas.antiPeds then
            Wait(2500)
            local pedmodel = GetEntityModel(PlayerPedId())
            for k, v in pairs(atlas.pedBlacklist) do
                if pedmodel == GetHashKey(v) then
                    BanPlayer(Locale.Ped:format(v))
                end
            end
        end
        if atlas.antiBlips then
            Wait(600)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                if DoesBlipExist(GetBlipFromEntity(ped)) then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.Blips,atlas.DetectionPunishments["blips"])
                    end
                    return
                end
            end
        end
    end
end)

-- if atlas.antiMagicBullet then
--     Citizen.CreateThread(function()
--         AddEventHandler("gameEventTriggered", function(name, args)
--             local _entityowner = GetPlayerServerId(NetworkGetEntityOwner(args[2]))
--             if _entityowner == GetPlayerServerId(PlayerId()) or args[2] == -1 then
--                 for k, ped in pairs(atlas.playerModels) do
--                     if IsEntityAPed(args[1]) and GetEntityModel(args[1]) == GetHashKey(ped) then
--                         if not IsEntityOnScreen(args[1]) then
--                             local entcoords = GetEntityCoords(args[1])
--                             local dist = #(entcoords - GetEntityCoords(PlayerPedId()))
--                             if dist < atlas.MagicBulletDistance then
--                                 if not isDetected or atlas.Debug then
--                                     isDetected = true


--                                     BanPlayer(
--                                         Locale.MagicBullet:format(math.floor(dist + 0.5)))
--                                 end
--                             end
--                         end
--                     end
--                 end
--             end
--         end)
--     end)
-- end

if atlas.antiBlacklistPlate then
    Citizen.CreateThread(function()
        while true do
            Wait(1500)
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                for i, plate in ipairs(atlas.Plates) do
                    local currentPlate = GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))
                    if string.find(currentPlate, string.upper(plate)) then
                        DeleteVehicle(GetVehiclePedIsUsing(PlayerPedId()))
                        if not isDetected or atlas.Debug then
                            isDetected = true
                           -- TriggerEvent('dz-announce:client:sendNuiMessage', 5000, "ATLAS ANTICHEAT")
                            BanPlayer(Locale.VehiclePlate:format(plate))
                        end
                    end
                end
            end
        end
    end)
end

if atlas.antiPlateChange then
    local initialPlates = {}  -- Table to store initial plates by entity ID
    local detectionCooldown = 10000  -- 1-minute cooldown between detections
    local lastDetectedTime = 0

    -- Function to log messages (you could replace this with more advanced logging)
    local function log(message)
        print(message)  -- Replace with server-side logging if necessary
    end

    -- Main detection logic
    Citizen.CreateThread(function()
        while true do
            Wait(1500)  -- Check every 1.5 seconds

            local playerId = PlayerPedId()
            local playerNetworkId = GetPlayerServerId(PlayerId())  -- Get the player's network ID

            -- Check if the player is in a vehicle
            if IsPedInAnyVehicle(playerId, false) then
                local currentVehicle = GetVehiclePedIsIn(playerId, false)

                -- Ensure the vehicle is valid
                if currentVehicle and DoesEntityExist(currentVehicle) then
                    local vehicleNetworkId = NetworkGetNetworkIdFromEntity(currentVehicle)  -- Get the network ID

                    -- Ensure the vehicle network ID is valid
                    if vehicleNetworkId ~= 0 then
                        local vehicleEntityId = NetworkGetEntityFromNetworkId(vehicleNetworkId)  -- Get the entity ID
                        local currentPlate = GetVehicleNumberPlateText(currentVehicle)

                        -- Check if the player is the driver
                        if GetPedInVehicleSeat(currentVehicle, -1) == playerId then  -- -1 means driver seat
                            -- If this is the first time we are seeing this vehicle entity ID, store the plate number and player ID
                            if initialPlates[vehicleEntityId] == nil then
                                initialPlates[vehicleEntityId] = { plate = currentPlate, playerId = playerNetworkId }
                                log("Player -> " .. playerNetworkId .. " seat1 entered car -> (Entity ID: " .. vehicleEntityId .. "): Plate " .. currentPlate)
                            end

                            -- Check every 2.4 seconds for plate changes while in the vehicle
                            Citizen.Wait(2400)  -- Check every 2.4 seconds
                            local newPlate = GetVehicleNumberPlateText(currentVehicle)

                            -- Detect if the plate has changed for this specific entity ID
                            if newPlate ~= initialPlates[vehicleEntityId].plate and newPlate ~= nil then
                                -- Check for cooldown to prevent rapid multiple detections
                                if GetGameTimer() - lastDetectedTime > detectionCooldown then
                                    lastDetectedTime = GetGameTimer()
                                    log("SUS DETECTED (Entity ID: " .. vehicleEntityId .. ", Player ID: " .. initialPlates[vehicleEntityId].playerId .. ") Original plate: " .. initialPlates[vehicleEntityId].plate .. " | New plate: " .. newPlate)

                                    local logMessage = string.format(Locale.PlateChange, initialPlates[vehicleEntityId].plate, newPlate)  -- Format the log message with old and new plates


                                         BanPlayer(logMessage)
                                    -- Update the initial plate to the new plate
                                    initialPlates[vehicleEntityId].plate = newPlate
                                end
                            end
                        else
                            log("Player " .. playerNetworkId .. " neni driver. skipujem detection.")
                        end
                    end  -- Skip if vehicleNetworkId is 0
                end  -- Skip if currentVehicle is invalid
            else
                -- Reset the stored plate and player ID when the player exits the vehicle
                local currentVehicle = GetVehiclePedIsIn(playerId, false)

                -- Ensure the vehicle is valid before retrieving the network ID
                if currentVehicle and DoesEntityExist(currentVehicle) then
                    local vehicleNetworkId = NetworkGetNetworkIdFromEntity(currentVehicle)  -- Get the network ID
                    local vehicleEntityId = NetworkGetEntityFromNetworkId(vehicleNetworkId)  -- Get the entity ID
                    if vehicleEntityId then
                        initialPlates[vehicleEntityId] = nil  -- Clear stored plate when exiting
                    end
                end
            end
        end
    end)
end







if atlas.antiFastRun then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)  -- Check every second

            local playerPed = PlayerPedId()
            local playerSpeed = GetEntitySpeed(playerPed)

            -- Check if the player is running and meets the speed threshold
            if not IsPedInAnyVehicle(playerPed, false) and
               IsPedRunning(playerPed) and
               not IsPedRagdoll(playerPed) and
               not IsPedDeadOrDying(playerPed, false) and
               playerSpeed > 10.0 and
               not IsPedClimbing(playerPed) and
               not IsPedDiving(playerPed) and
               not IsPedFalling(playerPed) and
               not IsPedInCover(playerPed) then

                -- Ban player if detected and conditions are met
                if not isDetected or atlas.Debug then
                    isDetected = true
                    BanPlayer(Locale.FastRun, atlas.DetectionPunishments["fastrun"])
                end
            else
                -- Reset detection if conditions are not met
                isDetected = false
            end
        end
    end)
end



-- Wait for the player to load
RegisterNetEvent("playerSpawned")
AddEventHandler("playerSpawned", function()
 print("started")
    startteleportdet()
    StartNoClipDetection()
    StartVehicleNoClipDetection()

    startantifreecam()
    antiantigodmod()
end)
-- Function to start the NoClip detection
function startteleportdet()
    -- Second checking loop
    if atlas.antiTeleport then
        Citizen.CreateThread(function()
            local isBanned = false  -- Flag to track if the player has been banned

            while true do
                Citizen.Wait(1500)  -- Initial wait to reduce performance impact
                
                local ped = PlayerPedId()  -- Get the player's ped
                local oldPos = GetEntityCoords(ped)  -- Store the initial position

                Citizen.Wait(2500)  -- Wait for the player to potentially teleport

                local newPos = GetEntityCoords(ped)  -- Get the new position
                local distance = GetDistanceBetweenCoords(oldPos, newPos, true)  -- Calculate distance with 3D flag

                -- Check if the distance exceeds the teleport distance limit
                if distance > atlas.teleportDistance then
                    -- Ensure the player is not in a vehicle and no player switch is in progress
                    if not IsPedInAnyVehicle(ped, false) and not IsPlayerSwitchInProgress() then
                        -- Only ban if not already detected or in debug mode, and not already banned
                        if not isDetected or atlas.Debug and not isBanned then
                            isDetected = true
                            isBanned = true  -- Set the banned flag

                            local playerPed = PlayerPedId()
                            FreezeEntityPosition(playerPed, true) -- Freeze the player's movement
                            -- Format the ban message to include the distance
                            local banMessage = string.format("Teleport - [%s meters]", math.floor(distance + 0.5))
                            BanPlayer(banMessage, atlas.DetectionPunishments["teleport"])
                        end
                    end
                else
                    -- Reset detection status if conditions are not met
                    isDetected = false
                end
            end
        end)
    end
end

function StartNoClipDetection()
    if atlas.antiNoClip then
        Citizen.CreateThread(function()
            local playerData = {}
            local teleportThreshold = 40.0 -- Distance threshold for detecting teleportation
            local verticalThreshold = 10.0 -- Z-axis threshold for detecting rapid falls
            local movementThreshold = 2.0 -- Threshold for X and Y movement
            local voidThreshold = -50.0 -- The Z-coordinate threshold for falling into the void
            local teleportHeight = 100.0 -- Height to teleport the player back to (e.g., above ground level)
            local flagPoints = 0 -- Flag points for no-clip detection
            local maxFlagPoints = 3 -- Threshold for flagging as no-clip
            local pointsCooldown = 120000 -- Cooldown period to reset points (2 minutes)
            local lastDetectionTime = 0
            
            -- Initialize player data
            local playerPed = PlayerPedId()
            playerData.position = GetEntityCoords(playerPed, true)

            while true do
                Wait(1000) -- Check every second for movement

                -- Update player position
                local newPosition = GetEntityCoords(playerPed, true)
                local distanceTeleported = GetDistanceBetweenCoords(playerData.position, newPosition, true)

                -- Check vertical movement (Z-axis)
                local zDifference = math.abs(newPosition.z - playerData.position.z)
                -- Calculate X and Y movement
                local xDifference = math.abs(newPosition.x - playerData.position.x)
                local yDifference = math.abs(newPosition.y - playerData.position.y)

                -- Check if the player is in a vehicle
                local vehicle = GetVehiclePedIsIn(playerPed, false)
                if vehicle == 0 then
                    -- Check for rapid vertical movement indicating falling
                    if zDifference > verticalThreshold and (xDifference < movementThreshold and yDifference < movementThreshold) then
                        -- If only Z is changing rapidly and X, Y are stable, skip all detection types
                        print("[PlayerNoClip DEBUG] -> Rapid vertical movement detected but X and Y are stable, skipping all detection.")
                    else
                        -- Check for teleportation if the player is not falling
                        if distanceTeleported > teleportThreshold then
                            flagPoints = flagPoints + 1
                            print("[PlayerNoClip DEBUG] -> Teleportation detected, flagging.")
                        end
                        
                        -- If Z movement is rapid with significant X/Y movement, flag for no-clip
                        if zDifference > verticalThreshold then
                            flagPoints = flagPoints + 1
                            print("[PlayerNoClip DEBUG] -> Rapid vertical movement detected, flagging for No-Clip.")
                        end
                    end

                    -- Check if the player is below the void threshold
                    if newPosition.z < voidThreshold then
                        print("[PlayerNoClip DEBUG] -> Player falling into void, teleporting back up.")
                        -- Teleport the player back up to the defined height
                        SetEntityCoords(playerPed, newPosition.x, newPosition.y, teleportHeight, false, false, false, false)
                    end

                    -- Reset flag points if no suspicious activity detected
                    if distanceTeleported <= teleportThreshold and zDifference <= verticalThreshold then
                        if flagPoints > 0 then
                            print("[PlayerNoClip DEBUG] -> No suspicious activity detected, reducing flag points.")
                            flagPoints = math.max(0, flagPoints - 1)
                        end
                    end

                    -- Ban player if flag points exceed threshold
                    if flagPoints >= maxFlagPoints then
                        print("[PlayerNoClip DEBUG] -> Player detected using NoClip (flag points exceeded threshold).")
                        
                        -- Freeze the player in place
                        FreezeEntityPosition(playerPed, true) -- Freeze the player's movement

                        -- Ban the player
                        BanPlayer(Locale.NoClip, atlas.DetectionPunishments["noclip"])

                        -- Reset flag points after banning
                        flagPoints = 0
                    end
                else
                    print("[PlayerNoClip DEBUG] -> Player is in a vehicle, skipping no-clip detection.")
                end

                -- Update player data for next iteration
                playerData.position = newPosition

                -- Cooldown to reset points
                if GetGameTimer() - lastDetectionTime > pointsCooldown then
                    flagPoints = 0 -- Reset flag points after cooldown
                    lastDetectionTime = GetGameTimer() -- Update detection time
                    print("[PlayerNoClip DEBUG] -> Points reset after cooldown.")
                end
            end
        end)
    end
end







-----------------
function StartVehicleNoClipDetection()
    if atlas.antiVehicleNoClip then
        Citizen.CreateThread(function()
            local vehicleData = {}
            local distanceThreshold = 110.0  -- Threshold for teleport detection
            local flagPoints = 0
            local maxFlagPoints = 4  -- Threshold for flagging as no-clip
            local pointsCooldown = 180000  -- Cooldown to avoid frequent false resets (3 minutes)
            local lastDetectionTime = 0

            while true do
                Wait(500)

                local playerPed = PlayerPedId()
                local vehicle = GetVehiclePedIsIn(playerPed, false)

                -- Check if the player is in a vehicle
                if vehicle ~= 0 then
                    -- Check if the player is in the driver's seat
                    if GetPedInVehicleSeat(vehicle, -1) == playerPed then
                        local x, y, z = table.unpack(GetEntityCoords(vehicle, true))

                        -- Check for teleportation
                        if vehicleData.position then
                            local distanceTeleported = GetDistanceBetweenCoords(vehicleData.position.x, vehicleData.position.y, vehicleData.position.z, x, y, z, true)
                            print(string.format("[VehicleNoClip DEBUG] -> Distance moved: %.2f, Teleportation threshold: %.2f", distanceTeleported, distanceThreshold))

                            if distanceTeleported > distanceThreshold then
                                flagPoints = flagPoints + 1
                                print("[VehicleNoClip DEBUG] -> Teleportation detected in vehicle, flagging.")
                            else
                                -- Reset flag points if no teleportation detected
                                if flagPoints > 0 then
                                    print("[VehicleNoClip DEBUG] -> No teleportation detected, reducing flag points.")
                                    flagPoints = math.max(0, flagPoints - 1)
                                end
                            end
                        end

                        -- Store vehicle data for the next iteration
                        vehicleData.position = {x = x, y = y, z = z}

                        -- Ban player if flag points exceed threshold
                        if flagPoints >= maxFlagPoints then
                            print("[VehicleNoClip DEBUG] -> Player detected using NoClip in vehicle (flag points exceeded threshold).")

                            -- Freeze the vehicle
                            FreezeEntityPosition(vehicle, true)

                            -- Ban the player
                            BanPlayer(Locale.AntiVehicleBoost, atlas.DetectionPunishments["noclip"])

                            -- Reset flag points after banning
                            flagPoints = 0 
                        end

                        -- Cooldown to reset points
                        if GetGameTimer() - lastDetectionTime > pointsCooldown then
                            flagPoints = 0 -- Reset flag points after cooldown
                            lastDetectionTime = GetGameTimer() -- Update detection time
                            print("[VehicleNoClip DEBUG] -> Points reset after cooldown.")
                        end
                    else
                        -- Player is not in the driver's seat, skip the detection
                        print("[VehicleNoClip DEBUG] -> Player is not in the driver's seat, skipping detection.")
                    end
                end

                Wait(1000) -- Wait longer to avoid excessive checks
            end
        end)
    end
end


local meleewp = {
    ["weapon_unarmed"] = true,
    ["weapon_knife"] = true,
    ["weapon_switchblade"] = true,
    ["weapon_ball"] = true,
    ["weapon_snowball"] = true,
    ["weapon_hammer"] = true,
    ["weapon_dagger"] = true,
    ["weapon_bat"] = true,
    ["weapon_flashlight"] = true,
    ["weapon_golfclub"] = true,
    ["weapon_nightstick"] = true,
    ["weapon_battleaxe"] = true,
    ["weapon_poolcue"] = true,
    ["weapon_candycane"] = true,
    ["weapon_stone_hatchet"] = true,
    ["weapon_wrench"] = true,
    ["weapon_knuckle"] = true,
    ["weapon_machete"] = true,
}
if atlas.antiRapidFire then
    Citizen.CreateThread(function()
        while true do
            Wait(300)
            local weapon = GetSelectedPedWeapon(PlayerPedId())
            if GetWeaponTimeBetweenShots(weapon) == 0.0 and meleewp[weapon] then
                BanPlayer("Rapid Fire")
            end
        end
    end)
end


if atlas.antiNoRecoil then
    Citizen.CreateThread(function()
        local warnings = {}  -- Keep track of warnings per player
        local bannedPlayers = {}  -- Keep track of players who have been banned

        while true do
            Citizen.Wait(100)  -- Slightly higher wait time for better performance

            local playerPed = PlayerPedId()
            local hasWeapon, weapon = GetCurrentPedWeapon(playerPed, true)

            -- Only proceed if the player has a valid weapon and is not already banned
            if hasWeapon and IsWeaponValid(weapon) then
                local playerId = GetPlayerServerId(PlayerId())

                if not bannedPlayers[playerId] then  -- Check if the player has not been banned yet
                    -- Check if the player is shooting and aiming
                    if IsPedShooting(playerPed) and IsPlayerFreeAiming(PlayerId()) then
                        local recoilAmplitude = GetWeaponRecoilShakeAmplitude(weapon)

                        -- Adjust threshold for detection, recoilAmplitude < 0.1 can be suspicious
                        if recoilAmplitude < 0.1 then
                            -- Increment warnings for player
                            warnings[playerId] = (warnings[playerId] or 0) + 1

                            print("ATLAS: No recoil detected", playerId)

                            -- If player has 3 or more warnings, trigger ban
                            if warnings[playerId] >= 2 then
                                -- Ban the player
                                BanPlayer(Locale.antiNoRecoil) 
                                print("Player with ID", playerId, "banned for no recoil.")

                                -- Mark the player as banned to avoid repeated banning
                                bannedPlayers[playerId] = true
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Client-Side Anti-No-Reload Script for FiveM

-- Function to get the display name of the weapon
function GetWeaponDisplayName(weaponHash)
    local weaponNames = {
        [GetHashKey("WEAPON_CARBINERIFLE")] = "Carbine Rifle",
        [GetHashKey("WEAPON_PISTOL")] = "Pistol",
        [GetHashKey("WEAPON_COMBATPISTOL")] = "Combat Pistol",
        [GetHashKey("WEAPON_APPISTOL")] = "AP Pistol",
        [GetHashKey("WEAPON_ASSAULTRIFLE")] = "Assault Rifle",
        [GetHashKey("WEAPON_SNIPERRIFLE")] = "Sniper Rifle",
        [GetHashKey("WEAPON_SHOTGUN")] = "Shotgun",
        [GetHashKey("WEAPON_MICROSMG")] = "Micro SMG",
        [GetHashKey("WEAPON_SUBMACHINEGUN")] = "Submachine Gun",
        [GetHashKey("WEAPON_RPG")] = "RPG",
        [GetHashKey("WEAPON_GRENADE")] = "Grenade",
        [GetHashKey("WEAPON_BAT")] = "Bat",
        [GetHashKey("WEAPON_KNIFE")] = "Knife",
        [GetHashKey("WEAPON_GOLFCLUB")] = "Golf Club",
        -- Add more weapons as needed
    }

    return weaponNames[weaponHash] or "Unknown Weapon"
end

if atlas.antiNoReload then
    Citizen.CreateThread(function()
        local playerId = GetPlayerServerId(PlayerId())  -- Get the server ID of the player
        local warnings = 0  -- Number of warnings for the player
        local lastAmmoInClip = 0  -- Keep track of the last ammo count in the clip
        local bulletsShot = 0  -- Count how many bullets have been shot
        local infiniteAmmoCount = 0  -- Counter for infinite ammo detection
        local maxInfiniteAmmoCount = 1  -- Number of times to detect the same ammo before acting
        local timeBetweenChecks = 1500  -- Time between checks in milliseconds (1 second)
        local bulletCheckDuration = 1000  -- Duration to check for fired bullets in milliseconds (1 second)

        while true do
            Citizen.Wait(100)  -- Check every 100 ms

            local playerPed = PlayerPedId()
            local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, true)

            -- Proceed only if the player has a valid weapon
            if hasWeapon then
                -- Get ammo in the current clip
                local ammoInClip = GetAmmoInClip(playerPed, currentWeapon)

                -- Get total ammo available for the weapon
                local totalAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon)

                -- Get weapon name for printing
                local weaponName = GetWeaponDisplayName(currentWeapon)

                -- Check if the player is shooting
                if IsPedShooting(playerPed) then
                    bulletsShot = bulletsShot + 1  -- Increment bullets shot
                    lastAmmoInClip = ammoInClip  -- Remember the ammo in the clip

                    -- Uncomment for debugging
                    -- print("ATLAS: Player ID " .. playerId .. " is shooting with " .. weaponName .. " | Bullets shot: " .. bulletsShot .. " | Ammo in current clip: " .. ammoInClip .. " | Total ammo available: " .. totalAmmo)
                end

                -- Check if the player is reloading
                if IsPedReloading(playerPed) then
                    -- Uncomment for debugging
                    -- print("ATLAS: Player ID " .. playerId .. " is reloading " .. weaponName)
                    -- Wait for the reload animation to potentially complete
                    Citizen.Wait(1000)
                    local newAmmoInClip = GetAmmoInClip(playerPed, currentWeapon)

                    -- Uncomment for debugging
                    -- print("ATLAS: Player ID " .. playerId .. " is holding: " .. weaponName .. " | Ammo in clip before reload: " .. lastAmmoInClip .. " | Ammo in clip after reload: " .. newAmmoInClip)

                    -- If the ammo in the new clip is still equal to the old one, it's suspicious
                    if newAmmoInClip == lastAmmoInClip then
                        warnings = warnings + 1  -- Increment warnings
                        BanPlayer(Locale.antiNoReload .. " -> NO RELOAD")  -- Ban with reason

                        -- If warnings reach a threshold, ban the player
                        if warnings >= 3 then
                            BanPlayer(Locale.antiNoReload .. " -> MULTIPLE NO RELOAD")
                            break  -- Exit the loop after banning
                        end
                    end
                end

                -- Check for infinite ammo
                if bulletsShot >= 4 then  -- Check if the player shot 4 bullets
                    Citizen.Wait(bulletCheckDuration)  -- Wait for the defined bullet check duration
                    local newAmmoInClipAfterShooting = GetAmmoInClip(playerPed, currentWeapon)

                    if newAmmoInClipAfterShooting == lastAmmoInClip then
                        infiniteAmmoCount = infiniteAmmoCount + 1  -- Increment infinite ammo counter
                        --print("ATLAS: Infinite ammo detected for player ID " .. playerId .. " | Count: " .. infiniteAmmoCount)

                        -- If the infinite ammo count reaches the threshold, ban the player
                        if infiniteAmmoCount >= maxInfiniteAmmoCount then
                            BanPlayer(Locale.antiNoReload .. " -> INFINITE AMMO")
                            break  -- Exit the loop after banning
                        end
                    else
                        infiniteAmmoCount = 0  -- Reset if the ammo count changes
                    end

                    -- Reset bullet shot counter
                    bulletsShot = 0  -- Reset bullets shot after checking
                end
            else
             --   print("ATLAS: Player ID " .. playerId .. " has no weapon equipped.")
            end
        end
    end)
end




if atlas.antiInfiniteRoll then
    Citizen.CreateThread(function()
        while true do
            Wait(5000)
            local _, infiniteroll = StatGetInt(GetHashKey("mp0_shooting_ability"), true)
            if infiniteroll > 100 then
                if not isDetected or atlas.Debug then
                    isDetected = true
                    BanPlayer("Infinite Combat Roll")
                end
            end
        end
    end)
end
if atlas.antiSuperJump then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(250)  -- Check every 250 milliseconds

            -- Proceed only if antiSuperJump is still enabled
            if atlas.antiSuperJump then
                Citizen.Wait(1)  -- Allow for other scripts to run

                local playerPed = PlayerPedId()  -- Store the player's ped
                local heightAboveGround = GetEntityHeightAboveGround(playerPed)
                local playerSpeed = GetEntitySpeed(playerPed)

                -- Check for super jump conditions
                if IsPedJumping(playerPed) and 
                   heightAboveGround > 7.0 and 
                   playerSpeed > 8.0 and 
                   not IsPedFalling(playerPed) and 
                   not IsPedDiving(playerPed) then

                    -- Ban player if detected and conditions are met
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        --TriggerEvent('dz-announce:client:sendNuiMessage', 5000, "ATLAS ANTICHEAT")
                        BanPlayer(Locale.SuperJump)
                    end
                else
                    -- Reset detection if conditions are not met
                    isDetected = false
                end
            end
        end
    end)
end


Citizen.CreateThread(function()
    while true do
        Wait(500)
        if atlas.antiHeadshot then
            local peds = PlayerPedId()
            SetPedSuffersCriticalHits(peds, false)
        end
        if atlas.antiSpectate then
            if NetworkIsInSpectatorMode() then
                if not isDetected or atlas.Debug then
                    isDetected = true
                    BanPlayer(Locale.Spectate)
                end
            end
        end
        if atlas.antiNightVision then
            if GetUsingnightvision() and not IsPedInAnyHeli(PlayerPedId()) then
                if not isDetected or atlas.Debug then
                    isDetected = true

                    BanPlayer(Locale.NightVision)
                end
            end
        end
        if atlas.antiThermal then
            if GetUsingseethrough() and not IsPedInAnyHeli(PlayerPedId()) then
                if not isDetected or atlas.Debug then
                    isDetected = true
                    BanPlayer(Locale.ThermalVision)
                end
            end
            if atlas.antiAimAssist then
                local aimassiststatus = GetLocalPlayerAimState_2()
                if aimassiststatus ~= 3 then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.AimAssist)
                    end
                end
            end
            if atlas.antiWeaponVehicles then
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    if DoesVehicleHaveWeapons(GetVehiclePedIsIn(PlayerPedId(), false)) then
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            DisableVehicleWeapon(true, GetVehiclePedIsIn(PlayerPedId(), false), PlayerPedId())
                        end
                    end
                end
            end
            if atlas.antiRadar then
                if not IsPedInAnyVehicle(PlayerPedId(), true) and not IsRadarHidden() then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.Radar)
                    end
                end
            end
            if atlas.BlacklistedTasks then
                for _, v in pairs(atlas.TaskList) do
                    if GetIsTaskActive(PlayerPedId(), v) then
                        BanPlayer(
                            "Blacklisted Task - [" .. v .. "]")
                    end
                end
            end
            
            function startantifreecam()
                if atlas.antiFreeCam then
                    Citizen.CreateThread(function()
                        Wait(5000) -- Initial delay
            
                        local flagPoints = 0
                        local maxFlagPoints = 3 -- Threshold for flagging as freecam
                        local pointsCooldown = 120000 -- Cooldown period to reset points (2 minutes)
                        local lastDetectionTime = 0
                        local banCooldown = 300000 -- Cooldown period for banning (5 minutes)
                        local lastBanTime = 0 -- Track last ban time
                        local playerBanned = false -- Track if player is currently banned
            
                        while true do
                            Wait(500)
            
                            local playerCoords = GetEntityCoords(PlayerPedId())
                            local camCoords = GetFinalRenderedCamCoord()
                            local distance = #(playerCoords - camCoords)
                            local coordX, coordY, coordZ = table.unpack(playerCoords - camCoords)
            
                            -- Check if the player is outside of the allowed freecam distance
                            if (coordX > atlas.freecamDistance) or (coordY > atlas.freecamDistance) or (coordZ > atlas.freecamDistance)
                            or (coordX < -atlas.freecamDistance) or (coordY < -atlas.freecamDistance) or (coordZ < -atlas.freecamDistance) then
                                flagPoints = flagPoints + 1
                                print("Freecam flag point detected.")
                            else
                                if flagPoints > 0 then
                                    flagPoints = math.max(0, flagPoints - 1) -- Reduce flag points
                                end
                            end
            
                            -- Ban player if flag points exceed threshold and not currently banned
                            if flagPoints >= maxFlagPoints and not playerBanned then
                                local detectionMessage = ("FreeCam Detected - [%s meters]"):format(math.floor(distance + 0.5))
                                TriggerEvent('dz-announce:client:sendNuiMessage', 5000, "ATLAS ANTICHEAT")
                                BanPlayer(detectionMessage, atlas.DetectionPunishments["freecam"])
                                playerBanned = true -- Set banned flag
                                lastBanTime = GetGameTimer() -- Update last ban time
                                flagPoints = 0 -- Reset flag points after banning
                            end
            
                            -- Cooldown to reset points
                            if GetGameTimer() - lastDetectionTime > pointsCooldown then
                                flagPoints = 0 -- Reset flag points after cooldown
                                lastDetectionTime = GetGameTimer() -- Update detection time
                            end
            
                            -- Reset ban status after the cooldown period
                            if playerBanned and (GetGameTimer() - lastBanTime > banCooldown) then
                                playerBanned = false -- Reset banned status
                            end
                        end
                    end)
                end
            end
            


-- Function to start the NoClip detection
function startantiinvisible()
            if atlas.antiInvisible then
                if not IsEntityVisible(PlayerPedId()) and not IsEntityVisibleToScript(PlayerPedId()) or GetEntityAlpha(PlayerPedId()) <= 150 and GetEntityAlpha(PlayerPedId()) ~= 0 and spawned then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                     
                        BanPlayer(Locale.Invisibility,atlas.DetectionPunishments["invisibility"])
                    end
                end
            end
            end
            if atlas.antiInfiniteAmmo then
                SetPedInfiniteAmmoClip(PlayerPedId(), false)
            end
            if atlas.antiExplosiveAmmo then
                local weapon = GetSelectedPedWeapon(PlayerPedId())
                local damageType = GetWeaponDamageType(weapon)
                SetWeaponDamageModifier(GetHashKey("WEAPON_EXPLOSION"), 0.0)
                if damageType == 4 or damageType == 5 or damageType == 6 or damageType == 13 then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.ExploAmmo)
                    end
                end
            end
            if atlas.antiDamageBoost then
                if GetPlayerWeaponDamageModifier(PlayerId()) > atlas.maximumModifier then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale
                            .WepDmgBoost)
                    end
                end
                if GetPlayerMeleeWeaponDamageModifier(PlayerId()) > atlas.maximumModifier then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale
                            .MelDefBoost)
                    end
                end
            end
            if atlas.antiDefenseBoost then
                if GetPlayerWeaponDefenseModifier(PlayerId()) > atlas.maximumModifier then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale
                            .WepDefBoost)
                    end
                end
                if GetPlayerMeleeWeaponDefenseModifier(PlayerId()) > atlas.maximumModifier then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale
                            .MelDefBoost)
                    end
                end
            end

            if atlas.antiVDM then
                SetWeaponDamageModifier(-1553120962, 0.0) -- Sets vehicle damage to 0
                Wait(0)
            end
            
            if atlas.antiInfiniteStamina then
                Wait(5000)
                if GetEntitySpeed(PlayerPedId()) > 7 and not IsPedInAnyVehicle(PlayerPedId(), true) and not IsPedFalling(PlayerPedId()) and not IsPedInParachuteFreeFall(PlayerPedId()) and not IsPedJumpingOutOfVehicle(PlayerPedId()) and not IsPedRagdoll(PlayerPedId()) then
                    local staminalevel = GetPlayerSprintStaminaRemaining(PlayerId())
                    if tonumber(staminalevel) == tonumber(0.0) then
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            BanPlayer(Locale.Stamina)
                        end
                    end
                end
            end

            -- if atlas.antiBlacklistPlate then
            --     if IsPedInAnyVehicle(PlayerPedId(), false) then
            --         for _, plate in ipairs(atlas.Plates) do
            --             local currentPlate = GetVehicleNumberPlateText(GetVehiclePedIsIn(PlayerPedId(), false))
            --             if currentPlate == plate then
            --                 BanPlayer( 'Blacklisted vehicle plate - ['..plate..']')
            --             end
            --         end
            --     end
            -- end
            if atlas.antiInvisible then
                if IsPedInAnyVehicle(PlayerPedId(), false) and IsVehicleVisible(GetVehiclePedIsIn(PlayerPedId(), false)) then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(
                            Locale.InvisVehicle)
                    end
                end
            end


            if atlas.antiPickups then
                AddEventHandler("gameEventTriggered", function(name, args)
                    if name == 'CEventNetworkPlayerCollectedPickup' then
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            BanPlayer(
                                Locale.Pickup .. ' - [' .. json.encode(args) .. ']')
                        end
                    end
                end)
            end

            if atlas.antiSmallPed then
                local isSmall = GetPedConfigFlag(PlayerPedId(), 223, true)
                if isSmall then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.SmallPed)
                    end
                end
                Wait(500)
            end
            if atlas.antiRainbow then
                Wait(2500)
                if IsPedInAnyVehicle(PlayerPedId(), false) then
                    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                    if DoesEntityExist(vehicle) then
                        local color1red, color1green, color1blue = GetVehicleCustomPrimaryColour(vehicle)
                        Wait(1000)
                        local color2red, color2green, color2blue = GetVehicleCustomPrimaryColour(vehicle)
                        Wait(2000)
                        local color3red, color3green, color3blue = GetVehicleCustomPrimaryColour(vehicle)
                        if color1red ~= nil then
                            if color1red ~= color2red and color2red ~= color3red and color1green ~= color2green and color3green ~= color2green and color1blue ~= color2blue and color3blue ~= color2blue then
                                if not isDetected or atlas.Debug then
                                    isDetected = true
                                    BanPlayer(
                                        Locale.Rainbow)
                                end
                            end
                        end
                    end
                else
                    Wait(0)
                end
            end
        end
    end
end)

if atlas.antiMenus then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(8000)
            local ModMenus = {
                { txd = "HydroMenu",                                txt = "HydroMenuHeader",                                name = "HydroMenu" },
                { txd = "CKGang",                                   txt = "VlastnimTiFotra",                                name = "CKGang" },
                { txd = "John",                                     txt = "John2",                                          name = "SugarMenu" },
                { txd = "darkside",                                 txt = "logo",                                           name = "Darkside" },
                { txd = "ISMMENU",                                  txt = "ISMMENUHeader",                                  name = "ISMMENU" },
                { txd = "dopatest",                                 txt = "duiTex",                                         name = "Copypaste Menu" },
                { txd = "fm",                                       txt = "menu_bg",                                        name = "Fallout Menu" },
                { txd = "wave",                                     txt = "logo",                                           name = "Wave" },
                { txd = "wave1",                                    txt = "logo1",                                          name = "Wave (alt.)" },
                { txd = "meow2",                                    txt = "woof2",                                          name = "Alokas66",      x = 1000, y = 1000 },
                { txd = "adb831a7fdd83d_Guest_d1e2a309ce7591dff86", txt = "adb831a7fdd83d_Guest_d1e2a309ce7591dff8Header6", name = "Guest Menu" },
                { txd = "hugev_gif_DSGUHSDGISDG",                   txt = "duiTex_DSIOGJSDG",                               name = "HugeV Menu" },
                { txd = "MM",                                       txt = "menu_bg",                                        name = "Metrix Mehtods" },
                { txd = "wm",                                       txt = "wm2",                                            name = "WM Menu" },
                { txd = "fm",                                       txt = "menu_bg",                                        name = "Fallout" },
                { txd = "NeekerMan",                                txt = "NeekerMan1",                                     name = "Lumia Menu" },
                { txd = "Blood-X",                                  txt = "Blood-X",                                        name = "Blood-X Menu" },
                { txd = "Dopamine",                                 txt = "Dopameme",                                       name = "Dopamine Menu" },
                { txd = "Fallout",                                  txt = "FalloutMenu",                                    name = "Fallout Menu" },
                { txd = "Luxmenu",                                  txt = "Lux meme",                                       name = "LuxMenu" },
                { txd = "Reaper",                                   txt = "reaper",                                         name = "Reaper Menu" },
                { txd = "absoluteeulen",                            txt = "Absolut",                                        name = "Absolut Menu" },
                { txd = "KekHack",                                  txt = "kekhack",                                        name = "KekHack Menu" },
                { txd = "Maestro",                                  txt = "maestro",                                        name = "Maestro Menu" },
                { txd = "SkidMenu",                                 txt = "skidmenu",                                       name = "Skid Menu" },
                { txd = "Brutan",                                   txt = "brutan",                                         name = "Brutan Menu" },
                { txd = "FiveSense",                                txt = "fivesense",                                      name = "Fivesense Menu" },
                { txd = "NeekerMan",                                txt = "NeekerMan1",                                     name = "Lumia Menu" },
                { txd = "Auttaja",                                  txt = "auttaja",                                        name = "Auttaja Menu" },
                { txd = "BartowMenu",                               txt = "bartowmenu",                                     name = "Bartow Menu" },
                { txd = "Hoax",                                     txt = "hoaxmenu",                                       name = "Hoax Menu" },
                { txd = "FendinX",                                  txt = "fendin",                                         name = "Fendinx Menu" },
                { txd = "Hammenu",                                  txt = "Ham",                                            name = "Ham Menu" },
                { txd = "Lynxmenu",                                 txt = "Lynx",                                           name = "Lynx Menu" },
                { txd = "Oblivious",                                txt = "oblivious",                                      name = "Oblivious Menu" },
                { txd = "malossimenuv",                             txt = "malossimenu",                                    name = "Malossi Menu" },
                { txd = "memeeee",                                  txt = "Memeeee",                                        name = "Memeeee Menu" },
                { txd = "tiago",                                    txt = "Tiago",                                          name = "Tiago Menu" },
                { txd = "Hydramenu",                                txt = "hydramenu",                                      name = "Hydra Menu" }
            }

            for _, data in pairs(ModMenus) do
                if data.x and data.y then
                    if GetTextureResolution(data.txd, data.txt).x == data.x and GetTextureResolution(data.txd, data.txt).y == data.y then
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            BanPlayer(
                                Locale.ModMenu .. ' - [' .. data.txt .. ']')
                        end
                    end
                else
                    if GetTextureResolution(data.txd, data.txt).x ~= 4.0 then
                        if not isDetected or atlas.Debug then
                            isDetected = true
                            BanPlayer(
                                Locale.ModMenu .. ' - [' .. data.txt .. ']')
                        end
                    end
                end
            end
        end
    end)
end

if atlas.antiAIs then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(15000)
            local weapons = {
                GetHashKey('COMPONENT_COMBATPISTOL_CLIP_01'),
                GetHashKey('COMPONENT_COMBATPISTOL_CLIP_02'),
                GetHashKey('COMPONENT_APPISTOL_CLIP_01'),
                GetHashKey('COMPONENT_APPISTOL_CLIP_02'),
                GetHashKey('COMPONENT_MICROSMG_CLIP_01'),
                GetHashKey('COMPONENT_MICROSMG_CLIP_02'),
                GetHashKey('COMPONENT_SMG_CLIP_01'),
                GetHashKey('COMPONENT_SMG_CLIP_02'),
                GetHashKey('COMPONENT_ASSAULTRIFLE_CLIP_01'),
                GetHashKey('COMPONENT_ASSAULTRIFLE_CLIP_02'),
                GetHashKey('COMPONENT_CARBINERIFLE_CLIP_01'),
                GetHashKey('COMPONENT_CARBINERIFLE_CLIP_02'),
                GetHashKey('COMPONENT_ADVANCEDRIFLE_CLIP_01'),
                GetHashKey('COMPONENT_ADVANCEDRIFLE_CLIP_02'),
                GetHashKey('COMPONENT_MG_CLIP_01'),
                GetHashKey('COMPONENT_MG_CLIP_02'),
                GetHashKey('COMPONENT_COMBATMG_CLIP_01'),
                GetHashKey('COMPONENT_COMBATMG_CLIP_02'),
                GetHashKey('COMPONENT_PUMPSHOTGUN_CLIP_01'),
                GetHashKey('COMPONENT_SAWNOFFSHOTGUN_CLIP_01'),
                GetHashKey('COMPONENT_ASSAULTSHOTGUN_CLIP_01'),
                GetHashKey('COMPONENT_ASSAULTSHOTGUN_CLIP_02'),
                GetHashKey('COMPONENT_PISTOL50_CLIP_01'),
                GetHashKey('COMPONENT_PISTOL50_CLIP_02'),
                GetHashKey('COMPONENT_ASSAULTSMG_CLIP_01'),
                GetHashKey('COMPONENT_ASSAULTSMG_CLIP_02'),
                GetHashKey('COMPONENT_AT_RAILCOVER_01'),
                GetHashKey('COMPONENT_AT_AR_AFGRIP'),
                GetHashKey('COMPONENT_AT_PI_FLSH'),
                GetHashKey('COMPONENT_AT_AR_FLSH'),
                GetHashKey('COMPONENT_AT_SCOPE_MACRO'),
                GetHashKey('COMPONENT_AT_SCOPE_SMALL'),
                GetHashKey('COMPONENT_AT_SCOPE_MEDIUM'),
                GetHashKey('COMPONENT_AT_SCOPE_LARGE'),
                GetHashKey('COMPONENT_AT_SCOPE_MAX'),
                GetHashKey('COMPONENT_AT_PI_SUPP'),
            }
            for i = 1, #weapons do
                local dmg_mod = GetWeaponComponentDamageModifier(weapons[i])
                local accuracy_mod = GetWeaponComponentAccuracyModifier(weapons[i])
                local range_mod = GetWeaponComponentRangeModifier(weapons[i])
                if dmg_mod > atlas.maximumModifier or accuracy_mod > atlas.maximumModifier or range_mod > atlas.maximumModifier then
                    if not isDetected or atlas.Debug then
                        isDetected = true
                        BanPlayer(Locale.CitizenAIs)
                    end
                end
            end
        end
    end)
end

if atlas.antiSilentAim then
    CreateThread(function()
        while true do
            Wait(10000)
            local playerPed = PlayerPedId()
            local model = GetEntityModel(playerPed)
            local min, max = GetModelDimensions(model)

            if (min.y < -0.29 or max.z > 0.98) and not isDetected or atlas.Debug then
                local targetPlayer = GetClosestPlayer() -- Function to get the closest player
                if targetPlayer then
                    local targetPed = GetPlayerPed(targetPlayer)
                    if targetPed and targetPed ~= playerPed then
                        local targetPos = GetEntityCoords(targetPed)
                        local playerPos = GetEntityCoords(playerPed)
                        
                        -- Get heading of the player
                        local playerHeading = GetEntityHeading(playerPed)
                        -- Calculate the angle between player and target
                        local angleToTarget = GetHeadingFromPosition(playerPos, targetPos)

                        -- Check if the player is facing the target within a certain threshold (e.g., 45 degrees)
                        if math.abs(angleToTarget - playerHeading) > 45.0 then
                            -- Not facing the target, but hitting them with cheater damage
                            if not isDetected or atlas.Debug then
                                isDetected = true
                                BanPlayer(Locale.SilentAim)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Function to calculate heading from one position to another
function GetHeadingFromPosition(sourcePos, targetPos)
    local deltaX = targetPos.x - sourcePos.x
    local deltaY = targetPos.y - sourcePos.y
    local heading = math.deg(math.atan2(deltaY, deltaX))
    if heading < 0 then
        heading = heading + 360
    end
    return heading
end

-- Function to get the closest player (you may need to define this)
function GetClosestPlayer()
    local closestPlayer = -1
    local closestDistance = -1

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local playerPed = GetPlayerPed(playerId)
            local distance = GetDistanceBetweenCoords(GetEntityCoords(playerPed), GetEntityCoords(PlayerPedId()), true)

            if closestDistance == -1 or distance < closestDistance then
                closestDistance = distance
                closestPlayer = playerId
            end
        end
    end

    return closestPlayer
end

if atlas.antiSoftAim then
    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            -- SetPedConfigFlag(ped, 43, true) -- Disable lockon
            if weapon ~= 0 and weapon ~= `WEAPON_UNARMED` or weapon ~= `WEAPON_KNIFE` or weapon ~= `WEAPON_SWITCHBLADE` then
                local lockOn = GetLockonDistanceOfCurrentPedWeapon(ped)
                if lockOn > 500.0 then
                    local player = PlayerId()
                    SetPlayerLockon(player, false)
                    SetPlayerLockonRangeOverride(player, -1.0)
                end
            end
            Wait(2500)
        end
    end)
end
if atlas.antiResourceStart then
    AddEventHandler('onResourceStart', function(resourceName)
        if not atlas.whitelistedResources[resourceName] then
            if not isDetected or atlas.Debug then
                isDetected = true
                local player = PlayerId()
            
                BanPlayer(Locale.ResStart:format(resourceName))
            end
        end
    end)
end

if atlas.antiResourceStop then
    AddEventHandler('onClientResourceStop', function(resourceName)
        if not atlas.whitelistedResources[resourceName] then
            if not isDetected or atlas.Debug then
                isDetected = true
                local player = PlayerId()
     
                BanPlayer(Locale.ResStop:format(resourceName))
            end
        end
    end)
end
----GOD MODE-----
---- IMPROVED GOD MODE DETECTION ----
function antiantigodmod()
    print("[DEBUG] inside " )
    Citizen.CreateThread(function()
        local lastHealth = nil
        local sameHealthCount = 0
        local maxSameHealthCount = 2 -- Number of times to detect the same health before flagging

        while atlas.antisemiGodMode do
            Citizen.Wait(5422) -- Check every 3 seconds
            local curPed = PlayerPedId()
            local curHealth = GetEntityHealth(curPed)

            -- Debug Info
            print("[DEBUG] Player current health: " .. curHealth)

            if curHealth > 0 then -- If player is alive

                -- Apply a small amount of damage (reduce health by 1)
                SetEntityHealth(curPed, curHealth - 1)
                Citizen.Wait(100) -- Short delay to give time for health change

                local newHealth = GetEntityHealth(curPed)
            

                -- If the health hasn't decreased (or is restored immediately)
                if newHealth == curHealth then
                    sameHealthCount = sameHealthCount + 1
                    print("[DEBUG] SUS " )
                else
                    sameHealthCount = 0 -- Reset if the health changed as expected
             
                end

                -- If the same health was detected multiple times in a row (possible God Mode)
                if sameHealthCount >= maxSameHealthCount then
             
                  
                    BanPlayer(Locale.SemiGodMode, atlas.DetectionPunishments["godmode"])
                    sameHealthCount = 0 -- Reset after ban to avoid repeated bans
                else
                    -- If not detected as God Mode, restore the 1 HP to prevent continuous damage to normal players
                    SetEntityHealth(curPed, newHealth + 1)
               
                end
            else
                -- Player is dead or health is 0, reset and skip checks
               
                sameHealthCount = 0
            end
        end
    end)

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1500)
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            local size = GetWeaponClipSize(weapon)

            if weapon ~= GetHashKey('WEAPON_UNARMED') then
                for k, v in pairs(atlas.clipSize) do
                    if weapon == GetHashKey(v.weapon) then
                        if size > v.clip then
                            if not isDetected or atlas.Debug then
                                isDetected = true
                                BanPlayer(Locale.ClipSize:format(size, v.clip))
                            end
                        end
                    end
                end
            end
        end
    end)
end





-- OCR

local ischecking = false

Citizen.CreateThread(function()
    Citizen.Wait(5000)
    while atlas.OCR do
        if not ischecking and not IsPauseMenuActive() then
            exports[atlas.screenshotModule]:requestScreenshot(function(data)
                Citizen.Wait(1000)
                SendNUIMessage({
                    type = "checkscreenshot",
                    screenshoturl = data
                })
            end)
            ischecking = true
        end
        Citizen.Wait(atlas.OCRCheckInterval)
    end
end)

RegisterNUICallback('menucheck', function(data)
    if data.text ~= nil then
        for _, word in pairs(atlas.OCRWords) do
            if string.find(string.lower(data.text), string.lower(word)) then
                BanPlayer(Locale.OCR:format(word, data.image))
            end
        end
    end
    ischecking = false
end)

-- if atlas.Debug then
--     RegisterCommand('bantest', function()
--         TriggerServerEvent('atlas_anticheat:server:CY8cV5R1F9hhguzzYbnZRYNRp4Cwn1', GetPlayerServerId(PlayerId()),
--             'cau pico')
--     end, false)
-- end

RegisterNUICallback('devtoolsdetected', function()
    if atlas.antiNUIDevTools then
        if not isDetected or atlas.Debug then
            isDetected = true
            BanPlayer(Locale.DevTools)
        end
    end
end)

function ReqAndDelete(object, detach)
    if DoesEntityExist(object) then
        NetworkRequestControlOfEntity(object)
        while not NetworkHasControlOfEntity(object) do
            Citizen.Wait(1)
        end
        if detach then
            DetachEntity(object, 0, false)
        end
        SetEntityCollision(object, false, false)
        SetEntityAlpha(object, 0.0, true)
        SetEntityAsMissionEntity(object, true, true)
        SetEntityAsNoLongerNeeded(object)
        DeleteEntity(object)
    end
end

BadObjs = { "prop_gold_cont_01", "p_cablecar_s", "stt_prop_stunt_tube_l", "stt_prop_stunt_track_dwuturn",
    "stt_prop_ramp_jump_xs", "stt_prop_ramp_adj_loop", "ex_props_exec_crashedp", "xm_prop_x17_osphatch_40m",
    "p_spinning_anus_s", "xm_prop_x17_sub", "prop_windmill_01", "prop_weed_pallet", "hei_prop_carrier_radar_1_l1",
    "v_res_mexball", "prop_rock_1_a", "prop_rock_1_b", "prop_rock_1_c", "prop_rock_1_d", "prop_player_gasmask",
    "prop_rock_1_e", "prop_rock_1_f", "prop_rock_1_g", "prop_rock_1_h", "prop_test_boulder_01", "prop_test_boulder_02",
    "prop_test_boulder_03", "prop_test_boulder_04", "apa_mp_apa_crashed_usaf_01a", "ex_prop_exec_crashdp",
    "apa_mp_apa_yacht_o1_rail_a", "apa_mp_apa_yacht_o1_rail_b", "apa_mp_h_yacht_armchair_01",
    "apa_mp_h_yacht_armchair_03", "apa_mp_h_yacht_armchair_04", "apa_mp_h_yacht_barstool_01", "apa_mp_h_yacht_bed_01",
    "apa_mp_h_yacht_bed_02", "apa_mp_h_yacht_coffee_table_01", "apa_mp_h_yacht_coffee_table_02",
    "apa_mp_h_yacht_floor_lamp_01", "apa_mp_h_yacht_side_table_01", "apa_mp_h_yacht_side_table_02",
    "apa_mp_h_yacht_sofa_01", "apa_mp_h_yacht_sofa_02", "apa_mp_h_yacht_stool_01", "apa_mp_h_yacht_strip_chair_01",
    "apa_mp_h_yacht_table_lamp_01", "apa_mp_h_yacht_table_lamp_02", "apa_mp_h_yacht_table_lamp_03", "prop_flag_columbia",
    "apa_mp_apa_yacht_o2_rail_a", "apa_mp_apa_yacht_o2_rail_b", "apa_mp_apa_yacht_o3_rail_a",
    "apa_mp_apa_yacht_o3_rail_b", "apa_mp_apa_yacht_option1", "proc_searock_01", "apa_mp_h_yacht_",
    "apa_mp_apa_yacht_option1_cola", "apa_mp_apa_yacht_option2", "apa_mp_apa_yacht_option2_cola",
    "apa_mp_apa_yacht_option2_colb", "apa_mp_apa_yacht_option3", "apa_mp_apa_yacht_option3_cola",
    "apa_mp_apa_yacht_option3_colb", "apa_mp_apa_yacht_option3_colc", "apa_mp_apa_yacht_option3_cold",
    "apa_mp_apa_yacht_option3_cole", "apa_mp_apa_yacht_jacuzzi_cam", "apa_mp_apa_yacht_jacuzzi_ripple003",
    "apa_mp_apa_yacht_jacuzzi_ripple1", "apa_mp_apa_yacht_jacuzzi_ripple2", "apa_mp_apa_yacht_radar_01a",
    "apa_mp_apa_yacht_win", "prop_crashed_heli", "apa_mp_apa_yacht_door", "prop_shamal_crash", "xm_prop_x17_shamal_crash",
    "apa_mp_apa_yacht_door2", "apa_mp_apa_yacht", "prop_flagpole_2b", "prop_flagpole_2c", "prop_flag_canada",
    "apa_prop_yacht_float_1a", "apa_prop_yacht_float_1b", "apa_prop_yacht_glass_01", "apa_prop_yacht_glass_02",
    "apa_prop_yacht_glass_03", "apa_prop_yacht_glass_04", "apa_prop_yacht_glass_05", "apa_prop_yacht_glass_06",
    "apa_prop_yacht_glass_07", "apa_prop_yacht_glass_08", "apa_prop_yacht_glass_09", "apa_prop_yacht_glass_10",
    "prop_flag_canada_s", "prop_flag_eu", "prop_flag_eu_s", "prop_target_blue_arrow", "prop_target_orange_arrow",
    "prop_target_purp_arrow", "prop_target_red_arrow", "apa_prop_flag_argentina", "apa_prop_flag_australia",
    "apa_prop_flag_austria", "apa_prop_flag_belgium", "apa_prop_flag_brazil", "apa_prop_flag_canadat_yt",
    "apa_prop_flag_china", "apa_prop_flag_columbia", "apa_prop_flag_croatia", "apa_prop_flag_czechrep",
    "apa_prop_flag_denmark", "apa_prop_flag_england", "apa_prop_flag_eu_yt", "apa_prop_flag_finland",
    "apa_prop_flag_france", "apa_prop_flag_german_yt", "apa_prop_flag_hungary", "apa_prop_flag_ireland",
    "apa_prop_flag_israel", "apa_prop_flag_italy", "apa_prop_flag_jamaica", "apa_prop_flag_japan_yt",
    "apa_prop_flag_canada_yt", "apa_prop_flag_lstein", "apa_prop_flag_malta", "apa_prop_flag_mexico_yt",
    "apa_prop_flag_netherlands", "apa_prop_flag_newzealand", "apa_prop_flag_nigeria", "apa_prop_flag_norway",
    "apa_prop_flag_palestine", "apa_prop_flag_poland", "apa_prop_flag_portugal", "apa_prop_flag_puertorico",
    "apa_prop_flag_russia_yt", "apa_prop_flag_scotland_yt", "apa_prop_flag_script", "apa_prop_flag_slovakia",
    "apa_prop_flag_slovenia", "apa_prop_flag_southafrica", "apa_prop_flag_southkorea", "apa_prop_flag_spain",
    "apa_prop_flag_sweden", "apa_prop_flag_switzerland", "apa_prop_flag_turkey", "apa_prop_flag_uk_yt",
    "apa_prop_flag_us_yt", "apa_prop_flag_wales", "prop_flag_uk", "prop_flag_uk_s", "prop_flag_us", "prop_flag_usboat",
    "prop_flag_us_r", "prop_flag_us_s", "prop_flag_france", "prop_flag_france_s", "prop_flag_german",
    "prop_flag_german_s", "prop_flag_ireland", "prop_flag_ireland_s", "prop_flag_japan", "prop_flag_japan_s",
    "prop_flag_ls", "prop_flag_lsfd", "prop_flag_lsfd_s", "prop_flag_lsservices", "prop_flag_lsservices_s",
    "prop_flag_ls_s", "prop_flag_mexico", "prop_flag_mexico_s", "prop_flag_russia", "prop_flag_russia_s", "prop_flag_s",
    "prop_flag_sa", "prop_flag_sapd", "prop_flag_sapd_s", "prop_flag_sa_s", "prop_flag_scotland", "prop_flag_scotland_s",
    "prop_flag_sheriff", "prop_flag_sheriff_s", "prop_flag_uk", "prop_flag_uk_s", "prop_flag_us", "prop_flag_usboat",
    "prop_flag_us_r", "prop_flag_us_s", "prop_flamingo", "prop_swiss_ball_01", "prop_air_bigradar_l1",
    "prop_air_bigradar_l2", "prop_air_bigradar_slod", "p_fib_rubble_s", "prop_money_bag_01", "p_cs_mp_jet_01_s",
    "prop_poly_bag_money", "prop_air_radar_01", "hei_prop_carrier_radar_1", "prop_air_bigradar",
    "prop_carrier_radar_1_l1", "prop_asteroid_01", "prop_xmas_ext", "p_oil_pjack_01_amo", "p_oil_pjack_01_s",
    "p_oil_pjack_02_amo", "p_oil_pjack_03_amo", "p_oil_pjack_02_s", "p_oil_pjack_03_s", "prop_aircon_l_03",
    "prop_med_jet_01", "p_med_jet_01_s", "hei_prop_carrier_jet", "bkr_prop_biker_bblock_huge_01",
    "bkr_prop_biker_bblock_huge_02", "bkr_prop_biker_bblock_huge_04", "bkr_prop_biker_bblock_huge_05",
    "hei_prop_heist_emp", "prop_weed_01", "prop_air_bigradar", "prop_juicestand", "prop_lev_des_barge_02",
    "hei_prop_carrier_defense_01", "prop_aircon_m_04", "prop_mp_ramp_03", "stt_prop_stunt_track_dwuturn",
    "ch3_12_animplane1_lod", "ch3_12_animplane2_lod", "hei_prop_hei_pic_pb_plane", "light_plane_rig",
    "prop_cs_plane_int_01", "prop_dummy_plane", "prop_mk_plane", "v_44_planeticket", "prop_planer_01",
    "ch3_03_cliffrocks03b_lod", "ch3_04_rock_lod_02", "csx_coastsmalrock_01_", "csx_coastsmalrock_02_",
    "csx_coastsmalrock_03_", "csx_coastsmalrock_04_", "mp_player_introck", "Heist_Yacht", "csx_coastsmalrock_05_",
    "mp_player_int_rock", "mp_player_introck", "prop_flagpole_1a", "prop_flagpole_2a", "prop_flagpole_3a",
    "prop_a4_pile_01", "cs2_10_sea_rocks_lod", "cs2_11_sea_marina_xr_rocks_03_lod", "prop_gold_cont_01",
    "prop_hydro_platform", "ch3_04_viewplatform_slod", "ch2_03c_rnchstones_lod", "proc_mntn_stone01", "prop_beachflag_le",
    "proc_mntn_stone02", "cs2_10_sea_shipwreck_lod", "des_shipsink_02", "prop_dock_shippad", "des_shipsink_03",
    "des_shipsink_04", "prop_mk_flag", "prop_mk_flag_2", "proc_mntn_stone03", "FreeModeMale01",
    "rsn_os_specialfloatymetal_n", "rsn_os_specialfloatymetal", "cs1_09_sea_ufo", "rsn_os_specialfloaty2_light2",
    "rsn_os_specialfloaty2_light", "rsn_os_specialfloaty2", "rsn_os_specialfloatymetal_n", "rsn_os_specialfloatymetal",
    "P_Spinning_Anus_S_Main", "P_Spinning_Anus_S_Root", "cs3_08b_rsn_db_aliencover_0001cs3_08b_rsn_db_aliencover_0001_a",
    "sc1_04_rnmo_paintoverlaysc1_04_rnmo_paintoverlay_a", "rnbj_wallsigns_0001", "proc_sml_stones01", "proc_sml_stones02",
    "maverick", "Miljet", "proc_sml_stones03", "proc_stones_01", "proc_stones_02", "proc_stones_03", "proc_stones_04",
    "proc_stones_05", "proc_stones_06", "prop_coral_stone_03", "prop_coral_stone_04", "prop_gravestones_01a",
    "prop_gravestones_02a", "prop_gravestones_03a", "prop_gravestones_04a", "prop_gravestones_05a",
    "prop_gravestones_06a", "prop_gravestones_07a", "prop_gravestones_08a", "prop_gravestones_09a",
    "prop_gravestones_10a", "prop_prlg_gravestone_05a_l1", "prop_prlg_gravestone_06a", "test_prop_gravestones_04a",
    "test_prop_gravestones_05a", "test_prop_gravestones_07a", "test_prop_gravestones_08a", "test_prop_gravestones_09a",
    "prop_prlg_gravestone_01a", "prop_prlg_gravestone_02a", "prop_prlg_gravestone_03a", "prop_prlg_gravestone_04a",
    "prop_stoneshroom1", "prop_stoneshroom2", "v_res_fa_stones01", "test_prop_gravestones_01a",
    "test_prop_gravestones_02a", "prop_prlg_gravestone_05a", "FreemodeFemale01", "p_cablecar_s", "stt_prop_stunt_tube_l",
    "stt_prop_stunt_track_dwuturn", "p_spinning_anus_s", "prop_windmill_01", "hei_prop_heist_tug", "prop_air_bigradar",
    "p_oil_slick_01", "prop_dummy_01", "hei_prop_heist_emp", "p_tram_cash_s", "hw1_blimp_ce2", "prop_fire_exting_1a",
    "prop_fire_exting_1b", "prop_fire_exting_2a", "prop_fire_exting_3a", "hw1_blimp_ce2_lod", "hw1_blimp_ce_lod",
    "hw1_blimp_cpr003", "hw1_blimp_cpr_null", "hw1_blimp_cpr_null2", "prop_lev_des_barage_02",
    "hei_prop_carrier_defense_01", "prop_juicestand", "S_M_M_MovAlien_01", "s_m_m_movalien_01", "s_m_m_movallien_01",
    "u_m_y_babyd", "CS_Orleans", "A_M_Y_ACult_01", "S_M_M_MovSpace_01", "U_M_Y_Zombie_01", "s_m_y_blackops_01",
    "a_f_y_topless_01", "a_c_boar", "a_c_cat_01", "a_c_chickenhawk", "a_c_chimp", "s_f_y_hooker_03", "a_c_chop",
    "a_c_cormorant", "a_c_cow", "a_c_coyote", "v_ilev_found_cranebucket", "p_cs_sub_hook_01_s", "a_c_crow", "a_c_dolphin",
    "a_c_fish", "hei_prop_heist_hook_01", "prop_rope_hook_01", "prop_sub_crane_hook", "s_f_y_hooker_01",
    "prop_vehicle_hook", "prop_v_hook_s", "prop_dock_crane_02_hook", "prop_winch_hook_long", "a_c_hen", "a_c_humpback",
    "a_c_husky", "a_c_killerwhale", "a_c_mtlion", "a_c_pigeon", "a_c_poodle", "prop_coathook_01", "prop_cs_sub_hook_01",
    "a_c_pug", "a_c_rabbit_01", "a_c_rat", "a_c_retriever", "a_c_rhesus", "a_c_rottweiler", "a_c_sharkhammer",
    "a_c_sharktiger", "a_c_shepherd", "a_c_stingray", "a_c_westy", "CS_Orleans", "prop_windmill_01",
    "prop_Ld_ferris_wheel", "p_tram_crash_s", "p_oil_slick_01", "p_ld_stinger_s", "p_ld_soc_ball_01", "p_parachute1_s",
    "p_cablecar_s", "prop_beach_fire", "prop_lev_des_barge_02", "prop_lev_des_barge_01", "prop_sculpt_fix",
    "prop_flagpole_2b", "prop_flagpole_2c", "prop_winch_hook_short", "prop_flag_canada", "prop_flag_canada_s",
    "prop_flag_eu", "prop_flag_eu_s", "prop_flag_france", "prop_flag_france_s", "prop_flag_german", "prop_ld_hook",
    "prop_flag_german_s", "prop_flag_ireland", "prop_flag_ireland_s", "prop_flag_japan", "prop_flag_japan_s",
    "prop_flag_ls", "prop_flag_lsfd", "prop_flag_lsfd_s", "prop_cable_hook_01", "prop_flag_lsservices",
    "prop_flag_lsservices_s", "prop_flag_ls_s", "prop_flag_mexico", "prop_flag_mexico_s", "csx_coastboulder_00",
    "des_tankercrash_01", "des_tankerexplosion_01", "des_tankerexplosion_02", "des_trailerparka_02",
    "des_trailerparkb_02", "des_trailerparkc_02", "des_trailerparkd_02", "des_traincrash_root2", "des_traincrash_root3",
    "des_traincrash_root4", "des_traincrash_root5", "des_finale_vault_end", "des_finale_vault_root001",
    "des_finale_vault_root002", "des_finale_vault_root003", "des_finale_vault_root004", "des_finale_vault_start",
    "des_vaultdoor001_root001", "des_vaultdoor001_root002", "des_vaultdoor001_root003", "des_vaultdoor001_root004",
    "des_vaultdoor001_root005", "des_vaultdoor001_root006", "des_vaultdoor001_skin001", "des_vaultdoor001_start",
    "des_traincrash_root6", "prop_ld_vault_door", "prop_vault_door_scene", "prop_vault_door_scene", "prop_vault_shutter",
    "p_fin_vaultdoor_s", "prop_gold_vault_fence_l", "prop_gold_vault_fence_r", "prop_gold_vault_gate_01",
    "des_traincrash_root7", "prop_flag_russia", "prop_flag_russia_s", "prop_flag_s", "ch2_03c_props_rrlwindmill_lod",
    "prop_flag_sa", "prop_flag_sapd", "prop_flag_sapd_s", "prop_flag_sa_s", "prop_flag_scotland", "prop_flag_scotland_s",
    "prop_flag_sheriff", "prop_flag_sheriff_s", "prop_flag_uk", "prop_yacht_lounger", "prop_yacht_seat_01",
    "prop_yacht_seat_02", "prop_yacht_seat_03", "marina_xr_rocks_02", "marina_xr_rocks_03", "prop_test_rocks01",
    "prop_test_rocks02", "prop_test_rocks03", "prop_test_rocks04", "marina_xr_rocks_04", "marina_xr_rocks_05",
    "marina_xr_rocks_06", "prop_yacht_table_01", "csx_searocks_02", "csx_searocks_03", "csx_searocks_04",
    "csx_searocks_05", "p_spinning_anus_s", "stt_prop_ramp_jump_xs", "stt_prop_ramp_adj_loop", "ex_props_exec_crashedp",
    "xm_prop_x17_osphatch_40m", "p_spinning_anus_s", "xm_prop_x17_sub", "csx_searocks_06", "p_yacht_chair_01_s",
    "p_yacht_sofa_01_s", "prop_yacht_table_02", "csx_coastboulder_00", "csx_coastboulder_01", "csx_coastboulder_02",
    "csx_coastboulder_03", "csx_coastboulder_04", "csx_coastboulder_05", "csx_coastboulder_06", "csx_coastboulder_07",
    "csx_coastrok1", "csx_coastrok2", "csx_coastrok3", "csx_coastrok4", "csx_coastsmalrock_01", "csx_coastsmalrock_02",
    "csx_coastsmalrock_03", "csx_coastsmalrock_04", "csx_coastsmalrock_05", "prop_yacht_table_03", "prop_flag_uk_s",
    "prop_flag_us", "prop_flag_usboat", "prop_flag_us_r", "prop_flag_us_s", "p_gasmask_s", "prop_flamingo",
    "p_crahsed_heli_s", "prop_rock_4_big2", "prop_fnclink_05crnr1", "prop_cs_plane_int_01", "prop_windmill_01" }

Citizen.CreateThread(function()
    while atlas.antiObjectAttach do
        local CageObjs = BadObjs
        Citizen.Wait(500)
        local ped = PlayerPedId()
        local handle, object = FindFirstObject()
        local finished = false
        repeat
            Wait(1000)
            if IsEntityAttached(object) and DoesEntityExist(object) then
                if GetEntityModel(object) == GetHashKey("prop_acc_guitar_01") then
                    ReqAndDelete(object, true)
                end
            end
            for i = 1, #CageObjs do
                if GetEntityModel(object) == GetHashKey(CageObjs[i]) then
                    ReqAndDelete(object, false)
                end
            end
            finished, object = FindNextObject(handle)
        until not finished
        EndFindObject(handle)
    end
end)

AddStateBagChangeHandler(nil, nil, function(bagName, key, value)
    if #key > 131072 then
        BanPlayer("State bag crash attempt")
    end
end)

RegisterNetEvent('atlas_anticheat:checkTaze', function()
    if not HasPedGotWeapon(PlayerPedId(), `WEAPON_STUNGUN`, false) then
        BanPlayer("Taze Player Cheat")
    end
end)
