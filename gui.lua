local baseName = "NotificationsOptionsPanel"

-- default settings. Don't touch this!
local defaults = {
	playSounds = true,
	animations = true, -- scale and fade the banner on show/hide. Not recommended for slow PCs.
	timeShown = 5, -- amount of time the banner is shown before it disappears. Mousing over the banner keeps it shown.
	interval = 0.1, -- difference in opacity/scale per new frame when the banner animates. Lower = smoother, but also slower.

	position = "TOP", -- choose a side of the screen
	width = 400,
	height = 50,

	backdrop = "Interface\\ChatFrame\\ChatFrameBackground",
	border = "Interface\\ChatFrame\\ChatFrameBackground",
	borderSize = 1,
	inset = 0, -- how far into the frame the background is drawn.

	bgRed = 0, bgGreen = 0, bgBlue = 0, bgAlpha = .5, -- colour of the backdrop.
	borderRed = 0, borderGreen = 0, borderBlue = 0, borderAlpha = 1, -- colour of the border.

	separatorWidth = 1,
	separatorUseRGB = true, -- use a plain colour instead of texture for separator
	separatorTexture = "", -- only applies with separatorUseRGB disabled
	separatorRed = 0, separatorGreen = 0, separatorBlue = 0, -- only applies with separatorUseRGB enabled
	separatorAlpha = 1,

	font = "FONTS\\ARIALN.TTF",
	fontSize = 14,
	textRed = 1, textGreen = 1, textBlue = 1, -- text colour.
	shadowRed = 0, shadowGreen = 0, shadowBlue = 0, -- font shadow colour.
	shadowH = 1, shadowV = -1, -- horizontal and vertical offset for font shadow.

	defaultIcon = "Interface\\Icons\\achievement_general", -- icon shown when no texture is specified for the banner icon.
}

-- these variables are loaded on init and updated only on gui.okay. Calling gui.cancel resets the saved vars to these
local old = {}

-- function to copy table by value
local function copyTable(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = {}
			copyTable(value, target[key])
		else
			target[key] = value
		end
	end
end

-- function to copy table only when equivalent keys exist in target table
local function copyTableExisting(source, target)
	for key, value in pairs(source) do
		if target[key] ~= nil then -- we don't want to set saved vars if they don't exist yet
			if type(value) == "table" then
				target[key] = {}
				copyTable(value, target[key])
			else
				target[key] = value
			end
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
credits:SetPoint("BOTTOM", 0, 50)

local test = CreateFrame("Button", baseName.."TestAlert", gui, "UIPanelButtonTemplate")
test:SetSize(128, 25)
test:SetPoint("BOTTOM", credits, "TOP", 0, 80)
test:SetText("Test Banner")
test:SetScript("OnClick", function()
	SlashCmdList.TESTALERT()
end)

local checkboxes = {}
local sliders = {}
local dropdowns = {}
local editboxes = {}

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
	value = floor(value*100)/100
	NotificationsOptions[f.option] = value
	Notifications.options[f.option] = value

	if f.textInput then
		f.textInput:SetText(value)
	end

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

local function onEscapePressed(self)
	self:ClearFocus()
end

local function onEnterPressed(self)
	local slider = self:GetParent()
	local min, max = slider:GetMinMaxValues()

	local value = tonumber(self:GetText())
	if value and value >= floor(min) and value <= floor(max) then
		slider:SetValue(value)
	else
		self:SetText(floor(slider:GetValue()*100)/100)
	end

	self:ClearFocus()
end

local function createNumberSlider(name, option, text, lowText, highText, low, high, step, alignRight)
	local slider = createSlider(name, option, text, lowText, highText, low, high, step)

	local f = CreateFrame("EditBox", baseName..name, slider)
	f:SetAutoFocus(false)
	f:SetWidth(60)
	f:SetHeight(20)
	f:SetMaxLetters(8)
	f:SetFontObject(GameFontHighlight)

	if alignRight then
		slider:SetPoint("RIGHT", f, "LEFT", -20, 0)
	else
		f:SetPoint("LEFT", slider, "RIGHT", 20, 0)
	end

	f:SetScript("OnEscapePressed", onEscapePressed)
	f:SetScript("OnEnterPressed", onEnterPressed)

	local left = f:CreateTexture(baseName..name.."Left", "BACKGROUND")
	left:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Left2")
	left:SetSize(32, 32)
	left:SetPoint("LEFT", -8, 0)
	local right = f:CreateTexture(baseName..name.."Right", "BACKGROUND")
	right:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Right2")
	right:SetSize(32, 32)
	right:SetPoint("RIGHT", 5, 0)
	local mid = f:CreateTexture(baseName..name.."Middle", "BACKGROUND")
	mid:SetTexture("Interface\\ChatFrame\\UI-ChatInputBorder-Mid2")
	mid:SetSize(0, 32)
	mid:SetPoint("TOPLEFT", left, "TOPRIGHT")
	mid:SetPoint("TOPRIGHT", right, "TOPLEFT")

	slider.textInput = f

	tinsert(editboxes, f)

	return slider
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

	UIDropDownMenu_SetWidth(f, 100)

	tinsert(dropdowns, f)

	return f
end

local playSounds = createCheckBox("PlaySounds", "playSounds", "Play sound")
playSounds:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -26)
local animations = createCheckBox("Animations", "animations", "Animate the banner")
animations:SetPoint("TOPLEFT", playSounds, "BOTTOMLEFT", 0, -8)

