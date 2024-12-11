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
	self.baseLocation = {
		x = 0,
		y = 0
	}
	return self
end

---Initializes the settings object with default values
---@param speedMeter SpeedMeterDisplay @The base game speed dial
function TIHSettings:init(speedMeter)
	self.baseLocation.x, self.baseLocation.y = speedMeter:scalePixelValuesToScreenVector(table.unpack(ToolInclinationHUD.POSITIONS.BG))
end
