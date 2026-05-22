local addonName, ns = ...

-- =====================================================================
-- Title generation
-- Name EditBox is securityDisableSetText: we can prevent fills but not
-- restore. Rules:
--   1. ns.titleSuppress (one-shot) skips the fill entirely. Used when
--      picking a party member's key — C_LFGList.SetEntryTitle would use
--      our own keystone level, not theirs, so the result is misleading.
--   2. Skip when the box is non-empty (preserves user text and prior fills).
--   3. ns.titleForceFill (one-shot) overrides the non-empty guard. The
--      self-key picker click sets it to refresh the title on demand.
--   4. When we do fill, pass Enum.LFGEntryGeneralPlaystyle.None so the
--      auto-filled title doesn't include the playstyle name ("+20 Competitive"
--      → "+20"). Guards mirror Blizzard's LFGList.lua:1303-1311 verbatim.
-- =====================================================================

LFGListEntryCreation_SetTitleFromActivityInfo = function(self)
    local nameBox = self.Name
    local currentText = nameBox and nameBox:GetText() or ""

    local forceFill = ns.titleForceFill
    local suppress = ns.titleSuppress
    ns.titleForceFill = false
    ns.titleSuppress = false

    if suppress then return end
    if currentText ~= "" and not forceFill then return end

    if not self.selectedActivity or not self.selectedGroup or not self.selectedCategory then return end
    local activeEntryInfo = C_LFGList.GetActiveEntryInfo()
    local activityID = activeEntryInfo and activeEntryInfo.activityIDs[1] or (self.selectedActivity or 0)
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID)
    if (activityInfo and activityInfo.isMythicPlusActivity)
       or IsActivityLockedForCustomText(self.selectedCategory, self.selectedActivity) then
        C_LFGList.SetEntryTitle(self.selectedActivity, self.selectedGroup, self.selectedPlaystyle, Enum.LFGEntryGeneralPlaystyle.None)
    end
end

-- =====================================================================
-- Activity / group selection tracking
-- - viewActivityID mirrors the currently-displayed activity. Updated on
--   any non-system Select call. Used to preserve difficulty when the
--   user switches dungeons.
-- - userGroupID only tracks explicit user group picks. Used to restore
--   the dungeon after SetEditMode(false)'s keystone override (the cause
--   of "delist then reopen forgets my dungeon").
-- Classification:
--   userGroupPick = groupID set, activityID nil   (left dropdown click)
--   systemCall    = both groupID and activityID set
--                   (keystone override, our own restoration, etc.)
-- =====================================================================

local viewActivityID = nil
local userGroupID = nil

local function getDifficultyKey(info)
    if not info then return nil end
    if info.isMythicPlusActivity then return "mplus" end
    if info.isMythicActivity     then return "mythic" end
    if info.isHeroicActivity     then return "heroic" end
    if info.isNormalActivity     then return "normal" end
    return info.shortName or info.fullName
end

local function findMatchingActivity(targetKey, categoryID, groupID, filters)
    if not (targetKey and categoryID and groupID) then return nil end
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID, filters)
    if not activities then return nil end
    for _, actID in ipairs(activities) do
        local info = C_LFGList.GetActivityInfoTable(actID)
        if getDifficultyKey(info) == targetKey then
            return actID
        end
    end
    return nil
end

local origSelect = LFGListEntryCreation_Select
LFGListEntryCreation_Select = function(self, filters, categoryID, groupID, activityID)
    local userGroupPick = groupID and not activityID
    local systemCall    = groupID and activityID

    if userGroupPick and viewActivityID then
        local prevInfo = C_LFGList.GetActivityInfoTable(viewActivityID)
        local matched = findMatchingActivity(
            getDifficultyKey(prevInfo),
            categoryID or self.selectedCategory,
            groupID,
            filters or self.selectedFilters
        )
        if matched then
            activityID = matched
        end
    end

    origSelect(self, filters, categoryID, groupID, activityID)

    -- Update viewActivityID on any non-system call, AND on system calls
    -- when no explicit user pick has been recorded yet. This keeps the
    -- tracker in sync with what's actually displayed during a fresh open
    -- (Show's Select + the keystone override that follows in SetEditMode),
    -- while still ignoring later system calls that would clobber a user
    -- pick (e.g. the delist-reopen keystone override).
    if self.selectedActivity and (not systemCall or not userGroupID) then
        viewActivityID = self.selectedActivity
    end
    if userGroupPick then
        userGroupID = groupID
    end
end

-- Restore the user's chosen dungeon after SetEditMode(false)'s keystone
-- override. Skipped when editing an existing listing (editMode == true)
-- or when the user hasn't explicitly picked a group this session.
hooksecurefunc("LFGListEntryCreation_SetEditMode", function(self, editMode)
    if editMode then return end
    if not userGroupID then return end
    if self.selectedGroup == userGroupID then return end
    LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, userGroupID, viewActivityID)
end)

