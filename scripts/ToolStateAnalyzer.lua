---This class is responsible for analyzing the current state of a tool
---@class ToolStateAnalyzer
ToolStateAnalyzer = {}

---Retrieves the inclination for the current tool
---@param vehicle Vehicle @The current vehicle
---@return boolean @True if a valid inclination was found
---@return number|nil @The inclination
---@param ignoreReferenceInclination boolean|nil @True if the reference inclination should be ignored, e.g. because a new reference inlination shall be calculated
---@return table|nil @The tool or component which was found
function ToolStateAnalyzer.getCurrentToolInclination(vehicle, ignoreReferenceInclination)
	if not g_localPlayer or vehicle == nil or vehicle ~= g_localPlayer:getCurrentVehicle() or not g_currentMission then
		-- Only render for the current vehicle
		return false
	end

	-- Check if there is a tool we can handle
	-- TODO: Optimization: We could probably cache the tool. We would however have to make sure we catch every player action which should update the cache
	--                     like attaching/detaching the tool etc.
	local tool = ToolFinder.findSupportedTool(vehicle)
	if not tool or (not tool.rootNode and not tool.node) then
		return false
	end

	-- Get the current inclination of the tool. RootNode for implements, Node for components like with forklifts
	local node = tool.rootNode or tool.node
	local x, y, z = localToWorld(node, 0, 0, 0)
	local zx, zy, zz = localToWorld(node, 0, 0, 1)
	local pitch, _ = MathUtil.directionToPitchYaw(zx - x, zy - y, zz - z)
	pitch = math.deg(pitch)

	if not ignoreReferenceInclination and tool.referenceInclination ~= nil then
		-- If the player set a reference inclination, subtract that from the current inclination
		pitch = pitch - tool.referenceInclination
	end

	return true, pitch, tool
end

---Tries finding out how much the tool is above the ground
---@param vehicle Vehicle @The vehicle
---@param tool table|nil @The implement or component
---@param ignoreReferenceHeight boolean<nil @True if the reference height should be ignored, e.g. because a new reference height shall be calculated
---@return number|nil @The distance to the ground, bale, pallet or vehicle below the forks (whichever is found first)
function ToolStateAnalyzer.getDistanceFromGround(vehicle, tool, ignoreReferenceHeight)
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
		groundDistance = nil
	}

	-- Note: We move the search location half a meter along the Z axis which hopefully points towards the front for all tools..
	--       This helps with detecting stuff below the forks earlier
	local x, y, z = localToWorld(node, 0, 0, .5)
	-- If the tool has a yOffset (because the origin is not at the bottom of the tool), we need to remove that from the Y raycasting position
	if tool.yOffset ~= nil then
		y = y - tool.yOffset
	end
	-- If the player set a reference height, use that
	if not ignoreReferenceHeight and tool.referenceGroundDistance ~= nil then
		y = y - tool.referenceGroundDistance
	end
	-- Raycast downwards 10m from the tool's origin (we need to be this high because of telehandlers)
	local maxDistance = 10
	raycastAll(x, y , z, 0, -1, 0, maxDistance, "raycastCallback", raycastParams, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT)

	if not raycastParams.groundDistance then
		raycastAll(x, y, z, 0, 1, 0, maxDistance, "raycastCallback", raycastParams, CollisionFlag.TERRAIN + CollisionFlag.STATIC_OBJECT + CollisionFlag.VEHICLE + CollisionFlag.DYNAMIC_OBJECT)
		raycastParams.groundDistance = raycastParams.groundDistance and raycastParams.groundDistance * -1 or nil
	end

	if ToolStateAnalyzer.debug and raycastParams.groundDistance then
		if raycastParams.groundDistance >= 0 then
			DebugUtil.drawDebugLine(x, y, z, x, y - maxDistance, z, 1, 0, 0, .2)
		else
			DebugUtil.drawDebugLine(x, y, z, x, y + maxDistance, z, 1, 0, 0, .2)
		end
		DebugUtil.drawDebugLine(x, y, z, x, y - raycastParams.groundDistance, z, 1, 0, 0, .5)
	end
	return raycastParams.groundDistance
end