local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

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
			--TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_WELDING", 0, true)
			TriggerEvent('esx_lockpick:LockpickAnimation')
			

			Citizen.CreateThread(function()
				ThreadID = GetIdOfThisThread()
				CurrentAction = 'lockpick'
				local chance =	lockpickchance()
				if chance == true then
				Citizen.Wait(Config.LockTime * 1000)

				if CurrentAction ~= nil then
					SetVehicleAlarm(vehicle, true)
					SetVehicleAlarmTimeLeft(vehicle, Config.AlarmTime * 1000)
					SetVehicleDoorsLocked(vehicle, 1)
					SetVehicleDoorsLockedForAllPlayers(vehicle, false)
					ClearPedTasksImmediately(playerPed)
					ESX.ShowNotification(_U('vehicle_unlocked'))
				end

				if not Config.IgnoreAbort then
					TriggerServerEvent('esx_lockpick:removeKit')
				end
				CurrentAction = nil
				TerminateThisThread()

			elseif chance == false then
				if Config.CallCops == true then
					callcopstrue()
			  elseif Config.CallCops == false then
					callcopsfalse()
			else
				Citizen.Wait(Config.LockTime * 1000)
				ClearPedTasksImmediately(playerPed)
				ESX.ShowNotification(_U('picklock_failed'))
			end
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

function callcopstrue()
	local playerPed		= GetPlayerPed(-1)
	local randomReport = math.random(1, Config.CallCopsPercent)
	print(Config.CallCopsPercent)
	if randomReport == Config.CallCopsPercent then
		TriggerServerEvent('esx_lockpick:Notify')
	Citizen.Wait(Config.LockTime * 1000)
	ClearPedTasksImmediately(playerPed)
	ESX.ShowNotification(_U('picklock_failed'))
	end
end

function callcopsfalse()
	local playerPed		= GetPlayerPed(-1)
	Citizen.Wait(Config.LockTime * 1000)
	ClearPedTasksImmediately(playerPed)
	ESX.ShowNotification(_U('picklock_failed'))
end

function lockpickchance()
	local nb = math.random(1, Config.percentage)
    percentage = Config.percentage
    if(nb < percentage)then
        return true
    else
        return false
    end
end

-- NPC Vehicles locked
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

--Only if Config.CallCops = true
GetPlayerName()
RegisterNetEvent('esx_lockpick:outlawNotify')
AddEventHandler('esx_lockpick:outlawNotify', function(alert)
		if PlayerData.job ~= nil and PlayerData.job.name == 'police' then
						Notify2(alert)
        end
end)

function Notify(text)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function Notify2(msg)

  local mugshot, mugshotStr = ESX.Game.GetPedMugshot(GetPlayerPed(-1))

  ESX.ShowAdvancedNotification(_U('911'), _U('911Lockpick'), _U('call'), mugshotStr, 1)

  UnregisterPedheadshot(mugshot)

end

Citizen.CreateThread(function()
    while true do
        Wait(100)
        if NetworkIsSessionStarted() then
            DecorRegister("IsOutlaw",  3)
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 1)
            return
        end
    end
end)

Citizen.CreateThread( function()
    while true do
        Wait(100)
        local plyPos = GetEntityCoords(GetPlayerPed(-1),  true)
        local s1, s2 = Citizen.InvokeNative( 0x2EB41072B4C1E4C0, plyPos.x, plyPos.y, plyPos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt() )
        local street1 = GetStreetNameFromHashKey(s1)
        local street2 = GetStreetNameFromHashKey(s2)
        if pedIsTryingToLockpickVehicle then
            DecorSetInt(GetPlayerPed(-1), "IsOutlaw", 2)
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


RegisterNetEvent('esx_lockpick:Enable')
AddEventHandler('esx_lockpick:Enable', function()
	pedIsTryingToLockpickVehicle = true
end)

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
