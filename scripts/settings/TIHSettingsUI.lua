---This class is responsible for managing UI controls for changing the settings
---@class TIHSettingsUI
---@field settings TIHSettings @The settings object
---@field controls table @A list of all UI controls
---@field sectionTitle table @The UI header for the settings
---@field baseX table @The UI control for the X coordinate
---@field baseY table @The UI control for the Y coordinate
TIHSettingsUI = {
}
local TIHSettingsUI_mt = Class(TIHSettingsUI)

---Creates a new settings UI
---@param settings TIHSettings @The settings object
---@return TIHSettingsUI @The new instance
function TIHSettingsUI.new(settings)
	local self = setmetatable({}, TIHSettingsUI_mt)
	self.controls = {}
	self.settings = settings
	return self
end

---Injects the UI into the base game UI
function TIHSettingsUI:injectUiSettings()
	-- Get a reference to the base game general settings page
	local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings

	-- Define the UI controls. For each control, a <prefix>_<name>_short and _long key must exist in the i18n values
	local controlProperties = {
		{ name = "baseX", min = 0, max = 1920, step = 10, autoBind = true, subTable = "baseLocation", propName="x" },
		{ name = "baseY", min = 0, max = 1080, step = 10, autoBind = true, subTable = "baseLocation", propName="y" }
	}
	UIHelper.createControlsDynamically(settingsPage, "tih_section_title", self, controlProperties, "tih_")
	UIHelper.setupAutoBindControls(self, self.settings, TIHSettingsUI.onSettingsChange)

	-- Apply initial values
	self:updateUiElements()

	-- Trigger an update in order to enable/disable controls on settings frame open
	InGameMenuSettingsFrame.onFrameOpen = Utils.appendedFunction(InGameMenuSettingsFrame.onFrameOpen, function()
		self:updateUiElements(true) -- skip autobind controls
	end)
end

---Updates the UI controls after settings have changed
function TIHSettingsUI:onSettingsChange()
	self:updateUiElements()
end

---Updates the UI elements
---@param skipAutoBindControls boolean @True if auto-bound controls shall not be updated (because they are already up to date)
function TIHSettingsUI:updateUiElements(skipAutoBindControls)
	if not skipAutoBindControls then
		-- Note: This method is created dynamically by UIHelper.setupAutoBindControls
		self.populateAutoBindControls()
	end

	-- Nothing else to do right now

	-- Update the focus manager (this will become necessary when enabling/disabling controls)
	-- local settingsPage = g_gui.screenControllers[InGameMenu].pageSettings
	-- settingsPage.generalSettingsLayout:invalidateLayout()
end
