---This class is responsible for giving the player the possibility to set a reference height/orientation for any tool
---@class ToolReferenceOrientationHandler
---@field SPEC_NAME string @The name of the specialization
---@field spec_toolReferenceOrientationHandler table @Stores the specialization's data
---@field settings TIHSettings @The settings object to store reference orientations in
---@field toolFinder ToolFinder @The object which can find supported tools
ToolReferenceOrientationHandler = {
	SPEC_NAME = g_currentModName .. ".toolReferenceOrientationHandler",
	SPEC_TABLE = "spec_" .. g_currentModName .. "toolReferenceOrientationHandler"
}

---Injects dependencies to the class (not a specific instance!) so they can be used by the specializations
---@param settings TIHSettings @The settings object to store reference orientations in
---@param toolFinder ToolFinder @The object which can find supported tools
function ToolReferenceOrientationHandler.injectDependencies(settings, toolFinder)
	ToolReferenceOrientationHandler.settings = settings
	ToolReferenceOrientationHandler.toolFinder = toolFinder
end

---Registers the specialization with the type manager so it can be assigned to vehicles
---@param typeManager table @The type manager to register the specialization with
---@param typeName string @The vehicle type name
---@param specializations table @The list of specializations to check for prerequisites
function ToolReferenceOrientationHandler.register(typeManager, typeName, specializations)
	if ToolReferenceOrientationHandler.prerequesitesPresent(specializations) then
		typeManager:addSpecialization(typeName, ToolReferenceOrientationHandler.SPEC_NAME)
	end
end

---Initializes the specialization
function ToolReferenceOrientationHandler.initSpecialization()
	-- Nothing to do right now
end

---Makes sure any dependent specializations are loaded
---@param specializations table @The list of specializations to check
function ToolReferenceOrientationHandler.prerequesitesPresent(specializations)
	-- TODO: Find a way so we add this only to supported vehicles
	return true -- SpecializationUtil.hasSpecialization(AttacherJoints, specializations)
end

---Reacts on action event events in order to offer the "Set Tool Inclination Reference" action
---@param vehicleType table @The vehicle type to register the action events for
function ToolReferenceOrientationHandler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", ToolReferenceOrientationHandler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", ToolReferenceOrientationHandler)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ToolReferenceOrientationHandler)
end

---Initializes the specialization so values can be referenced from multiple event handlers
function ToolReferenceOrientationHandler:onLoad(savegame)
	self[ToolReferenceOrientationHandler.SPEC_TABLE] = {
		actionEvents = {}
	}
end

---Registers the action event for setting the reference orientation
---@param isActiveForInput boolean @True if the vehicle is active for input
---@param isActiveForInputIgnoreSelection boolean @True if the vehicle is active for input, even if it is not selected
function ToolReferenceOrientationHandler:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	local spec = self[ToolReferenceOrientationHandler.SPEC_TABLE]
	if not spec then
		return
	end

	self:clearActionEventsTable(spec.actionEvents)

	-- Register the action only for the root vehicle
	local currentVehicle = g_localPlayer and g_localPlayer:getCurrentVehicle()
	if not currentVehicle or currentVehicle ~= self then
		return
	end

	-- Register the action no matter which implement is currently selected. We don't want the user to have to select the tool first
	if not isActiveForInputIgnoreSelection then
		return
	end

	local isValid
	isValid, spec.toolInclinationReferenceActionEvent = self:addActionEvent(
		spec.actionEvents, "SET_TOOL_INCLINATION_REFERENCE", self, ToolReferenceOrientationHandler.setReferenceOrientation,
		false, true, false, true, nil)
	if not isValid then
		Logging.warning("%s: Failed registering action event for setting the reference orientation", MOD_NAME)
	else
		g_inputBinding:setActionEventTextPriority(spec.toolInclinationReferenceActionEvent, GS_PRIO_VERY_LOW)
		g_inputBinding:setActionEventText(spec.toolInclinationReferenceActionEvent, g_i18n:getText("input_SET_TOOL_INCLINATION_REFERENCE"))
		ToolReferenceOrientationHandler.updateActionEvents(self)
	end
end

---Updates action events based on the current vehicle and vehicle state
function ToolReferenceOrientationHandler:updateActionEvents()
	local spec = self[ToolReferenceOrientationHandler.SPEC_TABLE]
	if not spec then
		return
	end

	-- Ignore everything except for the current root vehicle
	local currentVehicle = g_localPlayer and g_localPlayer:getCurrentVehicle()
	if not currentVehicle or currentVehicle ~= self then
		return
	end

	local eventActive = false
	if self:getIsActiveForInput(true) and spec.toolInclinationReferenceActionEvent then
		local tool = ToolReferenceOrientationHandler.toolFinder:findSupportedTool(self)
		eventActive = (tool and (tool.rootNode or tool.node)) ~= nil
	end
	-- Display the action event as long as a supported tool was found
	g_inputBinding:setActionEventActive(spec.toolInclinationReferenceActionEvent, eventActive)
end

---Disables the action event as soon as the player does something which causes the tool to no longer be supported (e.g. detaching)
---@param dt number @The delta time since the last update
function ToolReferenceOrientationHandler:onUpdate(dt)
	ToolReferenceOrientationHandler.updateActionEvents(self)
end

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

	local spec = self[ToolReferenceOrientationHandler.SPEC_TABLE]
	if not spec then
		return
	end
	-- Get the current inclination
	local tool = ToolReferenceOrientationHandler.toolFinder:findSupportedTool(vehicle)
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
		ToolReferenceOrientationHandler.settings.referenceSettings[identifier] = {
			inclination = tool.referenceInclination,
			groundDistance = tool.referenceGroundDistance
		}
	end
end