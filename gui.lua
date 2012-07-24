local baseName = "NotificationsOptionsPanel"

-- these variables are loaded on init and updated only on gui.okay. Calling gui.cancel resets the saved vars to these
local old = {}

-- function to copy table contents and inner table
local function copyTable(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = {}
			for k, v in pairs(value) do
				target[key][k] = value[k]
			end
		else
			target[key] = value
		end
	end
end

-- create frames/widgets

local gui = CreateFrame("Frame", "NotificationsOptionsPanel", UIParent)
gui.name = "Notifications"
InterfaceOptions_AddCategory(gui)

local title = gui:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Notifications")

local version = gui:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPRIGHT", -16, -16)
version:SetText("v."..GetAddOnMetadata(..., "Version"))

local credits = gui:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
credits:SetText("Notifications by Freethinker @ Steamwheedle Cartel - EU / Haleth on wowinterface.com")
credits:SetPoint("BOTTOM", 0, 188)

local checkboxes = {}
local sliders = {}
local dropdowns = {}

local function toggle(f)
	-- first we set the variable, then we set the cached setting
	-- since variables are only loaded once
	if f:GetChecked() then
		NotificationsOptions[f.option] = true
		Notifications.options[f.option] = true
	else
		NotificationsOptions[f.option] = false
		Notifications.options[f.option] = false
	end

	-- finally, we update Notifications with the new cached settings
	Notifications:Update()
end

local function createCheckBox(name, option, text)
	local f = CreateFrame("CheckButton", baseName..name, gui, "InterfaceOptionsCheckButtonTemplate")
	
	f.option = option
	f.Text:SetText(text)
	
	f:SetScript("OnClick", toggle)
	
	tinsert(checkboxes, f)

	return f
end

local function onValueChanged(f, value)
	NotificationsOptions[f.option] = value
	Notifications.options[f.option] = value
	
	Notifications:Update()
end

local function createSlider(name, option, text, lowText, highText, low, high, step)
	local f = CreateFrame("Slider", baseName..name, gui, "OptionsSliderTemplate")
	
	BlizzardOptionsPanel_Slider_Enable(f)
	
	f.option = option
	_G[baseName..name.."Text"]:SetText(text)
	_G[baseName..name.."Low"]:SetText(lowText)
	_G[baseName..name.."High"]:SetText(highText)
	f:SetMinMaxValues(low, high)
	f:SetValueStep(step)
	
	f:SetScript("OnValueChanged", onValueChanged)
	
	tinsert(sliders, f)
	
	return f
end

local function OnClick(self)
	local f = select(2, self:GetParent():GetPoint())
	UIDropDownMenu_SetSelectedID(f, self:GetID())
	NotificationsOptions[f.option] = self.value
	Notifications.options[f.option] = self.value
	
	Notifications:Update()
end

local function initialize(self)
	for _, v in pairs(self.items) do
		local info = UIDropDownMenu_CreateInfo()
		info.text = v
		info.value = strupper(strconcat(strsplit(" ", v)))
		info.func = OnClick
		UIDropDownMenu_AddButton(info)
	end
end

local function createDropDown(name, option, text, items) 
	local f = CreateFrame("Button", baseName..name, gui, "UIDropDownMenuTemplate")

	f.option = option
	f.items = items
	
	local label = f:CreateFontString(nil, "BACKGROUND", "GameFontNormalSmall")
	label:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 16, 3)
	label:SetText(text)
	
	UIDropDownMenu_Initialize(f, initialize)
	UIDropDownMenu_SetWidth(f, 100)
	
	tinsert(dropdowns, f)
	
	return f
end

local playSounds = createCheckBox("PlaySounds", "playSounds", "Play sound")
playSounds:SetPoint("TOPLEFT", title, 0, -26)
local animations = createCheckBox("Animations", "animations", "Animate the banner")
animations:SetPoint("TOPLEFT", playSounds, "BOTTOMLEFT", 0, -8)

local interval = createSlider("Interval", "interval", "Animation speed", SLOW, FAST, .1, 1, .1)
interval:SetPoint("TOPLEFT", animations, "BOTTOMLEFT", 12, -12)
local intervalLabel = interval:CreateFontString(nil, nil, "GameFontHighlightSmall")
intervalLabel:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", 0, -16)
intervalLabel:SetText("A slower animation speed ensures a smoother animation.")

