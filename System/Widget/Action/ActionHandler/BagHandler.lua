-- Author      : Kurapica
-- Create Date : 2013/11/25
-- Change Log  :

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Action.BagHandler", version) then
	return
end

_Enabled = false

_BagSlotMapTemplate = "_BagSlotMap[%d] = %d"

_BagSlotMap = {
	[0] = "BackSlot",
	"Bag0Slot",
	"Bag1Slot",
	"Bag2Slot",
	"Bag3Slot",
}

function OnEnable(self)
	self:RegisterEvent("ITEM_LOCK_CHANGED")
	self:RegisterEvent("CURSOR_UPDATE")

	self:RegisterEvent("BAG_UPDATE_DELAYED")
	self:RegisterEvent("INVENTORY_SEARCH_UPDATE")

	local cache = {}
	for i, slot in pairs(_BagSlotMap) do
		local id, texture = GetInventorySlotInfo(slot)
		_BagSlotMap[i] = { id = id, texture = texture, slot = slot }
		tinsert(cache, _BagSlotMapTemplate:format(i, id))
	end

	if next(cache) then
		Task.NoCombatCall(function ()
			handler:RunSnippet( tblconcat(cache, ";") )

			for _, btn in handler() do
				local target = tonumber(btn.ActionTarget)

				if target == 0 then
					btn:SetAttribute("*type*", "macro")
					btn:SetAttribute("*macrotext*", "/click MainMenuBarBackpackButton")
				elseif target and target <= 4 then
					btn:SetAttribute("*type*", "macro")
					btn:SetAttribute("*macrotext*", "/click CharacterBag".. tostring(target-1) .."Slot")
				else
					btn:SetAttribute("*type*", nil)
					btn:SetAttribute("*macrotext*", nil)
				end
			end

			handler:Refresh()
		end)
	end

	OnEnable = nil
end

function ITEM_LOCK_CHANGED(self, bag, slot)
	if not slot then
		for i, map in pairs(_BagSlotMap) do
			if map.id == bag then
				local flag = IsInventoryItemLocked(bag)
				for _, btn in handler() do
					if btn.ActionTarget == i then btn.IconLocked = flag end
				end
				break
			end
		end
	end
end

function CURSOR_UPDATE(self)
	for _, btn in handler() do
		local target = _BagSlotMap[self.ActionTarget]
		if target then
			btn.HighlightLocked = CursorCanGoInSlot(target.id)
		end
	end
end

function BAG_UPDATE_DELAYED(self)
	for _, btn in handler() do
		handler:Refresh(btn)
		local target = _BagSlotMap[btn.ActionTarget]
		if target then
			btn.IconLocked = IsInventoryItemLocked(target.id)
		end
	end
end

function INVENTORY_SEARCH_UPDATE(self)
	for _, btn in handler() do
		btn.ShowSearchOverlay = IsContainerFiltered(self.ActionTarget)
	end
end

handler = ActionTypeHandler {
	Name = "bag",
	DragStyle = "Keep",
	ReceiveStyle = "Keep",
	InitSnippet = [[ _BagSlotMap = newtable() ]],
	PickupSnippet = [[
		return "clear", "bag", _BagSlotMap[...]
	]],
	ReceiveSnippet = "Custom",
	UpdateSnippet = [[
		local target = ...
		target = tonumber(target)

		if target == 0 then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/click MainMenuBarBackpackButton")
		elseif target and target <= 4 then
			self:SetAttribute("*type*", "macro")
			self:SetAttribute("*macrotext*", "/click CharacterBag".. tostring(target-1) .."Slot")
		else
			self:SetAttribute("*type*", nil)
			self:SetAttribute("*macrotext*", nil)
		end
	]],
	ClearSnippet = [[
		self:SetAttribute("*type*", nil)
		self:SetAttribute("*macrotext*", nil)
	]],
	OnEnableChanged = function(self) _Enabled = self.Enabled end,
}

-- Overwrite methods
function handler:ReceiveAction(target, detail)
	if target == 0 then
		return PutItemInBackpack()
	elseif target and target <= 4 then
		return PutItemInBag(target)
	end
end

function handler:HasAction()
	return _BagSlotMap[self.ActionTarget] and true or false
end

function handler:GetActionTexture()
	local target = _BagSlotMap[self.ActionTarget]
	return target and GetInventoryItemTexture("player", target.id) or target.texture
end

function handler:IsConsumableAction()
	return true
end

function handler:GetActionCount()
	local target = _BagSlotMap[self.ActionTarget]
	if self.ShowEmptySpace then
		return target and GetInventoryItemCount("player", target.id)
	else
		return target and (GetContainerNumSlots(self.ActionTarget) - GetInventoryItemCount("player", target.id))
	end
end

function handler:IsActivedAction()
	-- Simple solution, need a better plan if support custom containers
	local translatedID = self.ActionTarget
	for i=1, NUM_CONTAINER_FRAMES do
		local frame = _G["ContainerFrame"..i]
		if frame:GetID() == translatedID then
			return frame:IsShown()
		end
	end
end

function handler:SetTooltip(GameTooltip)
	local target = self.ActionTarget
	if _BagSlotMap[target] then
		local id = _BagSlotMap[target].id
		if ( GameTooltip:SetInventoryItem("player", id) ) then
			local bindingKey = GetBindingKey("TOGGLEBAG"..(5 -  target))
			if ( bindingKey ) then
				GameTooltip:AppendText(" "..NORMAL_FONT_COLOR_CODE.."("..bindingKey..")"..FONT_COLOR_CODE_CLOSE);
			end
			if (not IsInventoryItemProfessionBag("player", ContainerIDToInventoryID(target))) then
				for i = LE_BAG_FILTER_FLAG_EQUIPMENT, NUM_LE_BAG_FILTER_FLAGS do
					if ( GetBagSlotFlag(target, i) ) then
						GameTooltip:AddLine(BAG_FILTER_ASSIGNED_TO:format(BAG_FILTER_LABELS[i]))
						break
					end
				end
			end
			GameTooltip:Show()
		else
			GameTooltip:SetText(EQUIP_CONTAINER, 1.0, 1.0, 1.0)
		end
	end
end

-- Expand IFActionHandler
interface "IFActionHandler"
	__Local__() __Default__(0)
	struct "BagSlot" {
		function (value)
			assert(type(value) == "number", "%s must be number.")
			assert(value >= 0 and value <= 4, "%s must between [0-4]")
			return math.floor(value)
		end
	}

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	__Doc__[[The action button's content if its type is 'bag']]
	property "BagSlot" {
		Get = function(self)
			return self:GetAttribute("actiontype") == "bag" and tonumber(self:GetAttribute("bag"))
		end,
		Set = function(self, value)
			self:SetAction("bag", value)
		end,
		Type = BagSlot,
	}

	__Doc__[[Whether the search overlay will be shown]]
	property "ShowSearchOverlay" { Type = Boolean }

	__Doc__[[Whether only show the empty space]]
	property "ShowEmptySpace" { Type = Boolean }
endinterface "IFActionHandler"