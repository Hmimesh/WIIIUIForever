local _, addon = ...

local slots = {
    { name = "Top left", default = "damage", x = 307, y = 54 },
    { name = "Top right", default = "spell", x = 404, y = 54 },
    { name = "Bottom left", default = "armor", x = 307, y = 19 },
    { name = "Bottom right", default = "healing", x = 404, y = 19 },
}

local function readableNumber(value)
    return not issecretvalue(value) and type(value) == "number"
end

local function restedExperience()
    local rested = GetXPExhaustion()
    if issecretvalue(rested) then
        return
    end
    if rested == nil then
        return 0
    end
    return readableNumber(rested) and math.max(0, rested) or nil
end

local function weaponDps(speed, low, high)
    if readableNumber(speed) and speed > 0 and readableNumber(low) and readableNumber(high) then
        return string.format("%.1f", (low + high) / (2 * speed))
    end
end

local function equipmentIcon(slotName)
    local slot = C_PaperDollInfo.GetInventorySlotInfo(slotName)
    if slot then
        local icon = GetInventoryItemTexture("player", slot)
        if not issecretvalue(icon) then
            return icon
        end
    end
end

function addon.ResetCombatStats(console)
    console.combatStats = { dps = 0, abilityDps = 0, waiting = true }
    addon.UpdateProfileStats(console, "combatDps")
    addon.UpdateProfileStats(console, "topAbility")
end

function addon.UpdateCombatStats(console, sessionUpdated)
    -- The meter's sourceGUID is secret in combat and cannot be passed back
    -- into its source lookup by addon code. Cache our public unit identity.
    if not InCombatLockdown() or not console.playerGUID then
        local guid = UnitGUID("player")
        if not issecretvalue(guid) and type(guid) == "string" then
            console.playerGUID = guid
        end
    end
    local snapshot = console.combatStats or {}
    console.combatStats = snapshot
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable()
        or not C_DamageMeter.GetCombatSessionFromType
        or not Enum.DamageMeterSessionType then
        snapshot.dps, snapshot.abilityDps = nil, nil
        snapshot.icon, snapshot.name, snapshot.spellID = nil, nil, nil
    elseif not snapshot.waiting or sessionUpdated then
        snapshot.waiting = false
        snapshot.dps, snapshot.abilityDps = 0, 0
        snapshot.icon, snapshot.name, snapshot.spellID = nil, nil, nil
        local current = Enum.DamageMeterSessionType.Current
        local meterType = Enum.DamageMeterType.DamageDone
        local session = C_DamageMeter.GetCombatSessionFromType(current, meterType)
        for _, source in ipairs(session and session.combatSources or {}) do
            -- isLocalPlayer is documented as never secret. All combat numbers
            -- go straight to the text widget, without comparing or sorting them.
            if source.isLocalPlayer then
                snapshot.dps = source.amountPerSecond
                local details
                if console.playerGUID and C_DamageMeter.GetCombatSessionSourceFromType then
                    details = C_DamageMeter.GetCombatSessionSourceFromType(current, meterType, console.playerGUID)
                end
                -- The native meter supplies its damage-ranked spell list.
                local ability = details and details.combatSpells and details.combatSpells[1]
                if ability then
                    snapshot.abilityDps = ability.amountPerSecond
                    snapshot.spellID = ability.spellID
                    snapshot.icon = C_Spell.GetSpellTexture(ability.spellID)
                    snapshot.name = C_Spell.GetSpellName(ability.spellID)
                end
                break
            end
        end
    end
    addon.UpdateProfileStats(console, "combatDps")
    addon.UpdateProfileStats(console, "topAbility")
end

local function readFightDps(previous)
    -- The native meter can make this data secret while a fight is in progress.
    if InCombatLockdown() then
        return previous
    end
    if not C_DamageMeter or not C_DamageMeter.IsDamageMeterAvailable() then
        return
    end
    local latestID
    for _, session in ipairs(C_DamageMeter.GetAvailableCombatSessions()) do
        latestID = math.max(latestID or session.sessionID, session.sessionID)
    end
    if not latestID then
        return
    end
    local session = C_DamageMeter.GetCombatSessionFromID(latestID, Enum.DamageMeterType.Dps)
    for _, source in ipairs(session and session.combatSources or {}) do
        if source.isLocalPlayer and readableNumber(source.amountPerSecond) then
            return string.format("%.1f", source.amountPerSecond)
        end
    end
end

