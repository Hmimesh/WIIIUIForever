local _, addon = ...

local function validOffset(value)
    return type(value) == "number" and math.abs(value) < math.huge
end

function addon.SetupCharacterSheet(settings, character)
    local sheet = CharacterFrame
    local scene = CharacterModelScene
    if not sheet or not PaperDollFrame or not scene then
        return
    end

    for _, key in ipairs({ "sheetPosition", "backpackPosition" }) do
        local position = character[key]
        if type(position) ~= "table" or not validOffset(position.x) or not validOffset(position.y) then
            character[key] = nil
        end
    end

    local trim = CreateFrame("Frame", nil, sheet)
    trim:SetAllPoints(sheet)
    trim:SetFrameLevel(sheet:GetFrameLevel())
    trim:Hide()
    local backing = trim:CreateTexture(nil, "BACKGROUND")
    backing:SetPoint("TOPLEFT", 6, -6)
    backing:SetPoint("BOTTOMRIGHT", -6, 6)
    local border = CreateFrame("Frame", nil, trim, "BackdropTemplate")
    border:SetAllPoints(trim)
    local defaultBorderLevel = trim:GetFrameLevel() + 1
    border:SetFrameLevel(defaultBorderLevel)

    local leftHost, rightHost = sheet.LeftPaneHost, sheet.RightPaneHost
    local boardFrames = { leftHost, rightHost, sheet.CloseButton, sheet.ModeTabs, PaperDollSidebarTabs }
    local function canChangeLayout()
        if not InCombatLockdown() then return true end
        if not sheet:CanChangeProtectedState() then return false end
        if leftHost and rightHost then
            for _, frame in pairs(boardFrames) do
                if not frame:CanChangeProtectedState() then return false end
            end
        end
        return true
    end

    local gap, sidebarWidth = 8, rightHost and rightHost:GetWidth() or 233
    local characterX = sidebarWidth + gap
    local talentsPanel, statsPanel, characterName
    addon.GetPlayerDisplayName(character)
    if leftHost and rightHost then
        talentsPanel = addon.CreateCharacterTalents(sheet, settings, sidebarWidth)
        talentsPanel:SetPoint("TOPLEFT", sheet, "TOPLEFT")
        talentsPanel:SetPoint("BOTTOMLEFT", sheet, "BOTTOMLEFT")

        statsPanel = CreateFrame("Frame", nil, sheet, "BackdropTemplate")
        statsPanel:SetAllPoints(rightHost)
        statsPanel:SetFrameLevel(sheet:GetFrameLevel())
        statsPanel:Hide()
        local statsTitle = statsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statsTitle:SetPoint("TOP", 0, -15)
        statsTitle:SetText(STATISTICS or "Stats")

        characterName = border:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        characterName:SetPoint("TOP", 0, -13)
        characterName:SetWidth(leftHost:GetWidth() - 76)
        characterName:SetWordWrap(false)
        characterName:Hide()
    end
    function addon.RefreshCharacterName()
        local name = addon.GetPlayerDisplayName(character)
        if characterName and name then characterName:SetText(name) end
    end

    local stone = scene:CreateTexture(nil, "BACKGROUND", nil, -5)
    stone:SetAllPoints(scene)
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
    backpack:Hide()
    local heading = backpack:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 18, -14)
    heading:SetWidth(150)
    heading:SetJustifyH("LEFT")
    heading:SetWordWrap(false)
    local function headerButton(label, right, width, callback)
        local button = CreateFrame("Button", nil, backpack, "UIPanelButtonTemplate")
        button:SetSize(width, 21)
        button:SetPoint("TOPRIGHT", -right, -14)
        button:SetText(label)
        button:SetScript("OnClick", callback)
        return button
    end
    headerButton("Open bags", 15, 80, function() OpenAllBags() end)
    local talents = headerButton("Talents", 99, 69, function()
        if TalentMicroButton and TalentMicroButton:IsEnabled() then TalentMicroButton:Click() end
    end)
    local viewButton = headerButton("View", 172, 54, function(button)
        MenuUtil.CreateContextMenu(button, function(_, menu)
            menu:CreateTitle("Character inventory")
            addon.AddCharacterBagChoices(menu)
        end)
    end)

    local firstBag, lastBag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS
    local function inventoryView()
        local view = character.sheetInventoryView
        if view == "hidden" or (type(view) == "number" and view >= firstBag and view <= lastBag and view % 1 == 0
            and C_Container.GetContainerNumSlots(view) > 0) then
            return view
        end
        return "all"
    end

    local scroll = CreateFrame("ScrollFrame", nil, backpack, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -36)
    scroll:SetWidth(348)
    scroll.ScrollBar:SetHideIfUnscrollable(true)
    local grid = CreateFrame("Frame", nil, scroll)
    grid:SetSize(348, 58)
    scroll:SetScrollChild(grid)
    local buttons = {}
    local columns, step = 6, 58
    function addon.UpdateCharacterSheetTheme()
        addon.SetWindowTheme(border, settings.theme, false)
        if talentsPanel then
            talentsPanel:UpdateTheme()
            addon.SetWindowTheme(statsPanel, settings.theme, true)
        end
        addon.SetWindowTheme(backpack, settings.theme, true)
        local panelArt = addon.GetWindowBacking(settings.theme)
        backing:SetTexture(panelArt)
        stone:SetTexture(panelArt)
        for _, slot in ipairs(buttons) do addon.SetCharacterSlotArt(slot.background, settings.theme) end
    end
    addon.UpdateCharacterSheetTheme()

    local function createSlot(index)
        local slot = CreateFrame("Button", nil, grid)
        slot:SetSize(52, 52)
        slot:SetPoint("TOPLEFT", 3 + (index - 1) % columns * step, -3 - math.floor((index - 1) / columns) * step)
        local background = slot:CreateTexture(nil, "BACKGROUND")
        background:SetAllPoints()
        slot.background = background
        addon.SetCharacterSlotArt(background, settings.theme)
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
        local visibleHeight = math.max(4, math.min(rows, 5)) * step
        grid:SetHeight(rows * step)
        scroll:SetHeight(visibleHeight)
        backpack:SetHeight(46 + visibleHeight)
        if view ~= lastView then
            scroll:SetVerticalScroll(0)
            lastView = view
        end
        talents:SetEnabled(TalentMicroButton ~= nil and TalentMicroButton:IsEnabled())
    end

    local original, boardState, moving
    local function place(frame, left, top, bottom)
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", sheet, "TOPLEFT", left, top)
        if bottom then frame:SetPoint("BOTTOMLEFT", sheet, "TOPLEFT", left, bottom) end
    end

    local function rememberPoints(frame)
        local points = {}
        for index = 1, frame:GetNumPoints() do points[index] = { frame:GetPoint(index) } end
        return points
    end

    local function restorePoints(frame, points)
        frame:ClearAllPoints()
        for _, point in ipairs(points) do frame:SetPoint(unpack(point, 1, 5)) end
    end

    local function restoreBoard()
        if not boardState then return end
        for frame, points in pairs(boardState.points) do restorePoints(frame, points) end
        for region, alpha in pairs(boardState.alphas) do region:SetAlpha(alpha) end
        if sheet.CloseButton then sheet.CloseButton:SetFrameLevel(boardState.closeLevel) end
        boardState = nil
        border:SetFrameLevel(defaultBorderLevel)
        trim:ClearAllPoints()
        trim:SetAllPoints(sheet)
        talentsPanel:Hide()
        statsPanel:Hide()
        characterName:Hide()
        talents:Show()
        viewButton:SetPoint("TOPRIGHT", backpack, "TOPRIGHT", -172, -14)
    end

    local function applyBoard(sheetHeight, sideHeight)
        if not boardState then
            boardState = { points = {}, alphas = {}, closeLevel = sheet.CloseButton and sheet.CloseButton:GetFrameLevel() }
            local function fade(region)
                if not region then return end
                boardState.alphas[region] = region:GetAlpha()
                region:SetAlpha(0)
            end
            local levelStrip = PaperDollFrame.TopBackgroundStripHost
            local borderLevel = math.max(scene:GetFrameLevel(), levelStrip and levelStrip:GetFrameLevel() or 0) + 1
            border:SetFrameLevel(borderLevel)
            if sheet.CloseButton then sheet.CloseButton:SetFrameLevel(math.max(boardState.closeLevel, borderLevel + 1)) end
            for _, frame in pairs(boardFrames) do
                boardState.points[frame] = rememberPoints(frame)
            end
            for _, region in pairs({ sheet.NineSlice, sheet.Bg, sheet.Inset, sheet.PortraitContainer,
                sheet.TitleContainer or sheet.TitleText, CharacterStatsPaneScrollBox and CharacterStatsPaneScrollBox.ClassBackground }) do
                fade(region)
            end
            if levelStrip then
                fade(levelStrip.TopBackgroundStrip)
                fade(levelStrip.TopBackgroundStripBottomEdge)
            end
            -- The native host art has fixed dimensions, so it can extend into the bags or the game world.
            for _, host in ipairs({ leftHost, rightHost }) do
                for _, region in ipairs({ host:GetRegions() }) do fade(region) end
            end
            for _, child in ipairs({ rightHost:GetChildren() }) do
                for _, region in ipairs({ child:GetRegions() }) do
                    if region.GetAtlas and region:GetAtlas() == "common-framedivider" then fade(region) end
                end
            end
            talentsPanel:Refresh()
        end

        place(leftHost, characterX, -20, -sheetHeight)
        place(rightHost, 0, -sheetHeight - gap, -sheetHeight - gap - sideHeight)
        trim:ClearAllPoints()
        trim:SetPoint("TOPLEFT", leftHost, "TOPLEFT", 0, 20)
        trim:SetPoint("BOTTOMRIGHT", leftHost, "BOTTOMRIGHT")
        if sheet.CloseButton then
            sheet.CloseButton:ClearAllPoints()
            sheet.CloseButton:SetPoint("TOPRIGHT", trim, "TOPRIGHT", -6, -6)
        end
        if sheet.ModeTabs then
            sheet.ModeTabs:ClearAllPoints()
            sheet.ModeTabs:SetPoint("TOPLEFT", trim, "TOPRIGHT", 0, -30)
        end
        if PaperDollSidebarTabs then
            PaperDollSidebarTabs:ClearAllPoints()
            PaperDollSidebarTabs:SetPoint("TOP", rightHost, "TOP", 0, -25)
        end
        addon.RefreshCharacterName()
        characterName:Show()
        statsPanel:Show()
        talentsPanel:Show()
        talents:Hide()
        viewButton:SetPoint("TOPRIGHT", backpack, "TOPRIGHT", -99, -14)
    end

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

    local function restore(keepOriginal)
        if not original then
            return
        end
        restoreBoard()
        sheet:SetScale(original.scale)
        sheet:SetClampedToScreen(original.clamped)
        restorePoints(sheet, original.points)
        for texture, alpha in pairs(original.alphas) do
            texture:SetAlpha(alpha)
        end
        if not keepOriginal then original = nil end
    end

    local function isSheetShown()
        return settings.enabled and settings.forsakenSheet ~= false
            and sheet:IsShown() and not InputUtil.IsGamepadUIEnabled()
    end

    local function isCharacterPageShown()
        return isSheetShown() and PaperDollFrame:IsShown()
    end

    local defaultPosition = { x = 16, y = 34 }
    local function refreshLayout()
        if not original or moving or not isSheetShown() or not canChangeLayout() then
            return
        end
        if not PaperDollFrame:IsShown() then
            -- Reputation, skills and the other native pages share the saved
            -- top-left position, without retaining the four-panel contents.
            restore(true)
            local width, height = sheet:GetSize()
            local scale = math.min(original.scale, math.max(1, UIParent:GetHeight() - 178) / height,
                math.max(1, UIParent:GetWidth() - 78) / width)
            sheet:SetScale(scale)
            sheet:SetClampedToScreen(true)
            placeAtSavedPosition(sheet, character.sheetPosition or defaultPosition, width + 64, height)
            return
        end
        local detached = character.backpackPosition
        local sheetWidth, sheetHeight = sheet:GetSize()
        local combinedHeight = sheetHeight
        local board = talentsPanel and (not sheet.IsRightPaneCollapsed or not sheet:IsRightPaneCollapsed())
        if board then
            local sideHeight = backpack:IsShown() and not detached and backpack:GetHeight() or 278
            combinedHeight = sheetHeight + sideHeight + gap
            sheetWidth = characterX + math.max(leftHost:GetWidth(), backpack:GetWidth())
            applyBoard(sheetHeight, sideHeight)
        else
            restoreBoard()
        end
        if not board and backpack:IsShown() and not detached then
            combinedHeight = sheetHeight + backpack:GetHeight() + 5
            sheetWidth = math.max(sheetWidth, backpack:GetWidth())
        end
        local availableHeight = math.max(1, UIParent:GetHeight() - 178)
        local availableWidth = math.max(1, UIParent:GetWidth() - 78)
        local scale = math.min(original.scale, availableHeight / combinedHeight, availableWidth / sheetWidth)
        sheet:SetScale(scale)
        placeAtSavedPosition(sheet, character.sheetPosition or defaultPosition, sheetWidth + 64, combinedHeight)
        if detached then
            placeAtSavedPosition(backpack, detached, backpack:GetSize())
        else
            place(backpack, board and characterX or 0, -sheetHeight - (board and gap or 5))
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
        return handle
    end
    addDragHandle(border, sheet, "sheetPosition", 60, 40, -1, 24)
    addDragHandle(backpack, backpack, "backpackPosition", 12, 230, -7, 28)
    -- The themed title is hidden on native pages such as Reputation and
    -- Skills. Give their shared header its own handle, clear of the portrait
    -- and close button, and save to the same per-character position.
    local nativeTitleDrag = addDragHandle(sheet, sheet, "sheetPosition", 60, 44, -4, 28)
    nativeTitleDrag:SetFrameLevel(sheet:GetFrameLevel() + 10)
    nativeTitleDrag:Hide()

    local function refresh()
        local enabled = isSheetShown()
        nativeTitleDrag:SetShown(enabled and not PaperDollFrame:IsShown())
        local canChange = canChangeLayout()
        -- A hidden parent already hides the whole board. Keep the existing
        -- layout available on reopen if a protected frame prevents a reset.
        if not canChange and (enabled or not sheet:IsShown()) then return end
        if not enabled then
            trim:Hide()
            stone:Hide()
            backpack:Hide()
            if talentsPanel then talentsPanel:Hide(); statsPanel:Hide() end
            if canChange then
                restore()
            end
            return
        end
        if not original then
            original = { scale = sheet:GetScale(), clamped = sheet:IsClampedToScreen(), points = rememberPoints(sheet), alphas = {} }
            for _, texture in pairs(backgrounds) do
                original.alphas[texture] = texture:GetAlpha()
            end
        end
        if not isCharacterPageShown() then
            trim:Hide()
            stone:Hide()
            backpack:Hide()
            if talentsPanel then talentsPanel:Hide(); statsPanel:Hide() end
            refreshLayout()
            return
        end
        for texture in pairs(original.alphas) do texture:SetAlpha(0) end
        local view = inventoryView()
        if view ~= "hidden" then
            updateBackpack(view)
        end
        backpack:SetShown(view ~= "hidden")
        sheet:SetClampedToScreen(true)
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
        if frame == sheet and isSheetShown() then
            refreshLayout()
        end
    end)
    local events = CreateFrame("Frame")
    events:RegisterEvent("DISPLAY_SIZE_CHANGED")
    events:RegisterEvent("UI_SCALE_CHANGED")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("PLAYER_TALENT_UPDATE")
    events:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    events:RegisterEvent("PLAYER_LEVEL_UP")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_TALENT_UPDATE" or event == "ACTIVE_TALENT_GROUP_CHANGED" or event == "PLAYER_LEVEL_UP" then
            if talentsPanel and talentsPanel:IsVisible() then talentsPanel:Refresh() end
        elseif event ~= "BAG_UPDATE_DELAYED" or backpack:IsShown() then
            refresh()
        end
    end)
    refresh()
end
