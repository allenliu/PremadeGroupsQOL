local addonName, ns = ...

-- =====================================================================
-- Applicant sort: descending Mythic+ score
-- Post-hooks LFGListApplicationViewer_UpdateResultList. Blizzard's
-- default sort (LFGListUtil_SortApplicants) runs first — new-at-bottom,
-- then by displayOrderID. Our re-sort overrides with primary member's
-- dungeonScore desc. Runs for everyone in the party, since the panel's
-- UnempoweredCover only dims the view; the data and code path are the
-- same regardless of leadership.
-- =====================================================================

local function getPrimaryScore(applicantID)
    -- GetApplicantMemberInfo returns:
    --   name, class, localizedClass, level, itemLevel, honorLevel,
    --   tank, healer, damage, assignedRole, relationship, dungeonScore, ...
    local _, _, _, _, _, _, _, _, _, _, _, dungeonScore =
        C_LFGList.GetApplicantMemberInfo(applicantID, 1)
    return dungeonScore or 0
end

local function compareApplicants(a, b)
    local sa, sb = getPrimaryScore(a), getPrimaryScore(b)
    if sa ~= sb then return sa > sb end
    -- Tiebreaker: stable-ish on applicantID so order doesn't churn between
    -- equal-score applicants when the list updates.
    return a < b
end

hooksecurefunc("LFGListApplicationViewer_UpdateResultList", function(self)
    if not self.applicants then return end
    table.sort(self.applicants, compareApplicants)
end)

-- =====================================================================
-- [OCE] badge on applicant member names
-- Realms in the US datacenter that belong to the Oceanic group. Used to
-- visually flag applicants likely to have low latency in OCE-led groups.
-- Update this list if Blizzard renames or adds OCE realms.
-- =====================================================================

local OCE_REALMS = {
    ["Aman'Thul"]   = true,
    ["Barthilas"]   = true,
    ["Caelestrasz"] = true,
    ["Dath'Remar"]  = true,
    ["Dreadmaul"]   = true,
    ["Frostmourne"] = true,
    ["Gundrak"]     = true,
    ["Jubei'Thos"]  = true,
    ["Khaz'goroth"] = true,
    ["Nagrand"]     = true,
    ["Saurfang"]    = true,
    ["Thaurissan"]  = true,
}

local function isOCEName(name)
    if not name or name == "" then return false end
    -- Cross-realm names look like "PlayerName-Realm"; same-realm names
    -- drop the suffix, so we fall back to the player's own realm.
    local realm = name:match("%-(.+)$") or GetRealmName()
    return OCE_REALMS[realm] == true
end

-- Cache OCE determinations per (applicantID, memberIdx) so we don't lose the
-- tag once we've confirmed it. The applicant's name from GetApplicantMemberInfo
-- can arrive in stages (the realm suffix may load later than the character
-- name). Without the cache, a hook fire that catches the partial state would
-- evaluate to non-OCE, and any subsequent SetText from Blizzard would erase a
-- tag that an earlier full-data fire had applied.
--
-- Only positive determinations are cached (key present = OCE). For absent
-- keys we always re-evaluate, so a later fire with full data can promote the
-- applicant to OCE. The cache is cleared whenever our listing changes.
local oceCache = {}

hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(member, appID, memberIdx)
    if not (member and member.Name) then return end
    local key = appID .. ":" .. memberIdx

    if not oceCache[key] then
        local name = C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
        if isOCEName(name) then
            oceCache[key] = true
        end
    end

    if oceCache[key] then
        local current = member.Name:GetText() or ""
        if not current:find("%[OCE%]") then
            member.Name:SetText(current .. " [OCE]")
        end
    end
end)

local oceCacheFrame = CreateFrame("Frame")
oceCacheFrame:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
oceCacheFrame:SetScript("OnEvent", function()
    wipe(oceCache)
end)
