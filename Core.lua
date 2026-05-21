local addonName, ns = ...

ns.db = nil

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        WowLFGDB = WowLFGDB or { version = 1 }
        ns.db = WowLFGDB
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
