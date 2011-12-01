--## OptionalDeps: Recount, Omen

-- APIs
-- AddToggleTab(anchor, position, name, textureName, alwaysVisible, frameToToggle) no return value
--	anchor: tab anchor
--	position: LEFT, RIGHT, TOP, BOTTOM (position of tab relative to anchor)
--	name: tab name
--	textureName: path to texture to display on tab
--	alwaysVisible: if false, tab is visible only when mouseovering it
--	frameToToggle: frame or frame name or function returning frame
--
-- AddCustomTab(anchor, position, name, textureName) return tab
--	anchor: tab anchor
--	position: LEFT, RIGHT, TOP, BOTTOM (position of tab relative to anchor)
--	name: tab name
--	textureName: path to texture to display on tab

local UI
if ElvUI then UI=ElvUI else UI=Tukui end
local T, C, L = unpack(UI) -- Import Functions/Constants, Config, Locales

-- Namespace
Tukui_TabMenu = {}

-- Config
local tabSize = C.actionbar.buttonsize
local tabSpacing = C.actionbar.buttonspacing
local selectionColor = {r = 23/255, g = 132/255, b = 209/255}

local function GetTabListAndIndex(anchor, position)
	local tabList = nil
	if position == "LEFT" then
		tabList = anchor.tabMenuLeft
	elseif position == "RIGHT" then
		tabList = anchor.tabMenuRight
	elseif position == "TOP" then
		tabList = anchor.tabMenuTop
	elseif position == "BOTTOM" then
		tabList = anchor.tabMenuBottom
	end
	local tabIndex = 1 + (tabList and #tabList or 0)
	return tabList, tabIndex
end

local function AddToTabList(tab, tabIndex, anchor, position)
	--print("AddToTabList: "..tostring(anchor.tabMenuLeft).."  "..tostring(anchor).."  "..tostring(tab))
	if position == "LEFT" then
		if not anchor.tabMenuLeft then anchor.tabMenuLeft = { tab }
		else anchor.tabMenuLeft[tabIndex] = tab end
	elseif position == "RIGHT" then
		if not anchor.tabMenuRight then anchor.tabMenuRight = { tab }
		else anchor.tabMenuRight[tabIndex] = tab end
	elseif position == "TOP" then
		if not anchor.tabMenuTop then anchor.tabMenuTop = { tab }
		else anchor.tabMenuTop[tabIndex] = tab end
	elseif position == "BOTTOM" then
		if not anchor.tabMenuBottom then anchor.tabMenuBottom = { tab }
		else anchor.tabMenuBottom[tabIndex] = tab end
	end
end

-- anchor: tab anchor
-- position: LEFT, RIGHT, TOP, BOTTOM (position of tab relative to anchor)
-- name: tab name
-- textureName: path to texture to display on tab
-- alwaysVisible: if false, tab is visible only when mouseovering it
-- frameToToggle: frame or frame name or function returning frame
-- toggleFunc: function to toggle frame (optional)
function Tukui_TabMenu:AddToggleTab(anchor, position, name, textureName, alwaysVisible, frameToToggle, toggleFunc)
	if not anchor then
		print("|CFFFF0000Tukui_TabMenu|r: anchor not found for "..tostring(name))
		return
	end
	-- get tabList and tabIndex
	local tabList, tabIndex = GetTabListAndIndex(anchor, position)
	--print("AddToggleTab:"..tostring(tabList).."  "..tostring(tabIndex).."  "..tostring(anchor).."  "..tostring(tabSize))

	-- creation
	local tab = CreateFrame("Button", name.."ToggleTab"..tabIndex, UIParent)
	tab:CreatePanel("Default", tabSize, tabSize, "TOPRIGHT", anchor, "TOPLEFT", -1, 0)
	if tabIndex == 1 then
		if position == "LEFT" then
			tab:ClearAllPoints()
			tab:Point("TOPRIGHT", anchor, "TOPLEFT", -1, 0)
		elseif position == "RIGHT" then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", anchor, "TOPRIGHT", 1, 0)
		elseif position == "TOP" then
			tab:ClearAllPoints()
			tab:Point("BOTTOMLEFT", anchor, "TOPLEFT", 0, 1)
		elseif position == "BOTTOM" then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
		end
	else
		if position == "LEFT" or position == "RIGHT" then
			tab:CreatePanel(tab, tabSize, tabSize, "TOP", tabList[tabIndex-1], "BOTTOM", 0, -tabSpacing)
		else
			tab:CreatePanel(tab, tabSize, tabSize, "LEFT", tabList[tabIndex-1], "RIGHT", -tabSpacing, 0)
		end
	end
	tab:CreateShadow("Default")
	tab:EnableMouse(true)
	tab:RegisterForClicks("AnyUp")
	if not alwaysVisible then tab:SetAlpha(0) end

	-- texture
	tab.texture = tab:CreateTexture(nil, "ARTWORK")
	tab.texture:SetTexture(textureName)
	tab.texture:Point("TOPLEFT", tab, 2, -2)
	tab.texture:Point("BOTTOMRIGHT", tab, -2, 2)

	local function GetFrameToToggle()
		if type(frameToToggle) == "function" then return frameToToggle()
		elseif type(frameToToggle) == "string" then return _G[frameToToggle]
		else return frameToToggle end
	end

	-- texture color function
	local function SetTextureColor(self)
		local frame = GetFrameToToggle()
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
		if not frame.tabMenuHooked then
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
			frame.tabMenuHooked = true
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
	tab:SetScript("OnEnter",
		function(self)
			local frame = GetFrameToToggle()
			if not alwaysVisible then tab:SetAlpha(1) end
			SetTooltip(self, frame)
		end)
	tab:SetScript("OnLeave",
		function(self)
			local frame = GetFrameToToggle()
			if frame and not frame:IsShown() and not alwaysVisible then tab:SetAlpha(0) end
			GameTooltip:Hide()
		end)
	tab:SetScript("OnMouseDown",
		function(self)
			self.texture:Point("TOPLEFT", self, 4, -4)
			self.texture:Point("BOTTOMRIGHT", self, -4, 4)
		end)
	tab:SetScript("OnMouseUp",
		function(self)
			self.texture:Point("TOPLEFT", self, 2, -2)
			self.texture:Point("BOTTOMRIGHT", self, -2, 2)
		end)
	tab:SetScript("OnClick",
		function(self)
			if toggleFunc then
				toggleFunc()
				local frame = GetFrameToToggle()
				if frame then
					SetHook(self, frame)
					SetTooltip(self, frame)
				else
					print("Tukui_TabMenu: Frame for "..name.." not found")
				end
			else
				local frame = GetFrameToToggle()
				-- load addon if not found
				-- if not frame then
					-- if not IsAddOnLoaded(name) then
						-- print("Loading "..name.."...")
						-- local loaded, reason = LoadAddOn(name)
						-- if loaded then
							-- print("Loaded successfully")
							-- frame = GetFrameToToggle()
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
					print("Tukui_TabMenu: Frame for "..name.." not found")
				end
			end
		end)

	-- Set texture color
	SetTextureColor(tab)

	local frame = GetFrameToToggle()
	if frame then
		SetHook(tab, frame)
	end

	-- save tab in anchor frame
	AddToTabList(tab, tabIndex, anchor, position)
end

function Tukui_TabMenu:AddCustomTab(anchor, position, name, textureName)
	if not anchor then return end
	-- get tabList and tabIndex
	local tabList, tabIndex = GetTabListAndIndex(anchor, position)

	-- creation
	local tab = CreateFrame("Button", name.."CustomTab"..tabIndex, UIParent)
	tab:CreatePanel(tab, tabSize, tabSize, "TOPRIGHT", anchor, "TOPLEFT", -1, 0)
	if tabIndex == 1 then
		if position == "LEFT" then
			tab:ClearAllPoints()
			tab:Point("TOPRIGHT", anchor, "TOPLEFT", -1, 0)
		elseif position == "RIGHT" then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", anchor, "TOPRIGHT", 1, 0)
		elseif position == "TOP" then
			tab:ClearAllPoints()
			tab:Point("BOTTOMLEFT", anchor, "TOPLEFT", 0, 1)
		elseif position == "BOTTOM" then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
		end
	else
		if position == "LEFT" or position == "RIGHT" then
			tab:CreatePanel(tab, tabSize, tabSize, "TOP", tabList[tabIndex-1], "BOTTOM", 0, -tabSpacing)
		else
			tab:CreatePanel(tab, tabSize, tabSize, "LEFT", tabList[tabIndex-1], "RIGHT", -tabSpacing, 0)
		end
	end
	tab:CreateShadow("Default")
	tab:EnableMouse(true)
	tab:RegisterForClicks("AnyUp")

	-- texture
	tab.texture = tab:CreateTexture(nil, "ARTWORK")
	tab.texture:SetTexture(textureName)
	tab.texture:Point("TOPLEFT", tab, 2, -2)
	tab.texture:Point("BOTTOMRIGHT", tab, -2, 2)

	-- events
	tab:SetScript("OnMouseDown",
		function(self)
			self.texture:Point("TOPLEFT", self, 4, -4)
			self.texture:Point("BOTTOMRIGHT", self, -4, 4)
		end)
	tab:SetScript("OnMouseUp",
		function(self)
			self.texture:Point("TOPLEFT", self, 2, -2)
			self.texture:Point("BOTTOMRIGHT", self, -2, 2)
		end)

	-- save tab in anchor frame
	AddToTabList(tab, anchor, position)
	
	return tab
end

-------------------------------------------------------------------------
-- Tabs
-------------------------------------------------------------------------
local tabAnchorRight = ElvUI and ChatRBGDummy or TukuiChatBackgroundRight -- C["chat"].["background"] must be set to true
local tabAnchorLeft = ElvUI and ChatRBGDummy or TukuiChatBackgroundLeft -- C["chat"].["background"] must be set to true

-- Use a function to pass frame as parameter if you are not sure the frame is already created
-- Encounter Journal
Tukui_TabMenu:AddToggleTab(tabAnchorRight, "LEFT", "Encounter Journal", "Interface\\AddOns\\Tukui_TabMenu\\media\\EJ", true, "EncounterJournal", ToggleEncounterJournal)
-- Recount
Tukui_TabMenu:AddToggleTab(tabAnchorRight, "LEFT", "Recount", "Interface\\AddOns\\Tukui_TabMenu\\media\\Recount", true, function() return Recount and Recount.MainWindow end)
-- Omen
Tukui_TabMenu:AddToggleTab(tabAnchorRight, "LEFT", "Omen", "Interface\\AddOns\\Tukui_TabMenu\\media\\Omen", true, function() return Omen and Omen.Anchor end)
