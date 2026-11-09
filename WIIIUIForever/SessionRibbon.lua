local _, addon = ...

local metrics = {
    xpHour = { label = "XP / hour", icon = "Spell_Holy_BorrowedTime" },
    xp = { label = "XP gained", icon = "INV_Misc_Book_09" },
    gold = { label = "Gold gained", icon = "INV_Misc_Coin_01" },
    goldHour = { label = "Gold / hour", icon = "INV_Misc_Coin_02" },
    money = { label = "Current money", icon = "INV_Misc_Bag_10" },
    time = { label = "Session time", icon = "INV_Misc_PocketWatch_01" },
    levelTime = { label = "Time to level", icon = "Spell_Holy_BorrowedTime" },
    rested = { label = "Rested XP", icon = "Spell_Nature_Sleep" },
    none = { label = "Hidden" },
}
local order = { "xpHour", "xp", "gold", "goldHour", "money", "time", "levelTime", "rested", "none" }
local defaults = { "xpHour", "gold", "goldHour", "time", "levelTime" }

local function readable(value)
    return not issecretvalue(value) and type(value) == "number" and value == value and value < math.huge
end

local function duration(seconds)
    seconds = math.max(0, math.floor(seconds))
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

local function validSession(session)
    if type(session) ~= "table" then return false end
    for _, key in ipairs({ "started", "xp", "gold", "money", "lastXP", "lastMax", "level" }) do
        if not readable(session[key]) or session[key] < 0 then return false end
    end
    return session.started <= GetServerTime()
end

