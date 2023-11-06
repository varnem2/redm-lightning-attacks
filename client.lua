local RSGCore = exports['rsg-core']:GetCoreObject()

local enabled = false
local cooldownActive = false

RegisterNetEvent("lightning-attacks:toggle")
RegisterNetEvent("lightning-attacks:strike")
RegisterNetEvent("lightning-attacks:smite")

local function ForceLightningFlashAtCoords(x, y, z, p3)
	return Citizen.InvokeNative(0x67943537D179597C, x, y, z, p3)
end

local function lightningStrike(targetPos)
	TriggerServerEvent("lightning-attacks:strike", targetPos)
end

local function checkIfUserHasItem(--[[optional]] itemName)
	local _itemName = itemName or Config.WeaponName

	-- local player = PlayerPedId()
	--  0x8425C5F057012DAB == _GET_PED_CURRENT_HELD_WEAPON
    -- local weapon = Citizen.InvokeNative(0x8425C5F057012DAB, player)
	-- local WeaponData = RSGCore.Shared.Items[weapon]
	-- local _userHasItem = RSGCore.Functions.HasItem(WeaponData[_itemName])

	local _userHasItem = RSGCore.Functions.HasItem(_itemName)
	if _userHasItem then
		return true
	elseif
		return false
	end
end

local function toggle()
	if not checkIfUserHasItem() then
		return
	end
	enabled = not enabled

	TriggerEvent("chat:addMessage", {
		color = {255, 255, 128},
		args = {"Lightning Attacks", enabled and "on" or "off"}
	})
end

AddEventHandler("lightning-attacks:toggle", toggle)

AddEventHandler("lightning-attacks:strike", function(targetPos, addExplosion)
	if not checkIfUserHasItem then
		return
	end

	local ped = PlayerPedId()
	local pos = GetEntityCoords(ped)
	local distance = #(targetPos - pos)

	if distance <= Config.MaxDistance then
		ForceLightningFlashAtCoords(targetPos.x, targetPos.y, targetPos.z, -1.0)

		if AddExplosion then
			Citizen.Wait(300)
			AddExplosion(targetPos.x, targetPos.y, targetPos.z, 25, 10000.0, true, false, 1.0)
		end

		cooldownActive = true
		Citizen.SetTimeout(Config.Cooldown, function()
			cooldownActive = false
		end)
	end
end)

AddEventHandler("lightning-attacks:smite", function()
	if not checkIfUserHasItem then
		return
	end
	lightningStrike(GetEntityCoords(PlayerPedId()))
end)

Citizen.CreateThread(function()
	TriggerEvent("chat:addSuggestion", "/lightningattacks", "Toggle lightning attack mode")
	TriggerEvent("chat:addSuggestion", "/smite", "Smite a player", {
		{name = "player", help = "Name or ID of a player"}
	})

	while true do
		if enabled then
			if cooldownActive then
				DisablePlayerFiring(PlayerId(), true)
			else
				local firedWeapon, impactCoords = GetPedLastWeaponImpactCoord(PlayerPedId())

				if firedWeapon then
					lightningStrike(impactCoords)
				end
			end
		end

		Citizen.Wait(0)
	end
end)
