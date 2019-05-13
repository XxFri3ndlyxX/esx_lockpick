ESX						= nil
local CurrentAction		= nil
local PlayerData		= {}
local pedIsTryingToLockpickVehicle  = false
local timer = 1 --in minutes - Set the time during the player is outlaw
local showOutlaw = true --Set if show outlaw act on map
local blipTime = 35 --in second
local showcopsmisbehave = true --show notification when cops steal too
local timing = timer * 60000 --Don't touche it

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)
--//////////////////////////////////////////////--
--                MAIN FUNCTION                 --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:onUse')
AddEventHandler('esx_lockpick:onUse', function()
	local playerPed		= GetPlayerPed(-1)
    local coords		= GetEntityCoords(playerPed)

	if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
		local vehicle = nil

		if IsPedInAnyVehicle(playerPed, false) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		else
			vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
		end

		if DoesEntityExist(vehicle) then
			if Config.IgnoreAbort then
				TriggerServerEvent('esx_lockpick:removeKit')
			end

			TriggerEvent('esx_lockpick:LockpickAnimation')
			
			Citizen.CreateThread(function()
				ThreadID = GetIdOfThisThread()
				CurrentAction = 'lockpick'
				local chance =	lockpickchance()
				if chance == true then
					if Config.CallCops then
						local randomReport = math.random(1, Config.CallCopsPercent)
						print(Config.CallCopsPercent)
						if randomReport == Config.CallCopsPercent then
							TriggerServerEvent('esx_lockpick:Notify')
						end
					end
					exports.pNotify:SendNotification({text = "Lockpicking vehicle, please wait...", type = "error", timeout = Config.NotificationLockTime * 1000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
				Citizen.Wait(Config.LockTime * 1000)

                if CurrentAction ~= nil then
					SetVehicleAlarm(vehicle, true)
					SetVehicleAlarmTimeLeft(vehicle, Config.AlarmTime * 1000)
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                    ClearPedTasksImmediately(playerPed)
                    ESX.ShowNotification(_U('vehicle_unlocked'))
                    SetVehicleNeedsToBeHotwired(vehicle, true)
                    IsVehicleNeedsToBeHotwired(vehicle)
                    TaskEnterVehicle(playerPed, vehicle, 10.0, -1, 1.0, 1, 0)
                    Wait(1000)
                    TriggerEvent('esx_lockpick:HotWireAnimation')
                    FreezeEntityPosition(vehicle, true)
                    exports.pNotify:SendNotification({text = "Unjamming The handbrake", type = "error", timeout = Config.JammedHandbrakeTime * 1000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
                    Citizen.Wait(Config.JammedHandbrakeTime * 1000)
                    ClearPedTasks(playerPed)
                    FreezeEntityPosition(vehicle, false)
                end
			else
				if Config.CallCops then
					local randomReport = math.random(1, Config.CallCopsPercent)
					print(Config.CallCopsPercent)
					if randomReport == Config.CallCopsPercent then
						TriggerServerEvent('esx_lockpick:Notify')
					end
				end
				exports.pNotify:SendNotification({text = "Lockpicking vehicle, please wait...", type = "error", timeout = Config.NotificationLockTime * 1000, layout = "centerRight", queue = "right", animation = {open = "gta_effects_fade_in", close = "gta_effects_fade_out"}})
				Citizen.Wait(Config.LockTime * 1000)
	            ClearPedTasksImmediately(playerPed)
				ESX.ShowNotification(_U('picklock_failed'))
				
				if not Config.IgnoreAbort then
					TriggerServerEvent('esx_lockpick:removeKit')
				end
				CurrentAction = nil
				TerminateThisThread()
			end
			end)
		end

		Citizen.CreateThread(function()
			Citizen.Wait(0)

			if CurrentAction ~= nil then
				SetTextComponentFormat('STRING')
				AddTextComponentString(_U('abort_hint'))
				DisplayHelpTextFromStringLabel(0, 0, 1, -1)

				if (IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35)) then
					TerminateThread(ThreadID)
					ESX.ShowNotification(_U('aborted_lockpicking'))
					CurrentAction = nil
				end
			end

		end)
	else
		ESX.ShowNotification(_U('no_vehicle_nearby'))
	end
end)
--//////////////////////////////////////////////--
--                LOCKPICK CHANCE               --
--//////////////////////////////////////////////--
function lockpickchance()
	local nb = math.random(1, Config.percentage)
    percentage = Config.percentage
    if(nb < percentage)then
        return true
    else
        return false
    end
end
--//////////////////////////////////////////////--
--                LOCK VEHICLES                 --
--//////////////////////////////////////////////--
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end
Citizen.CreateThread(function()
	while true do
		-- gets if player is entering vehicle
		if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId())) then
			-- gets vehicle player is trying to enter and its lock status
			local xPlayer = ESX.GetPlayerData()
			local veh = GetVehiclePedIsTryingToEnter(PlayerPedId())
			local lock = GetVehicleDoorLockStatus(veh)
				
				-- Get the conductor door angle, open if value > 0.0
				local doorAngle = GetVehicleDoorAngleRatio(veh, 0)
			
				-- normalizes chance
				if Config.chance > 100 then
					Config.chance = 100
				elseif Config.chance < 0 then
					Config.chance = 0
				end
			
				-- check if got lucky
				local lucky = (math.random(100) < Config.chance)
			
				-- Set lucky if conductor door is open
				if doorAngle > 0.0 then
					lucky = true
				end
			
				-- check if vehicle is in blacklist
				local blacklisted = false
				for k,model in pairs(Config.blacklist) do
					if IsVehicleModel(veh, GetHashKey(model)) then
						blacklisted = true
					end
				end

				-- gets ped that is driving the vehicle
				local pedd = GetPedInVehicleSeat(veh, -1)
				local plate = GetVehicleNumberPlateText(veh)
				-- lock doors if not lucky or blacklisted
				if ((lock == 7) or (pedd ~= 0 )) then
					if has_value(Config.job_whitelist, xPlayer.job.name) then
						TriggerServerEvent('esx_lockpick:setVehicleDoorsForEveryone', {veh, 1, plate})
					else
						if not lucky or blacklisted then
							TriggerServerEvent('esx_lockpick:setVehicleDoorsForEveryone', {veh, 2, plate})
						else
							TriggerServerEvent('esx_lockpick:setVehicleDoorsForEveryone', {veh, 1, plate})
						end
					end
				end
			end
		Citizen.Wait(0)
	end
end)
RegisterNetEvent('esx_lockpick:setVehicleDoors')
AddEventHandler('esx_lockpick:setVehicleDoors', function(veh, doors)
	SetVehicleDoorsLocked(veh, doors)
end)
--//////////////////////////////////////////////--
--                 NOTIFICATION                 --
--//////////////////////////////////////////////--
GetPlayerName()
RegisterNetEvent('esx_lockpick:outlawLockNotify')
AddEventHandler('esx_lockpick:outlawLockNotify', function(alert)
    if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
        LockNotify(alert)
    end
end)
--[[ function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end ]]
function LockNotify(msg)
    local mugshot, mugshotStr = ESX.Game.GetPedMugshot(GetPlayerPed(-1))
    ESX.ShowAdvancedNotification(_U('911Call'), _U('911Lockpick'), _U('Lockcall'), mugshotStr, 1)
    UnregisterPedheadshot(mugshot)
end
--//////////////////////////////////////////////--
--                   NETWORK                    --
--//////////////////////////////////////////////--
Citizen.CreateThread(function()
    while true do
        Wait(100)
        if NetworkIsSessionStarted() then
            DecorRegister("IsLockOutlaw",  3)
            DecorSetInt(GetPlayerPed(-1), "IsLockOutlaw", 1)
            return
        end
    end
end)
--//////////////////////////////////////////////--
--           SUSPECT DESCRITION                 --
--//////////////////////////////////////////////--
Citizen.CreateThread( function()
    while true do
        Wait(100)
        local plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        if pedIsTryingToLockpickVehicle then
            DecorSetInt(GetPlayerPed(-1), "IsLockOutlaw", 2)
            if PlayerData.job ~= nil and PlayerData.job.name == 'police' and showcopsmisbehave == false then
            elseif PlayerData.job ~= nil and PlayerData.job.name == 'police' and showcopsmisbehave then
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "male" --male/change it to your language
                    else
                        sex = "female" --female/change it to your language
                    end
                    TriggerServerEvent('esx_lockpick:InProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('esx_lockpick:InProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent('esx_lockpick:InProgress', street1, street2, sex)
                    end
                end)
                Wait(3000)
                pedIsTryingToLockpickVehicle = false
            else
                ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
                    local sex = nil
                    if skin.sex == 0 then
                        sex = "male"
                    else
                        sex = "female"
                    end
                    TriggerServerEvent('esx_lockpick:InProgressPos', plyPos.x, plyPos.y, plyPos.z)
                    if s2 == 0 then
                        TriggerServerEvent('esx_lockpick:InProgressS1', street1, sex)
                    elseif s2 ~= 0 then
                        TriggerServerEvent('esx_lockpick:InProgress', street1, street2, sex)
                    end
                end)
                Wait(3000)
                pedIsTryingToLockpickVehicle = false
            end
        end
    end
end)
--//////////////////////////////////////////////--
--              SUSPECT LOCATION                --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:location')
AddEventHandler('esx_lockpick:location', function(tx, ty, tz)
    if PlayerData.job.name == 'police' then
        local transT = 250
        local Blip = AddBlipForCoord(tx, ty, tz)
        SetBlipSprite(Blip,  10)
        SetBlipColour(Blip,  1)
        SetBlipAlpha(Blip,  transT)
        SetBlipAsShortRange(Blip,  false)
        while transT ~= 0 do
            Wait(blipTime * 4)
            transT = transT - 1
            SetBlipAlpha(Blip,  transT)
            if transT == 0 then
                SetBlipSprite(Blip,  2)
                return
            end
        end
    end
end)
--//////////////////////////////////////////////--
--               LOCKPICK CHECK                 --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:Enable')
AddEventHandler('esx_lockpick:Enable', function()
	pedIsTryingToLockpickVehicle = true
end)
--//////////////////////////////////////////////--
--           LOCKPICK ANIMATION                 --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:LockpickAnimation')
AddEventHandler('esx_lockpick:LockpickAnimation', function()
    local ped = GetPlayerPed(-1)
    local x,y,z = table.unpack(GetEntityCoords(playerPed, true))
    if not IsEntityPlayingAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 3) then
        RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
            Citizen.Wait(100)
        end
        --SetEntityCoords(PlayerPedId(), 1057.54, -3197.39, -40.14)
        --SetEntityHeading(PlayerPedId(), 171.5)
        Wait(100)
        TaskPlayAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8, -1, 49, 0, 0, 0, 0)
        Wait(2000)
        while IsEntityPlayingAnim(ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 3) do
            Wait(1)
            if (IsControlPressed(0, 32) or IsControlPressed(0, 33) or IsControlPressed(0, 34) or IsControlPressed(0, 35)) then
                ClearPedTasksImmediately(ped)
                if CurrentAction ~= nil then
                    TerminateThread(ThreadID)
                    ESX.ShowNotification(_U('aborted_lockpicking'))
                    CurrentAction = nil
                    break
                end
            end
        end
    end
