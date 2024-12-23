---This class is responsible for rendering an indicator for the tool inclination into the HUD
---@class ToolInclinationHUD
---@field speedMeter SpeedMeterDisplay @The base game speed meter
---@field uvFile string @The file name for the UV file
---@field iconBox HUDElement @The overlay box which displays the leveling icon, consisting of the background and the optional other icons
---@field lineElement HUDElement @The element which displays the "level" line
---@field upArrowElement HUDElement @The element which displays the upwards facing arrow
---@field downArrowElement HUDElement @The element which displays the downwards facing arrow
---@field distanceBox HUDElement @The overlay box with the background for displaying the distance of the tool to the ground
---@field distanceTextElement HUDElement @The element which displays the distance to the ground
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
		INCLINATION_TEXT = { 16, 18 }, -- relative to BG
		LINE = { 4, 14 },
		UPARROW = { 7, 8 },
		DOWNARROW = { 7, 6 },
		DISTANCE_BG = { -35, 0 },
		DISTANCE_TEXT = { 16, 18 } -- relative to DISTANCE_BG
	},
	-- Define the dimensions of things in the .dds file (x/y/width/height)
	UV_DIMENSIONS = {
		BG = { 0, 0, 32, 32 },
		LINE =  { 33, 25, 24, 3},
		UPARROW = { 33, 0, 24, 24 },
		DOWNARROW = { 57, 0, 24, 24 }
	},
	-- Define colors of things
	COLORS = {
		BG = { 0, 0, 0, 0.8 },
		LEVEL = { .0, 1, .0, 1.0 },
		UPWARDS = { .1, .1, .4, 1.0 },
		DOWNWARDS = { .4, .1, .1, 1.0 },
		TEXT = { 1.0, 1.0, 1.0, 1.0}
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

---Creates an HUD element with the given parameters
---@param position table @Contains the X/Y coordinate of the element in pixels
---@param size table @Contains the width/height of the element in pixels
---@param uvDimensions table|nil @Contains x/y/width/height of the area in the DDS file to read from (optional)
---@param colors table @Contains the RGBA values for the element
---@return HUDElement @The created element
function ToolInclinationHUD:createElement(position, size, uvDimensions, colors)
	local x, y = self.speedMeter:scalePixelValuesToScreenVector(table.unpack(position))
	local width, height = self.speedMeter:scalePixelValuesToScreenVector(table.unpack(size))
	local overlay = Overlay.new(self.uvFile, x, y, width, height)
	overlay.isVisible = true
	local element = HUDElement.new(overlay)
	if uvDimensions then
		element:setUVs(GuiUtils.getUVs(uvDimensions))
	end
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
		ToolInclinationHUD.COLORS.LEVEL)
	self.iconBox:addChild(self.lineElement)

	-- Create an icon to represent the "tilted downwards" condition
	self.downArrowElement = self:createElement(
		ToolInclinationHUD.POSITIONS.DOWNARROW,
		ToolInclinationHUD.OVERLAY_SIZES.ARROWS,
		ToolInclinationHUD.UV_DIMENSIONS.DOWNARROW,
		ToolInclinationHUD.COLORS.UPWARDS)
	self.iconBox:addChild(self.downArrowElement)

	-- Create an icon to represent the "tilted upwards" condition
	self.upArrowElement = self:createElement(
		ToolInclinationHUD.POSITIONS.UPARROW,
		ToolInclinationHUD.OVERLAY_SIZES.ARROWS,
		ToolInclinationHUD.UV_DIMENSIONS.UPARROW,
		ToolInclinationHUD.COLORS.DOWNWARDS)
	self.iconBox:addChild(self.upArrowElement)

	self.lineElement:setVisible(false)
	self.downArrowElement:setVisible(false)
	self.upArrowElement:setVisible(false)
	self.iconBox:setVisible(false)

	-- Create the background for displaying the distance to the ground
	self.distanceBox = self:createElement(
		ToolInclinationHUD.POSITIONS.DISTANCE_BG,
		ToolInclinationHUD.OVERLAY_SIZES.BG,
		ToolInclinationHUD.UV_DIMENSIONS.BG,
		ToolInclinationHUD.COLORS.BG)
	self.distanceText =  {
		text = "-",
		size = self.speedMeter:scalePixelToScreenWidth(20)
	}
	self.inclinationText = {
		text = "",
		size = self.speedMeter:scalePixelToScreenWidth(30)
	}

	self.distanceBox:setVisible(false)
	self.iconBox:setVisible(false)
end

