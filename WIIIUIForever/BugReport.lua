local _, addon = ...

local issueURL = "https://github.com/Hmimesh/WIIIUIForever/issues/new"
local issueDialog = "WIIIUIFOREVER_ISSUE_LINK"

function addon.RegisterSettings(settings, setEnabled, selectTheme)
    if not Settings or not Settings.RegisterCanvasLayoutCategory then return end

    StaticPopupDialogs[issueDialog] = {
        text = "Press Ctrl+C to copy the GitHub issue link, then open it in your browser.",
        button1 = CLOSE,
        hasEditBox = true,
        editBoxWidth = 360,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
        OnShow = function(dialog)
            local editBox = dialog:GetEditBox()
            editBox:SetText(issueURL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
    }

    local panel = CreateFrame("Frame")
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 24, -24)
    title:SetText("WIIIUI Forever")

    local report = CreateFrame("Button", nil, panel)
    report:SetSize(24, 24)
    report:SetPoint("TOPRIGHT", -24, -20)
    report:SetNormalTexture("Interface\\HelpFrame\\HelpIcon-Bug")
    report:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    report:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Report a bug")
        GameTooltip:AddLine("GitHub Issues", 1, 1, 1)
        GameTooltip:Show()
    end)
    report:SetScript("OnLeave", function() GameTooltip:Hide() end)
    report:SetScript("OnClick", function() StaticPopup_Show(issueDialog) end)

    local enabled = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    enabled:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -4, -16)
    enabled.Text:SetText("Enable console")
    enabled:SetScript("OnClick", function(self) setEnabled(self:GetChecked()) end)

    local themeLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    themeLabel:SetPoint("TOPLEFT", enabled, "BOTTOMLEFT", 4, -14)
    themeLabel:SetText("Theme")

    local themeButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    themeButton:SetSize(120, 24)
    themeButton:SetPoint("LEFT", themeLabel, "RIGHT", 12, 0)
    themeButton:SetScript("OnClick", function(self)
        MenuUtil.CreateContextMenu(self, function(_, menu)
            for _, theme in ipairs({ "human", "orc", "undead", "nightelf" }) do
                menu:CreateRadio(addon.themes[theme].label, function(value)
                    return settings.theme == value
                end, function(value)
                    selectTheme(value)
                    self:SetText(addon.themes[settings.theme].label)
                end, theme)
            end
        end)
    end)

    panel:SetScript("OnShow", function()
        enabled:SetChecked(settings.enabled)
        themeButton:SetText(addon.themes[settings.theme].label)
    end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, "WIIIUI Forever")
    Settings.RegisterAddOnCategory(category)
end