function addon.SetupSessionRibbon(console, character, settings, openSettings)
    local options = type(character.ribbon) == "table" and character.ribbon or {}
    character.ribbon = options
    options.enabled = options.enabled ~= false
    options.showClock = options.showClock ~= false
    if options.backing ~= "transparent" then options.backing = "warcraft" end
    options.slots = type(options.slots) == "table" and options.slots or {}
    for index, key in ipairs(defaults) do
        if not metrics[options.slots[index]] then options.slots[index] = key end
    end

    local ribbon = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ribbon:SetFrameStrata("LOW")
    ribbon:SetPoint("TOP", UIParent, "TOP", 0, -3)
    ribbon:SetHeight(34)
    -- The original console beam has its own alpha-shaped edges. Do not
    -- place a solid rectangular backdrop underneath it.
    local backing = {}
    for index, crop in ipairs({ { 0, 24 }, { 24, 488 }, { 488, 512 } }) do
        local texture = ribbon:CreateTexture(nil, "BACKGROUND")
        texture:SetTexCoord(crop[1] / 512, crop[2] / 512, 0, 56 / 512)
        backing[index] = texture
    end
    ribbon:Hide()
    local cog = CreateFrame("Button", nil, ribbon)
    cog:SetSize(82, 28)
    cog:SetPoint("LEFT", 0, 0)
    local header = addon.CreateConsoleChrome(cog)
    header:SetSize(82, 28)
    cog:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    cog:SetScript("OnClick", openSettings)
    local title = cog:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("CENTER")
    title:SetText("Session")

    local clock = CreateFrame("Frame", nil, ribbon)
    clock:SetSize(52, 52)
    clock:SetPoint("TOPLEFT", ribbon, "TOPLEFT", 82, 0)
    clock:SetFrameLevel(ribbon:GetFrameLevel())
    clock:EnableMouse(true)
    local face = clock:CreateTexture(nil, "ARTWORK")
    face:SetSize(32, 32)
    face:SetPoint("CENTER")
    face:SetTexture(addon.artPath .. "wc3\\day-night.tga", "REPEAT", "CLAMP")
    local mask = clock:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(face)
    face:AddMaskTexture(mask)
    local rim = clock:CreateTexture(nil, "OVERLAY")
    rim:SetSize(52 * 256 / 96, 52 * 128 / 96)
    rim:SetPoint("TOP", clock, "TOP", 0, 0)
    clock.face, clock.rim = face, rim
    local state = { frame = ribbon, options = options, character = character, cells = {}, clock = clock, backing = backing }
    console.sessionRibbon = state
    local function clockTooltip()
        GameTooltip:SetOwner(clock, "ANCHOR_BOTTOM")
        GameTooltip:SetText(string.format("Game time %02d:%02d", state.hour or 0, state.minute or 0))
        GameTooltip:AddLine(state.isDay and "Daytime" or "Nighttime", 1, 1, 1)
        GameTooltip:AddLine("The sun and moon follow realm time and the game's day/night cycle.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end
    clock:SetScript("OnEnter", clockTooltip)
    clock:SetScript("OnLeave", function()
        if GameTooltip:GetOwner() == clock then GameTooltip:Hide() end
    end)
    function state:UpdateClock()
        local hour, minute = GetGameTime()
        if not readable(hour) or not readable(minute) then return end
        self.hour, self.minute = hour, minute
        local time = hour + minute / 60 + (GetServerTime() % 60) / 3600
        local day
        if C_DateAndTime and C_DateAndTime.IsDayTime then day = C_DateAndTime.IsDayTime()
        else day = hour >= 6 and hour < 18 end
        self.isDay = day
        -- The WC3 panorama wraps at the sun and has its moon in the middle.
        -- Move each across its half-cycle; use the client's daylight flag so
        -- the dial agrees with Forever's day/night indicator.
        local offset = day and (time - 12) or (time > 12 and time - 24 or time)
        local center = (day and 0 or 0.5) + math.max(-6, math.min(6, offset)) / 48
        face:SetTexCoord(center - 0.125, center + 0.125, 0.25, 0.75)
        if GameTooltip:GetOwner() == clock then clockTooltip() end
    end
    function state:Reset()
        character.ribbonSession = {
            started = GetServerTime(), xp = 0, gold = 0,
            money = GetMoney(), lastXP = UnitXP("player"), lastMax = UnitXPMax("player"), level = UnitLevel("player"),
        }
        self.session = character.ribbonSession
    end
    if validSession(character.ribbonSession) then state.session = character.ribbonSession
    else state:Reset() end

    function state:RecordXP()
        local xp, maximum, level = UnitXP("player"), UnitXPMax("player"), UnitLevel("player")
        if not readable(xp) or not readable(maximum) or not readable(level) then return end
        local session, gain = self.session, 0
        if level > session.level then
            gain = math.max(0, session.lastMax - session.lastXP) + xp
        elseif xp >= session.lastXP then
            gain = xp - session.lastXP
            level = math.max(level, session.level)
        elseif level == session.level and session.lastMax > 0 then
            -- XP can roll over before the client updates UnitLevel. Remember
            -- the next level now so its later level event cannot count twice.
            gain = session.lastMax - session.lastXP + xp
            level = level + 1
        end
        session.xp = session.xp + math.max(0, gain)
        session.lastXP, session.lastMax, session.level = xp, maximum, level
    end

    function state:RecordMoney()
        local money = GetMoney()
        if not readable(money) then return end
        local session = self.session
        session.gold = session.gold + math.max(0, money - session.money)
        session.money = money
    end

    function state:Value(key)
        local session = self.session
        local elapsed = math.max(0, GetServerTime() - session.started)
        local rateElapsed = math.max(1, elapsed)
        if key == "xpHour" then return string.format("%.0f", session.xp * 3600 / rateElapsed)
        elseif key == "xp" then return string.format("%.0f", session.xp)
        elseif key == "gold" then return GetMoneyString(math.floor(session.gold), true)
        elseif key == "goldHour" then return GetMoneyString(math.floor(session.gold * 3600 / rateElapsed), true)
        elseif key == "money" then return GetMoneyString(math.floor(session.money), true)
        elseif key == "time" then return duration(elapsed)
        elseif key == "levelTime" then
            local maximum, xp = UnitXPMax("player"), UnitXP("player")
            if not readable(maximum) or not readable(xp) then return "—" end
            if maximum == 0 then return "Max level" end
            if session.xp == 0 then return "—" end
            return duration(math.max(0, maximum - xp) * rateElapsed / session.xp)
        elseif key == "rested" then
            local rested = GetXPExhaustion()
            if rested == nil then return "0" end
            return readable(rested) and string.format("%.0f", rested) or "—"
        end
        return ""
    end

    for index = 1, #defaults do
        local cell = CreateFrame("Frame", nil, ribbon, "BackdropTemplate")
        cell:SetSize(132, 24)
        cell.chrome = addon.CreateConsoleChrome(cell)
        cell.chrome:SetSize(132, 24)
        cell.icon = cell:CreateTexture(nil, "ARTWORK")
        cell.icon:SetSize(16, 16)
        cell.icon:SetPoint("LEFT", 5, 0)
        cell.icon:SetTexCoord(0, 1, 0, 1)
        cell.label = cell:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        cell.label:SetPoint("TOPLEFT", 25, -1)
        cell.label:SetWidth(103)
        cell.label:SetJustifyH("LEFT")
        cell.label:SetWordWrap(false)
        cell.value = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        cell.value:SetPoint("BOTTOMLEFT", 25, 1)
        cell.value:SetWidth(103)
        cell.value:SetJustifyH("LEFT")
        cell.value:SetWordWrap(false)
        cell:EnableMouse(true)
        cell:SetScript("OnEnter", function(self)
            local key = options.slots[index]
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(metrics[key].label)
            GameTooltip:AddLine("This session: " .. duration(GetServerTime() - state.session.started), 1, 1, 1)
            if key == "gold" or key == "goldHour" then
                GameTooltip:AddLine("Money received this session. Spending does not subtract from gold gained.", 1, 1, 1, true)
            elseif key == "levelTime" then
                GameTooltip:AddLine("Estimate based on your XP rate this session.", 1, 1, 1, true)
            end
            GameTooltip:AddLine("Configure fields or reset the session in the cog menu.", 0.75, 0.75, 0.75, true)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        state.cells[index] = cell
    end

    function state:Refresh()
        local theme = console.theme or "human"
        header:SetTheme(theme)
        rim:SetTexture(addon.artPath .. theme .. "\\chrome\\clock.tga")
        clock:SetShown(options.showClock)
        if not options.showClock and GameTooltip:GetOwner() == clock then GameTooltip:Hide() end
        self:UpdateClock()
        local x = options.showClock and 134 or 82
        for index, cell in ipairs(self.cells) do
            local key = options.slots[index]
            local shown = key ~= "none"
            cell:SetShown(shown)
            if shown then
                cell:ClearAllPoints()
                cell:SetPoint("LEFT", ribbon, "LEFT", x, 0)
                cell.label:SetText(metrics[key].label)
                cell.chrome:SetTheme(theme)
                local nativeIcon = ({ xpHour = "xp", xp = "xp", gold = "gold", goldHour = "gold-hour", money = "money", levelTime = "xp", rested = "resting" })[key]
                cell.icon:SetTexture(nativeIcon and (addon.artPath .. "wc3\\" .. nativeIcon .. ".tga") or ("Interface\\Icons\\" .. metrics[key].icon))
                cell.value:SetText(self:Value(key))
                x = x + 134
            elseif GameTooltip:GetOwner() == cell then GameTooltip:Hide() end
        end
        ribbon:SetWidth(x + 4)
        local width, cap = x + 4, 34 * 24 / 56
        for index, texture in ipairs(backing) do
            local widths, offsets = { cap, width - cap * 2, cap }, { 0, cap, width - cap }
            texture:SetTexture(addon.artPath .. theme .. "\\chrome\\rail.tga")
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", ribbon, "TOPLEFT", offsets[index], 0)
            texture:SetSize(widths[index], 34)
            texture:SetShown(options.backing == "warcraft")
        end
        ribbon:SetScale(math.min(1, math.max(0.1, (UIParent:GetWidth() - 16) / (x + 4))))
        ribbon:SetShown(options.enabled and settings.enabled and console:IsShown())
    end
    local elapsed = 0
    ribbon:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then elapsed = 0; state:Refresh() end
    end)
    console:HookScript("OnShow", function() state:Refresh() end)
    console:HookScript("OnHide", function() ribbon:Hide() end)
    local events = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_CHANGED", "PLAYER_MONEY", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "UPDATE_EXHAUSTION", "DIEL_CYCLE_CHANGED" }) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(_, event, initialLogin, reloadingUI)
        if event == "PLAYER_ENTERING_WORLD" and initialLogin and not reloadingUI then
            state:Reset()
        elseif event == "PLAYER_ENTERING_WORLD" then
            state:RecordXP()
            state:RecordMoney()
        elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_CHANGED" then
            state:RecordXP()
        elseif event == "PLAYER_MONEY" then
            state:RecordMoney()
        elseif event == "PLAYER_LEAVING_WORLD" then
            state:RecordXP()
            state:RecordMoney()
        end
        state:Refresh()
    end)
    state.events = events
    state:Refresh()
