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
		return vehicle.components[3]
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
