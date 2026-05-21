local addonName, ns = ...

ns.keystone = ns.keystone or {}
local K = ns.keystone

-- challengeMapID → { activityID, groupID, dungeonName }
-- Built by bridging C_ChallengeMode.GetMapUIInfo's uiMapID return to
-- C_LFGList.GetActivityInfoTable's mapID field. No direct API for the
-- challengeMapID → activityID conversion as of 11.0.7.
K.lookup = {}

-- name (Ambiguated by LibKeystone) → { level, challengeMapID, rating, isSelf }
K.keys = {}

K.onChange = nil

local function notifyChange()
    if K.onChange then K.onChange() end
end

local playerName = UnitNameUnmodified("player")

local function buildLookup()
    wipe(K.lookup)
    local cat = GROUP_FINDER_CATEGORY_ID_DUNGEONS
    if not cat then return end

    local byUiMapID = {}
    local groups = C_LFGList.GetAvailableActivityGroups(cat)
    if groups then
        for _, groupID in ipairs(groups) do
            local activities = C_LFGList.GetAvailableActivities(cat, groupID)
            if activities then
                for _, actID in ipairs(activities) do
                    local info = C_LFGList.GetActivityInfoTable(actID)
                    if info and info.isMythicPlusActivity and info.mapID then
                        byUiMapID[info.mapID] = {
                            activityID = actID,
                            groupID = groupID,
                            shortName = info.shortName,
                        }
                    end
                end
            end
        end
    end

    local maps = C_ChallengeMode.GetMapTable()
    if maps then
        for _, challengeMapID in ipairs(maps) do
            local name, _, _, _, _, uiMapID = C_ChallengeMode.GetMapUIInfo(challengeMapID)
            local entry = uiMapID and byUiMapID[uiMapID]
            if entry then
                K.lookup[challengeMapID] = {
                    activityID = entry.activityID,
                    groupID = entry.groupID,
                    dungeonName = name or entry.shortName,
                }
            end
        end
    end
end

function K.GetAllKnownKeys()
    local result = {}
    for name, data in pairs(K.keys) do
        local entry = K.lookup[data.challengeMapID]
        if entry then
            result[#result + 1] = {
                playerName = name,
                level = data.level,
                rating = data.rating,
                activityID = entry.activityID,
                groupID = entry.groupID,
                dungeonName = entry.dungeonName,
                isSelf = data.isSelf,
            }
        end
    end
    table.sort(result, function(a, b)
        if a.isSelf ~= b.isSelf then return a.isSelf end
        if a.level ~= b.level then return a.level > b.level end
        return a.playerName < b.playerName
    end)
    return result
end

local function onLKSCallback(level, challengeMapID, rating, name, channel)
    if channel ~= "PARTY" then return end
    if not name or name == "" then return end
    if level <= 0 or challengeMapID <= 0 then
        K.keys[name] = nil
    else
        K.keys[name] = {
            level = level,
            challengeMapID = challengeMapID,
            rating = rating,
            isSelf = (name == playerName),
        }
    end
    notifyChange()
end

function K.RequestPartyKeys()
    local LKS = LibStub and LibStub("LibKeystone", true)
    if LKS then LKS.Request("PARTY") end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_ENTERING_WORLD")
loader:RegisterEvent("LFG_LIST_AVAILABILITY_UPDATE")
loader:RegisterEvent("GROUP_ROSTER_UPDATE")
loader:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        local LKS = LibStub and LibStub("LibKeystone", true)
        if LKS then LKS.Register(ns, onLKSCallback) end
        C_LFGList.RequestAvailableActivities()
        buildLookup()
        K.RequestPartyKeys()
    elseif event == "LFG_LIST_AVAILABILITY_UPDATE" then
        buildLookup()
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Party membership changed; drop stale entries and re-poll
        wipe(K.keys)
        K.RequestPartyKeys()
        notifyChange()
    end
end)
