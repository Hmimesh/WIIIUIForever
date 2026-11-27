local _, addon = ...

local function readableNumber(value)
    return not issecretvalue(value) and type(value) == "number"
end

-- A 0..1 bar acts as a visibility gate: zero has an empty fill, and any
-- positive heal fills it. Clipping to that fill hides +0 without inspecting
-- a restricted combat value in Lua.
local function amountLabel(parent, width, height, fontSize)
    local gate = CreateFrame("StatusBar", nil, parent)
    gate:SetSize(width, height)
    gate:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    gate:SetStatusBarColor(0, 0, 0, 0)
    gate:SetMinMaxValues(0, 1)
    gate:SetValue(0)
    gate:EnableMouse(false)
    local clip = CreateFrame("Frame", nil, gate)
    clip:SetAllPoints(gate:GetStatusBarTexture())
    clip:SetClipsChildren(true)
    clip:EnableMouse(false)
    local text = clip:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    text:SetTextColor(0.45, 1, 0.45)
    text:SetWordWrap(false)
    text:SetPoint("CENTER", gate, "CENTER")
    text:SetSize(width, height)
    gate.text = text
    return gate
end

function addon.SetupHealingFeedback(console, character)
    local health = console.health
    local panel = console.dockFrames.character.content
    local root = CreateFrame("Frame", nil, panel)
    root:SetAllPoints(console.portraitViewport)
    root:SetFrameStrata("MEDIUM")
    root:EnableMouse(false)

    -- Draw above the portrait's baked bar artwork, with the HP readout on
    -- its own higher layer. The prediction begins at the current fill edge,
    -- so it only paints the portion of missing health the heal will restore.
    local clip = CreateFrame("Frame", nil, panel)
    clip:SetAllPoints(health)
    clip:SetFrameLevel(health:GetFrameLevel() + 1)
    clip:SetClipsChildren(true)
    clip:EnableMouse(false)
    local prediction = CreateFrame("StatusBar", nil, clip)
    prediction:SetFrameLevel(clip:GetFrameLevel())
    prediction:SetSize(health:GetWidth(), health:GetHeight())
    prediction:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT")
    prediction:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    prediction:SetStatusBarColor(0.15, 0.9, 1, 1)
    prediction:EnableMouse(false)

    local incoming = amountLabel(root, 94, 12, 9)
    incoming:SetPoint("BOTTOM", root, "TOP", 0, 2)
    local state = { root = root, prediction = prediction, incoming = incoming, numbers = {}, nextNumber = 0 }
    console.healingFeedback = state

    if CreateUnitHealPredictionCalculator and UnitGetDetailedHealPrediction then
        state.calculator = CreateUnitHealPredictionCalculator()
        state.calculator:SetMaximumHealthMode(Enum.UnitMaximumHealthMode.Default)
        state.calculator:SetIncomingHealClampMode(Enum.UnitIncomingHealClampMode.MissingHealth)
        state.calculator:SetIncomingHealOverflowPercent(1)
        state.calculator:SetHealAbsorbMode(Enum.UnitHealAbsorbMode.ReducedByIncomingHeals)
    end

    function state:ClearNumbers()
        for _, number in ipairs(self.numbers) do
            number:SetScript("OnUpdate", nil)
            number:SetValue(0)
            number.text:SetText("")
            number:Hide()
        end
        self.nextNumber = 0
    end

    function state:UpdatePrediction()
        if character.incomingHealing == false or not root:IsVisible() then
            prediction:SetValue(0)
            incoming:SetValue(0)
            return
        end
        local maximum, amount = UnitHealthMax("player"), 0
        if self.calculator then
            UnitGetDetailedHealPrediction("player", "player", self.calculator)
            maximum = self.calculator:GetMaximumHealth()
            amount = self.calculator:GetIncomingHeals()
        elseif UnitGetIncomingHeals then
            -- Older client builds can only calculate a preview when every
            -- input is public. Heal event numbers remain available separately.
            local current = UnitHealth("player")
            local total = UnitGetIncomingHeals("player")
            local absorb = 0
            if UnitGetTotalHealAbsorbs then absorb = UnitGetTotalHealAbsorbs("player") end
            if not issecretvalue(total) and total == nil then total = 0 end
            if readableNumber(current) and readableNumber(maximum) and readableNumber(total) and readableNumber(absorb) then
                amount = math.min(math.max(0, total - absorb), math.max(0, maximum - current))
            end
        end
        if readableNumber(maximum) and maximum <= 0 then maximum, amount = 1, 0 end
        prediction:SetMinMaxValues(0, maximum)
        prediction:SetValue(amount)
        incoming.text:SetFormattedText("Incoming +%.0f", amount)
        incoming:SetValue(amount)
    end

    for index = 1, 3 do
        local number = amountLabel(root, 90, 20, 12)
        number.baseY = 16 + (index - 1) * 13
        number:Hide()
        state.numbers[index] = number
    end

    local function animate(number, elapsed)
        number.age = number.age + elapsed
        local progress = number.age / 1.2
        if progress >= 1 then
            number:SetScript("OnUpdate", nil)
            number:Hide()
            return
        end
        number:SetPoint("BOTTOM", root, "BOTTOM", 0, number.baseY + progress * 18)
        number:SetAlpha(math.min(1, number.age / 0.1, (1.2 - number.age) / 0.45))
    end

    function state:ShowHeal(amount, flags)
        if character.healingNumbers == false or not root:IsVisible() then return end
        if not issecretvalue(amount) and (type(amount) ~= "number" or amount <= 0) then return end
        self.nextNumber = self.nextNumber % #self.numbers + 1
        local number = self.numbers[self.nextNumber]
        local critical = not issecretvalue(flags) and flags == "CRITICAL"
        number.text:SetFont(STANDARD_TEXT_FONT, critical and 15 or 12, "OUTLINE")
        -- Amount goes directly to native formatting, including secret heals.
        number.text:SetFormattedText("+%.0f", amount)
        number:SetValue(amount)
        number.age = 0
        number:SetPoint("BOTTOM", root, "BOTTOM", 0, number.baseY)
        number:SetAlpha(0)
        number:Show()
        number:SetScript("OnUpdate", animate)
    end

    root:SetScript("OnHide", function()
        state:ClearNumbers()
        prediction:SetValue(0)
        incoming:SetValue(0)
    end)
    root:SetScript("OnShow", function() state:UpdatePrediction() end)
    local events = CreateFrame("Frame")
    events:RegisterUnitEvent("UNIT_HEAL_PREDICTION", "player")
    events:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", "player")
    events:RegisterUnitEvent("UNIT_COMBAT", "player")
    events:SetScript("OnEvent", function(_, event, unit, kind, flags, amount)
        if issecretvalue(unit) or unit ~= "player" then return end
        if event == "UNIT_COMBAT" then
            if not issecretvalue(kind) and kind == "HEAL" then state:ShowHeal(amount, flags) end
        else
            state:UpdatePrediction()
        end
    end)
    state:UpdatePrediction()
end

function addon.AddHealingFeedbackMenu(menu, console)
    local character = console.characterSettings
    local root = menu:CreateButton("Healing feedback")
    root:CreateCheckbox("Incoming healing preview", function() return character.incomingHealing ~= false end, function()
        character.incomingHealing = character.incomingHealing == false
        console.healingFeedback:UpdatePrediction()
    end)
    root:CreateCheckbox("Floating healing received", function() return character.healingNumbers ~= false end, function()
        character.healingNumbers = character.healingNumbers == false
        if not character.healingNumbers then console.healingFeedback:ClearNumbers() end
    end)
end
