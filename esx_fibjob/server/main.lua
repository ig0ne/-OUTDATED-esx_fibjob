require "resources/[essential]/es_extended/lib/MySQL"
MySQL:open("127.0.0.1", "gta5_gamemode_essential", "user", "password")

RegisterServerEvent('esx_fibjob:requestPlayerData')
AddEventHandler('esx_fibjob:requestPlayerData', function(reason)
	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		TriggerEvent('esx_skin:requestPlayerSkinInfosCb', source, function(skin, jobSkin)

			local data = {
				job       = xPlayer.job,
				inventory = xPlayer.inventory,
				skin      = skin
			}

			TriggerClientEvent('esx_fibjob:responsePlayerData', source, data, reason)
		end)
	end)
end)

RegisterServerEvent('esx_fibjob:requestOtherPlayerData')
AddEventHandler('esx_fibjob:requestOtherPlayerData', function(playerId, reason)
	TriggerClientEvent('esx_fibjob:requestPlayerWeapons', playerId, source, reason)
end)

RegisterServerEvent('esx_fibjob:responsePlayerWeapons')
AddEventHandler('esx_fibjob:responsePlayerWeapons', function(weapons, playerId, reason)

	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)

		local data = {
			name       = GetPlayerName(source),
			job        = xPlayer.job,
			inventory  = xPlayer.inventory,
			accounts   = xPlayer.accounts,
			weapons    = weapons
		}

		TriggerClientEvent('esx_fibjob:responseOtherPlayerData', playerId, data, reason)

	end)
end)

RegisterServerEvent('esx_fibjob:requestPlayerPositions')
AddEventHandler('esx_fibjob:requestPlayerPositions', function(reason)
	
	local _source = source

	TriggerEvent('esx:getPlayers', function(xPlayers)

		local positions = {}

		for k, v in pairs(xPlayers) do
			positions[tostring(k)] = v.player.coords
		end

		TriggerClientEvent('esx_fibjob:responsePlayerPositions', _source, positions, reason)

	end)

end)

RegisterServerEvent('esx_fibjob:confiscatePlayerBlackMoney')
AddEventHandler('esx_fibjob:confiscatePlayerBlackMoney', function(playerId, amount)
	TriggerEvent('esx:getPlayerFromId', playerId, function(xPlayer)
		xPlayer:removeAccountMoney('black_money', amount)
	end)
	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		xPlayer:addAccountMoney('black_money', amount)
	end)
end)

RegisterServerEvent('esx_fibjob:confiscatePlayerWeapon')
AddEventHandler('esx_fibjob:confiscatePlayerWeapon', function(playerId, weaponName)
	TriggerClientEvent('esx_fibjob:confiscatePlayerWeapon', playerId, weaponName);
end)

RegisterServerEvent('esx_fibjob:confiscatePlayerInventoryItem')
AddEventHandler('esx_fibjob:confiscatePlayerInventoryItem', function(playerId, itemName, count)
	TriggerEvent('esx:getPlayerFromId', playerId, function(xPlayer)
		xPlayer:removeInventoryItem(itemName, count)
	end)
end)

RegisterServerEvent('esx_fibjob:addPlayerInventoryItem')
AddEventHandler('esx_fibjob:addPlayerInventoryItem', function(playerId, itemName, count)
	TriggerEvent('esx:getPlayerFromId', playerId, function(xPlayer)
		xPlayer:addInventoryItem(itemName, count)
	end)
end)

RegisterServerEvent('esx_fibjob:handcuff')
AddEventHandler('esx_fibjob:handcuff', function(playerId)
	TriggerClientEvent('esx_fibjob:handcuff', playerId)
end)

RegisterServerEvent('esx_fibjob:putInVehicle')
AddEventHandler('esx_fibjob:putInVehicle', function(playerId)
	TriggerClientEvent('esx_fibjob:putInVehicle', playerId)
end)

RegisterServerEvent('esx_fibjob:requestFineData')
AddEventHandler('esx_fibjob:requestFineData', function(category)

	local executed_query = MySQL:executeQuery("SELECT * FROM fine_types WHERE category = '@category'", {['@category'] = category})
	local result         = MySQL:getResults(executed_query, {'id', 'label', 'amount', 'category'}, 'id')
	local data           = {}

	for i=1, #result, 1 do
		table.insert(data, {
			id     = result[i].id,
			label  = result[i].label,
			amount = result[i].amount
		})
	end

	TriggerClientEvent('esx_fibjob:responseFineData', source, data)

end)

RegisterServerEvent('esx_fibjob:applyFine')
AddEventHandler('esx_fibjob:applyFine', function(playerId, fineId)
	
	TriggerClientEvent('esx:showNotification', source, 'Vous avez mis une ammende')

	TriggerEvent('esx:getPlayerFromId', playerId, function(xPlayer)
		MySQL:executeQuery("INSERT INTO fines (identifier, fine_id) VALUES ('@identifier', '@fine_id')", {['@identifier'] = xPlayer.identifier, ['@fine_id'] = fineId})
		TriggerClientEvent('esx:showNotification', xPlayer.player.source, 'Vous avez recu une amende')
	end)

end)

RegisterServerEvent('esx_fibjob:requestFineList')
AddEventHandler('esx_fibjob:requestFineList', function()
	
	local _source        = source
	local executed_query = MySQL:executeQuery("SELECT * FROM fine_types")
	local result         = MySQL:getResults(executed_query, {'id', 'label', 'amount', 'category'}, 'id')

	local fineTypes      = {}

	for i=1, #result, 1 do
		fineTypes[result[i].id] = {
			label  = result[i].label,
			amount = result[i].amount
		}
	end

	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)

		local executed_query = MySQL:executeQuery("SELECT * FROM fines WHERE identifier = '@identifier'", {['@identifier'] = xPlayer.identifier})
		local result         = MySQL:getResults(executed_query, {'id', 'fine_id'}, 'id')
		local fines          = {}

		for i=1, #result, 1 do
			table.insert(fines, {
				id     = result[i].id,
				label  = fineTypes[result[i].fine_id].label,
				amount = fineTypes[result[i].fine_id].amount
			})
		end

		TriggerClientEvent('esx_fibjob:responseFineList', _source, fines)

	end)

end)

RegisterServerEvent('esx_fibjob:requestPayFine')
AddEventHandler('esx_fibjob:requestPayFine', function(fineId, amount, playerName)
	
	local _source = source

	MySQL:executeQuery("DELETE FROM fines WHERE id = '@id'", {['@id'] = fineId})

	TriggerEvent('esx:getPlayerFromId', source, function(xPlayer)
		--xPlayer:removeMoney(amount)
		xPlayer:removeAccountMoney('bank', amount)
		TriggerClientEvent('esx:showNotification', _source, 'Vous avez payé une ammende de $' .. amount)
		TriggerClientEvent('esx_fibjob:hasPayedFine', -1, playerName, amount)
	end)
end)