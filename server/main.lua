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
    TriggerClientEvent("esx_lockpick:outlawNotify", -1, "~r~Someone is lockpicking a vehicle")
end)


RegisterServerEvent('esx_lockpick:InProgressS1')
AddEventHandler('esx_lockpick:InProgressS1', function(street1, sex)
    TriggerClientEvent("esx_lockpick:outlawNotify", -1, "~r~Someone is lockpicking a vehicle")
end)

RegisterServerEvent('esx_lockpick:InProgressPos')
AddEventHandler('esx_lockpick:InProgressPos', function(gx, gy, gz)
    TriggerClientEvent('esx_lockpick:location', -1, gx, gy, gz)
end)
