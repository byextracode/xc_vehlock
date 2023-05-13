local saved_vehicle = {}

RegisterServerEvent("xc_vehlock:soundRequest")
AddEventHandler("xc_vehlock:soundRequest", function(coords, file)
	local source = source
	local pedCoords = GetEntityCoords(GetPlayerPed(source))
	if #(coords-pedCoords) > 10.0 then -- security matters
		return
	end
    TriggerClientEvent("xc_vehlock:soundHandle", -1, coords, file)
end)

lib.callback.register("xc_vehlock:dataRequest", function(source)
	local owned = {}
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then
		return owned
	end
	local result = MySQL.prepare.await('SELECT `plate` FROM `owned_vehicles` WHERE `owner` = ?', {xPlayer.identifier})
	if result then
		if type(result) ~= "table" then
			result = {
				{
					plate = result
				}
			}
		end
		for i = 1, #result do
			owned[result[i].plate] = true
		end
	end
	if saved_vehicle[source] then
		for k, v in pairs(saved_vehicle[source]) do
			owned[k] = true
		end
	end
	return owned
end)

lib.callback.register("xc_vehlock:giveKey", function(source, data)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not xPlayer then
		return "error"
	end
	local plate = data?.plate
	local targetId = data?.targetId
	if plate == nil or targetId == nil then
		return "error"
	end
	local result = MySQL.prepare.await('SELECT `plate` FROM `owned_vehicles` WHERE `owner` = ? AND `plate` = ?', {xPlayer.identifier, plate})
	if not result then
		return labelText("not_owned")
	end
	if not saved_vehicle[targetId] then
		saved_vehicle[targetId] = {}
	end
	saved_vehicle[targetId][plate] = true
	TriggerClientEvent("xc_vehlock:update", targetId)
	return true
end)

RegisterServerEvent("xc_vehlock:givekey", function(id, plate)
	if id == nil then
		return
	end
	if plate == nil then
		return
	end
	if GetPlayerName(id) == nil then
		return
	end
	if not saved_vehicle[id] then
		saved_vehicle[id] = {}
	end
	saved_vehicle[id][plate] = true
	TriggerClientEvent("xc_vehlock:update", id)
end)