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
Citizen.CreateThread(function()
    while true do
		Wait(0)
        if Config.NPCVehiclesLocked then
            local ped = GetPlayerPed(-1)
            if DoesEntityExist(GetVehiclePedIsTryingToEnter(PlayerPedId(ped))) then
                local veh = GetVehiclePedIsTryingToEnter(PlayerPedId(ped))
                local LockStatus = GetVehicleDoorLockStatus(veh)
                if LockStatus >= 2 then
                    SetVehicleDoorsLocked(veh, 2)
                    locked = true
				end

                local npc = GetPedInVehicleSeat(veh, -1)
                if npc then
                    SetPedCanBeDraggedOut(npc, false)
                end
			end
        end
    end
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
