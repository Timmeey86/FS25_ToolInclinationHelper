---This class is responsible for analyzing the current state of a tool
---@class ToolStateAnalyzer
ToolStateAnalyzer = {}

---Retrieves the inclination for the current tool
---@param vehicle Vehicle @The current vehicle
---@return boolean @True if a valid inclination was found
---@return number @The inclination
---@return table @The tool or component which was found
function ToolStateAnalyzer.getCurrentToolInclination(vehicle)
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

	return true, pitch, tool
end

---Tries finding out how much the tool is above the ground
---@param vehicle Vehicle @The vehicle
---@param tool table @The implement or component
---@return number|nil @The distance to the ground, bale, pallet or vehicle below the forks (whichever is found first)
function ToolStateAnalyzer.getDistanceFromGround(vehicle, tool)
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
	raycastAll(x, y, z, 0, -1, 0, maxDistance, "raycastCallback", raycastParams, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT)
	return ToolStateAnalyzer.getAdjustedGroundDistance(tool, raycastParams.groundDistance)
end

---Removes a potential Y offset from the ground distance. This is used for vehicles like base game forklift forks which don't have their "origin" on the ground.
---@param vehicle Vehicle @The vehicle
---@param distanceToGround number @The distance to the ground in meters
---@return number @The potentially adjusted ground distance
function ToolStateAnalyzer.getAdjustedGroundDistance(vehicle, distanceToGround)
	if vehicle.forkYOffset ~= nil then
		return distanceToGround - vehicle.forkYOffset
	else
		return distanceToGround
	end
end