local stats = {
    damage = { label = "Damage", icon = "INV_Misc_MonsterClaw_02", read = function()
        local low, high = UnitDamage("player")
        if readableNumber(low) and readableNumber(high) then
            return string.format("%d–%d", math.max(math.floor(low), 1), math.max(math.ceil(high), 1))
        end
    end },
    spell = { label = "Spell", name = "Spell damage", icon = "Spell_Nature_Lightning", read = function()
        local highest
        for school = 2, MAX_SPELL_SCHOOLS or 7 do
            local bonus = GetSpellBonusDamage(school)
            if readableNumber(bonus) then
                highest = math.max(highest or bonus, bonus)
            end
        end
        return highest
    end },
    armor = { label = "Armor", name = "Armor reduction", icon = "INV_Chest_Chain_05", read = function()
        local _, armor = UnitArmor("player")
        local level = UnitLevel("player")
        if readableNumber(armor) and readableNumber(level) and level > 0 then
            local reduction = C_PaperDollInfo.GetArmorEffectiveness(armor, level)
            if readableNumber(reduction) then
                return string.format("%.1f%%", reduction * 100), equipmentIcon("ChestSlot")
            end
        end
        return nil, equipmentIcon("ChestSlot")
    end },
    healing = { label = "Healing", name = "Bonus healing", icon = "Spell_Holy_Heal", read = function()
        local bonus = GetSpellBonusHealing()
        return readableNumber(bonus) and bonus or nil
    end },
    ammo = { label = "Ammo", name = "Equipped ammo", icon = "INV_Ammo_Arrow_01", read = function()
        if not C_PaperDollInfo.AmmoNeeded() or not UnitUsesAmmo("player") then
            return
        end
        local slot = C_PaperDollInfo.GetInventorySlotInfo("AmmoSlot")
        if not slot then
            return
        end
        local item = GetInventoryItemID("player", slot)
        if issecretvalue(item) then
            return
        end
        if not item then
            return 0
        end
        local count = GetInventoryItemCount("player", slot)
        local icon = GetInventoryItemTexture("player", slot)
        return readableNumber(count) and count or nil, not issecretvalue(icon) and icon or nil
    end },
    meleeDps = { label = "Melee DPS", name = "Main-hand weapon DPS", icon = "INV_Sword_04", read = function()
        local speed = UnitAttackSpeed("player")
        local low, high = UnitDamage("player")
        return weaponDps(speed, low, high), equipmentIcon("MainHandSlot")
    end },
    rangedDps = { label = "Ranged DPS", name = "Ranged weapon DPS", icon = "INV_Weapon_Bow_07", read = function()
        return weaponDps(UnitRangedDamage("player")), equipmentIcon("RangedSlot")
    end },
    fightDps = { label = "Fight DPS", name = "Last fight average DPS", icon = "Ability_DualWield", read = readFightDps },
    combatDps = { label = "Combat DPS", name = "Combat DPS (resets each fight)", icon = "Ability_DualWield", numeric = true,
        read = function(_, console)
            return console.combatStats and console.combatStats.dps
        end },
    topAbility = { label = "Top ability", name = "Highest damage ability (DPS)", icon = "Ability_CriticalStrike", numeric = true,
        read = function(_, console)
            local snapshot = console.combatStats or {}
            return snapshot.abilityDps, snapshot.icon, snapshot.name, snapshot.spellID
        end },
    crit = { label = "Crit", name = "Melee critical chance", icon = "Ability_CriticalStrike", read = function()
        local chance = GetCritChance()
        return readableNumber(chance) and string.format("%.1f%%", chance) or nil, equipmentIcon("MainHandSlot")
    end },
    restedXp = { label = "Rested XP", icon = "Spell_Nature_Sleep", read = function()
        local rested, maximum = restedExperience(), UnitXPMax("player")
        if readableNumber(rested) and readableNumber(maximum) then
            return string.format("%.1f%%", maximum > 0 and rested / maximum * 100 or 0)
        end
    end },
}
local statOrder = { "damage", "armor", "spell", "healing", "ammo", "meleeDps", "rangedDps", "combatDps", "topAbility", "fightDps", "crit", "restedXp" }

local function experienceTooltip(xp)
    GameTooltip:SetOwner(xp, "ANCHOR_TOP")
    GameTooltip:SetText("Experience")
    local current, maximum, rested = UnitXP("player"), UnitXPMax("player"), restedExperience()
    if readableNumber(current) and readableNumber(maximum) and maximum > 0 then
        GameTooltip:AddLine(string.format("XP %d / %d (%.1f%%)", current, maximum, current / maximum * 100), 1, 1, 1)
        if readableNumber(rested) then
            GameTooltip:AddLine(string.format("Rested XP %d (%.1f%% of a level)", rested, rested / maximum * 100), 0.4, 0.7, 1)
        end
    elseif readableNumber(maximum) and maximum == 0 then
        GameTooltip:AddLine("Maximum level", 1, 1, 1)
    end
    GameTooltip:Show()
