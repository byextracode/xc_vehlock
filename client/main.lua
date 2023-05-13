local owned_vehicles = {}

if Config.target then
	local options = {
		{
			name = 'vehlock:give',
			icon = 'fa-solid fa-key',
			label = labelText("givekey_label"),
			canInteract = function(entity, distance, coords, name, bone)
				return not LocalPlayer.state.isDead
			end,
			onSelect = function(data)
				local ped = data.entity
				local pedIndex = NetworkGetPlayerIndexFromPed(ped)
				local targetId = GetPlayerServerId(pedIndex)
				giveKey(targetId)
			end,
			distance = 2.0
		},
	}

	exports["ox_target"]:addGlobalPlayer(options)
end

local function giveKey(targetId)
	local input = lib.inputDialog(labelText("input_title"), {
		{ type = "input", label = labelText("input_label"), placeholder = labelText("input_placeholder") }
	})
	if not input then
		return
	end
	local plate = input[1]:upper()
	if type(plate) ~= "string" then
		return lib.notify({
            title = labelText("failure"),
            description = labelText("invalid_input"),
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#909296'
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
	end
	if not owned_vehicles[plate] then
		return lib.notify({
            title = labelText("failure"),
            description = labelText("not_owned"),
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#909296'
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
	end
	local data = {
		targetId = targetId,
		plate = plate
	}
	local result = lib.callback.await("xc_vehlock:giveKey", false, data)
	if type(result) == "string" then
		return lib.notify({
            title = labelText("failure"),
            description = result,
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#909296'
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
	end
	lib.notify({
		title = labelText("givekey_success"),
		description = labelText("givekey_success_desc", plate),
		position = 'top',
		style = {
			backgroundColor = '#141517',
			color = '#909296'
		},
		icon = 'circle-check',
		iconColor = '#00ff00'
	})
end

local function lockVehicle()
	local coords = GetEntityCoords(cache.ped)
	local vehicle = cache.vehicle or GetClosestVehicle(coords, 8.0, 0, 71)
	local dict = "anim@mp_player_intmenu@key_fob@"
	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Wait(100)
		end
	end
	if not cache.vehicle then
		TaskPlayAnim(cache.ped, dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
	end
	if not DoesEntityExist(vehicle) then
		return
	end

	local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
	if not owned_vehicles[plate] then
		return
	end

	local lockStatus = GetVehicleDoorLockStatus(vehicle)
	local vehcoords = GetEntityCoords(vehicle)
	if lockStatus == 1 then -- unlocked
		SetVehicleDoorsLocked(vehicle, 2)
		if IsPedInVehicle(cache.ped, vehicle, false) then
			PlayVehicleDoorCloseSound(vehicle, 1)
		end
		if not GetIsVehicleEngineRunning(vehicle) then
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			Wait(150)
			TriggerServerEvent("xc_vehlock:soundRequest", vehcoords, "carlock_s")
		end
		SetVehicleDoorsShut(vehicle, false)
	elseif lockStatus == 2 then -- locked
		SetVehicleDoorsLocked(vehicle, 1)
		if IsPedInVehicle(cache.ped, vehicle, false) then
			PlayVehicleDoorOpenSound(vehicle, 0)
		end
		if not GetIsVehicleEngineRunning(vehicle) then
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			Wait(150)
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			TriggerServerEvent("xc_vehlock:soundRequest", vehcoords, "carlock")
		end
	end
end

RegisterCommand('+'..Config.commandlock, function()
	lockVehicle()	
end, false)

RegisterCommand('-'..Config.commandlock, function()

end, false)

RegisterKeyMapping('+'..Config.commandlock, Config.keybindlabel, 'keyboard', Config.keybind)

RegisterCommand(Config.commandgivekey, function()
	local otherPlayer = lib.getClosestPlayer(GetEntityCoords(cache.ped), 2.0, false)
	if otherPlayer == nil then
		return lib.notify({
            title = labelText("failure"),
            description = labelText("no_player_nearby"),
            position = 'top',
            style = {
                backgroundColor = '#141517',
                color = '#909296'
            },
            icon = 'ban',
            iconColor = '#C53030'
        })
	end
	local targetId = GetPlayerServerId(pedIndex)
	giveKey(targetId)
end)

RegisterNetEvent("xc_vehlock:soundHandle", function(coords, file)
    local pcoords = GetEntityCoords(cache.ped)
    local dst = #(pcoords- coords)
    if dst <= 8.0 then
        if dst < 1 then
            dst = 1
        end
        local volume = 1.0 / dst
        volume = tonumber(tostring(volume):sub(1, 3))
        SendNUIMessage({type = 'playSound', file = file, volume = volume})
    end
end)

RegisterNetEvent("xc_vehlock:update", function()
	local result = lib.callback.await("xc_vehlock:dataRequest")
	if not result then
		Wait(10000)
		result = lib.callback.await("xc_vehlock:dataRequest")
	end
	print(labelText("update"))
	table.sort(result)
	for k, v in pairs(result) do
		if not owned_vehicles[k] then
			owned_vehicles[k] = true
			print(k)
		end
	end
end)

CreateThread(function()
	while not ESX.PlayerLoaded do
		Wait(100)
	end
	TriggerEvent("xc_vehlock:update")
end)