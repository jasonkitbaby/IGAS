-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.PetActionHandler", version) then
	return
end

import "ActionRefreshMode"

-- Event handler
function OnEnable(self)
	self:RegisterEvent("PET_STABLE_UPDATE")
	self:RegisterEvent("PET_STABLE_SHOW")
	self:RegisterEvent("PET_BAR_SHOWGRID")
	self:RegisterEvent("PET_BAR_HIDEGRID")
	self:RegisterEvent("PLAYER_CONTROL_LOST")
	self:RegisterEvent("PLAYER_CONTROL_GAINED")
	self:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("UNIT_FLAGS")
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("PET_UI_UPDATE")
	self:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
	self:RegisterEvent("UNIT_AURA")
	self:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	self:RegisterEvent("PET_BAR_UPDATE_USABLE")

	OnEnable = nil
end

function PET_STABLE_UPDATE(self)
	return handler:Refresh()
end

function PET_STABLE_SHOW(self)
	return handler:Refresh()
end


function PLAYER_CONTROL_LOST(self)
	return handler:Refresh(RefreshActionButton)
end

function PLAYER_CONTROL_GAINED(self)
	return handler:Refresh(RefreshActionButton)
end

function PLAYER_FARSIGHT_FOCUS_CHANGED(self)
	return handler:Refresh(RefreshActionButton)
end

function UNIT_PET(self, unit)
	if unit == "player" then
		return handler:Refresh(RefreshActionButton)
	end
end

function UNIT_FLAGS(self, unit)
	if unit == "pet" then
		return handler:Refresh(RefreshActionButton)
	end
end

function PET_BAR_UPDATE(self)
	return handler:Refresh(RefreshActionButton)
end

function PET_UI_UPDATE(self)
	return handler:Refresh(RefreshActionButton)
end

function UPDATE_VEHICLE_ACTIONBAR(self)
	return handler:Refresh(RefreshActionButton)
end

function UNIT_AURA(self, unit)
	if unit == "pet" then
		return handler:Refresh(RefreshActionButton)
	end
end

function PET_BAR_UPDATE_COOLDOWN(self)
	return handler:Refresh(RefreshCooldown)
end

function PET_BAR_UPDATE_USABLE(self)
	return handler:Refresh(RefreshUsable)
end

-- Pet action type handler
handler = ActionTypeHandler {
	Type = "pet",

	Action = "action",

	DragStyle = "Keep",

	ReceiveStyle = "Keep",

	InitSnippet = [[
	]],

	PickupSnippet = [[
		return "petaction", ...
	]],

	UpdateSnippet = [[
		local target = ...

		if tonumber(target) then
			-- Use macro to toggle auto cast
			self:SetAttribute("type2", "macro")
			self:SetAttribute("macrotext2", "/click PetActionButton".. target .. " RightButton")
		end
	]],

	ReceiveSnippet = [[
	]],

	ClearSnippet = [[
		self:SetAttribute("type2", nil)
		self:SetAttribute("macrotext2", nil)
	]],
}

-- Overwritde methods
function handler:PickupAction(target)
	return PickupPetAction(target)
end

function handler:HasAction()
	return GetPetActionInfo(self.ActionTarget) and true
end

function handler:GetActionTexture()
	local name, _, texture, isToken = GetPetActionInfo(self.ActionTarget)
	if name then
		return isToken and _G[texture] or texture
	end
end

function handler:GetActionCooldown()
	return GetPetActionCooldown(self.ActionTarget)
end

function handler:IsUsableAction()
	return GetPetActionSlotUsable(self.ActionTarget)
end

function handler:IsActivedAction()
	return select(5, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCastAction()
	return select(6, GetPetActionInfo(self.ActionTarget))
end

function handler:IsAutoCasting()
	return select(7, GetPetActionInfo(self.ActionTarget))
end

function handler:SetTooltip(GameTooltip)
	GameTooltip:SetPetAction(self.ActionTarget)
end