-- =====================================================================
-- Default playstyle to Competitive on fresh panel opens
-- Hook Clear (not OnShow): Clear only fires when Show takes the
-- not-keepOldData branch, so this won't override the user's prior
-- playstyle pick when Blizzard preserves panel data across reopens.
-- The active-entry check guards against unusual edit-mode paths.
-- =====================================================================

hooksecurefunc("LFGListEntryCreation_Clear", function(self)
    viewActivityID = nil
    userGroupID = nil
    if not C_LFGList.GetActiveEntryInfo() then
        -- FunSerious = the 3rd radio = "Competitive". The 4th (Expert)
        -- is "Carry Offered" despite its enum name.
        self.generalPlaystyle = Enum.LFGEntryGeneralPlaystyle.FunSerious
    end
    if ns.HideTitleHint then ns.HideTitleHint() end
end)

-- =====================================================================
-- Title hint label
-- Created lazily on first need. Shown next to the "Title" header when
-- the user picks a party member's key, indicating the level they need
-- to type (since the field can't be filled programmatically). Hides as
-- soon as they start typing.
-- =====================================================================

local titleHint

local function ensureTitleHint()
    if titleHint then return titleHint end
    local panel = LFGListFrame and LFGListFrame.EntryCreation
    if not (panel and panel.NameLabel and panel.Name) then return nil end

    titleHint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    titleHint:SetPoint("LEFT", panel.NameLabel, "RIGHT", 8, 0)
    titleHint:SetTextColor(0.4, 1, 0.4)
    titleHint:Hide()

    panel.Name:HookScript("OnTextChanged", function(_, userInput)
        if userInput and titleHint then titleHint:Hide() end
    end)

    return titleHint
end

function ns.ShowTitleHint(text)
    local lbl = ensureTitleHint()
    if not lbl then return end
    lbl:SetText(text)
    lbl:Show()
end

function ns.HideTitleHint()
    if titleHint then titleHint:Hide() end
end

-- WowStyle1Dropdown's displayed label is updated via SignalUpdate, NOT
-- GenerateMenu. Re-poll the radios so the visible label reflects whatever
-- self.generalPlaystyle currently is (Expert from us, or active entry's
-- playstyle when editing).
hooksecurefunc("LFGListEntryCreation_OnShow", function(self)
    if self.PlayStyleDropdown and self.PlayStyleDropdown.SignalUpdate then
        self.PlayStyleDropdown:SignalUpdate()
    end
end)

-- =====================================================================
-- Filter the dungeon dropdown to Mythic+ keystone dungeons only
-- Applied to the Dungeons category; other categories are unchanged.
-- "More" is forced visible so non-M+ activities remain reachable via
-- the ActivityFinder.
-- Body is verbatim from Blizzard's LFGListEntryCreation_SetupGroupDropdown
-- (LFGList.lua:782-871) except for the WowLFG-marked filter block.
-- =====================================================================

local function hasMythicPlusActivity(categoryID, groupID, filters)
    local activities = C_LFGList.GetAvailableActivities(categoryID, groupID, filters)
    if not activities then return false end
    for _, actID in ipairs(activities) do
        local info = C_LFGList.GetActivityInfoTable(actID)
        if info and info.isMythicPlusActivity then
            return true
        end
    end
    return false
end

LFGListEntryCreation_SetupGroupDropdown = function(self)
    self.GroupDropdown.overrideName = nil
    self.GroupDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:SetTag("MENU_LFG_FRAME_GROUP")

        if not self.selectedCategory then return end

        -- WowLFG: Party Keys section at the top of the dungeon dropdown.
        -- Lists keystones held by self + party members (via LibKeystone).
        -- A click sets titleForceFill so the title hook refreshes even when
        -- the EditBox is non-empty, then calls Select to populate dungeon
        -- and difficulty.
        if self.selectedCategory == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
            local keys = ns.keystone and ns.keystone.GetAllKnownKeys() or {}
            if #keys > 0 then
                rootDescription:CreateTitle("Party Keys")
                for _, key in ipairs(keys) do
                    local who = key.isSelf and "You" or key.playerName
                    local text = string.format("%s — %s +%d", who, key.dungeonName, key.level)
                    rootDescription:CreateButton(text, function()
                        if key.isSelf then
                            -- Our own key: let the C-side fill produce "+<myLevel>"
                            ns.titleForceFill = true
                        else
                            -- Party member's key: C-side fill returns empty
                            -- (doesn't match our own keystone). Suppress it,
                            -- then write the picker's level via Insert below.
                            ns.titleSuppress = true
                        end
                        LFGListEntryCreation_Select(
                            self,
                            nil,
                            GROUP_FINDER_CATEGORY_ID_DUNGEONS,
                            key.groupID,
                            key.activityID
                        )
                        if not key.isSelf then
                            -- securityDisableSetText blocks both SetText AND
                            -- Insert, so we can't programmatically fill the
                            -- title. Best we can do: focus + select existing
                            -- text so any keystroke replaces it, and show a
                            -- hint label with the level the user should type.
                            local nameBox = self.Name
                            if nameBox then
                                nameBox:SetFocus()
                                nameBox:HighlightText()
                            end
                            if ns.ShowTitleHint then
                                ns.ShowTitleHint("+" .. key.level)
                            end
                        else
                            if ns.HideTitleHint then ns.HideTitleHint() end
                        end
                    end)
                end
                rootDescription:CreateDivider()
            end
        end

        local useMore = false

        local groups = C_LFGList.GetAvailableActivityGroups(self.selectedCategory, bit.bor(self.baseFilters, self.selectedFilters))
        local activities = C_LFGList.GetAvailableActivities(self.selectedCategory, 0, bit.bor(self.baseFilters, self.selectedFilters))
        if self.selectedFilters == 0 then
            if #groups + #activities > 5 then
                local filters = bit.bor(self.selectedFilters, self.baseFilters, Enum.LFGListFilter.Recommended)
                local recGroups = C_LFGList.GetAvailableActivityGroups(self.selectedCategory, filters)
                local recActivities = C_LFGList.GetAvailableActivities(self.selectedCategory, 0, filters)

                if #recGroups + #recActivities > 0 then
                    useMore = #recGroups ~= #groups or #recActivities ~= #activities
                    groups = recGroups
                    activities = recActivities
                end
            end
        end

        -- WowLFG: limit to M+ keystone-capable entries for Dungeons.
        -- Always force "More" so the full list stays reachable.
        if self.selectedCategory == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
            local filters = bit.bor(self.baseFilters, self.selectedFilters)
            local filteredGroups, filteredActivities = {}, {}
            for _, groupID in ipairs(groups) do
                if hasMythicPlusActivity(self.selectedCategory, groupID, filters) then
                    filteredGroups[#filteredGroups + 1] = groupID
                end
            end
            for _, actID in ipairs(activities) do
                local info = C_LFGList.GetActivityInfoTable(actID)
                if info and info.isMythicPlusActivity then
                    filteredActivities[#filteredActivities + 1] = actID
                end
            end
            if #filteredGroups + #filteredActivities > 0 then
                groups, activities = filteredGroups, filteredActivities
                useMore = true
            end
        end

        local groupOrder = groups[1] and select(2, C_LFGList.GetActivityGroupInfo(groups[1]))
        local firstActivityInfo = activities[1] and C_LFGList.GetActivityInfoTable(activities[1])
        local activityOrder = firstActivityInfo and firstActivityInfo.orderIndex
        local groupIndex, activityIndex = 1, 1

        local function IsActivitySelected(activityID)
            return self.selectedActivity == activityID
        end

        local function SetActivitySelected(activityID)
            LFGListEntryCreation_Select(self, nil, nil, nil, activityID)
        end

        local function IsGroupSelected(groupID)
            return self.selectedGroup == groupID
        end

        local function SetGroupSelected(groupID)
            LFGListEntryCreation_Select(self, self.selectedFilters, self.selectedCategory, groupID)
        end

        for i = 1, MAX_LFG_LIST_GROUP_DROPDOWN_ENTRIES do
            if not groupOrder and not activityOrder then break end

            if activityOrder and (not groupOrder or activityOrder < groupOrder) then
                local activityID = activities[activityIndex]
                local activityInfo = activityID and C_LFGList.GetActivityInfoTable(activityID)
                local name = activityInfo and activityInfo.shortName
                rootDescription:CreateRadio(name, IsActivitySelected, SetActivitySelected, activityID)

                activityIndex = activityIndex + 1
                local nextActivityInfo = activities[activityIndex] and C_LFGList.GetActivityInfoTable(activities[activityIndex])
                activityOrder = nextActivityInfo and nextActivityInfo.orderIndex
            else
                local groupID = groups[groupIndex]
                local name = C_LFGList.GetActivityGroupInfo(groupID)
                rootDescription:CreateRadio(name, IsGroupSelected, SetGroupSelected, groupID)

                groupIndex = groupIndex + 1
                groupOrder = groups[groupIndex] and select(2, C_LFGList.GetActivityGroupInfo(groups[groupIndex]))
            end
        end

        if #activities + #groups > MAX_LFG_LIST_GROUP_DROPDOWN_ENTRIES then
            useMore = true
        end

        if useMore then
            rootDescription:CreateButton(LFG_LIST_MORE, function()
                LFGListEntryCreationActivityFinder_Show(self.ActivityFinder, self.selectedCategory, nil, bit.bor(self.baseFilters, self.selectedFilters))
            end)
        end
    end)
end
