---This class is responsible for finding forks or similar tools attached to the player vehicle
---@class ToolFinder
ToolFinder = {}
local ToolFinder_mt = Class(ToolFinder)

---Creates a new instance of the ToolFinder
---@param settings TIHSettings @The settings object which stores reference orientations
---@return ToolFinder @The new instance
function ToolFinder.new(settings)
	local self = setmetatable({}, ToolFinder_mt)
	self.settings = settings
	return self
end

local supportedCategories = {}
supportedCategories["teleLoaderTools"] = true
supportedCategories["wheelLoaderTools"] = true
supportedCategories["skidSteerTools"] = true
supportedCategories["frontLoaderTools"] = true

---Tries finding a supported tool somewhere in the or attached to the given vehicle.
---If reference settings were stored for the tool, they will be applied in here as well.
---@param vehicle Vehicle @The vehicle to search in
---@return table|nil @The found tool or nil if no tool was found
function ToolFinder:findSupportedTool(vehicle)
	local tool = ToolFinder.searchForSupportedToolIn(vehicle)
	if tool and (tool.rootNode or tool.node) then
		if not tool.referenceIdentifier then
			tool.referenceIdentifier = ToolReferenceOrientationHandler.buildVehicleIdentifier(tool, vehicle)
			if self.settings.referenceSettings[tool.referenceIdentifier] ~= nil then
				-- Restore reference info from XML or from identical tools
				tool.referenceInclination = self.settings.referenceSettings[tool.referenceIdentifier].inclination
				tool.referenceGroundDistance = self.settings.referenceSettings[tool.referenceIdentifier].groundDistance
			end
		end
		return tool
	end
	return nil
end

---Tries finding a supported tool somewhere in the or attached to the given vehicle. Don't call this directly, use findSupportedTool instead.
---@param vehicle Vehicle @The vehicle to search in
---@return table|nil @The found tool or nil if no tool was found
function ToolFinder.searchForSupportedToolIn(vehicle)
	if not vehicle then return nil end
	local category = getXMLString(vehicle.xmlFile.handle, "vehicle.storeData.category")
	if not category then return nil end

	-- Special case: Forklifts: The forks are a component rather than an attached implement
	if category == "forklifts" then
		local forkComponent = ToolFinder.findForkliftForks(vehicle)
		if forkComponent then
			return forkComponent
		end
		-- Else: No fork components found. The forklift might actually be something else like a skid steer in disguise => Keep searching
	end

	-- Find the first attachment which is within the given tool categories
	local attacherSpec = vehicle.spec_attacherJoints
	if not attacherSpec then return nil end

	for _, implement in pairs(attacherSpec.attachedImplements) do
		if implement.object ~= nil then
			category = getXMLString(implement.object.xmlFile.handle, "vehicle.storeData.category")
			if supportedCategories[category] then
				-- Tool found, return the tool
				return implement.object
			else
				local furtherImplement = ToolFinder.findSupportedTool(implement.object)
				if furtherImplement then
					-- This finds front loader attachments which are connected to separate front loader arms on tractors
					return furtherImplement
				end
			end

			-- Another special case: 3 point forks
			if implement.object.typeName == "dynamicMountAttacherFork" then
				return ToolFinder.findForkliftForks(implement.object)
			end
		end
	end

	-- Nothing was found
	return nil
end

---Tries finding the forks of the forklift
---@param vehicle Vehicle @the forklift
---@return table|nil @The UI component for the forks
function ToolFinder.findForkliftForks(vehicle)

	if vehicle.forkComponentIndex ~= nil then
		return vehicle.components[vehicle.forkComponentIndex]
	end

	-- Load the i3D as an XML file in order to find values.
	-- Only do this once for each vehicle, however
	local i3dAsXml = XMLFile.load("Vehicle i3D as XML", vehicle.i3dFilename, nil)
	if i3dAsXml then
		-- Try finding the first component which has "forks" in the name. Any mod which names the components like Giants does, will be supported that way
		-- That seems like the best option for now
		i3dAsXml:iterate("i3D.Scene.Shape", function(index, shapeXmlPath)
			local shapeName = i3dAsXml:getString(shapeXmlPath .. "#name")
			if shapeName:find("fork") then
				print(MOD_NAME .. ": Found forks in component # " .. tostring(index))
				vehicle.forkComponentIndex = index
				local translation = i3dAsXml:getVector(shapeXmlPath .. "#translation")
				local forkComponent = vehicle.components[vehicle.forkComponentIndex]
				-- Note: The fork component might be configurable, like in the JCB teletruk
				if translation and forkComponent ~= nil then
					forkComponent.yOffset = translation[2]
					print(MOD_NAME .. ": Found Y offset " .. tostring(translation[2]))
					return -- stop searching
				end
			end
		end)
	end

	if vehicle.forkComponentIndex then
		return vehicle.components[vehicle.forkComponentIndex]
	end
	return nil
end