end)
--//////////////////////////////////////////////--
--               HOTWRING VEHCILE               --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:HotWireTime')
AddEventHandler('esx_lockpick:HotWireTime', function()
	Citizen.CreateThread(function()
        while true do
            Wait(0)
                local player = GetPlayerPed(-1)
                local InsideVeh = IsPedInAnyVehicle(player, true)
                local vehh = GetVehiclePedIsIn(PlayerPedId(player))
                local HotWireStatus = IsVehicleNeedsToBeHotwired(vehh)
                if InsideVeh then
                if HotWireStatus then
                    FreezeEntityPosition(vehh, true)
                    TriggerEvent('esx_lockpick:HotWireAnimation')
                    Citizen.Wait(30000)
                    ClearPedTasks(player)
                    FreezeEntityPosition(vehh, false)
                    ESX.ShowNotification('HotWire')
                end
            end
        end
    end)
end)

--//////////////////////////////////////////////--
--             HOTWIRING ANIMATION              --
--//////////////////////////////////////////////--
RegisterNetEvent('esx_lockpick:HotWireAnimation')
AddEventHandler('esx_lockpick:HotWireAnimation', function()
    local ped = GetPlayerPed(-1)
    local x,y,z = table.unpack(GetEntityCoords(playerPed, true))
    if not IsEntityPlayingAnim(ped, "veh@std@ds@base", "hotwire", 3) then
        RequestAnimDict("veh@std@ds@base")
        while not HasAnimDictLoaded("veh@std@ds@base") do
            Citizen.Wait(100)
        end
        --SetEntityCoords(PlayerPedId(), 1057.54, -3197.39, -40.14)
        --SetEntityHeading(PlayerPedId(), 171.5)
        Wait(100)
        TaskPlayAnim(ped, "veh@std@ds@base", "hotwire", 8.0, -8, -1, 49, 0, 0, 0, 0)
        Wait(2000)
        while IsEntityPlayingAnim(ped, "veh@std@ds@base", "hotwire", 3) do
            Wait(1)
             if IsControlPressed(0, 243) then
                ClearPedTasksImmediately(ped)
                if CurrentAction ~= nil then
                    TerminateThread(ThreadID)
                    ESX.ShowNotification(_U('aborted_lockpicking'))
                    CurrentAction = nil
                    break
                end
            end 
        end
    end
end)
