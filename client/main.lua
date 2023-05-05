local owned_vehicles = {}

local function lockVehicle()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local vehicle
	local dict = "anim@mp_player_intmenu@key_fob@"

	if not HasAnimDictLoaded(dict) then
		RequestAnimDict(dict)
		while not HasAnimDictLoaded(dict) do
			Wait(100)
		end
	end

	if IsPedInAnyVehicle(playerPed, false) then
		vehicle = GetVehiclePedIsIn(playerPed, false)
	else
		vehicle = GetClosestVehicle(coords, 8.0, 0, 71)
		TaskPlayAnim(GetPlayerPed(-1), dict, "fob_click_fp", 8.0, 8.0, -1, 48, 1, false, false, false)
	end

	if not DoesEntityExist(vehicle) then
		return
	end

	local plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle))
	if not owned_vehicles[plate] then
		return
	end

	CreateThread(function()
		local lockStatus = GetVehicleDoorLockStatus(vehicle)
		local playerPed = PlayerPedId()
		local vehcoords = GetEntityCoords(vehicle)

		if lockStatus == 1 then -- unlocked
			SetVehicleDoorsLocked(vehicle, 2)
			if IsPedInVehicle(playerPed, vehicle, false) then
				PlayVehicleDoorCloseSound(vehicle, 1)
			end
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			Wait(150)
			SetVehicleDoorsShut(vehicle, false)
			TriggerServerEvent("xc_vehlock:soundRequest", vehcoords, "carlock_s")
		elseif lockStatus == 2 then -- locked
			SetVehicleDoorsLocked(vehicle, 1)
			if IsPedInVehicle(playerPed, vehicle, false) then
				PlayVehicleDoorOpenSound(vehicle, 0)
			end
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			Wait(150)
			SetVehicleLights(vehicle, 2)
			Wait(150)
			SetVehicleLights(vehicle, 0)
			TriggerServerEvent("xc_vehlock:soundRequest", vehcoords, "carlock")
		end
	end)
end

RegisterCommand('+'..Config.commandname, function()
	lockVehicle()	
end, false)

RegisterCommand('-'..Config.commandname, function()

end, false)

RegisterKeyMapping('+'..Config.commandname, Config.keybindlabel, 'keyboard', Config.keybind)

RegisterNetEvent("xc_vehlock:soundHandle", function(coords, file)
    local pcoords = GetEntityCoords(PlayerPedId())
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
	print("Update owned vehicle keys data")
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

	local options = {
		{
			name = 'vehlock:give',
			icon = 'fa-solid fa-key',
			label = 'Give Key',
			canInteract = function(entity, distance, coords, name, bone)
				return not LocalPlayer.state.isDead
			end,
			onSelect = function(data)
				local ped = data.entity
				local pedIndex = NetworkGetPlayerIndexFromPed(ped)
				local targetId = GetPlayerServerId(pedIndex)
				local input = lib.inputDialog('Vehicle', {
					{ type = "input", label = "Plate number", placeholder = "plate number" }
				})
				if not input then
					return
				end
				local plate = input[1]:upper()
				if type(plate) ~= "string" then
					return ESX.ShowNotification("Input data is not valid", "error", 5000)
				end
				if not owned_vehicles[plate] then
					return ESX.ShowNotification("You don't own this vehicle?", "error", 5000)
				end
				local data = {
					targetId = targetId,
					plate = plate
				}
				local result = lib.callback.await("xc_vehlock:giveKey", false, data)
				if type(result) == "string" then
					return ESX.ShowNotification(result, "error")
				end
				ESX.ShowNotification("Success", "check")
			end,
			distance = 2.0
		},
	}

	exports["ox_target"]:addGlobalPlayer(options)
end)