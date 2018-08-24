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
