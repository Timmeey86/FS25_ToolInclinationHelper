---This class is responsible for rendering an indicator for the tool inclination into the HUD
---@class ToolInclinationHUD
---@field speedMeter SpeedMeterDisplay @The base game speed meter
---@field uvFile string @The file name for the UV file
---@field iconBox table @The overlay box which displays the leveling icon, consisting of the background and the optional other icons
---@field lineElement HUDElement @The element which displays the "level" line
---@field upArrowElement HUDElement @The element which displays the upwards facing arrow
---@field downArrowElement HUDElement @The element which displays the downwards facing arrow
ToolInclinationHUD = {
	-- Define the size of things in the UI, based on full HD
	OVERLAY_SIZES = {
		BG = { 32, 32 },
		LINE = { 24, 3 },
		ARROWS = { 18, 18 }
	},
	-- Define positions of things relative to the reference point
	POSITIONS = {
		BG = { 0, 0 },
		LINE = { 4, 14 },
		UPARROW = { 7, 8 },
		DOWNARROW = { 7, 6 }
	},
	-- Define the dimensions of things in the .dds file (x/y/width/height)
	UV_DIMENSIONS = {
		BG = { 0, 0, 32, 32 },
		LINE =  { 32, 25, 24, 3},
		UPARROW = { 32, 0, 24, 24 },
		DOWNARROW = { 56, 0, 24, 24 }
	},
	-- Define colors of things
	COLORS = {
		BG = { 0, 0, 0, 0.5 },
		LINE = { .2, 1.0, .2, 1 },
		ARROWS = { 1.0, 0.5, 0, 1 }
	}
}
-- Make this a subclass of base game HUDDisplayElement
local ToolInclinationHUD_mt = Class(ToolInclinationHUD, HUDDisplayElement)

---Creates a new HUD for the ToolInclination mod
---@param speedMeter SpeedMeterDisplay @The base game display for the speed meter
---@param modDirectory string @The current mod directory
---@return ToolInclinationHUD @The new instance
function ToolInclinationHUD.new(speedMeter, modDirectory)
	local self = setmetatable({}, ToolInclinationHUD_mt)
	self.speedMeter = speedMeter
	self.uvFile = Utils.getFilename("resources/FS25_ToolInclinationHelper_uv.dds", modDirectory)
	return self
end

function ToolInclinationHUD:createElement(position, size, uvDimensions, colors)
	local x, y = self.speedMeter:scalePixelValuesToScreenVector(table.unpack(position))
	local width, height = self.speedMeter:scalePixelValuesToScreenVector(table.unpack(size))
	local overlay = Overlay.new(self.uvFile, x, y, width, height)
	overlay.isVisible = true
	local element = HUDElement.new(overlay)
	element:setUVs(GuiUtils.getUVs(uvDimensions))
	element:setColor(table.unpack(colors))
	return element
end

function ToolInclinationHUD:load()

	-- Create a box for the icon background
	self.iconBox = self:createElement(
		ToolInclinationHUD.POSITIONS.BG,
		ToolInclinationHUD.OVERLAY_SIZES.BG,
		ToolInclinationHUD.UV_DIMENSIONS.BG,
		ToolInclinationHUD.COLORS.BG)

	-- Create an icon to represent the "level" condition
	self.lineElement = self:createElement(
		ToolInclinationHUD.POSITIONS.LINE,
		ToolInclinationHUD.OVERLAY_SIZES.LINE,
		ToolInclinationHUD.UV_DIMENSIONS.LINE,
		ToolInclinationHUD.COLORS.LINE)
	self.iconBox:addChild(self.lineElement)

	-- Create an icon to represent the "tilted downwards" condition
	self.downArrowElement = self:createElement(
		ToolInclinationHUD.POSITIONS.DOWNARROW,
		ToolInclinationHUD.OVERLAY_SIZES.ARROWS,
		ToolInclinationHUD.UV_DIMENSIONS.DOWNARROW,
		ToolInclinationHUD.COLORS.ARROWS)
	self.iconBox:addChild(self.downArrowElement)

	-- Create an icon to represent the "tilted upwards" condition
	self.upArrowElement = self:createElement(
		ToolInclinationHUD.POSITIONS.UPARROW,
		ToolInclinationHUD.OVERLAY_SIZES.ARROWS,
		ToolInclinationHUD.UV_DIMENSIONS.UPARROW,
		ToolInclinationHUD.COLORS.ARROWS)
	self.iconBox:addChild(self.upArrowElement)

	self.lineElement:setVisible(false)
	self.downArrowElement:setVisible(false)
	self.upArrowElement:setVisible(false)
	self.iconBox:setVisible(false)
end

function ToolInclinationHUD:drawHUD()
	if self.iconBox ~= nil then
		self.iconBox:setPosition(self.speedMeter.speedBg.x, self.speedMeter.speedBg.y)
	end
	self.iconBox.overlay:render()
	self.downArrowElement.overlay:render()
	self.upArrowElement.overlay:render()
	self.lineElement.overlay:render()
end

function ToolInclinationHUD:setState(isVisible, direction)
	self.iconBox:setVisible(isVisible)
	self.lineElement:setVisible(isVisible and direction == 0)
	self.upArrowElement:setVisible(isVisible and direction > 0)
	self.downArrowElement:setVisible(isVisible and direction < 0)
end