end

function addon.AddRibbonMenu(menu, console)
    local state = console.sessionRibbon
    if not state then return end
    local root = menu:CreateButton("Session ribbon")
    root:CreateCheckbox("Show ribbon", function() return state.options.enabled end, function()
        state.options.enabled = not state.options.enabled
        state:Refresh()
    end)
    root:CreateCheckbox("Show day/night clock", function() return state.options.showClock end, function()
        state.options.showClock = not state.options.showClock
        state:Refresh()
    end)
    local backing = root:CreateButton("Backing")
    for _, choice in ipairs({ { "warcraft", "Warcraft III frame" }, { "transparent", "Transparent" } }) do
        backing:CreateRadio(choice[2], function(value) return state.options.backing == value end, function(value)
            state.options.backing = value
            state:Refresh()
        end, choice[1])
    end
    for index = 1, #defaults do
        local slot = index
        local submenu = root:CreateButton("Field " .. index .. " · " .. metrics[state.options.slots[index]].label)
        for _, key in ipairs(order) do
            submenu:CreateRadio(metrics[key].label, function(value) return state.options.slots[slot] == value end, function(value)
                state.options.slots[slot] = value
                state:Refresh()
            end, key)
        end
    end
    root:CreateButton("Reset session statistics", function() state:Reset(); state:Refresh() end)
end
