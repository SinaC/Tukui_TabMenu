--## OptionalDeps: Recount, Omen

local UI
if ElvUI then UI=ElvUI else UI=Tukui end
local T, C, L = unpack(UI) -- Import Functions/Constants, Config, Locales

-- Config
local tabSize = C.actionbar.buttonsize
local tabSpacing = C.actionbar.buttonspacing
local selectionColor = {r = 23/255, g = 132/255, b = 209/255}

-- anchor: tab anchor (tab will be added to this frame  .tabLeft, .tabRight, .tabTop, .tabBottom)
-- position: LEFT, RIGHT, TOP, BOTTOM (position of tab relative to anchor)
-- name: tab name
-- textureName: path to texture to display on tab
-- frameToToggle: frame or frame name or function returning frame
local function AddTab(anchor, position, name, textureName, alwaysVisible, frameToToggle)
	if not anchor then return end
	-- get tabList and tabIndex
	local tabList = nil
	if position == "LEFT" then
		tabList = anchor.tabLeft
	elseif position == "RIGHT" then
		tabList = anchor.tabRight
	elseif position == "TOP" then
		tabList = anchor.tabTop
	elseif position == "BOTTOM" then
		tabList = anchor.tabBottom
	end
	local tabIndex = 1 + (tabList and #tabList or 0)

	--print("AddTab:"..(tabList and #tabList or 'nil').."  "..tabIndex.."  "..name)

	-- creation
	local button = CreateFrame("Button", name.."ToggleSwitch"..tabIndex, UIParent)
	button:CreatePanel(button, tabSize, tabSize, "TOPRIGHT", anchor, "TOPLEFT", -1, 0)
	if tabIndex == 1 then
		if position == "LEFT" then
			button:ClearAllPoints()
			button:Point("TOPRIGHT", anchor, "TOPLEFT", -1, 0)
		elseif position == "RIGHT" then
			button:ClearAllPoints()
			button:Point("TOPLEFT", anchor, "TOPRIGHT", 1, 0)
		elseif position == "TOP" then
			button:ClearAllPoints()
			button:Point("BOTTOMLEFT", anchor, "TOPLEFT", 0, 1)
		elseif position == "BOTTOM" then
			button:ClearAllPoints()
			button:Point("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
		end
	else
		if position == "LEFT" or position == "RIGHT" then
			button:CreatePanel(button, tabSize, tabSize, "TOP", tabList[tabIndex-1], "BOTTOM", 0, -tabSpacing)
		else
			button:CreatePanel(button, tabSize, tabSize, "LEFT", tabList[tabIndex-1], "RIGHT", -tabSpacing, 0)
		end
	end
	button:CreateShadow("Default")
	button:EnableMouse(true)
	button:RegisterForClicks("AnyUp")
	if not alwaysVisible then button:SetAlpha(0) end

	-- texture
	button.texture = button:CreateTexture(nil, "ARTWORK")
	button.texture:SetTexture(textureName)
	button.texture:Point("TOPLEFT", button, 2, -2)
	button.texture:Point("BOTTOMRIGHT", button, -2, 2)

	local function GetframeToToggle()
		if type(frameToToggle) == "function" then return frameToToggle()
		elseif type(frameToToggle) == "string" then return _G[frameToToggle]
		else return frameToToggle end
	end

	-- texture color function
	local function SetTextureColor(self)
		local frame = GetframeToToggle()
		--print("SetTextureColor:"..(frame and frame:GetName() or "nil").." "..tostring(frame and frame:IsShown() or "nil"))
		if frame and frame:IsShown() then
			-- Selected
			self.texture:SetVertexColor(35/255, 164/255, 255/255)
		else
			-- Not selected
			self.texture:SetVertexColor(1, 1, 1)
		end
	end

	-- hook function
	local function SetHook(self, frame)
		if not frame.tabHooked then
			-- hook OnShow/OnHide
			frame:HookScript("OnShow",
				function(hooked)
					SetTextureColor(self)
				end)
			frame:HookScript("OnHide",
				function(hooked)
					SetTextureColor(self)
					if not alwaysVisible then self:SetAlpha(0) end
				end)
			frame.tabHooked = true
		end
	end

	-- tooltip function
	local function SetTooltip(self, frame)
		GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, T.Scale(6))
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, T.mult)
		GameTooltip:ClearLines()
		if frame and frame:IsShown() then
			GameTooltip:AddDoubleLine(HIDE, name, selectionColor.r, selectionColor.g, selectionColor.b, 1, 1, 1)
		else
			GameTooltip:AddDoubleLine(SHOW, name, selectionColor.r, selectionColor.g, selectionColor.b, 1, 1, 1)
		end
		GameTooltip:Show()
	end

	-- events
	button:SetScript("OnEnter",
		function(self)
			local frame = GetframeToToggle()
			if not alwaysVisible then button:SetAlpha(1) end
			SetTooltip(self, frame)
		end)
	button:SetScript("OnLeave",
		function(self)
			local frame = GetframeToToggle()
			if frame and not frame:IsShown() and not alwaysVisible then button:SetAlpha(0) end
			GameTooltip:Hide()
		end)
	button:SetScript("OnMouseDown",
		function(self)
			self.texture:Point("TOPLEFT", self, 4, -4)
			self.texture:Point("BOTTOMRIGHT", self, -4, 4)
		end)
	button:SetScript("OnMouseUp",
		function(self)
			self.texture:Point("TOPLEFT", self, 2, -2)
			self.texture:Point("BOTTOMRIGHT", self, -2, 2)
		end)
	button:SetScript("OnClick",
		function(self)
			local frame = GetframeToToggle()
			-- load addon if not found
			-- if not frame then
				-- if not IsAddOnLoaded(name) then
					-- print("Loading "..name.."...")
					-- local loaded, reason = LoadAddOn(name)
					-- if loaded then
						-- print("Loaded successfully")
						-- frame = GetframeToToggle()
					-- else
						-- print("Load failed, reason: ".._G["ADDON_"..reason])
						-- return
					-- end
				-- end
			-- end
			if frame then
				SetHook(self, frame)
				ToggleFrame(frame)
				SetTooltip(self, frame)
			else
				print("Tukui_TabMenu: Frame not found")
			end
		end)

	-- Set texture color
	SetTextureColor(button)

	local frame = GetframeToToggle()
	if frame then
		SetHook(button, frame)
	end

	-- save tab in anchor frame
	if position == "LEFT" then
		if not anchor.tabLeft then anchor.tabLeft = { button }
		else anchor.tabLeft[tabIndex] = button end
	elseif position == "RIGHT" then
		if not anchor.tabRight then anchor.tabRight = { button }
		else anchor.tabRight[tabIndex] = button end
	elseif position == "TOP" then
		if not anchor.tabTop then anchor.tabTop = { button }
		else anchor.tabTop[tabIndex] = button end
	elseif position == "BOTTOM" then
		if not anchor.tabBottom then anchor.tabBottom = { button }
		else anchor.tabBottom[tabIndex] = button end
	end
end

-------------------------------------------------------------------------
-- Tabs
-------------------------------------------------------------------------
local tabAnchorRight = ElvUI and ChatRBGDummy or TukuiChatBackgroundRight -- C["chat"].["background"] must be set to true
local tabAnchorLeft = ElvUI and ChatRBGDummy or TukuiChatBackgroundLeft -- C["chat"].["background"] must be set to true

-- Use a function to pass frame as parameter if you are not sure the frame is already created
-- Encounter Journal
AddTab(tabAnchorRight, "LEFT", "Encounter Journal", "Interface\\AddOns\\Tukui_TabMenu\\media\\EJ", true, EncounterJournal)
-- Recount
AddTab(tabAnchorRight, "LEFT", "Recount", "Interface\\AddOns\\Tukui_TabMenu\\media\\Recount", true, function() return Recount and Recount.MainWindow end)
-- Omen
AddTab(tabAnchorRight, "LEFT", "Omen", "Interface\\AddOns\\Tukui_TabMenu\\media\\Omen", true, function() return Omen and Omen.Anchor end)
