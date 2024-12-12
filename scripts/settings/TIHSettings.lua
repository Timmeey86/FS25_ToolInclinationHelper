---Helper class which stores coordinates
---@class UICoordinates
---@field x number @the X coordinate
---@field y number @the Y coordinate
UICoordinates = {}

---This class is reponsible for storing settings for the ToolInclinationHelper at runtime
---@class TIHSettings
---@field baseLocation UICoordinates @The point of reference for the location of the UI icons
TIHSettings = {}
local TIHSettings_mt = Class(TIHSettings)

---Creates a new settings instance
---@return TIHSettings @the new instance
function TIHSettings.new()
	local self = setmetatable({}, TIHSettings_mt)
	-- Location of the speedmeter in version 1.3.0.0 (roughly)
	self.baseLocation = {
		x = 1560,
		y = 30
	}
	return self
end

-- Retrieves the base location in relative screen coordinates (0..1)
---@param speedMeter SpeedMeterDisplay @The base game speed dial
---@return number @The X coordinate in relative coordinates
---@return number @The Y coordinate in relative coordinates
function TIHSettings:getRelativeBaseLocation(speedMeter)
	return speedMeter.speedBg.x, speedMeter.speedBg.y
end