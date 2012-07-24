-- Options table, change this if editing locally
-- Developers: To edit, change Notifications.options in your addon then call Notifications:Update()

local options = {
	playSounds = true,
	animations = true, -- scale and fade the banner on show/hide. Not recommended for slow PCs.
	timeShown = 5, -- amount of time the banner is shown before it disappears. Mousing over the banner keeps it shown.
	interval = 0.1, -- difference in opacity/scale per new frame when the banner animates. Lower = smoother, but also slower.

	position = "TOP", -- choose a side of the screen
	width = 400,
	height = 50,
	iconSize = 32,

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

-- Create frame and stuff

local f = CreateFrame("Frame", "Notifications", UIParent)
f:SetFrameStrata("FULLSCREEN_DIALOG")
f:Hide()
f:SetAlpha(0.1)
f:SetScale(0.1)

local icon = f:CreateTexture(nil, "OVERLAY")
f.icon = icon

local iconBg = CreateFrame("Frame", nil, f)
iconBg:SetPoint("CENTER", icon)
f.iconBg = iconBg

local sep = f:CreateTexture(nil, "BACKGROUND")
f.sep = sep

local title = f:CreateFontString(nil, "OVERLAY")
title:SetJustifyH("LEFT")
f.title = title

local text = f:CreateFontString(nil, "OVERLAY")
text:SetJustifyH("LEFT")
f.text = text

f.options = options

-- Banner show/hide animations

local bannerShown = false

local function hideBanner()
	if options.animations then
		local scale
		f:SetScript("OnUpdate", function(self)
			scale = self:GetScale() - options.interval
			if scale <= 0.1 then
				self:SetScript("OnUpdate", nil)
				self:Hide()
				bannerShown = false
				return
			end
			self:SetScale(scale)
			self:SetAlpha(scale)
		end)
	else
		f:Hide()
		f:SetScale(0.1)
		f:SetAlpha(0.1)
		bannerShown = false
	end
end

local function fadeTimer()
	local last = 0
	f:SetScript("OnUpdate", function(self, elapsed)
		last = last + elapsed
		if last >= options.timeShown then
			self:SetScript("OnUpdate", nil)
			hideBanner()
		end
	end)
end

local function showBanner()
	bannerShown = true
	if options.animations then
		f:Show()
		local scale
		f:SetScript("OnUpdate", function(self)
			scale = self:GetScale() + options.interval
			self:SetScale(scale)
			self:SetAlpha(scale)
			if scale >= 1 then
				self:SetScale(1)
				self:SetScript("OnUpdate", nil)
				fadeTimer()
			end
		end)
	else
		f:SetScale(1)
		f:SetAlpha(1)
		f:Show()
		fadeTimer()
	end
end

-- Display a notification

local function display(name, message, clickFunc, texture, ...)
	if type(clickFunc) == "function" then
		f.clickFunc = clickFunc
	else
		f.clickFunc = nil
	end

	if type(texture) == "string" then
		icon:SetTexture(texture)
	else
		icon:SetTexture(options.defaultIcon)
	end
	
	if ... then
		icon:SetTexCoord(...)
	else
		icon:SetTexCoord(.08, .92, .08, .92)
	end
	
	title:SetText(name)
	text:SetText(message)
	
	showBanner()
	
	if options.playSounds == true then
		PlaySoundFile("Interface\\AddOns\\Notifications\\sound.mp3")
	end
end

-- Handle incoming notifications

local handler = CreateFrame("Frame")
local incoming = {}
local processing = false

local function handleIncoming()
	processing = true
	local i = 1

	handler:SetScript("OnUpdate", function(self)
		if incoming[i] == nil then
			self:SetScript("OnUpdate", nil)
			incoming = {}
			processing = false
			return
		else
			if not bannerShown then
				display(unpack(incoming[i]))
				i = i + 1
			end
		end
	end)
end

handler:SetScript("OnEvent", function(self, _, unit)
	if unit == "player" and not UnitIsAFK("player") then
		handleIncoming()
		self:UnregisterEvent("PLAYER_FLAGS_CHANGED")
	end
end)

-- The API show function

function Notifications:Alert(message, clickFunc, texture, ...)
	local _, _, name = strsplit("\\", debugstack(2))
	name = GetAddOnInfo(name)
	if UnitIsAFK("player") then
		tinsert(incoming, {name, message, clickFunc, texture, ...})
		handler:RegisterEvent("PLAYER_FLAGS_CHANGED")
	elseif bannerShown or #incoming ~= 0 then
		tinsert(incoming, {name, message, clickFunc, texture, ...})
		if not processing then
			handleIncoming()
		end
	else
		display(name, message, clickFunc, texture, ...)
	end
end

-- Call this function after editing options remotely

function Notifications:Update()
	f:SetSize(options.width, options.height)
	local position = options.position
	local x, y = 0
	if position:find("TOP") then
		y = options.borderSize
	elseif position:find("BOTTOM") then
		y = -options.borderSize
	end
	if position:find("LEFT") then
		x = -options.borderSize
	elseif position:find("RIGHT") then
		x = options.borderSize
	end
	f:ClearAllPoints()
	f:SetPoint(position, UIParent, position, x, y)
	f:SetBackdrop({
		bgFile = options.border,
		edgeFile = options.backdrop,
		edgeSize = options.borderSize,
		insets = {left = options.inset, right = options.inset, top = options.inset, bottom = options.inset}
	})
	f:SetBackdropColor(options.bgRed, options.bgGreen, options.bgBlue, options.bgAlpha)
	f:SetBackdropBorderColor(options.borderRed, options.borderGreen, options.borderBlue, options.borderAlpha)
	
	local spacing = (options.height - (options.iconSize + (2 * options.borderSize))) / 2 -- distance between icon and banner border

	icon:SetPoint("LEFT", f, "LEFT", spacing, 0)
	icon:SetSize(options.iconSize, options.iconSize)
	
	iconBg:SetSize(options.iconSize + (options.borderSize * 2), options.iconSize + (options.borderSize * 2))
	iconBg:SetBackdrop({
		edgeFile = options.backdrop,
		edgeSize = options.borderSize,
		insets = {left = options.inset, right = options.inset, top = options.inset, bottom = options.inset}
	})
	iconBg:SetBackdropBorderColor(options.borderRed, options.borderGreen, options.borderBlue, options.borderAlpha)

	sep:SetSize(options.separatorWidth, options.height)
	sep:SetPoint("LEFT", icon, "RIGHT", spacing, 0)
	sep:SetTexture(options.separatorUseRGB == true and options.separatorRed, options.separatorGreen, options.separatorBlue or options.separatorTexture)
	sep:SetAlpha(options.separatorAlpha)
	
	title:SetPoint("TOPLEFT", sep, "TOPRIGHT", spacing, -spacing)
	title:SetPoint("RIGHT", f, -spacing, 0)	
	title:SetFont(options.font, options.fontSize + 2)
	title:SetTextColor(options.textRed, options.textGreen, options.textBlue)
	title:SetShadowOffset(options.shadowH, options.shadowV)
	title:SetShadowColor(options.shadowRed, options.shadowGreen, options.shadowBlue)

	text:SetPoint("BOTTOMLEFT", sep, "BOTTOMRIGHT", spacing, spacing)
	text:SetPoint("RIGHT", f, -spacing, 0)	
	text:SetFont(options.font, options.fontSize)
	text:SetTextColor(options.textRed, options.textGreen, options.textBlue)
	text:SetShadowOffset(options.shadowH, options.shadowV)
	text:SetShadowColor(options.shadowRed, options.shadowGreen, options.shadowBlue)
end

-- Mouse events

f:SetScript("OnEnter", function(self)
	self:SetScript("OnUpdate", nil)
	self:SetScale(1)
	self:SetAlpha(1)
end)

f:SetScript("OnLeave", fadeTimer)

f:SetScript("OnMouseUp", function(self, button)
	self:SetScript("OnUpdate", nil)
	self:Hide()
	self:SetScale(0.1)
	self:SetAlpha(0.1)
	bannerShown = false
	-- right click just hides the banner
	if button ~= "RightButton" and f.clickFunc then
		f.clickFunc()
	end
end)

-- Load saved variables if present

f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, addon)
	if addon ~= "Notifications" then return end
	self:UnregisterEvent("ADDON_LOADED")
	
	local vars = NotificationsOptions
	
	if not vars then vars = {} end

	for option in pairs(options) do
		if vars[option] ~= nil then
			options[option] = vars[option]
		end
	end
	
	Notifications:Update()
end)

-- Test function

local function testCallback()
	print("Banner clicked!")
end

SlashCmdList.TESTALERT = function(b)
	Notifications:Alert("This is an example of a notification.", testCallback, b == "true" and "INTERFACE\\ICONS\\SPELL_FROST_ARCTICWINDS" or nil, .08, .92, .08, .92)
end
SLASH_TESTALERT1 = "/testalert"