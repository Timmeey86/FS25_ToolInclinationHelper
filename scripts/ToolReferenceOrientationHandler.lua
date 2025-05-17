---This class is responsible for giving the player the possibility to set a reference height/orientation for any tool
---@class ToolReferenceOrientationHandler
---@field settings TIHSettings @The settings object to store reference orientations in
---@field toolFinder ToolFinder @The object which can find supported tools
ToolReferenceOrientationHandler = {}
local ToolReferenceOrientationHandler_mt = Class(ToolReferenceOrientationHandler)

---Creates a new instance of the ToolReferenceOrientationHandler
---@param settings TIHSettings @The settings object to store reference orientations in
---@param toolFinder ToolFinder @The object which can find supported tools
function ToolReferenceOrientationHandler.new(settings, toolFinder)
	local self = setmetatable({}, ToolReferenceOrientationHandler_mt)
	self.settings = settings
	self.toolFinder = toolFinder

	-- VehicleDebug.registerActionEvents seems to be the perfect point in time to register action events at. 
	-- We don't want to depend on a specific specialization
	VehicleDebug.registerActionEvents = Utils.appendedFunction(VehicleDebug.registerActionEvents, function(vehicle, ...)
		self:registerActionEvents(vehicle, ...)
	end)
	Vehicle.updateActionEvents = Utils.appendedFunction(Vehicle.updateActionEvents, function(vehicle, ...)
		self:updateActionEvents(vehicle, ...)
	end)
end


---Registers the action event for setting the reference orientation
---@param vehicle Vehicle @Ignored since this parameter seems unreliable
function ToolReferenceOrientationHandler:registerActionEvents(vehicle)
	if vehicle.rootVehicle ~= vehicle then
		-- Implement: Ignore. We'll get a call for the root vehicle, too
		return
	end
	if not vehicle:getIsActiveForInput(true) then
		-- The call probably references the previous vehicle. ignore it
		return
	end
	local isValid
	isValid, vehicle.toolInclinationReferenceActionEvent = vehicle:addActionEvent(
		vehicle.actionEvents, "SET_TOOL_INCLINATION_REFERENCE", self, ToolReferenceOrientationHandler.setReferenceOrientation,
		false, true, false, true, nil)
	if not isValid then
		Logging.warning("%s: Failed registering action event for setting the reference orientation", MOD_NAME)
	else
		g_inputBinding:setActionEventTextPriority(self.toolInclinationReferenceActionEvent, GS_PRIO_VERY_LOW)
		g_inputBinding:setActionEventActive(self.toolInclinationReferenceActionEvent, false)
		g_inputBinding:setActionEventText(self.toolInclinationReferenceActionEvent, g_i18n:getText("input_SET_TOOL_INCLINATION_REFERENCE"))
	end
end

---Updates action events based on the current vehicle and vehicle state
---@param vehicle Vehicle @Ignored since this parameter seems unreliable
function ToolReferenceOrientationHandler:updateActionEvents(vehicle)
	if vehicle.rootVehicle ~= vehicle then
		return
	end
	local currentVehicle = g_localPlayer and g_localPlayer:getCurrentVehicle()
	if currentVehicle and vehicle ~= currentVehicle then
		printf("BUGFIX: Received update call for an old vehicle. Registering action events for the current one and sending a new update call")
		currentVehicle:updateActionEvents() -- This will also register the event since that's what the base game function does
		return
	end
	if not vehicle:getIsActiveForInput(true) then
		-- This might not be possible due to the previous check
		return
	end
	if not vehicle.toolInclinationReferenceActionEvent then
		-- We couldn't register our action => we can't execute it
		return
	end
	local tool = self.toolFinder:findSupportedTool(vehicle)
	-- Display the action event as long as a supported tool was found
	g_inputBinding:setActionEventActive(vehicle.toolInclinationReferenceActionEvent, tool and (tool.rootNode or tool.node))
end

Vehicle.draw = Utils.appendedFunction(Vehicle.draw, function(vehicle)
	local x, y, z = localToWorld(vehicle.rootNode or vehicle.node, 0, 1, 0)
	Utils.renderTextAtWorldPosition(x, y, z, tostring(vehicle.uniqueId), getCorrectTextSize(.02), 0, 1, 1, 1, 1)
end)

---Builds an identifier which is unique for each buyable vehicle, but equal for multiple instance of it across different saves
function ToolReferenceOrientationHandler.buildVehicleIdentifier(tool, vehicle)
	local relevantVehicle
	if tool.i3dFilename ~= nil then
		-- An attachable implement, which is a vehicle by itself
		relevantVehicle = tool
	else
		-- "Tool" is just a component. This is the default case for things like forklifts. 
		relevantVehicle = vehicle
	end
	if relevantVehicle.customEnvironment then
		-- mod vehicle - It should have unique config file names
		return ("%s|%s"):format(relevantVehicle.customEnvironment, relevantVehicle.configFileNameClean)
	else
		-- Giants vehicle - it has relative i3d filenames
		return ("Giants|%s"):format(relevantVehicle.i3dFilename)
	end
end

---Remembers the current inclination and distance to the ground and stores that information in the tool
function ToolReferenceOrientationHandler:setReferenceOrientation()
	local vehicle = g_localPlayer:getCurrentVehicle()
	if not vehicle then
		-- Shouldn't be possible, but just in case
		return
	end
	-- Get the current inclination
	local tool = self.toolFinder:findSupportedTool(vehicle)
	if not tool then
		Logging.error("%s: Triggered setReferenceOrientation, but no supported tool was found. This means the action was registered and activated in a case where that should not be possible", MOD_NAME)
		return
	end
	local isValid, inclination = ToolStateAnalyzer.getCurrentToolInclination(tool, vehicle, true)

	if isValid and tool then
		-- Remember the inclination and distance to the ground
		tool.referenceInclination = inclination
		tool.referenceGroundDistance = ToolStateAnalyzer.getDistanceFromGround(vehicle, tool, true)
		printf("Setting reference inclination to %s and ground distance to %s", inclination, tool.referenceGroundDistance)

		-- Build an identifier which allows reusing these values across multiple saves
		local identifier = ToolReferenceOrientationHandler.buildVehicleIdentifier(tool, vehicle)
		if not identifier then
			Logging.warning("%s: Failed building a vehicle identifier for the current tool. Can't save reference settings", MOD_NAME)
			return
		end

		-- Store the values in the settings. They will get saved by TIHSettingsRepository when the player saves the game the next time
		self.settings.referenceSettings[identifier] = {
			inclination = tool.referenceInclination,
			groundDistance = tool.referenceGroundDistance
		}
	end
end