---Helper class which stores coordinates
---@class UICoordinates
---@field xOffset number @the X offset in pixels
---@field yOffset number @the Y offset in pixels
UICoordinates = {}

---This class is reponsible for storing settings for the ToolInclinationHelper at runtime
---@class TIHSettings
---@field displayMode number @1 for "icons", 2 for "numbers"
---@field colorCoding boolean @True if numbers shall be colored
---@field invertArrows boolean @True if the up/down icons shall be inverted
---@field baseLocation UICoordinates @The point of reference for the location of the UI icons
TIHSettings = {
	DISPLAY_MODES = {
		ICONS = 1,
		NUMBERS = 2
	}
}
local TIHSettings_mt = Class(TIHSettings)

---Creates a new settings instance
---@return TIHSettings @the new instance
function TIHSettings.new()
	local self = setmetatable({}, TIHSettings_mt)
	self.baseLocation = {
		xOffset = 0,
		yOffset = 0
	}
	self.displayMode = TIHSettings.DISPLAY_MODES.NUMBERS
	self.colorCoding = true
	self.invertArrows = false
	return self
end

-- Retrieves the base location in relative screen coordinates (0..1)
---@param speedMeter SpeedMeterDisplay @The base game speed dial
---@return number @The X coordinate in relative coordinates
---@return number @The Y coordinate in relative coordinates
function TIHSettings:getRelativeBaseLocation(speedMeter)
	local xOff, yOff = speedMeter:scalePixelValuesToScreenVector(self.baseLocation.xOffset, self.baseLocation.yOffset)
	return speedMeter.speedBg.x + xOff, speedMeter.speedBg.y + yOff
end

---Convenience function for checking if icons shall be displayed instead of numbers
---@return boolean @True if icons shall be displayed
function TIHSettings:iconsShallBeDisplayed()
	return self.displayMode == TIHSettings.DISPLAY_MODES.ICONS
end

---Convenience function for checking if numbers shall be displayed instead of icons
---@return boolean @True if numbers shall be displayed
function TIHSettings:numbersShallBeDisplayed()
	return self.displayMode == TIHSettings.DISPLAY_MODES.NUMBERS
end