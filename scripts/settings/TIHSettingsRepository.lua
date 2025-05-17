---@class TIHSettingsRepository
---This class is responsible for reading and writing settings
TIHSettingsRepository = {
	FILENAME = "ToolInclinationHelperSettings.xml",
	MAIN_KEY = "ToolInclinationHelper",
	BASE_LOCATION = "baseLocation",
	XOFFSET_KEY = "xOffset",
	YOFFSET_KEY = "yOffset",
	DISPLAY_MODE = "displayMode",
	COLOR_CODING = "colorCoding",
	INVERT_ARROWS = "invertArrows",
	REFERENCE_SETTINGS = "referenceSettings",
	REFERENCE_SETTING = "referenceSetting",
	REF_IDENTIFIER = "identifier",
	REF_INCLINATION = "inclination",
	REF_DISTANCE = "distanceToGround"
}

---Writes the settings to our own XML file
---@param settings TIHSettings @The settings object
function TIHSettingsRepository.storeSettings(settings)
	local xmlPath = TIHSettingsRepository.getXmlFilePath()
	if xmlPath == nil then
		Logging.warning(MOD_NAME .. ": Could not store settings.") -- another warning has been logged before this
		return
	end

	-- Create an empty XML file in memory
	local xmlFileId = createXMLFile("ToolInclinationHelper", xmlPath, TIHSettingsRepository.MAIN_KEY)

	-- Add XML data in memory
	local baseLocationProperty = TIHSettingsRepository.getXMLSubPath(TIHSettingsRepository.BASE_LOCATION)
	setXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.XOFFSET_KEY, baseLocationProperty), settings.baseLocation.xOffset)
	setXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.YOFFSET_KEY, baseLocationProperty), settings.baseLocation.yOffset)
	setXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.DISPLAY_MODE), settings.displayMode)
	setXMLBool(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.COLOR_CODING), settings.colorCoding)
	setXMLBool(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.INVERT_ARROWS), settings.invertArrows)

	local referenceSettingsProperty = TIHSettingsRepository.getXMLSubPath(TIHSettingsRepository.REFERENCE_SETTINGS)
	local referenceSettingBasePath = ("%s.%s"):format(referenceSettingsProperty, TIHSettingsRepository.REFERENCE_SETTING)

	local i = 0
	for identifier, referenceSetting in pairs(settings.referenceSettings) do
		local key = ("%s(%s)"):format(referenceSettingBasePath, i)
		setXMLString(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_IDENTIFIER), identifier)
		setXMLFloat(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_INCLINATION), referenceSetting.inclination)
		setXMLFloat(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_DISTANCE), referenceSetting.groundDistance)
		i = i + 1
	end
	-- Write the XML file to disk
	saveXMLFile(xmlFileId)
end

---Reads settings from an existing XML file, if such a file exists
---@param settings TIHSettings @The settings object which should already contain default values at this point
function TIHSettingsRepository.restoreSettings(settings)

	local xmlPath = TIHSettingsRepository.getXmlFilePath()
	if xmlPath == nil then
		-- This is a valid case when a new game was started. The savegame path will only be available after saving once
		return
	end

	-- Abort if no settings have been saved yet
	if not fileExists(xmlPath) then
		print(MOD_NAME .. ": No settings found, using default settings")
		return
	end

	-- Load the XML if possible
	local xmlFileId = loadXMLFile("UnloadBalesEarly", xmlPath)
	if xmlFileId == 0 then
		Logging.warning(MOD_NAME .. ": Failed reading from XML file")
		return
	end

	-- Read the values from memory
	local baseLocationProperty = TIHSettingsRepository.getXMLSubPath(TIHSettingsRepository.BASE_LOCATION)
	settings.baseLocation.xOffset = getXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.XOFFSET_KEY, baseLocationProperty)) or settings.baseLocation.xOffset
	settings.baseLocation.yOffset = getXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.YOFFSET_KEY, baseLocationProperty)) or settings.baseLocation.yOffset
	settings.displayMode = getXMLInt(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.DISPLAY_MODE)) or settings.displayMode
	settings.colorCoding = getXMLBool(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.COLOR_CODING)) or settings.colorCoding
	settings.invertArrows = getXMLBool(xmlFileId, TIHSettingsRepository.getPathForStateAttribute(TIHSettingsRepository.INVERT_ARROWS)) or settings.invertArrows

	settings.referenceSettings = {}
	local referenceSettingsProperty = TIHSettingsRepository.getXMLSubPath(TIHSettingsRepository.REFERENCE_SETTINGS)
	if hasXMLProperty(xmlFileId, referenceSettingsProperty) then
		print(MOD_NAME .. ": Restoring reference settings")
		local i = 0
		local referenceSettingBasePath = ("%s.%s"):format(referenceSettingsProperty, TIHSettingsRepository.REFERENCE_SETTING)
		while true do
			local key = ("%s(%d)"):format(referenceSettingBasePath, i)
			if not hasXMLProperty(xmlFileId, key) then
				break
			end
			local identifier = getXMLString(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_IDENTIFIER))
			local referenceSetting = {
				inclination = getXMLFloat(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_INCLINATION)),
				groundDistance = getXMLFloat(xmlFileId, ("%s#%s"):format(key, TIHSettingsRepository.REF_DISTANCE))
			}
			if identifier ~= nil and referenceSetting.inclination ~= nil and referenceSetting.groundDistance ~= nil then
				settings.referenceSettings[identifier] = referenceSetting
			else
				Logging.warning("%s: Failed reading reference setting #%d from XML file", MOD_NAME, i)
			end
			i = i + 1
		end
	end

	print(MOD_NAME .. ": Successfully restored settings")
end

---Builds an XML path for a "state" attribute like a true/false switch or a selection of predefined values, but not a custom text, for example
---@param property string @The name of the XML property.
---@param parentProprety string|nil @The name of the parent property
---@return string @The path to the XML attribute
function TIHSettingsRepository.getPathForStateAttribute(property, parentProprety)
	return ("%s.%s#%s"):format(parentProprety or TIHSettingsRepository.MAIN_KEY, property, "state")
end

---Retrieves an XML path for an element which will receive further properties or attributes
---@param property string @The name of the XML property.
---@param parentProperty string|nil @The name of the parent property
---@return string @The path to the XML attribute
function TIHSettingsRepository.getXMLSubPath(property, parentProperty)
	return ("%s.%s"):format(parentProperty or TIHSettingsRepository.MAIN_KEY, property)
end

---Builds a path to the XML file.
---@return string|nil @The path to the XML file
function TIHSettingsRepository.getXmlFilePath()
	if g_modSettingsDirectory then
		return ("%s%s"):format(g_modSettingsDirectory, TIHSettingsRepository.FILENAME)
	end
	Logging.warning("%s: Could not retrieve mod settings directory, using local path", MOD_NAME)
	return "./" .. TIHSettingsRepository.FILENAME
end