local interval = createNumberSlider("Interval", "interval", "Animation speed", SLOW, FAST, .1, 1, .1)
interval:SetPoint("TOPLEFT", animations, "BOTTOMLEFT", 16, -24)
local intervalLabel = interval:CreateFontString(nil, nil, "GameFontHighlightSmall")
intervalLabel:SetPoint("TOPLEFT", interval, "BOTTOMLEFT", 0, -16)
intervalLabel:SetText("A slower animation speed ensures a smoother animation.")

local timeShown = createNumberSlider("TimeShown", "timeShown", "Time shown", TOAST_DURATION_SHORT, TOAST_DURATION_LONG, 1, 15, 1)
timeShown:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 0, -24)

local position = createDropDown("Position", "position", "Position", {"Top", "Top Right", "Right", "Bottom Right", "Bottom", "Bottom Left", "Left", "Top Left"})
position:SetPoint("TOPRIGHT", version, "BOTTOMRIGHT", 0, -26)

local width = createNumberSlider("Width", "width", "Width", SMALL, LARGE, 50, 1000, 1, true)
width.textInput:SetPoint("TOPRIGHT", position, "BOTTOMRIGHT", -18, -24)

local height = createNumberSlider("Height", "height", "Height", SMALL, LARGE, 50, 1000, 1, true)
height.textInput:SetPoint("TOPRIGHT", width.textInput, "BOTTOMRIGHT", 0, -24)

-- add event handlers

gui.refresh = function()
	for _, box in pairs(checkboxes) do
		box:SetChecked(Notifications.options[box.option])
	end

	for _, slider in pairs(sliders) do
		slider:SetValue(Notifications.options[slider.option])
		if slider.textInput and slider.textInput:GetCursorPosition() == slider.textInput:GetNumLetters() then
			slider.textInput:SetCursorPosition(0)
		end
	end

	for _, dropdown in pairs(dropdowns) do
		UIDropDownMenu_Initialize(dropdown, initialize)
		UIDropDownMenu_SetSelectedValue(dropdown, Notifications.options[dropdown.option])
	end

	-- don't allow huge dimensions
	width:SetMinMaxValues(50, GetScreenWidth() / 1.5)
	height:SetMinMaxValues(10, GetScreenHeight() / 4)
end

gui.okay = function()
	-- refresh the 'old' table for the next gui.cancel()
	copyTable(Notifications.options, old)
end

gui.cancel = function()
	-- copy the old values to the cache and to saved vars if they exist
	copyTable(old, Notifications.options)
	copyTableExisting(old, NotificationsOptions)

	Notifications:Update()
end

gui.default = function()
	copyTable(defaults, Notifications.options)
	copyTable(defaults, NotificationsOptions)

	Notifications:Update()
end

gui:RegisterEvent("ADDON_LOADED")
gui:SetScript("OnEvent", function()
	gui:UnregisterEvent("ADDON_LOADED")

	-- backup the cache in case we call gui.cancel()
	copyTable(Notifications.options, old)
end)

-- easy slash command

SlashCmdList.NOTIFICATIONS = function()
	InterfaceOptionsFrame_OpenToCategory(gui)
end
SLASH_NOTIFICATIONS1 = "/notifications"

-- Aurora theme support

if Aurora or FreeUI then
	local F = unpack(Aurora or FreeUI)

	F.Reskin(test)

	for _, box in pairs(checkboxes) do
		F.ReskinCheck(box)
	end

	for _, slider in pairs(sliders) do
		F.ReskinSlider(slider)
	end

	for _, dropdown in pairs(dropdowns) do
		F.ReskinDropDown(dropdown)
	end

	for _, editbox in pairs(editboxes) do
		F.ReskinInput(editbox)
	end
end