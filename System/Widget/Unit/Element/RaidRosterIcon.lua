﻿-- Author      : Kurapica
-- Create Date : 2012/06/25
-- Change Log  :

----------------------------------------------------------------------------------------------------------------------------------------
--- RaidRosterIcon
-- <br><br>inherit <a href="..\Base\Texture.html">Texture</a> For all methods, properties and scriptTypes
-- @name RaidRosterIcon
----------------------------------------------------------------------------------------------------------------------------------------

-- Check Version
local version = 1
if not IGAS:NewAddon("IGAS.Widget.Unit.RaidRosterIcon", version) then
	return
end

class "RaidRosterIcon"
	inherit "Texture"
	extend "IFRaidRoster"
	
	------------------------------------------------------
	-- Constructor
	------------------------------------------------------
	function RaidRosterIcon(...)
		local icon = Super(...)

		icon.Height = 16
		icon.Width = 16

		return icon
	end
endclass "RaidRosterIcon"