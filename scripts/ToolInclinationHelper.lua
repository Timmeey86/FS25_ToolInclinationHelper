local MOD_DIR = g_currentModDirectory
MOD_NAME = g_currentModName

ToolInclinationHelper = {}
ToolInclinationHelper.hud = nil
ToolInclinationHelper.settings = TIHSettings.new()
-- Overwrite with settings from XML, if those are available
TIHSettingsRepository.restoreSettings(ToolInclinationHelper.settings)

ToolInclinationHelper.toolFinder = ToolFinder.new(ToolInclinationHelper.settings)


TypeManager.finalizeTypes = Utils.prependedFunction(TypeManager.finalizeTypes, function(typeManager)
	if typeManager.typeName == "vehicle" then
		-- Inject dependencies now
		ToolReferenceOrientationHandler.injectDependencies(ToolInclinationHelper.settings, ToolInclinationHelper.toolFinder)

		-- Register our specialization for all vehicle types for now. We don't have a reliable way to figure out if the vehicle actually is 
		-- supported at this point
		for typeName, typeEntry in pairs(typeManager.types) do
			ToolReferenceOrientationHandler.register(typeManager, typeName, typeEntry.specializations)
		end
	end
end)

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function()

	-- Save settings when the savegame is being saved
	ItemSystem.save = Utils.prependedFunction(ItemSystem.save, function()
		TIHSettingsRepository.storeSettings(ToolInclinationHelper.settings)
	end)

	-- Initialize the HUD
	ToolInclinationHelper.hud = ToolInclinationHUD.new(g_currentMission.hud.speedMeter, MOD_DIR)
	ToolInclinationHelper.hud:load()

	-- Initialize the UI
	local ui = TIHSettingsUI.new(ToolInclinationHelper.settings)
	ui:injectUiSettings()

	-- Draw our icon when the base game HUD is drawn.
	-- Note that overwriting HUD.drawControlledEntityHUD at this point in time seems to be too late, so we overwrite the function in the instance instead.
	g_currentMission.hud.drawControlledEntityHUD = Utils.appendedFunction(g_currentMission.hud.drawControlledEntityHUD, function(self)
		if self.isVisible then
			local tool = ToolInclinationHelper.toolFinder:findSupportedTool(self.controlledVehicle)
			if tool then
				local isVisible, inclination = ToolStateAnalyzer.getCurrentToolInclination(tool, self.controlledVehicle, false)
				local distanceToGround = ToolStateAnalyzer.getDistanceFromGround(self.controlledVehicle, tool, false)
				ToolInclinationHelper.hud:setState(isVisible, inclination, distanceToGround)
				ToolInclinationHelper.hud:drawHUD()
			end
		end
	end)
end)