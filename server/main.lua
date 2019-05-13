ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Make the kit usable!
ESX.RegisterUsableItem('lockpick', function(source)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	
	if Config.AllowMecano then
		TriggerClientEvent('esx_lockpick:onUse', _source)
	else
		if xPlayer.job.name ~= 'mecano' then
			TriggerClientEvent('esx_lockpick:onUse', _source)
		end
	end
end)

RegisterNetEvent('esx_lockpick:removeKit')
AddEventHandler('esx_lockpick:removeKit', function()
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if not Config.InfiniteLocks then
		xPlayer.removeInventoryItem('lockpick', 1)
		TriggerClientEvent('esx:showNotification', _source, _U('used_kit'))
	end
end)

RegisterServerEvent('esx_lockpick:Notify')
AddEventHandler('esx_lockpick:Notify', function()
    TriggerClientEvent("esx_lockpick:Enable", source)
end)


RegisterServerEvent('esx_lockpick:InProgress')
AddEventHandler('esx_lockpick:InProgress', function(street1, street2, sex)
    TriggerClientEvent("esx_lockpick:outlawLockNotify", -1, "~r~Someone is lockpicking a vehicle")
end)


RegisterServerEvent('esx_lockpick:InProgressS1')
AddEventHandler('esx_lockpick:InProgressS1', function(street1, sex)
    TriggerClientEvent("esx_lockpick:outlawLockNotify", -1, "~r~Someone is lockpicking a vehicle")
end)

RegisterServerEvent('esx_lockpick:InProgressPos')
AddEventHandler('esx_lockpick:InProgressPos', function(tx, ty, tz)
    TriggerClientEvent('esx_lockpick:location', -1, tx, ty, tz)
end)

local vehicles = {}

function getVehData(plate, callback)
    MySQL.Async.fetchAll("SELECT * FROM `owned_vehicles`", {},
    function(result)
        local foundIdentifier = nil
        for i=1, #result, 1 do
            local vehicleData = json.decode(result[i].vehicle)
            if vehicleData.plate == plate then
                foundIdentifier = result[i].owner
                break
            end
        end
        if foundIdentifier ~= nil then
            MySQL.Async.fetchAll("SELECT * FROM `users` WHERE `identifier` = @identifier", {['@identifier'] = foundIdentifier},
            function(result)
                local ownerName = result[1].firstname .. " " .. result[1].lastname

                local info = {
                    plate = plate,
                    owner = ownerName
                }
                callback(info)
            end
          )
        else -- if identifier is nil then...
          local info = {
            plate = plate
          }
          callback(info)
        end
    end)
  end

RegisterNetEvent("esx_lockpick:setVehicleDoorsForEveryone")
AddEventHandler("esx_lockpick:setVehicleDoorsForEveryone", function(veh, doors, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local veh_model = veh[1]
    local veh_doors = veh[2]
    local veh_plate = veh[3]

    if not vehicles[veh_plate] then
        getVehData(veh_plate, function(veh_data)
            if veh_data.plate ~= plate then
                local players = GetPlayers()
                for _,player in pairs(players) do
                    TriggerClientEvent("esx_lockpick:setVehicleDoors", player, table.unpack(veh, doors))
                end
            end
        end)
        vehicles[veh_plate] = true
    end
end)
