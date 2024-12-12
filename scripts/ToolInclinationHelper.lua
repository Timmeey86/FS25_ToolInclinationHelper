local MOD_DIR = g_currentModDirectory
MOD_NAME = g_currentModName

ToolInclinationHelper = {}
ToolInclinationHelper.hud = nil
ToolInclinationHelper.settings = TIHSettings.new()
-- Overwrite with settings from XML, if those are available
TIHSettingsRepository.restoreSettings(ToolInclinationHelper.settings)

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()

	-- Save settings when the savegame is being saved
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, function()
		TIHSettingsRepository.storeSettings(ToolInclinationHelper.settings)
	end)

	-- Initialize the HUD
	ToolInclinationHelper.hud = ToolInclinationHUD.new(g_currentMission.hud.speedMeter, MOD_DIR)
	ToolInclinationHelper.hud:load()

	-- Initialize the UI
	local ui = TIHSettingsUI.new(ToolInclinationHelper.settings)
	--ui:injectUiSettings()

	-- Draw our icon when the base game HUD is drawn.
	-- Note that overwriting HUD.drawControlledEntityHUD at this point in time seems to be too late, so we overwrite the function in the instance instead.
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
	return ToolInclinationHelper.getAdjustedGroundDistance(tool, raycastParams.groundDistance)
end

---Removes a potential Y offset from the ground distance. This is used for vehicles like base game forklift forks which don't have their "origin" on the ground.
---@param vehicle Vehicle @The vehicle
---@param distanceToGround number @The distance to the ground in meters
---@return number @The potentially adjusted ground distance
function ToolInclinationHelper.getAdjustedGroundDistance(vehicle, distanceToGround)
	if vehicle.forkYOffset ~= nil then
		return distanceToGround - vehicle.forkYOffset
	else
		return distanceToGround
	end
end