end

local function fadeExperienceText(xp, elapsed)
    local blend, target = xp.labelBlend, xp.labelTarget
    local step = elapsed / 0.16
    blend = target > blend and math.min(blend + step, target) or math.max(blend - step, target)
    xp.labelBlend = blend
    xp.levelLabel:SetAlpha(1 - blend)
    xp.valueLabel:SetAlpha(blend)
    if blend == target then
        xp:SetScript("OnUpdate", nil)
    end
end

local function updateExperienceText(xp)
    local target = xp.hovering and xp.hasExperience and 1 or 0
    if target ~= xp.labelTarget then
        xp.labelTarget = target
        xp:SetScript("OnUpdate", xp.labelBlend ~= target and fadeExperienceText or nil)
    end
end

function addon.CreateProfile(console, character)
    local function text(parent, x, y, width, font, alignment)
        local label = parent:CreateFontString(nil, "OVERLAY", font)
        label:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
        label:SetWidth(width)
        label:SetJustifyH(alignment)
        return label
    end

    console.playerName = text(console, 307, 112, 190, "GameFontHighlight", "CENTER")

    local xp = CreateFrame("StatusBar", nil, console)
    xp:SetRoundLayoutToNearestPixel(true)
    xp:SetSize(170, 12)
    xp:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", 317, 91)
    xp:SetStatusBarTexture(addon.artPath .. "other\\xpProgressBar.tga")
    xp:SetStatusBarColor(0.63, 0.22, 0.85)
    local background = xp:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.018, 0.012, 1)
    for index, file in ipairs({ "xp1", "xp2", "xp3" }) do
        local frame = xp:CreateTexture(nil, "OVERLAY", nil, 1)
        frame:SetRoundLayoutToNearestPixel(true)
        frame:SetTexture(addon.artPath .. "other\\" .. file .. ".tga")
        frame:SetTexCoord(0, 1, 7 / 64, 1)
        frame:SetSize(index == 2 and 170 or 5, 18)
        frame:SetPoint("BOTTOMLEFT", xp, "BOTTOMLEFT", index == 1 and -5 or (index == 3 and 170 or 0), -3)
    end
    local rested = xp:CreateTexture(nil, "ARTWORK", nil, 1)
    rested:SetTexture(addon.artPath .. "other\\xpProgressBar.tga")
    rested:SetVertexColor(0.18, 0.5, 1, 0.8)
    rested:Hide()
    xp.rested = rested
    xp:EnableMouse(true)
    xp:SetScript("OnEnter", function(self)
        self.hovering = true
        updateExperienceText(self)
        experienceTooltip(self)
    end)
    xp:SetScript("OnLeave", function(self)
        self.hovering = false
        updateExperienceText(self)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    xp:SetScript("OnHide", function(self)
        self.hovering = false
        self.labelBlend, self.labelTarget = 0, 0
        fadeExperienceText(self, 0)
        if GameTooltip:GetOwner() == self then
            GameTooltip:Hide()
        end
    end)
    console.xp = xp
    console.level = text(xp, 0, 0, 170, "GameFontHighlightSmall", "CENTER")
    xp.levelLabel = console.level
    xp.valueLabel = text(xp, 0, 0, 170, "GameFontHighlightSmall", "CENTER")
    xp.valueLabel:SetAlpha(0)
    xp.labelBlend, xp.labelTarget = 0, 0

    character.profileStats = type(character.profileStats) == "table" and character.profileStats or {}
    console.profileStats = character.profileStats
    console.statSlots = {}
    addon.CreateStatusIndicators(console, character)

    for index, slot in ipairs(slots) do
        if not stats[console.profileStats[index]] then
            console.profileStats[index] = slot.default
        end
        local border = console:CreateTexture(nil, "OVERLAY", nil, 1)
        border:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", slot.x, slot.y)
        border:SetSize(28, 28)
        border:SetTexture(addon.artPath .. "other\\golden_frame.tga")

        local icon = console:CreateTexture(nil, "OVERLAY")
        icon:SetPoint("BOTTOMLEFT", border, "BOTTOMLEFT", 1, 1)
        icon:SetSize(26, 26)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

        console.statSlots[index] = {
            icon = icon,
            label = text(console, slot.x + 32, slot.y + 14, 65, "GameFontNormalSmall", "LEFT"),
            value = text(console, slot.x + 32, slot.y + 2, 62, "GameFontHighlightSmall", "LEFT"),
        }
        local widget = console.statSlots[index]
        widget.label:SetWordWrap(false)
        local hover = CreateFrame("Frame", nil, console)
        hover:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", slot.x, slot.y)
        hover:SetSize(96, 28)
        hover:EnableMouse(true)
        hover:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            local key = console.profileStats[index]
            local stat = stats[key]
            if key == "topAbility" and (issecretvalue(widget.spellID) or widget.spellID ~= nil) then
                GameTooltip:SetSpellByID(widget.spellID)
            else
                GameTooltip:SetText(stat.name or stat.label)
            end
            if key == "combatDps" or key == "topAbility" then
                GameTooltip:AddLine("Damage per second in this combat session. Resets for the next fight.", 1, 1, 1, true)
            end
            GameTooltip:Show()
        end)
        hover:SetScript("OnLeave", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        widget.hover = hover
    end
end

function addon.UpdateProfileStats(console, onlyStat)
    for index, widget in ipairs(console.statSlots) do
        local key = console.profileStats[index]
        if not onlyStat or key == onlyStat then
            local stat = stats[key]
            local previous
            if not stat.numeric and widget.key == key then previous = widget.lastValue end
            local value, icon, label, spellID = stat.read(previous, console)
            widget.key, widget.lastValue = key, value
            widget.spellID = spellID
            if issecretvalue(label) or label ~= nil then
                widget.label:SetText(label)
            else
                widget.label:SetText(stat.label)
            end
            if stat.numeric and (issecretvalue(value) or type(value) == "number") then
                widget.value:SetFormattedText("%.1f", value)
            else
                widget.value:SetText(value == nil and "—" or tostring(value))
            end
            if issecretvalue(icon) or icon ~= nil then
                widget.icon:SetTexture(icon)
            else
                widget.icon:SetTexture("Interface\\Icons\\" .. stat.icon)
            end
        end
    end
end

function addon.AddProfileMenu(menu, console)
    local profile = menu:CreateButton("Character panel")
    for index, slot in ipairs(slots) do
        local slotIndex = index
        local submenu = profile:CreateButton(slot.name .. " · " .. stats[console.profileStats[index]].label)
        local function selected(key)
            return console.profileStats[slotIndex] == key
        end
        local function choose(key)
            console.profileStats[slotIndex] = key
            addon.UpdateProfileStats(console, key)
        end
        for _, key in ipairs(statOrder) do
            local stat = stats[key]
            submenu:CreateRadio(stat.name or stat.label, selected, choose, key)
        end
    end
end

function addon.UpdateExperience(console)
    local current, maximum, rested = UnitXP("player"), UnitXPMax("player"), restedExperience()
    local xp = console.xp
    xp.hasExperience = readableNumber(current) and readableNumber(maximum) and maximum > 0
    if xp.hasExperience then
        xp.valueLabel:SetFormattedText("%d/%d XP", current, maximum)
    end
    updateExperienceText(xp)
    xp.rested:Hide()
    if readableNumber(current) and readableNumber(maximum) then
        xp:SetMinMaxValues(0, math.max(maximum, 1))
        xp:SetValue(maximum > 0 and current or 1)
        if maximum > 0 and readableNumber(rested) and rested > 0 then
            local start = math.max(0, math.min(1, current / maximum))
            local finish = math.max(start, math.min(1, (current + rested) / maximum))
            if finish > start then
                xp.rested:ClearAllPoints()
                xp.rested:SetPoint("LEFT", xp, "LEFT", xp:GetWidth() * start, 0)
                xp.rested:SetSize(xp:GetWidth() * (finish - start), xp:GetHeight())
                xp.rested:Show()
            end
        end
    end
    if GameTooltip:GetOwner() == xp then
        experienceTooltip(xp)
    end
end

function addon.UpdateProfile(console)
    local name = UnitName("player")
    local class = UnitClass("player")
    local level = UnitLevel("player")
    if not issecretvalue(name) and name then
        console.playerName:SetText(name)
    end
    if not issecretvalue(class) and class and readableNumber(level) then
        console.level:SetText(LEVEL .. " " .. level .. " " .. class)
    end

    addon.UpdateExperience(console)
    addon.UpdateProfileStats(console)
end
