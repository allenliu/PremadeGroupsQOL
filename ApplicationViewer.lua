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

hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(member, appID, memberIdx)
    if not (member and member.Name) then return end
    local name = C_LFGList.GetApplicantMemberInfo(appID, memberIdx)
    if not isOCEName(name) then return end

    local current = member.Name:GetText() or ""
    if not current:find("%[OCE%]") then
        member.Name:SetText(current .. " [OCE]")
    end
end)
