local MOD_DIR = g_currentModDirectory

local supportedCategories = {}
supportedCategories["teleLoaderTools"] = true
supportedCategories["wheelLoaderTools"] = true
supportedCategories["skidSteerTools"] = true
supportedCategories["frontLoaderTools"] = true


ToolInclinationHelper = {}


local hud
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()

	hud = ToolInclinationHUD.new(g_currentMission.hud.speedMeter, MOD_DIR)
	hud:load()

	g_currentMission.hud.drawControlledEntityHUD = Utils.appendedFunction(g_currentMission.hud.drawControlledEntityHUD, function(self)
		if self.isVisible then
			local isVisible, direction = ToolInclinationHelper.getCurrentToolInclination(self.controlledVehicle)
			hud:setState(isVisible, direction)
			hud:drawHUD()
		end
	end)
end)

function ToolInclinationHelper.getLevelableTool(vehicle)
	if not vehicle then return nil end
	local category = getXMLString(vehicle.xmlFile.handle, "vehicle.storeData.category")
	if not category then return nil end

	-- Special case: Forklifts: The forks are a component rather than an attached implement
	if category == "forklifts" then
		-- TODO: Maybe cycle components and find one which has the correct axes assigned to it
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
				local furtherImplement = ToolInclinationHelper.getLevelableTool(implement.object)
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

function ToolInclinationHelper.getCurrentToolInclination(vehicle)
	if not g_localPlayer or vehicle ~= g_localPlayer:getCurrentVehicle() or not g_currentMission then
		-- Only render for the current vehicle
		return false
	end

	-- Check if there is a tool we can handle
	local tool = ToolInclinationHelper.getLevelableTool(vehicle)
	if not tool or (not tool.rootNode and not tool.node) then
		return false
	end

	-- Get the current inclination of the tool
	local node = tool.rootNode or tool.node
	local x, y, z = localToWorld(node, 0, 0, 0)
	local xx, xy, xz = localToWorld(node, 0, 0, 1)
	local pitch, _ = MathUtil.directionToPitchYaw(xx - x, xy - y, xz - z)
	pitch = math.deg(pitch)

	local direction = 0
	if pitch > 1 then
		direction = 1
	elseif pitch < -1 then
		direction = -1
	end
	return true, direction
end