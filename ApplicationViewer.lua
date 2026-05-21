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