local timeShown = createSlider("TimeShown", "timeShown", "Time shown", TOAST_DURATION_SHORT, TOAST_DURATION_LONG, 1, 15, 1)
timeShown:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", -12, -24)

local position = createDropDown("Position", "position", "Position", {"Top", "Top Right", "Right", "Bottom Right", "Bottom", "Bottom Left", "Left", "Top Left"})
position:SetPoint("TOPLEFT", timeShown, "BOTTOMLEFT", 0, -24)

if Aurora or FreeUI then
	local F = unpack(Aurora or FreeUI)
	
	for _, box in pairs(checkboxes) do
		F.ReskinCheck(box)
	end
	
	for _, slider in pairs(sliders) do
		F.ReskinSlider(slider)
	end
	
	for _, dropdown in pairs(dropdowns) do
		F.ReskinDropDown(dropdown)
	end
end

-- add event handlers

gui.refresh = function()
	for _, box in pairs(checkboxes) do
		box:SetChecked(Notifications.options[box.option])
	end

	for _, slider in pairs(sliders) do
		slider:SetValue(Notifications.options[slider.option])
	end
end

gui:RegisterEvent("ADDON_LOADED")
gui:SetScript("OnEvent", function()
	gui:UnregisterEvent("ADDON_LOADED")
	
	-- because dropdowns are "special" and don't play nicely with refresh()
	for _, dropdown in pairs(dropdowns) do
		UIDropDownMenu_SetSelectedValue(dropdown, Notifications.options[dropdown.option])
	end
end)

--[[gui:RegisterEvent("ADDON_LOADED")
gui:SetScript("OnEvent", function(self, _, addon)
	if addon ~= "Aurora" then return end

	-- fill 'old' table
	copyTable(AuroraConfig, old)
	
	gui.refresh()
	
	F.Reskin(reloadButton)
	F.Reskin(colourButton)
	F.ReskinCheck(fontBox)
	F.ReskinCheck(colourBox)
	F.ReskinCheck(bagsBox)
	F.ReskinCheck(lootBox)
	F.ReskinCheck(mapBox)
	F.ReskinCheck(tooltipsBox)
	F.ReskinSlider(alphaSlider)
	
	self:UnregisterEvent("ADDON_LOADED")
end)

local function updateFrames()
	for i = 1, #C.frames do
		F.CreateBD(C.frames[i], AuroraConfig.alpha)
	end
end

gui.okay = function()
	copyTable(AuroraConfig, old)
end

gui.cancel = function()
	copyTable(old, AuroraConfig)
	
	updateFrames()
	gui.refresh()
end

gui.default = function()
	copyTable(C.defaults, AuroraConfig)
	
	updateFrames()
	gui.refresh()
end

reloadButton:SetScript("OnClick", ReloadUI)

alphaSlider:SetScript("OnValueChanged", function(_, value)
	AuroraConfig.alpha = value
	updateFrames()
end)

colourBox:SetScript("OnClick", function(self)
	if self:GetChecked() then
		AuroraConfig.useCustomColour = true
		colourButton:Enable()
	else
		AuroraConfig.useCustomColour = false
		colourButton:Disable()
	end
end)

local function setColour()
	local r, g, b = ColorPickerFrame:GetColorRGB()
	AuroraConfig.customColour.r, AuroraConfig.customColour.g, AuroraConfig.customColour.b = r, g, b
end

local function resetColour(restore)
	AuroraConfig.customColour.r, AuroraConfig.customColour.g, AuroraConfig.customColour.b = restore.r, restore.g, restore.b
end

colourButton:SetScript("OnClick", function()
	local r, g, b = AuroraConfig.customColour.r, AuroraConfig.customColour.g, AuroraConfig.customColour.b
	ColorPickerFrame:SetColorRGB(r, g, b)
	ColorPickerFrame.previousValues = {r = r, g = g, b = b}
	ColorPickerFrame.func = setColour
	ColorPickerFrame.cancelFunc = resetColour
	ColorPickerFrame:Hide()
	ColorPickerFrame:Show()
end)]]

-- easy slash command

SlashCmdList.NOTIFICATIONS = function()
	InterfaceOptionsFrame_OpenToCategory(gui)
end
SLASH_AURORA1 = "/notifications"