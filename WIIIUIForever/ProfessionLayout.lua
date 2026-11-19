local _, addon = ...

function addon.SetupProfessionLayout(settings)
    local events = CreateFrame("Frame")
    local border, previousAlpha
    local function refresh()
        if not border then return end
        if settings.enabled then
            if previousAlpha == nil then previousAlpha = border:GetAlpha() end
            border:SetAlpha(0)
        elseif previousAlpha ~= nil then
            border:SetAlpha(previousAlpha)
            previousAlpha = nil
        end
    end

    local function attach()
        local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
        local form = page and page.SchematicForm
        if not form or not form.NineSlice then return end
        border = form.NineSlice
        -- Forever clears this border's anchors to remove it, but recipe Init
        -- shows it again and its retained geometry can extend outside the frame.
        border:HookScript("OnShow", refresh)
        events:UnregisterEvent("ADDON_LOADED")
        refresh()
    end

    addon.RefreshProfessionLayout = refresh
    events:RegisterEvent("ADDON_LOADED")
    events:SetScript("OnEvent", function(_, _, name)
        if name == "Blizzard_Professions" then attach() end
    end)
    attach()
end
