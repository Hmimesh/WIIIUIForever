local _, addon = ...

local modes = {
    { key = "both", label = "Icon and text" },
    { key = "icon", label = "Icon only" },
    { key = "text", label = "Text only" },
    { key = "hidden", label = "Hidden" },
}
local states = {
    off = { "PvP off", "INV_Shield_05", { 0.68, 0.68, 0.63 }, false, "You are not flagged for PvP." },
    on = { "PvP on", "INV_BannerPVP_01", { 1, 0.74, 0.3 }, true, "You are flagged for player-versus-player combat." },
    ffa = { "PvP FFA", "Ability_DualWield", { 1, 0.5, 0.2 }, true, "Free-for-all PvP is active." },
    unknown = { "PvP —", "INV_Misc_QuestionMark", { 0.7, 0.7, 0.7 }, true, "The client is withholding your current PvP state." },
    aggro = { "Aggro", "Spell_Shadow_DeathScream", { 1, 0.3, 0.22 }, true, "An enemy is focused on you." },
    threat = { "High threat", "Ability_Racial_BloodRage", { 1, 0.64, 0.2 }, true, "You have threat, but are not currently tanking." },
    combat = { "In combat", "Ability_DualWield", { 1, 0.7, 0.25 }, true, "You are in combat." },
    resting = { "Resting", "Spell_Nature_Sleep", { 0.4, 0.72, 1 }, true, "You are in a resting area." },
    idle = { "Idle", "INV_Misc_PocketWatch_01", { 0.68, 0.68, 0.63 }, false, "You are out of combat." },
}

