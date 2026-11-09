local _, addon = ...

function addon.SetupCharacterSheet(settings, character)
    local sheet = CharacterFrame
    local scene = CharacterModelScene
    if not sheet or not PaperDollFrame or not scene then
        return
    end

    local art = addon.artPath .. "forsaken\\"
    local edge = { edgeFile = art .. "border.tga", edgeSize = 18 }
    local trim = CreateFrame("Frame", nil, sheet, "BackdropTemplate")
    trim:SetAllPoints(sheet)
    trim:SetFrameLevel(sheet:GetFrameLevel() + 4)
    trim:SetBackdrop(edge)
    trim:Hide()

    local stone = scene:CreateTexture(nil, "BACKGROUND", nil, -5)
    stone:SetAllPoints(scene)
    stone:SetTexture(art .. "panel.tga")
    stone:Hide()
    local backgrounds = {
        scene.BackgroundTopLeft, scene.BackgroundTopRight, scene.BackgroundBotLeft,
        scene.BackgroundBotRight, scene.BackgroundOverlay,
    }

    local backpack = CreateFrame("Frame", nil, sheet, "BackdropTemplate")
    backpack:SetPoint("TOPLEFT", sheet, "BOTTOMLEFT", 0, -5)
    backpack:SetWidth(398)
    backpack:SetMovable(true)
    backpack:SetClampedToScreen(true)
    backpack:SetBackdrop({
        bgFile = art .. "panel.tga", edgeFile = edge.edgeFile, edgeSize = edge.edgeSize,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    backpack:Hide()
    local heading = backpack:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 18, -14)
    heading:SetWidth(150)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)
    local function headerButton(label, right, width, callback)
        local button = CreateFrame("Button", nil, backpack, "UIPanelButtonTemplate")
        button:SetSize(width, 21)
        button:SetPoint("TOPRIGHT", -right, -10)
        button:SetText(label)
        button:SetScript("OnClick", callback)
        return button
    end
    headerButton("Open bags", 15, 80, function() OpenAllBags() end)
    local talents = headerButton("Talents", 99, 69, function() TalentMicroButton:Click() end)
    headerButton("View", 172, 54, function(button)
        MenuUtil.CreateContextMenu(button, function(_, menu)
            menu:CreateTitle("Character inventory")
            addon.AddCharacterBagChoices(menu)
        end)
    end)

    local firstBag, lastBag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS
    local function inventoryView()
        local view = character.sheetInventoryView
        if view == "hidden" or (type(view) == "number" and view >= firstBag and view <= lastBag
            and C_Container.GetContainerNumSlots(view) > 0) then
            return view
        end
        return "all"
    end

    local scroll = CreateFrame("ScrollFrame", nil, backpack, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -36)
    scroll:SetWidth(352)
    scroll.ScrollBar:SetHideIfUnscrollable(true)
    local grid = CreateFrame("Frame", nil, scroll)
    grid:SetSize(352, 44)
    scroll:SetScrollChild(grid)
    local buttons = {}
    local columns, step = 8, 44
    local function createSlot(index)
        local slot = CreateFrame("Button", nil, grid)
        slot:SetSize(38, 38)
        slot:SetPoint("TOPLEFT", 3 + (index - 1) % columns * step, -3 - math.floor((index - 1) / columns) * step)
        local background = slot:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        background:SetTexture(art .. "slot.tga")
        slot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        local icon = slot:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 3, -3)
        icon:SetPoint("BOTTOMRIGHT", -3, 3)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        slot.icon = icon
        local count = slot:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        count:SetPoint("BOTTOMRIGHT", -3, 3)
        slot.count = count
        slot:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetBagItem(self.bagIndex, self.itemIndex)
        end)
        slot:SetScript("OnLeave", function(self)
            if GameTooltip:GetOwner() == self then
                GameTooltip:Hide()
            end
        end)
        local function pickup(self)
            if not InCombatLockdown() then
                C_Container.PickupContainerItem(self.bagIndex, self.itemIndex)
            end
        end
        slot:RegisterForDrag("LeftButton")
        slot:SetScript("OnClick", pickup)
        slot:SetScript("OnDragStart", pickup)
        slot:SetScript("OnReceiveDrag", pickup)
        return slot
    end

    local lastView
    local function bagLabel(bag)
        if bag == firstBag then
            return BACKPACK_TOOLTIP or "Backpack"
        end
        return C_Container.GetBagName(bag) or ("Bag " .. bag)
    end

    local function updateBackpack(view)
        heading:SetText(view == "all" and "All carried bags" or bagLabel(view))
        local first = view == "all" and firstBag or view
        local last = view == "all" and lastBag or view
        local count = 0
        for bag = first, last do
            for index = 1, C_Container.GetContainerNumSlots(bag) do
                count = count + 1
                local slot = buttons[count] or createSlot(count)
                buttons[count] = slot
                slot.bagIndex, slot.itemIndex = bag, index
                local item = C_Container.GetContainerItemInfo(bag, index)
                local stack = item and item.stackCount
                slot.icon:SetTexture(item and item.iconFileID)
                slot.icon:SetShown(item ~= nil)
                slot.count:SetText(not issecretvalue(stack) and stack and stack > 1 and stack or "")
                slot:Show()
            end
        end
        for index = count + 1, #buttons do
            buttons[index]:Hide()
        end
        local rows = math.max(1, math.ceil(count / columns))
        local visibleHeight = math.min(rows, 5) * step
        grid:SetHeight(rows * step)
        scroll:SetHeight(visibleHeight)
        backpack:SetHeight(46 + visibleHeight)
        if view ~= lastView then
            scroll:SetVerticalScroll(0)
            lastView = view
        end
        talents:SetEnabled(TalentMicroButton ~= nil and TalentMicroButton:IsEnabled())
    end

    local original, moving
    local function placeAtSavedPosition(frame, position, width, height)
        local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local screenWidth, screenHeight = UIParent:GetSize()
        local x = math.max(0, math.min(position.x, screenWidth - width * scale))
        local y = math.max(0, math.min(position.y, screenHeight - height * scale))
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", x / scale, -y / scale)
    end

    local function stopDragging(frame, key, userPlaced)
        if moving ~= frame then
            return
        end
        frame:StopMovingOrSizing()
        frame:SetUserPlaced(userPlaced)
        moving = nil
        local left, top = frame:GetLeft(), frame:GetTop()
        if left and top then
            local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
            character[key] = {
                x = left * scale - UIParent:GetLeft(),
                y = UIParent:GetTop() - top * scale,
            }
        end
    end

    local function restore()
        if not original then
            return
        end
        sheet:SetScale(original.scale)
        sheet:SetClampedToScreen(original.clamped)
        sheet:ClearAllPoints()
        for _, point in ipairs(original.points) do
            sheet:SetPoint(unpack(point, 1, 5))
        end
        for texture, alpha in pairs(original.alphas) do
            texture:SetAlpha(alpha)
        end
        original = nil
    end

    local function refreshLayout()
        if not original or moving or InCombatLockdown() then
            return
        end
        local detached = character.backpackPosition
        local sheetWidth, sheetHeight = sheet:GetSize()
        local combinedHeight = sheetHeight
        if backpack:IsShown() and not detached then
            combinedHeight = sheetHeight + backpack:GetHeight() + 5
            sheetWidth = math.max(sheetWidth, backpack:GetWidth())
            sheetHeight = combinedHeight
        end
        local availableHeight = UIParent:GetHeight() - 178
        local scale = math.min(original.scale, math.max(0.5, availableHeight / combinedHeight))
        sheet:SetScale(scale)
        if character.sheetPosition then
            placeAtSavedPosition(sheet, character.sheetPosition, sheetWidth, sheetHeight)
        else
            sheet:ClearAllPoints()
            sheet:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -62 / scale, -42 / scale)
        end
        if detached then
            placeAtSavedPosition(backpack, detached, backpack:GetSize())
        else
            backpack:ClearAllPoints()
            backpack:SetPoint("TOPLEFT", sheet, "BOTTOMLEFT", 0, -5)
        end
    end

    local function addDragHandle(parent, frame, key, left, right, top, height)
        local handle = CreateFrame("Frame", nil, parent)
        handle:SetPoint("TOPLEFT", left, top)
        handle:SetPoint("TOPRIGHT", -right, top)
        handle:SetHeight(height)
        handle:EnableMouse(true)
        handle:RegisterForDrag("LeftButton")
        local userPlaced
        handle:SetScript("OnDragStart", function()
            if not moving and not InCombatLockdown() then
                userPlaced = frame:IsUserPlaced()
                moving = frame
                frame:StartMoving()
            end
        end)
        handle:SetScript("OnDragStop", function()
            stopDragging(frame, key, userPlaced)
            refreshLayout()
        end)
        handle:SetScript("OnHide", function()
            stopDragging(frame, key, userPlaced)
        end)
    end
    addDragHandle(trim, sheet, "sheetPosition", 60, 40, -1, 21)
    addDragHandle(backpack, backpack, "backpackPosition", 12, 230, -7, 28)

    local function refresh()
        local enabled = settings.enabled and settings.forsakenSheet ~= false
            and sheet:IsShown() and PaperDollFrame:IsShown() and not InputUtil.IsGamepadUIEnabled()
        if not enabled then
            trim:Hide()
            stone:Hide()
            backpack:Hide()
            if not InCombatLockdown() then
                restore()
            end
            return
        end
        if not original then
            original = { scale = sheet:GetScale(), clamped = sheet:IsClampedToScreen(), points = {}, alphas = {} }
            for index = 1, sheet:GetNumPoints() do
                local point, relative, relativePoint, x, y = sheet:GetPoint(index)
                original.points[index] = { point, relative, relativePoint, x, y }
            end
            for _, texture in pairs(backgrounds) do
                original.alphas[texture] = texture:GetAlpha()
                texture:SetAlpha(0)
            end
        end
        local view = inventoryView()
        if view ~= "hidden" then
            updateBackpack(view)
        end
        backpack:SetShown(view ~= "hidden")
        if not InCombatLockdown() then
            sheet:SetClampedToScreen(true)
        end
        refreshLayout()
        trim:Show()
        stone:Show()
    end

    addon.RefreshCharacterSheet = refresh
    function addon.AddCharacterBagChoices(menu)
        local function selected(view)
            return inventoryView() == view
        end
        local function choose(view)
            character.sheetInventoryView = view
            refresh()
        end
        menu:CreateRadio("All carried bags", selected, choose, "all")
        for bag = firstBag, lastBag do
            if bag == firstBag or C_Container.GetContainerNumSlots(bag) > 0 then
                local label = bag == firstBag and bagLabel(bag) or ("Bag " .. bag .. " · " .. bagLabel(bag))
                menu:CreateRadio(label, selected, choose, bag)
            end
        end
        menu:CreateRadio("Hide inventory panel", selected, choose, "hidden")
    end
    addon.ResetCharacterPositions = function()
        character.sheetPosition = nil
        character.backpackPosition = nil
        refresh()
    end
    sheet:HookScript("OnShow", refresh)
    sheet:HookScript("OnHide", refresh)
    PaperDollFrame:HookScript("OnShow", refresh)
    PaperDollFrame:HookScript("OnHide", refresh)
    hooksecurefunc(sheet, "RefreshDisplay", refresh)
    hooksecurefunc("UpdateUIPanelPositions", refreshLayout)
    hooksecurefunc("ShowUIPanel", function(frame)
        if frame == sheet and trim:IsShown() then
            refreshLayout()
        end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:SetScript("OnEvent", function(_, event)
        if event ~= "BAG_UPDATE_DELAYED" or backpack:IsShown() then
            refresh()
        end
    end)
    refresh()
end
