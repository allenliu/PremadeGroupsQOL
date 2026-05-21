local addonName, ns = ...

local dropdown

local function populateMenu(_, root)
    root:SetTag("MENU_PGQOL_KEYS")
    local keys = ns.keystone.GetAllKnownKeys()
    if #keys == 0 then
        root:CreateButton(GRAY_FONT_COLOR:WrapTextInColorCode("No keys detected"), function() end)
        return
    end
    for _, key in ipairs(keys) do
        local who = key.isSelf and "You" or key.playerName
        local text = string.format("%s — %s +%d", who, key.dungeonName, key.level)
        root:CreateButton(text, function()
            LFGListEntryCreation_Select(
                LFGListFrame.EntryCreation,
                nil,
                GROUP_FINDER_CATEGORY_ID_DUNGEONS,
                key.groupID,
                key.activityID
            )
            if dropdown.OverrideText then
                dropdown:OverrideText(text)
            end
        end)
    end
end

local function createUI()
    if dropdown then return end
    local panel = LFGListFrame and LFGListFrame.EntryCreation
    if not (panel and panel.GroupDropdown) then return end

    local row = CreateFrame("Frame", "PGQOLKeyPickerRow", panel)
    row:SetSize(360, 36)
    row:SetPoint("BOTTOMLEFT", panel.GroupDropdown, "TOPLEFT", 0, 8)

    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    label:SetText("Use Key")

    dropdown = CreateFrame("DropdownButton", "PGQOLKeyDropdown", row, "WowStyle1DropdownTemplate")
    dropdown:SetSize(220, 22)
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -2)
    dropdown:SetDefaultText("Select a key...")
    dropdown:SetupMenu(populateMenu)
end

ns.keystone = ns.keystone or {}
-- The dropdown's SetupMenu callback re-runs on every open, so on-change
-- notifications would only matter for an already-open menu. Cheap no-op.
ns.keystone.onChange = function() end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if LFGListFrame and LFGListFrame.EntryCreation and LFGListFrame.EntryCreation.GroupDropdown then
        createUI()
        if dropdown then
            self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            self:UnregisterEvent("ADDON_LOADED")
        end
    end
end)