function addon.CreateStatusIndicators(console, character)
    local options = type(character.statusIndicators) == "table" and character.statusIndicators or {}
    character.statusIndicators, console.statusOptions = options, options
    for _, key in ipairs({ "pvpMode", "combatMode" }) do
        local valid = false
        for _, mode in ipairs(modes) do if options[key] == mode.key then valid = true end end
        if not valid then options[key] = "both" end
    end
    if options.style ~= "simple" then options.style = "warcraft" end
    console.statusIndicators = {}
    for _, kind in ipairs({ "pvp", "combat" }) do
        local badge = CreateFrame("Frame", nil, console, "BackdropTemplate")
        badge:EnableMouse(true)
        badge.chrome = addon.CreateConsoleChrome(badge)
        badge.icon = badge:CreateTexture(nil, "ARTWORK")
        badge.icon:SetSize(14, 14)
        badge.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        badge.label = badge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        badge.label:SetWordWrap(false)
        badge:SetScript("OnEnter", function(self)
            if not self.state then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.state[1], unpack(self.state[3]))
            GameTooltip:AddLine(self.state[5], 1, 1, 1, true)
            GameTooltip:Show()
        end)
        badge:SetScript("OnLeave", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        console.statusIndicators[kind] = badge
    end
    console.pvpStatus = console.statusIndicators.pvp.label
    console.combatStatus = console.statusIndicators.combat.label
end

function addon.UpdatePlayerStatus(console)
    local flagged, freeForAll = UnitIsPVP("player"), UnitIsPVPFreeForAll("player")
    local pvpState
    if not issecretvalue(freeForAll) and freeForAll then pvpState = "ffa"
    elseif issecretvalue(flagged) or issecretvalue(freeForAll) then pvpState = "unknown"
    elseif flagged then pvpState = "on"
    else pvpState = "off" end
    local threat, combatState = UnitThreatSituation("player")
    if not issecretvalue(threat) and type(threat) == "number" and threat >= 2 then combatState = "aggro"
    elseif not issecretvalue(threat) and type(threat) == "number" and threat == 1 then combatState = "threat"
    elseif InCombatLockdown() then combatState = "combat"
    elseif IsResting() then combatState = "resting"
    else combatState = "idle" end

    local options, x = console.statusOptions, 216
    for _, kind in ipairs({ "pvp", "combat" }) do
        local badge = console.statusIndicators[kind]
        local state = states[kind == "pvp" and pvpState or combatState]
        local mode = options[kind .. "Mode"]
        local shown = mode ~= "hidden" and (not options[kind .. "ActiveOnly"] or state[4])
        badge.state = state
        badge.label:SetText(state[1])
        badge.label:SetTextColor(unpack(state[3]))
        local icon = ({ off = "armor", on = "pvp", ffa = "combat", aggro = "aggro", threat = "threat", combat = "combat", resting = "resting", idle = "armor" })[kind == "pvp" and pvpState or combatState]
        if icon == "pvp" then
            badge.icon:SetTexture(addon.artPath .. console.theme .. "\\chrome\\pvp.tga")
        elseif icon then
            badge.icon:SetTexture(addon.artPath .. "wc3\\" .. icon .. ".tga")
        else
            badge.icon:SetTexture("Interface\\Icons\\" .. state[2])
        end
        badge.icon:SetDesaturated(not state[4])
        if badge.style ~= options.style then
            local styled = options.style == "warcraft"
            if styled then
                badge:SetBackdrop(nil)
            else
                badge:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                    insets = { left = 3, right = 3, top = 3, bottom = 3 },
                })
            end
            badge.style = options.style
        end
        if options.style == "simple" then
            badge:SetBackdropColor(0.10, 0.08, 0.05, 0.96)
            badge:SetBackdropBorderColor(unpack(state[3]))
        end
        local width = mode == "icon" and 24 or (kind == "pvp" and 76 or 96)
        badge:SetSize(width, 18)
        badge.chrome:SetSize(width, 18)
        badge.chrome:SetTheme(console.theme)
        badge.chrome:SetShown(options.style == "warcraft")
        badge:ClearAllPoints()
        badge:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", x, 127)
        badge.icon:ClearAllPoints()
        badge.label:ClearAllPoints()
        if mode == "both" then
            badge.icon:SetPoint("LEFT", 4, 0)
            badge.label:SetPoint("LEFT", 21, 0)
            badge.label:SetWidth(width - 25)
            badge.label:SetJustifyH("LEFT")
        else
            badge.icon:SetPoint("CENTER")
            badge.label:SetPoint("CENTER")
            badge.label:SetWidth(width - 8)
            badge.label:SetJustifyH("CENTER")
        end
        badge.icon:SetShown(mode == "icon" or mode == "both")
        badge.label:SetShown(mode == "text" or mode == "both")
        badge:SetShown(shown)
        if shown then x = x + width + 4 end
        if not shown and GameTooltip:GetOwner() == badge then GameTooltip:Hide() end
    end
end

function addon.AddStatusMenu(menu, console)
    local root = menu:CreateButton("PvP and combat indicators")
    local options = console.statusOptions
    for _, entry in ipairs({ { "pvp", "PvP", "Hide when PvP is off" }, { "combat", "Combat", "Hide while idle" } }) do
        local key, activeKey = entry[1] .. "Mode", entry[1] .. "ActiveOnly"
        local submenu = root:CreateButton(entry[2])
        for _, mode in ipairs(modes) do
            submenu:CreateRadio(mode.label, function(value) return options[key] == value end, function(value)
                options[key] = value
                addon.UpdatePlayerStatus(console)
            end, mode.key)
        end
        submenu:CreateCheckbox(entry[3], function() return options[activeKey] == true end, function()
            options[activeKey] = not options[activeKey]
            addon.UpdatePlayerStatus(console)
        end)
    end
    local styles = root:CreateButton("Style")
    for _, style in ipairs({ { "warcraft", "Warcraft frame" }, { "simple", "Simple frame" } }) do
        styles:CreateRadio(style[2], function(value) return options.style == value end, function(value)
            options.style = value
            addon.UpdatePlayerStatus(console)
        end, style[1])
    end
end
