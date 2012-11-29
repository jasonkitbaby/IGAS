-- Author      : Kurapica
-- Create Date : 8/22/2008 23:25
-- ChangeLog   :
--              1/04/2009 the Container's Height can't be less then the frame
--              2010/02/16 Remove the back
--              2010/02/22 Add FixHeight to Container
--				2011/03/13	Recode as class

---------------------------------------------------------------------------------------------------------------------------------------
--- ScrollForm is a widget type using as a scrollable container.
-- <br><br>inherit <a href="..\Base\ScrollFrame.html">ScrollFrame</a> For all methods, properties and scriptTypes
-- @name ScrollForm
-- @class table
-- @field Container the scrollform's container, using to contain other frames.
-- @field ValueStep the minimum increment between allowed slider values
-- @field Value the value representing the current position of the slider thumb
-- @field AutoHeight true if the height of the container would be auto-adjust
---------------------------------------------------------------------------------------------------------------------------------------

-- Check Version
local version = 8
if not IGAS:NewAddon("IGAS.Widget.ScrollForm", version) then
	return
end

class "ScrollForm"
	inherit "ScrollFrame"

    -- Scripts
    _FrameBackdrop = {
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 9,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    }

	local function OnValueChanged(self, value)
        local frame, container = self.Parent, self.Parent:GetChild("Container")
		local viewheight, height = frame.Height, container.Height
		local offset = value

		if viewheight > height then
			offset = 0
		elseif offset > height - viewheight then
			offset = height - viewheight
		end

		container:ClearAllPoints()
		container:SetPoint("TOPLEFT",frame,"TOPLEFT",0,offset)
		container:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,offset)
	end

	local OnSizeChanged

	local function ConvertPos(point)
		if strfind(strupper(point), "BOTTOM") then
			return 1
		elseif strfind(strupper(point), "TOP") then
			return -1
		else
			return 0
		end
	end

	local function GetPos(frame, _Frame, _Center)
		local point, relativeTo, relativePoint, xOfs, yOfs
		local dx, dxp

		_Center[frame] = _Center[frame] or 0

		for i = 1, frame:GetNumPoints() do
			point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(i)

			if _Frame[relativeTo] then
				if not _Center[relativeTo] then
					GetPos(relativeTo, _Frame, _Center)
				end

				dx = ConvertPos(point)
				dxp = ConvertPos(relativePoint)

				if dx == -1 or _Center[frame] == 0 then
					_Center[frame] = _Center[relativeTo] + dxp * (relativeTo.Height / 2) - yOfs - dx * (frame.Height / 2)
				end
			end
		end
	end

	local function DoFixHeight(self)
		local _Frame = {}
		local _Center = {}
		local _MaxHeight = 0
		local h

		_Frame[self] = true
		_Center[self] = self.Height / 2

		for i, v in pairs(self:GetChilds()) do
			if v.GetPoint and v.Visible then
				_Frame[v] = true
			end
		end

		for i in pairs(_Frame) do
			if not _Center[i] then
				GetPos(i, _Frame, _Center)
			end
		end

		for i, v in pairs(_Center) do
			if i ~= self then
				h = v + i.Height / 2
				_MaxHeight = (_MaxHeight > h and _MaxHeight) or h
			end
		end

		self.Height = _MaxHeight
	end

	local function FixScroll(self)
		self:GetChild("Container").OnSizeChanged = self:GetChild("Container").OnSizeChanged - OnSizeChanged

		if self.__AutoHeight then
			DoFixHeight(self:GetChild("Container"))
		end

		local bar = self:GetChild("Bar")
		local viewheight, height = self.Height, self:GetChild("Container").Height
		local curvalue = bar.Value

		if viewheight >= height then
			if self.__AutoHeight then
				self:GetChild("Container").Height = viewheight
			end
			bar:SetValue(0)
            bar:Disable()
			bar:Hide()
		else
			local maxValue = height - viewheight
            if curvalue > maxValue then curvalue = maxValue end
            bar:SetMinMaxValues(0,maxValue)
			bar:SetValue(curvalue)
            bar:Enable()
			bar:Show()
		end

		self:GetChild("Container").OnSizeChanged = self:GetChild("Container").OnSizeChanged + OnSizeChanged
	end

    local function OnMouseWheel(self, delta)
        local scrollBar = self:GetChild("Bar")
		local minV, maxV = scrollBar:GetMinMaxValues()

        if (delta > 0 ) then
			if scrollBar.Value - (scrollBar.Height / 2) >= minV then
				scrollBar.Value = scrollBar.Value - (scrollBar.Height / 2)
			else
				scrollBar.Value = minV
			end
        else
			if scrollBar.Value + (scrollBar.Height / 2) <= maxV then
				scrollBar.Value = scrollBar.Value + (scrollBar.Height / 2)
			else
				scrollBar.Value = maxV
			end
        end
    end

    OnSizeChanged =  function(self)
        return FixScroll(self.Parent)
    end

	local function OnUpdate_Init(self)
		self:FixHeight()
		if self.Container.Height > 0 then
			self.OnUpdate = self.OnUpdate - OnUpdate_Init
		end
	end

	local function OnTimer(self)
		FixScroll(self.Parent)
	end

	local function Container_FixHeight(self)
		self.Parent:FixHeight()
	end

	------------------------------------------------------
	-- Script
	------------------------------------------------------

	------------------------------------------------------
	-- Method
	------------------------------------------------------
	------------------------------------
	--- Adjust the container's height, using when you add, remove or modify some frames
	-- @name ScrollForm:FixHeight
	-- @class function
	-- @usage ScrollForm:FixHeight()
	------------------------------------
	function FixHeight(self)
		local flg = self.__AutoHeight
		self.__AutoHeight = true
		FixScroll(self)
		self.__AutoHeight = flg
	end

	-- Override Getheight & GetWidth
	function GetHeight(self)
		return self:GetChild("Bar"):GetHeight()
	end

	function GetWidth(self)
		return self:GetChild("Container").Width + 18
	end

	------------------------------------------------------
	-- Property
	------------------------------------------------------
	-- Container
	property "Container" {
		Get = function(self)
			return self:GetChild("Container")
		end,
	}
	-- ValueStep
	property "ValueStep" {
		Set = function(self, value)
			if value > 1 then
				self:GetChild("Bar").ValueStep = value
			else
				self:GetChild("Bar").ValueStep = 1
			end
		end,

		Get = function(self)
			return self:GetChild("Bar").ValueStep
		end,

		Type = Number,
	}
	-- Value
	property "Value" {
		Set = function(self, value)
			self:GetChild("Bar").Value = value
		end,

		Get = function(self)
			return self:GetChild("Bar").Value
		end,

		Type = Number,
	}
	-- AutoHeight
	property "AutoHeight" {
		Set = function(self, auto)
			self.__AutoHeight = (auto and true) or false
			if self.__AutoHeight then
				local timer = Timer("AutoTimer", self)
				timer.OnTimer = OnTimer
				timer.Interval = 2
			else
				if self.AutoTimer then
					self.AutoTimer:Dispose()
				end
			end
		end,

		Get = function(self)
			return (self.__AutoHeight and true) or false
		end,

		Type = Boolean,
	}

	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
    function ScrollForm(name, parent)
		local frame = ScrollFrame(name, parent)
        frame:SetBackdrop(_FrameBackdrop)
		frame:SetBackdropColor(0, 0, 0)
		frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
        frame.MouseWheelEnabled = true
		frame.MouseEnabled = true

        local slider = ScrollBar("Bar", frame)
        slider:SetMinMaxValues(0,0)
        slider.Value = 0
        slider.ValueStep = 10

        local container = Frame("Container", frame)
        frame:SetScrollChild(container)
		container:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		container:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-18,0)
		container.FixHeight = Container_FixHeight

        frame.OnMouseWheel = frame.OnMouseWheel + OnMouseWheel
        slider.OnSizeChanged = OnSizeChanged
        slider.OnValueChanged = OnValueChanged
        container.OnSizeChanged = container.OnSizeChanged + OnSizeChanged

		frame.__AutoHeight = false

		-- Don't move this code
		slider.Value = 10
		slider.Value = 0

		frame.OnUpdate = frame.OnUpdate + OnUpdate_Init

        return frame
    end
endclass "ScrollForm"