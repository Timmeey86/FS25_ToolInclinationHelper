---This class is responsible for giving the player the possibility to set a reference height/orientation for any tool
---@class ToolReferenceOrientationHandler
ToolReferenceOrientationHandler = {}
local ToolReferenceOrientationHandler_mt = Class(ToolReferenceOrientationHandler)
local toolReferenceOrientationHandler = setmetatable({}, ToolReferenceOrientationHandler_mt)
toolReferenceOrientationHandler.actionEvent = nil
toolReferenceOrientationHandler.registerWarningShown = false

---Registers the action event for setting the reference orientation
---@param vehicle Vehicle @The vehicle the player is sitting in
function ToolReferenceOrientationHandler.registerActionEvents(vehicle)
	if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
		local isValid
		isValid, toolReferenceOrientationHandler.actionEvent = vehicle:addActionEvent(
			vehicle.actionEvents, "SET_TOOL_INCLINATION_REFERENCE", vehicle, ToolReferenceOrientationHandler.setReferenceOrientation,
			false, true, false, true, nil)
		if not isValid then
			if not toolReferenceOrientationHandler.registerWarningShown then
				Logging.warning("%s: Failed registering action event for setting the reference orientation", MOD_NAME)
				-- TODO
				--toolReferenceOrientationHandler.registerWarningShown = true
			end
		else
			g_inputBinding:setActionEventTextPriority(toolReferenceOrientationHandler.actionEvent, GS_PRIO_VERY_LOW)
			g_inputBinding:setActionEventActive(toolReferenceOrientationHandler.actionEvent, false)
			g_inputBinding:setActionEventText(toolReferenceOrientationHandler.actionEvent, g_i18n:getText("input_SET_TOOL_INCLINATION_REFERENCE"))
		end
	end
end
--VehicleDebug.registerActionEvents seems to be the perfect point in time to register action events at. We don't want to depend on a specific specialization
VehicleDebug.registerActionEvents = Utils.appendedFunction(VehicleDebug.registerActionEvents, ToolReferenceOrientationHandler.registerActionEvents)

---Updates action events based on the current vehicle and vehicle state
---@param vehicle Vehicle @The vehicle the player is sitting in
function ToolReferenceOrientationHandler.updateActionEvents(vehicle)
	if not toolReferenceOrientationHandler.actionEvent then
		return
	end
	local tool = ToolFinder.findSupportedTool(vehicle)
	-- Display the action event as long as a supported tool was found
	g_inputBinding:setActionEventActive(toolReferenceOrientationHandler.actionEvent, tool and (tool.rootNode or tool.node))
end
Vehicle.updateActionEvents = Utils.appendedFunction(Vehicle.updateActionEvents, ToolReferenceOrientationHandler.updateActionEvents)

function ToolReferenceOrientationHandler.setReferenceOrientation(vehicle)
	local isValid, inclination, tool = ToolStateAnalyzer.getCurrentToolInclination(vehicle, true)

	if isValid and tool then
		tool.referenceInclination = inclination
		tool.referenceGroundDistance = ToolStateAnalyzer.getDistanceFromGround(vehicle, tool, true)
		printf("Setting reference inclination to %s and ground distance to %s", inclination, tool.referenceGroundDistance)
	end
end