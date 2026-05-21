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
            -- Signal the title hook to override its non-empty guard for this
            -- one call. A key pick is explicit intent to refresh the title.
            ns.titleForceFill = true
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
    if not (panel and panel.GroupDropdown and panel.NameLabel) then return end

    -- Free 30px above NameLabel for the key picker. NameLabel was anchored
    -- TOPLEFT x=20, y=-120 in LFGList.xml. Shifting it cascades to the Title
    -- EditBox and (via $parent.NameLabel) DescriptionLabel + everything below.
    panel.NameLabel:ClearAllPoints()
    panel.NameLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -150)

    dropdown = CreateFrame("DropdownButton", "PGQOLKeyDropdown", panel, "WowStyle1DropdownTemplate")
    dropdown:SetSize(240, 22)
    dropdown:SetPoint("TOPLEFT", panel.GroupDropdown, "BOTTOMLEFT", 0, -8)
    dropdown:SetDefaultText("Use Key…")
    dropdown:SetupMenu(populateMenu)
end

ns.keystone = ns.keystone or {}
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
