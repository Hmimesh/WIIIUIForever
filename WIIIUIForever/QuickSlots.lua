local _, addon = ...

local function validAssignment(value)
    return type(value) == "table" and (value.kind == "item" or value.kind == "spell")
        and type(value.id) == "number" and value.id > 0 and value.id % 1 == 0
end

function addon.CreateQuickSlots(character)
    character.quickSlots = type(character.quickSlots) == "table" and character.quickSlots or {}
    local saved = character.quickSlots
    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(addon.quickSlots.width, addon.quickSlots.height)
    holder:SetFrameStrata("LOW")
    holder:Hide()
    local heading = holder:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    heading:SetPoint("BOTTOMLEFT", 0, 123)
    heading:SetWidth(80)
    heading:SetJustifyH("CENTER")
    heading:SetText("Inventory")

    local buttons = {}
    local function tooltip(button)
        GameTooltip:SetOwner(button, "ANCHOR_TOP")
        local action = button.assignment
        if action then
            if action.kind == "item" then
                GameTooltip:SetItemByID(action.id)
            else
                GameTooltip:SetSpellByID(action.id)
            end
            GameTooltip:AddLine("Right-click to clear outside combat.", 0.75, 0.75, 0.75)
        else
            GameTooltip:SetText("Quick slot " .. button.slotIndex)
            GameTooltip:AddLine("Drag an item or spell here outside combat.", 1, 1, 1, true)
        end
        GameTooltip:Show()
    end

    local function updateSlot(button)
        local action = button.assignment
        button.cooldown:Clear()
        button.count:SetText("")
        button.icon:SetDesaturated(false)
        if not action then
            button.icon:Hide()
            return
        end
        local icon
        if action.kind == "item" then
            icon = C_Item.GetItemIconByID(action.id)
            local count = C_Item.GetItemCount(action.id)
            if not issecretvalue(count) then
                button.count:SetText(count ~= 1 and count or "")
                button.icon:SetDesaturated(count == 0)
            end
            local start, duration = C_Container.GetItemCooldown(action.id)
            button.cooldown:SetCooldown(start or 0, duration or 0)
        else
            icon = C_Spell.GetSpellTexture(action.id)
            local duration = C_Spell.GetSpellCooldownDuration(action.id)
            if duration then
                button.cooldown:SetCooldownFromDurationObject(duration)
            end
        end
        button.icon:SetTexture(icon or 134400)
        button.icon:Show()
        if GameTooltip:GetOwner() == button then
            tooltip(button)
        end
    end

    local function assign(button, action)
        if InCombatLockdown() then
            return
        end
        button:SetAttribute("useOnKeyDown", false)
        button:SetAttribute("type1", nil)
        button:SetAttribute("item", nil)
        button:SetAttribute("spell", nil)
        if action then
            local value = action.kind == "item" and ("item:" .. action.id) or action.id
            button:SetAttribute(action.kind, value)
            button:SetAttribute("type1", action.kind)
        end
        saved[button.slotIndex] = action
        button.assignment = action
        updateSlot(button)
        if not action and GameTooltip:GetOwner() == button then
            tooltip(button)
        end
    end

    local function receiveDrag(button)
        if InCombatLockdown() then
            return
        end
        local kind, id, _, spellID = GetCursorInfo()
        if kind == "spell" then
            id = spellID
        elseif kind == "action" then
            kind, id = GetActionInfo(id)
        end
        local action = { kind = kind, id = id }
        if validAssignment(action) then
            assign(button, action)
            ClearCursor()
            updateSlot(button)
        end
    end

    for index = 1, 6 do
        local button = CreateFrame("Button", "WIIIUIForeverQuickSlot" .. index, holder, "SecureActionButtonTemplate")
        button.slotIndex = index
        button:SetSize(25, 25)
        button:SetPoint("CENTER", holder, "BOTTOMLEFT", 20 + (index - 1) % 2 * 40,
            96 - math.floor((index - 1) / 2) * 40)
        button:RegisterForClicks("AnyUp")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetAllPoints()
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        button.icon = icon
        local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", 0, 0)
        button.count = count
        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
        cooldown:SetAllPoints()
        cooldown:SetDrawEdge(false)
        button.cooldown = cooldown
        button:SetScript("OnReceiveDrag", receiveDrag)
        button:HookScript("OnClick", function(self, mouseButton)
            if mouseButton == "RightButton" then
                assign(self, nil)
            end
        end)
        button:SetScript("OnEnter", tooltip)
        button:SetScript("OnLeave", function(self)
            if GameTooltip:GetOwner() == self then
                GameTooltip:Hide()
            end
        end)
        buttons[index] = button
        if not validAssignment(saved[index]) then
            saved[index] = nil
        end
        assign(button, saved[index])
    end

    local events = CreateFrame("Frame")
    for _, event in ipairs({
        "BAG_UPDATE_DELAYED", "BAG_UPDATE_COOLDOWN", "SPELL_UPDATE_COOLDOWN",
        "GET_ITEM_INFO_RECEIVED", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    }) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnEvent", function(_, event)
        for _, button in ipairs(buttons) do
            if event == "PLAYER_REGEN_ENABLED" then
                assign(button, saved[button.slotIndex])
            else
                updateSlot(button)
            end
        end
    end)
    return holder
end
