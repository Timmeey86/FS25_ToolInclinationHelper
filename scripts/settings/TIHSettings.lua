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
	-- Convert the relative locations of the speed dial which range from 0..1, 0..1 back to a pixel value for full HD resolution
	self.baseLocation.x, self.baseLocation.y =
		speedMeter.speedBg.x / speedMeter.uiScale / g_aspectScaleX * g_referenceScreenWidth,
		speedMeter.speedBg.y / speedMeter.uiScale / g_aspectScaleY * g_referenceScreenHeight
	printf("%s: Initialized base location from %.5f, %.5f to %d, %d", MOD_NAME, speedMeter.speedBg.x, speedMeter.speedBg.y, self.baseLocation.x, self.baseLocation.y)
end

-- Retrieves the base location in relative screen coordinates (0..1)
---@param speedMeter SpeedMeterDisplay @The base game speed dial
---@return number @The X coordinate in relative coordinates
---@return number @The Y coordinate in relative coordinates
function TIHSettings:getRelativeBaseLocation(speedMeter)
	return speedMeter:scalePixelValuesToScreenVector(self.baseLocation.x, self.baseLocation.y)
end