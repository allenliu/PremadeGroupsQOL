local addonName, ns = ...

ns.db = nil

-- Defaults mirror the addon's prior unconditional behavior, so a first-time
-- load with no SavedVariables produces the same experience as before settings
-- existed. defaultPlaystyle uses Enum.LFGEntryGeneralPlaystyle.FunSerious,
-- which is the "Competitive" radio (4th value, "Expert", is "Carry Offered").
local DEFAULTS = {
    sortApplicantsByScore  = true,
    showOCEBadge           = true,
    defaultPlaystyle       = Enum.LFGEntryGeneralPlaystyle.FunSerious,
    stripPlaystyleFromTitle = true,
}
ns.DEFAULTS = DEFAULTS

-- Enum.LFGEntryGeneralPlaystyle.None may be nil in some patch versions;
-- 0 is its documented numeric value and is safe to use directly.
ns.PLAYSTYLE_NONE = (Enum.LFGEntryGeneralPlaystyle and Enum.LFGEntryGeneralPlaystyle.None) or 0

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        PremadeGroupsQOLDB = PremadeGroupsQOLDB or {}
        ns.db = PremadeGroupsQOLDB
        ns.db.settings = ns.db.settings or {}
        for k, v in pairs(DEFAULTS) do
            if ns.db.settings[k] == nil then
                ns.db.settings[k] = v
            end
        end
        if ns.InitSettings then ns.InitSettings() end
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