function ToolInclinationHUD:setScaledPos(element, relativePixelPos)
	local xRel, yRel = self.speedMeter:scalePixelValuesToScreenVector(table.unpack(relativePixelPos))
	local baseX, baseY = ToolInclinationHelper.settings:getRelativeBaseLocation(self.speedMeter)
	element:setPosition(baseX + xRel, baseY + yRel)
end

function ToolInclinationHUD:drawHUD()

	-- We center our texts and specify the desired middle as the position. That way, the engine will perfectly center the text within the background circles
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	setTextBold(false)

	if self.iconBox.overlay:getIsVisible() then
		self:setScaledPos(self.iconBox, ToolInclinationHUD.POSITIONS.BG)
		self.iconBox.overlay:render()

		if ToolInclinationHelper.settings:numbersShallBeDisplayed() then
			if ToolInclinationHelper.settings.colorCoding then
				if self.inclinationText.inclination < -1 then
					setTextColor(table.unpack(ToolInclinationHUD.COLORS.DOWNWARDS))
				elseif self.inclinationText.inclination > 1 then
					setTextColor(table.unpack(ToolInclinationHUD.COLORS.UPWARDS))
				else
					setTextColor(table.unpack(ToolInclinationHUD.COLORS.LEVEL))
				end
			else
				setTextColor(table.unpack(ToolInclinationHUD.COLORS.TEXT))
			end
			local xPixel, yPixel =
				ToolInclinationHUD.POSITIONS.BG[1] + ToolInclinationHUD.POSITIONS.INCLINATION_TEXT[1],
				ToolInclinationHUD.POSITIONS.BG[2] + ToolInclinationHUD.POSITIONS.INCLINATION_TEXT[2]
			local xRel, yRel = self.speedMeter:scalePixelValuesToScreenVector(xPixel, yPixel)
			local baseX, baseY = ToolInclinationHelper.settings:getRelativeBaseLocation(self.speedMeter)
			renderText(baseX + xRel, baseY + yRel, self.inclinationText.size, self.inclinationText.text)
		else
			self.downArrowElement.overlay:render()
			self.upArrowElement.overlay:render()
			self.lineElement.overlay:render()
		end
	end


	if self.distanceBox.overlay:getIsVisible() then
		self:setScaledPos(self.distanceBox, ToolInclinationHUD.POSITIONS.DISTANCE_BG)
		self.distanceBox.overlay:render()

		-- Center the text in the distance box
		setTextColor(table.unpack(ToolInclinationHUD.COLORS.TEXT))
		local xPixel, yPixel = 
			ToolInclinationHUD.POSITIONS.DISTANCE_BG[1] + ToolInclinationHUD.POSITIONS.DISTANCE_TEXT[1],
			ToolInclinationHUD.POSITIONS.DISTANCE_BG[2] + ToolInclinationHUD.POSITIONS.DISTANCE_TEXT[2]
		local xRel, yRel = self.speedMeter:scalePixelValuesToScreenVector(xPixel, yPixel)
		local baseX, baseY = ToolInclinationHelper.settings:getRelativeBaseLocation(self.speedMeter)
		renderText(baseX + xRel, baseY + yRel, self.distanceText.size, self.distanceText.text)
	end

	-- Reset to default values so mods which don't explicilty set these four attributes don't get influenced by our mod
	setTextColor(1,1,1,1)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
	setTextBold(false)
end

function ToolInclinationHUD:setState(isVisible, inclination, distanceToGround)
	self.iconBox:setVisible(isVisible)

	local iconsShallBeDisplayed = ToolInclinationHelper.settings:iconsShallBeDisplayed()
	-- Figure out which icon to display
	local displayLine, displayUpArrow, displayDownArrow = false, false, false
	if isVisible and iconsShallBeDisplayed then
		if inclination <= -1 then
			displayDownArrow = ToolInclinationHelper.settings.invertArrows
			displayUpArrow = not displayDownArrow
		elseif inclination >= 1 then
			displayUpArrow = ToolInclinationHelper.settings.invertArrows
			displayDownArrow = not displayUpArrow
		else
			displayLine = true
		end
	-- else: not visible, or numbers are displayed instead of icons
	end

	self.lineElement:setVisible(displayLine)
	self.upArrowElement:setVisible(displayUpArrow)
	self.downArrowElement:setVisible(displayDownArrow)

	self.distanceBox:setVisible(isVisible)

	self.distanceText.text = ("%.1f %s"):format(distanceToGround or 0, g_i18n:getText("unit_mShort"))
	self.inclinationText.text = ("%d"):format(inclination and math.abs(inclination) or 0)
	self.inclinationText.inclination = inclination
end