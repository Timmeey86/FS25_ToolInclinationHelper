local MOD_DIR = g_currentModDirectory


ToolInclinationHelper = {}
ToolInclinationHelper.hud = nil
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()

	ToolInclinationHelper.hud = ToolInclinationHUD.new(g_currentMission.hud.speedMeter, MOD_DIR)
	ToolInclinationHelper.hud:load()

	g_currentMission.hud.drawControlledEntityHUD = Utils.appendedFunction(g_currentMission.hud.drawControlledEntityHUD, function(self)
		if self.isVisible then
			local isVisible, direction, tool = ToolInclinationHelper.getCurrentToolInclination(self.controlledVehicle)
			local distanceToGround = ToolInclinationHelper.getDistanceFromGround(self.controlledVehicle, tool)
			ToolInclinationHelper.hud:setState(isVisible, direction, distanceToGround)
			ToolInclinationHelper.hud:drawHUD()
		end
	end)
end)

---Retrieves the inclination for the current tool
---@param vehicle Vehicle @The current vehicle
---@return boolean @True if a valid inclination was found
---@return number @The direction of the inclination (1, 0, or -1)
---@return table @The tool or component which was found
function ToolInclinationHelper.getCurrentToolInclination(vehicle)
	if not g_localPlayer or vehicle ~= g_localPlayer:getCurrentVehicle() or not g_currentMission then
		-- Only render for the current vehicle
		return false
	end

	-- Check if there is a tool we can handle
	local tool = ToolFinder.findSupportedTool(vehicle)
	if not tool or (not tool.rootNode and not tool.node) then
		return false
	end

	-- Get the current inclination of the tool. RootNode for implements, Node for components like with forklifts
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
	return true, direction, tool
end

---Tries finding out how much the tool is above the ground
---@param vehicle Vehicle @The vehicle
---@param tool table @The implement or component
---@return number|nil @The distance to the ground
function ToolInclinationHelper.getDistanceFromGround(vehicle, tool)
	if not vehicle or not tool or (not tool.rootNode and not tool.node) then
		return nil
	end

	-- Raycast to get the distance to the ground similar to how VehicleDebug.drawDebugAttributeRendering does it
	local node = tool.rootNode or tool.node
	local raycastParams = {
		raycastCallback = function(self, transformId, _, _, _, distance)
			-- Search until something is found which is not part of the vehicle or the tool
			if (not vehicle.vehicleNodes or vehicle.vehicleNodes[transformId] == nil) and (not tool.vehicleNodes or tool.vehicleNodes[transformId] == nil) then
				self.groundDistance = distance
				return false
			end
			return true
		end,
		vehicle = vehicle,
		object = tool,
		groundDistance = 0
	}
	local x, y, z = localToWorld(node, 0, 0, 0)
	-- Raycast downwards 10m from the tool's origin (we need to be this high because of telehandlers)
	local maxDistance = 10
	raycastAll(x, y, z, 0, -1, 0, maxDistance, "raycastCallback", raycastParams, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT)
	return ToolInclinationHelper.dirtyWorkaroundForForklifts(vehicle, raycastParams.groundDistance)
end

-- TODO: Find out how to calculate distance to ground properly for these
function ToolInclinationHelper.dirtyWorkaroundForForklifts(vehicle, distanceToGround)
	local configFileName = vehicle.configFileName
	local storeItem = g_storeManager:getItemByXMLFilename(configFileName)
	if storeItem.brandNameRaw == "JUNGHEINRICH" and storeItem.name == "EFG S50" then
		return distanceToGround - 0.4
	elseif storeItem.brandNameRaw == "MANITOU" and storeItem.name == "M50-4" then
		return distanceToGround - 0.8
	else
		return distanceToGround
	end
end