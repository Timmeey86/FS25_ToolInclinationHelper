---This class is responsible for finding forks or similar tools attached to the player vehicle
---@class ToolFinder
ToolFinder = {}


local supportedCategories = {}
supportedCategories["teleLoaderTools"] = true
supportedCategories["wheelLoaderTools"] = true
supportedCategories["skidSteerTools"] = true
supportedCategories["frontLoaderTools"] = true
function ToolFinder.findSupportedTool(vehicle)
	if not vehicle then return nil end
	local category = getXMLString(vehicle.xmlFile.handle, "vehicle.storeData.category")
	if not category then return nil end

	-- Special case: Forklifts: The forks are a component rather than an attached implement
	if category == "forklifts" then
		-- TODO: This works for both basegame forklifts but will likely not support modded forklifts.
		-- Maybe we can loop through the components and see which ones are affected by joystick movements or something
		return ToolFinder.findForkliftForks(vehicle)
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
				print("Found forks in component # " .. tostring(index))
				local translation = i3dAsXml:getVector(shapeXmlPath .. "#translation")
				if translation then
					vehicle.forkYOffset = translation[2]
					print("Found Y offset " .. tostring(translation[2]))
				end
				vehicle.forkComponentIndex = index
				return -- stop searching
			end
		end)
	end

	if vehicle.forkComponentIndex then
		return vehicle.components[vehicle.forkComponentIndex]
	end

	Logging.error("Failed resolving forklift")
	printCallstack()

	return nil
end