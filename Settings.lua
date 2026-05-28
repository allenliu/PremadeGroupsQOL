local addonName, ns = ...

-- The settings panel is built lazily on first need (either via ADDON_LOADED
-- calling ns.InitSettings, or via /pgqol). The slash command is registered
-- at file-load time so it stays available even if panel registration fails;
-- pcall surfaces any registration error to chat instead of silently breaking.

local category
local initError

local function buildPanel()
    if category or initError then return end

    local ok, err = pcall(function()
        category = Settings.RegisterVerticalLayoutCategory("Premade Groups QOL")

        local function AddCheckbox(key, name, tooltip)
            local setting = Settings.RegisterAddOnSetting(
                category, "PGQOL_" .. key, key, ns.db.settings,
                Settings.VarType.Boolean, name, ns.DEFAULTS[key]
            )
            Settings.CreateCheckbox(category, setting, tooltip)
        end

        AddCheckbox(
            "sortApplicantsByScore",
            "Sort applicants by M+ score",
            "Re-sort the applicant list descending by the primary applicant's Mythic+ rating."
        )
        AddCheckbox(
            "showOCEBadge",
            "Show [OCE] badge on applicants",
            "Append [OCE] to the names of applicants whose realm belongs to the Oceanic group."
        )
        AddCheckbox(
            "stripPlaystyleFromTitle",
            "Omit playstyle from auto-filled title",
            "Exclude the playstyle name when the title is auto-filled (e.g. \"+20\" instead of \"+20 Competitive\")."
        )

        local playstyleSetting = Settings.RegisterAddOnSetting(
            category, "PGQOL_defaultPlaystyle", "defaultPlaystyle", ns.db.settings,
            Settings.VarType.Number, "Default playstyle for new listings", ns.DEFAULTS.defaultPlaystyle
        )
        Settings.CreateDropdown(
            category, playstyleSetting,
            function()
                local container = Settings.CreateControlTextContainer()
                container:Add(Enum.LFGEntryGeneralPlaystyle.None,       "Don't override")
                container:Add(Enum.LFGEntryGeneralPlaystyle.Standard,   "Standard")
                container:Add(Enum.LFGEntryGeneralPlaystyle.FunSerious, "Competitive")
                container:Add(Enum.LFGEntryGeneralPlaystyle.Expert,     "Carry Offered")
                return container:GetData()
            end,
            "Playstyle radio selected by default when opening a fresh listing. \"Don't override\" leaves Blizzard's default in place."
        )

        Settings.RegisterAddOnCategory(category)

        -- The "Defaults" button at the bottom of the panel is a single shared
        -- element on SettingsPanel (no per-category opt-out exists in the
        -- API). Hook DisplayCategory and hide it whenever our category is
        -- the one being shown.
        if SettingsPanel and SettingsPanel.DisplayCategory then
            hooksecurefunc(SettingsPanel, "DisplayCategory", function(self, cat)
                local btn = self:GetSettingsList().Header.DefaultsButton
                if btn then btn:SetShown(cat ~= category) end
            end)
        end
    end)

    if not ok then
        initError = err
        category = nil
    end
end

function ns.InitSettings()
    if ns.db and ns.db.settings then buildPanel() end
end

SLASH_PGQOL1 = "/pgqol"
SlashCmdList["PGQOL"] = function()
    if not (ns.db and ns.db.settings) then
        print("|cffff7f7f[PGQOL]|r settings not loaded yet — try /reload.")
        return
    end
    buildPanel()
    if initError then
        print("|cffff7f7f[PGQOL]|r failed to register settings panel: " .. tostring(initError))
        return
    end
    if not category then
        print("|cffff7f7f[PGQOL]|r settings panel unavailable.")
        return
    end
    Settings.OpenToCategory(category:GetID())
end
