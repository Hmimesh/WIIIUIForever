local _, addon = ...
local events = CreateFrame("Frame")
local console
local settings
local character
local nativeLayoutRequested = true
local original = {}
local faded = {}
local mainSlotAnchors = {}
local minimapIconHooks = {}
local layoutQueued = false
local layoutPending = false
local layoutApplying = false
local tooltipClamped
local scale = 1
local portraitZoom = 1
local portraitCameraVersion = 2
local portraitCameraSettle = 0.75
local portraitAxes = {
    { key = "x", label = "X · Depth" },
    { key = "y", label = "Y · Horizontal" },
    { key = "z", label = "Z · Vertical" },
}
local portraitControls
local quickSlots
local barTextModes = {
    { key = "numbers", label = "Numbers" },
    { key = "percent", label = "Percentage" },
    { key = "both", label = "Both" },
    { key = "none", label = "None" },
}
local percentCurve

local function message(text)
    print("|cffffcd58WIIIUI Forever|r " .. text)
end

local function remember(frame, sizeChanges)
    if original[frame] then
        return
    end
    local state = { scale = frame:GetScale(), points = {} }
    for index = 1, frame:GetNumPoints() do
        local point, relative, relativePoint, x, y = frame:GetPoint(index)
        state.points[index] = { point, relative, relativePoint, x, y }
    end
    if sizeChanges then
        state.width, state.height = frame:GetSize()
    end
    original[frame] = state
end

local function fade(region)
    if region then
        if faded[region] == nil then
            faded[region] = region:GetAlpha()
        end
        if region:GetAlpha() ~= 0 then
            region:SetAlpha(0)
        end
    end
end

local function restoreLayout()
    if not next(original) then
        return
    end
    for frame, state in pairs(original) do
        frame:SetScale(state.scale)
        if state.width then
            frame:SetSize(state.width, state.height)
        end
        frame:ClearAllPoints()
        for _, point in ipairs(state.points) do
            frame:SetPoint(unpack(point, 1, 5))
        end
    end
    for region, alpha in pairs(faded) do
        region:SetAlpha(alpha)
    end
    wipe(original)
    wipe(faded)
    if tooltipClamped ~= nil then
        GameTooltip:SetClampedToScreen(tooltipClamped)
        tooltipClamped = nil
    end
    MinimapCluster:UpdateMinimapConfig()
end

local function anchor(frame, point, relative, relativePoint, x, y)
    local current, currentRelative, currentRelativePoint, currentX, currentY = frame:GetPoint(1)
    if frame:GetNumPoints() == 1 and current == point and currentRelative == relative
        and currentRelativePoint == relativePoint and math.abs(currentX - x) < 0.01
        and math.abs(currentY - y) < 0.01 then
        return
    end
    frame:ClearAllPoints()
    frame:SetPoint(point, relative, relativePoint, x, y)
end

-- Anchor native frames directly to UIParent. Anchoring a protected frame to
-- the art frame would restrict changes to the entire console in combat.
local function place(frame, x, y, point)
    local units = scale * UIParent:GetEffectiveScale() / frame:GetEffectiveScale()
    anchor(frame, point or "BOTTOMLEFT", UIParent, "BOTTOM", (x - addon.width / 2) * units, y * units)
end

local function setScale(frame, relativeToUIParent)
    local parentScale = frame:GetParent():GetEffectiveScale()
    local newScale = relativeToUIParent * UIParent:GetEffectiveScale() / parentScale
    if math.abs(frame:GetScale() - newScale) > 0.001 then
        frame:SetScale(newScale)
    end
end

local function fit(frame, x, y, width, height, point)
    if not frame or frame:GetWidth() <= 0 or frame:GetHeight() <= 0 then
        return
    end
    remember(frame)
    local fitScale = math.min(width / frame:GetWidth(), height / frame:GetHeight())
    setScale(frame, scale * fitScale)
    place(frame, x, y, point)
end

local queueLayout
local function placeMinimap()
    local cluster = MinimapCluster
    local map = cluster.MinimapContainer
    local mapCenter = 79
    local mapWidth = Minimap:GetWidth() * Minimap:GetScale()
    if not map or mapWidth <= 0 then
        return
    end
    remember(cluster)
    place(cluster, 0, 0)
    -- The cluster resizes around its header on first login. Anchor the map's
    -- own container directly so a cluster resize cannot lift it out of the art.
    remember(map)
    setScale(map, scale * 137 / mapWidth)
    place(map, mapCenter, 76, "CENTER")
    Minimap:SetMaskTexture(addon.artPath .. "other\\MinimapMask.blp")
    console.mapTrim:SetFrameLevel(Minimap:GetFrameLevel() + 1)
    fade(MinimapCompassTexture)
    fade(MinimapCompassTextureUnderlay)
    fit(cluster.ZoneTextButton, mapCenter, 169, 138, 15, "BOTTOM")
    local buttons = addon.themes[settings.theme].mapButtons
    local tracking = cluster.Tracking
    local trackingButton = tracking and (tracking.Button or tracking)
    if trackingButton and trackingButton:GetWidth() > 0 and trackingButton:GetHeight() > 0 then
        remember(tracking)
        local buttonScale = math.min(18 / trackingButton:GetWidth(), 18 / trackingButton:GetHeight())
        setScale(tracking, scale * buttonScale / (trackingButton == tracking and 1 or trackingButton:GetScale()))
        place(tracking, buttons.x, buttons[1], "CENTER")
    end
    fit(GameTimeFrame, buttons.x, buttons[2], 18, 17, "CENTER")
    fit(AddonCompartmentFrame, buttons.x, buttons[3], 18, 17, "CENTER")
    fit(cluster.IndicatorFrame, buttons.x, buttons[4], 18, 15, "CENTER")
    fit(cluster.DielFrame, buttons.x, buttons[5], 22, 22, "CENTER")

    local icons = {}
    for _, child in ipairs({ Minimap:GetChildren() }) do
        local name = child:GetName()
        if name and name:match("^LibDBIcon10_") then
            if not minimapIconHooks[child] then
                minimapIconHooks[child] = true
                child:HookScript("OnShow", queueLayout)
                child:HookScript("OnHide", queueLayout)
                child:HookScript("OnDragStop", queueLayout)
            end
            if child:IsShown() then
                icons[#icons + 1] = child
            end
        end
    end
    table.sort(icons, function(a, b) return a:GetName() < b:GetName() end)
    local columns, spacing = 6, 23
    for rowStart = 1, #icons, columns do
        local rowCount = math.min(columns, #icons - rowStart + 1)
        local y = 200 + math.floor((rowStart - 1) / columns) * spacing
        for column = 0, rowCount - 1 do
            local x = mapCenter + (column - (rowCount - 1) / 2) * spacing
            fit(icons[rowStart + column], x, y, 21, 21, "CENTER")
        end
    end
end

local function fitActionRow(bar, y)
    local grid = addon.grid
    local center = grid.x + grid.width / 2
    local buttons = bar and bar.shownButtonContainers
    if buttons and #buttons == 12 and bar.isHorizontal and bar.numRows == 1 then
        local first, last = buttons[1], buttons[12]
        local left, bottom = bar:GetLeft(), bar:GetBottom()
        local firstLeft, firstBottom = first:GetLeft(), first:GetBottom()
        local lastRight = last:GetRight()
        if left and bottom and firstLeft and firstBottom and lastRight then
            -- Measure the buttons themselves. Camelot's layout frames can
            -- have different padding from the twelve visible slots.
            local firstRatio = first:GetEffectiveScale() / bar:GetEffectiveScale()
            local lastRatio = last:GetEffectiveScale() / bar:GetEffectiveScale()
            local rowLeft = firstLeft * firstRatio
            local rowWidth = lastRight * lastRatio - rowLeft
            local rowHeight = first:GetHeight() * firstRatio
            if rowWidth > 0 and rowHeight > 0 then
                remember(bar)
                local rowScale = math.min((grid.width - 2) / rowWidth, (grid.rowHeight - 1) / rowHeight)
                setScale(bar, scale * rowScale)
                place(bar, center - (rowLeft - left + rowWidth / 2) * rowScale,
                    y - (firstBottom * firstRatio - bottom) * rowScale)
                return
            end
        end
    end
    fit(bar, center, y, grid.width - 2, grid.rowHeight - 1, "BOTTOM")
end

local function placeMainActionRow(bar)
    local buttons = bar.actionButtons
    if not buttons or #buttons ~= 12 or bar.numButtonsShowable ~= 12 or not bar.isHorizontal or bar.numRows ~= 1 then
        fitActionRow(bar, 1)
        return
    end

    local grid = addon.grid
    local first = buttons[1].container
    local width, height = first:GetSize()
    if width <= 0 or height <= 0 then
        fitActionRow(bar, 1)
        return
    end

    local cellWidth = grid.width / #buttons
    local buttonScale = math.min((cellWidth - 2) / width, (grid.rowHeight - 2) / height) / first:GetScale()
    remember(bar)
    setScale(bar, scale * buttonScale)
    place(bar, grid.x, 0)

    -- Forever's compact main bar packs its buttons closer than bars 2 and 3.
    -- Keep each native button centered in the corresponding art cell.
    for index, button in ipairs(buttons) do
        local slot = mainSlotAnchors[index]
        if not slot then
            slot = CreateFrame("Frame", nil, UIParent)
            slot:SetSize(1, 1)
            mainSlotAnchors[index] = slot
        end
        place(slot, grid.x + (index - 0.5) * cellWidth, grid.rowHeight / 2, "CENTER")
        local container = button.container
        remember(container)
        -- The bar and its containers can have different scales. A zero-offset
        -- anchor puts each center on the artwork's pitch in UIParent units.
        anchor(container, "CENTER", slot, "CENTER", 0, 0)
    end
end

local function placeTrackingBar(container, x, y)
    if not container then
        return
    end
    local experience = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum.Experience
    if experience and container.bars then
        fade(container.bars[experience])
        if container.shownBarIndex == experience then
            -- Keep the native animation running, including its dividers and
            -- rested-XP marker, while the profile displays the visible XP bar.
            y = -30
        end
    end
    fit(container, x, y, addon.grid.width, 11, "BOTTOM")
end

local function placeActionBars()
    local grid = addon.grid
    local center = grid.x + grid.width / 2
    if MainActionBar and not MainActionBar.attachedFrame then
        placeMainActionRow(MainActionBar)
        fade(MainActionBar.BorderArt)
        fade(MainActionBar.EndCaps)
        local page = MainActionBar.ActionBarPageNumber
        if page then
            remember(page)
            place(page, 1032, 157, "CENTER")
        end
    end
    fitActionRow(MultiBarBottomLeft, grid.rowHeight + 1)
    fitActionRow(MultiBarBottomRight, grid.rowHeight * 2 + 1)
    placeTrackingBar(MainStatusTrackingBarContainer, center, 143)
    placeTrackingBar(SecondaryStatusTrackingBarContainer, center, 155)
    fit(PetActionBar, grid.x, 168, 300, 28)
    fit(StanceBar, grid.x, 198, 300, 28)
    fit(PlayerCastingBarFrame, center, 229, 186, 19, "BOTTOM")
end

local function placeSideBars(width, height)
    local x = addon.width / 2 + width / (2 * scale) - 14
    local y = height * 0.53 / scale
    local availableHeight = height * 0.49 / scale
    for _, bar in ipairs({ MultiBarRight, MultiBarLeft }) do
        if bar:IsShown() and not bar.isHorizontal then
            fit(bar, x, y, 39, availableHeight, "RIGHT")
            local screenWidth = bar:GetWidth() * bar:GetEffectiveScale() / UIParent:GetEffectiveScale()
            x = x - screenWidth / scale - 7
        end
    end
end

local function placeChat()
    if not ChatFrame1 then
        return
    end
    remember(ChatFrame1, true)
    local chat = addon.chat
    local ratio = UIParent:GetEffectiveScale() / ChatFrame1:GetEffectiveScale()
    local width, height = (chat.width - 47) * scale * ratio, (chat.height - 65) * scale * ratio
    if math.abs(ChatFrame1:GetWidth() - width) > 0.01 or math.abs(ChatFrame1:GetHeight() - height) > 0.01 then
        ChatFrame1:SetSize(width, height)
    end
    place(ChatFrame1, chat.x + 17, 38)
end

local function updateOptionalRows()
    console:SetOptionalRows(MultiBarBottomLeft:IsShown(), MultiBarBottomRight:IsShown())
end

local function placeMicroMenu()
    if MicroMenu:GetParent() ~= MicroMenuContainer then
        return
    end
    remember(MicroMenuContainer)
    local width, height = MicroMenuContainer:GetSize()
    if width > 1 and height > 1 then
        setScale(MicroMenuContainer, scale * math.min((addon.chat.width - 14) / width, 29 / height))
    end
    place(MicroMenuContainer, addon.width - 7, 201, "BOTTOMRIGHT")
end

local function applyLayoutNow()
    if InCombatLockdown() then
        layoutPending = true
        return
    end
    layoutPending = false

    if not settings.enabled or EditModeManagerFrame:IsEditModeActive() or InputUtil.IsGamepadUIEnabled()
        or (PlayerFrame and PlayerFrame.unit == "vehicle") then
        quickSlots:Hide()
        console:Hide()
        restoreLayout()
        if not settings.enabled and not InputUtil.IsGamepadUIEnabled() and EditModeManagerFrame:IsInitialized() then
            addon.DisableNativeLayout(character)
        end
        return
    end
    local width, height = UIParent:GetSize()
    if width <= 0 or height <= 0 then
        return
    end
    scale = math.min(width * 0.98 / addon.width, height / 900)
    console:SetScale(scale)
    console:Show()
    setScale(quickSlots, scale)
    place(quickSlots, addon.quickSlots.x, 0)
    local showQuickSlots = character.quickSlotsEnabled ~= false
    console:SetQuickSlotsShown(showQuickSlots)
    quickSlots:SetShown(showQuickSlots)
    placeMinimap()
    placeActionBars()
    updateOptionalRows()
    placeSideBars(width, height)
    placeChat()
    if PlayerFrame and PlayerFrame.unit == "player" then
        -- Keep the native click target and pet frame while the console draws
        -- the player's portrait, bars and character sheet.
        fit(PlayerFrame, 210, 8, 289, 118)
        fade(PlayerFrame.PlayerFrameContainer)
        fade(PlayerFrame.PlayerFrameContent)
    end
    fit(PetFrame, 216, 147, 136, 45)
    placeMicroMenu()
    fit(BagsBar, addon.width - 7, 171, addon.chat.width - 14, 28, "BOTTOMRIGHT")
    if GameTooltipDefaultContainer then
        remember(GameTooltipDefaultContainer)
        place(GameTooltipDefaultContainer, addon.width - 12, 239, "BOTTOMRIGHT")
    end
    if GameTooltip and tooltipClamped == nil then
        tooltipClamped = GameTooltip:IsClampedToScreen()
        GameTooltip:SetClampedToScreen(true)
    end
    if nativeLayoutRequested and EditModeManagerFrame:IsInitialized() then
        nativeLayoutRequested = false
        local ok, applied, reason = pcall(addon.EnableNativeLayout, character)
        if not ok then
            message("Could not create the Edit Mode layout. Run /wiiiui on to retry out of combat.")
            geterrorhandler()(applied)
        elseif applied == nil then
            nativeLayoutRequested = true
        elseif reason then
            message(reason)
        end
    end
end

local function applyLayout()
    if layoutApplying then return end
    layoutApplying = true
    local ok, reason = pcall(applyLayoutNow)
    layoutApplying = false
    if not ok then error(reason, 0) end
end

queueLayout = function()
    if not console or not settings.enabled or layoutQueued then
        return
    end
    layoutQueued = true
    C_Timer.After(0, function()
        layoutQueued = false
        applyLayout()
    end)
end

local function restoreDockAfterNativeUpdate()
    if layoutApplying or not console or not console:IsShown() or not settings.enabled then return end
    if EditModeManagerFrame:IsEditModeActive() then return end
    if EditModeManagerFrame.layoutApplyInProgress or InCombatLockdown() then
        queueLayout()
        return
    end
    -- Native layout updates can move the controls during a level-up. Dock
    -- them again in the same frame so the default placement does not flash.
    applyLayout()
end

local function applyPortraitOffsets(model)
    local offsets = character.portraitOffsets
    model:SetPosition(offsets.x, offsets.y, offsets.z)
end

local function portraitCameraForModel(model)
    local camera = character.portraitCamera
    local modelID = model:GetModelFileID()
    if issecretvalue(modelID) or type(modelID) ~= "number" or modelID <= 0 then return end
    if type(camera) ~= "table" or camera.model ~= modelID or camera.version ~= portraitCameraVersion then return end
    for _, key in ipairs({ "x", "y", "z", "targetX", "targetY", "targetZ", "roll" }) do
        local value = camera[key]
        if issecretvalue(value) or type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return end
    end
    local distanceSquared = (camera.x - camera.targetX)^2 + (camera.y - camera.targetY)^2 + (camera.z - camera.targetZ)^2
    if distanceSquared > 0.000001 then return camera end
end

local function restorePortraitCamera(model)
    if character.portraitLocked == false then return false end
    local camera = portraitCameraForModel(model)
    if not camera then return false end
    model:MakeCurrentCameraCustom()
    model:SetCameraPosition(camera.x, camera.y, camera.z)
    model:SetCameraTarget(camera.targetX, camera.targetY, camera.targetZ)
    model:SetCameraRoll(camera.roll)
    return true
end

local function framePortraitModel(model)
    if restorePortraitCamera(model) then
        applyPortraitOffsets(model)
        return
    end
    -- Camera 0 is a model's embedded camera, not necessarily its head camera.
    -- Toggle the zoom to rebuild the automatic portrait camera even when the
    -- previous model/custom camera already had the same zoom value.
    model:SetPortraitZoom(0)
    model:SetPortraitZoom(portraitZoom)
    model:SetCamDistanceScale(1)
    applyPortraitOffsets(model)
end

local function capturePortraitCamera(model)
    if character.portraitLocked == false then return end
    -- Copy the actual settled camera, not a race-specific set of constants.
    -- A custom camera stops the client's automatic portrait tracking from
    -- changing the view underneath the player's saved model translation.
    model:MakeCurrentCameraCustom()
    local x, y, z = model:GetCameraPosition()
    local targetX, targetY, targetZ = model:GetCameraTarget()
    character.portraitCamera = {
        version = portraitCameraVersion,
        model = model:GetModelFileID(), x = x, y = y, z = z,
        targetX = targetX, targetY = targetY, targetZ = targetZ, roll = model:GetCameraRoll(),
    }
    if portraitCameraForModel(model) then
        restorePortraitCamera(model)
    else
        -- An unloaded camera may report zeroes. Keep the normal view and
        -- make a bounded retry instead of saving an unusable camera.
        character.portraitCamera = nil
        framePortraitModel(model)
        model.cameraAttempts = (model.cameraAttempts or 0) + 1
        if model.cameraAttempts < 3 then model.framingSettle = portraitCameraSettle end
    end
end

local function showAnimatedPortrait(model)
    model:SetDoBlend(false)
    model:SetAnimation(0, 0)
    framePortraitModel(model)
    if (model:GetModelFileID() or 0) <= 0 then
        return
    end
    model:SetAlpha(1)
    console.portrait:Hide()
    console.portraitBorder:Hide()
    model.cameraAttempts = 0
    if character.portraitLocked ~= false and not portraitCameraForModel(model) then
        -- A model ID can be available before the portrait camera has settled.
        -- Do not freeze the initial full-body view on a cold character load.
        model.framingSettle = portraitCameraSettle
    else
        model.framingSettle = nil
    end
end

local function updatePortrait()
    local model = console.portraitModel
    SetPortraitTexture(console.portrait, "player", true)
    console.portrait:Show()
    console.portraitBorder:Show()
    model:SetAlpha(0)
    model:ClearModel()
    if model:SetUnit("player", false, true) then
        showAnimatedPortrait(model)
    end
end

local function maintainPortraitFraming(model, elapsed)
    if model.framingSettle then
        model.framingSettle = model.framingSettle - elapsed
        if model.framingSettle <= 0 then
            model.framingSettle = nil
            if (model:GetModelFileID() or 0) > 0 then capturePortraitCamera(model) end
        end
    end
    if character.portraitLocked == false then return end
    model.framingElapsed = (model.framingElapsed or 0) + elapsed
    if model.framingElapsed < 0.25 then return end
    model.framingElapsed = 0
    if (model:GetModelFileID() or 0) > 0 then
        -- Keep translation fixed without recalculating a camera from the
        -- changing animation bounds or restarting the idle animation.
        applyPortraitOffsets(model)
        restorePortraitCamera(model)
        if model:GetAlpha() == 0 then
            showAnimatedPortrait(model)
        end
    end
end

local function resetPortraitFraming()
    local offsets = character.portraitOffsets
    offsets.x, offsets.y, offsets.z = 0, 0, 0
    character.portraitCamera = nil
    if portraitControls then
        for _, slider in ipairs(portraitControls.sliders) do slider:SetValue(0) end
    end
    framePortraitModel(console.portraitModel)
    console.portraitModel.cameraAttempts = 0
    console.portraitModel.framingSettle = portraitCameraSettle
end

local function openPortraitControls()
    if portraitControls then
        portraitControls:Show()
        return
    end

    local panel = CreateFrame("Frame", "WIIIUIForeverPortraitControls", UIParent, "BackdropTemplate")
    portraitControls = panel
    panel:SetSize(360, 222)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 90)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = addon.artPath .. "forsaken\\panel.tga",
        edgeFile = addon.artPath .. "forsaken\\border.tga",
        edgeSize = 18,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    table.insert(UISpecialFrames, panel:GetName())
    console:HookScript("OnHide", function() panel:Hide() end)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -17)
    title:SetText("Portrait framing")
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("TOP", 0, -41)
    hint:SetText("X/Y/Z move the model. Lock anchors its camera and position.")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    close:SetScript("OnClick", function() panel:Hide() end)

    local offsets = character.portraitOffsets
    local sliders = {}
    local function formatOffset(value)
        return string.format("%+.2f", value)
    end
    local sliderMixin = MinimalSliderWithSteppersMixin
    for index, axis in ipairs(portraitAxes) do
        local key = axis.key
        local slider = CreateFrame("Frame", nil, panel, "MinimalSliderWithSteppersTemplate")
        slider:SetSize(190, 28)
        slider:SetPoint("TOPLEFT", 112, -60 - (index - 1) * 37)
        slider:Init(offsets[key], -1, 1, 200, { [sliderMixin.Label.Right] = formatOffset })
        slider:RegisterCallback(sliderMixin.Event.OnValueChanged, function(_, value)
            offsets[key] = value
            applyPortraitOffsets(console.portraitModel)
        end, panel)
        sliders[index] = slider

        local label = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", slider, "LEFT", -94, 0)
        label:SetText(axis.label)
    end

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(144, 23)
    reset:SetPoint("BOTTOMLEFT", 22, 15)
    reset:SetText("Reset portrait")
    reset:SetScript("OnClick", resetPortraitFraming)
    panel.sliders = sliders
    local reapply = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reapply:SetSize(144, 23)
    reapply:SetPoint("BOTTOMRIGHT", -22, 15)
    reapply:SetText("Reapply saved")
    reapply:SetScript("OnClick", function()
        framePortraitModel(console.portraitModel)
    end)
    panel:Show()
end

local function createPortraitBar(y)
    local bar = CreateFrame("StatusBar", nil, console)
    bar:SetSize(70, 9)
    bar:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", 217, y)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetAllPoints()
    text:SetFont(STANDARD_TEXT_FONT, 7, "OUTLINE")
    text:SetWordWrap(false)
    text:SetJustifyH("CENTER")
    text:Hide()
    bar.text = text
    return bar
end

local function updateBarText(bar, mode, current, maximum, powerType)
    if mode == "none" then
        bar.text:SetText("")
        bar.text:Hide()
        return
    end
    bar.text:Show()
    if mode == "numbers" then
        bar.text:SetFormattedText("%.0f/%.0f", current, maximum)
        return
    end
    -- Let the client calculate percentages: health and resource values can
    -- be secret during combat, so addon code must not divide them itself.
    if not percentCurve then
        percentCurve = C_CurveUtil.CreateCurve()
        percentCurve:SetType(Enum.LuaCurveType.Linear)
        percentCurve:AddPoint(0, 0)
        percentCurve:AddPoint(1, 100)
    end
    local percent
    if powerType == nil then
        percent = UnitHealthPercent("player", true, percentCurve)
    else
        percent = UnitPowerPercent("player", powerType, false, percentCurve)
    end
    if mode == "percent" then
        bar.text:SetFormattedText("%.0f%%", percent)
    else
        bar.text:SetFormattedText("%.0f/%.0f (%.0f%%)", current, maximum, percent)
    end
end

local function updateHealth()
    -- Forever can return secret combat values. Pass them straight to the bar.
    local current, maximum = UnitHealth("player"), UnitHealthMax("player")
    console.health:SetMinMaxValues(0, maximum)
    console.health:SetValue(current)
    updateBarText(console.health, character.healthText, current, maximum)
end

local function updatePower()
    local powerType, token = UnitPowerType("player")
    local color = PowerBarColor[token] or PowerBarColor.MANA
    console.power:SetStatusBarColor(color.r, color.g, color.b)
    local current, maximum = UnitPower("player", powerType), UnitPowerMax("player", powerType)
    console.power:SetMinMaxValues(0, maximum)
    console.power:SetValue(current)
    updateBarText(console.power, character.powerText, current, maximum, powerType)
end

local function addBarTextMenu(menu)
    local textMenu = menu:CreateButton("Health and resource text")
    for _, option in ipairs({
        { label = "Health", key = "healthText", update = updateHealth },
        { label = "Resource", key = "powerText", update = updatePower },
    }) do
        local key, update = option.key, option.update
        local submenu = textMenu:CreateButton(option.label)
        for _, mode in ipairs(barTextModes) do
            submenu:CreateRadio(mode.label, function(value)
                return character[key] == value
            end, function(value)
                character[key] = value
                update()
            end, mode.key)
        end
    end
end

local function selectTheme(theme)
    settings.theme = theme
    console:SetTheme(theme)
    queueLayout()
    message(addon.themes[theme].label .. " theme selected.")
end

local function setEnabled(enabled)
    settings.enabled = not not enabled
    nativeLayoutRequested = settings.enabled
    applyLayout()
    if addon.RefreshCharacterSheet then
        addon.RefreshCharacterSheet()
    end
end

local function printThemes()
    message("Use /wiiiui human, orc, undead, or nightelf to select a theme. Use /wiiiui off or on to toggle the console.")
end

local function initialize()
    WIIIUIForeverDB = type(WIIIUIForeverDB) == "table" and WIIIUIForeverDB or {}
    settings = WIIIUIForeverDB
    WIIIUIForeverCharacterDB = type(WIIIUIForeverCharacterDB) == "table" and WIIIUIForeverCharacterDB or {}
    character = WIIIUIForeverCharacterDB
    character.portraitLocked = character.portraitLocked ~= false
    for _, key in ipairs({ "healthText", "powerText" }) do
        local valid = false
        for _, mode in ipairs(barTextModes) do
            if character[key] == mode.key then valid = true; break end
        end
        if not valid then character[key] = "none" end
    end
    character.portraitOffsets = type(character.portraitOffsets) == "table" and character.portraitOffsets or {}
    for _, axis in ipairs(portraitAxes) do
        local value = character.portraitOffsets[axis.key]
        character.portraitOffsets[axis.key] = type(value) == "number" and value == value
            and math.max(-1, math.min(1, value)) or 0
    end
    settings.theme = addon.themes[settings.theme] and settings.theme or "human"
    settings.enabled = settings.enabled ~= false
    addon.SetupCharacterSheet(settings, character)

    console = addon.CreateArt()
    console:SetTheme(settings.theme)
    local portrait = console:CreateTexture(nil, "OVERLAY")
    portrait:SetSize(58, 58)
    portrait:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", 223, 35)
    local portraitBorder = console:CreateTexture(nil, "OVERLAY", nil, 1)
    portraitBorder:SetTexture(addon.artPath .. "other\\golden_frame.tga")
    portraitBorder:SetSize(62, 62)
    portraitBorder:SetPoint("CENTER", portrait, "CENTER")
    console.portrait = portrait
    console.portraitBorder = portraitBorder
    local model = CreateFrame("PlayerModel", nil, console.portraitViewport)
    model:SetAllPoints()
    model:SetFrameLevel(console.portraitViewport:GetFrameLevel() + 1)
    model:SetKeepModelOnHide(true)
    model:SetScript("OnModelLoaded", showAnimatedPortrait)
    model:SetScript("OnUpdate", maintainPortraitFraming)
    model:SetScript("OnShow", function(self)
        if character.portraitLocked ~= false and (self:GetModelFileID() or 0) > 0 then
            restorePortraitCamera(self)
            applyPortraitOffsets(self)
        end
    end)
    console.portraitModel = model
    console.health = createPortraitBar(16)
    console.health:SetStatusBarColor(0.20, 0.76, 0.14)
    console.power = createPortraitBar(3)
    addon.CreateProfile(console, character)
    quickSlots = addon.CreateQuickSlots(character)

    local gear = CreateFrame("Button", nil, console)
    gear:SetSize(19, 19)
    gear:SetPoint("BOTTOMRIGHT", console, "BOTTOMRIGHT", -14, 147)
    gear:SetNormalTexture(addon.artPath .. "other\\cogwheel.tga")
    gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    gear:SetScript("OnClick", function(button)
        MenuUtil.CreateContextMenu(button, function(_, menu)
            menu:CreateTitle("WIIIUI Forever")
            local function isSelected(theme)
                return settings.theme == theme
            end
            for _, theme in ipairs({ "human", "orc", "undead", "nightelf" }) do
                menu:CreateRadio(addon.themes[theme].label, isSelected, selectTheme, theme)
            end
            addon.AddProfileMenu(menu, console)
            addon.AddStatusMenu(menu, console)
            addon.AddRibbonMenu(menu, console)
            addBarTextMenu(menu)
            menu:CreateButton("Portrait framing", openPortraitControls)
            menu:CreateButton("Reset portrait to default", resetPortraitFraming)
            menu:CreateCheckbox("Lock portrait framing", function()
                return character.portraitLocked ~= false
            end, function()
                character.portraitLocked = character.portraitLocked == false
                if character.portraitLocked then
                    character.portraitCamera = nil
                    framePortraitModel(console.portraitModel)
                    console.portraitModel.cameraAttempts = 0
                    console.portraitModel.framingSettle = portraitCameraSettle
                else
                    console.portraitModel.framingSettle = nil
                    framePortraitModel(console.portraitModel)
                end
            end)
            menu:CreateCheckbox("Quick slots", function()
                return character.quickSlotsEnabled ~= false
            end, function()
                character.quickSlotsEnabled = character.quickSlotsEnabled == false
                applyLayout()
                if InCombatLockdown() then
                    message("Quick slot visibility will update after combat.")
                end
            end)
            if addon.RefreshCharacterSheet then
                menu:CreateCheckbox("Forsaken Character window", function()
                    return settings.forsakenSheet ~= false
                end, function()
                    settings.forsakenSheet = settings.forsakenSheet == false
                    addon.RefreshCharacterSheet()
                end)
                addon.AddCharacterBagChoices(menu:CreateButton("Character inventory"))
                menu:CreateButton("Reset Character window and backpack positions", addon.ResetCharacterPositions)
            end
        end)
    end)

    addon.SetupSessionRibbon(console, character, settings, function(button)
        gear:GetScript("OnClick")(button)
    end)

    SLASH_WIIIUIFOREVER1 = "/wiiiui"
    SlashCmdList.WIIIUIFOREVER = function(input)
        local command = input:lower():match("^%s*(.-)%s*$")
        if addon.themes[command] then
            selectTheme(command)
        elseif command == "off" or command == "on" then
            setEnabled(command == "on")
        else
            printThemes()
        end
    end

    hooksecurefunc(EditModeManagerFrame, "UpdateBottomActionBarPositions", restoreDockAfterNativeUpdate)
    hooksecurefunc(EditModeManagerFrame, "UpdateRightActionBarPositions", restoreDockAfterNativeUpdate)
    if type(EditModeManagerFrame.UpdateLayoutInfo) == "function" then
        hooksecurefunc(EditModeManagerFrame, "UpdateLayoutInfo", restoreDockAfterNativeUpdate)
    end
    hooksecurefunc(EditModeManagerFrame, "SetToLayoutAnchor", queueLayout)
    hooksecurefunc(MainActionBar, "UpdateGridLayout", restoreDockAfterNativeUpdate)
    hooksecurefunc(MinimapCluster, "UpdateMinimapConfig", queueLayout)
    hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", queueLayout)
    hooksecurefunc(MinimapCluster, "SetEditModeScale", queueLayout)
    MinimapCluster:HookScript("OnShow", queueLayout)
    local minimapIcons = LibStub and LibStub("LibDBIcon-1.0", true)
    if minimapIcons then
        for _, method in ipairs({ "Register", "Show", "Refresh", "SetButtonRadius", "SetButtonToPosition" }) do
            if type(minimapIcons[method]) == "function" then
                hooksecurefunc(minimapIcons, method, queueLayout)
            end
        end
    end
    hooksecurefunc(MicroMenu, "ResetMicroMenuPosition", restoreDockAfterNativeUpdate)
    hooksecurefunc(MicroMenuContainer, "Layout", restoreDockAfterNativeUpdate)
    for _, bar in ipairs({ MultiBarBottomLeft, MultiBarBottomRight }) do
        bar:HookScript("OnShow", updateOptionalRows)
        bar:HookScript("OnHide", updateOptionalRows)
    end
    EventRegistry:RegisterCallback("EditMode.Enter", applyLayout, console)
    EventRegistry:RegisterCallback("EditMode.Exit", queueLayout, console)
    updatePortrait()
    updateHealth()
    updatePower()
    addon.UpdateCombatStats(console)
    addon.UpdateProfile(console)
    addon.UpdatePlayerStatus(console)
    queueLayout()
    addon.RegisterSettings(settings, setEnabled, selectTheme)
end

events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_FLAGS_CHANGED")
events:RegisterEvent("PLAYER_UPDATE_RESTING")
events:RegisterEvent("UPDATE_EXHAUSTION")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:RegisterEvent("INPUT_DEVICE_INTERFACE_TRANSITION")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("PLAYER_XP_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_CHANGED")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("SPELL_POWER_CHANGED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("COMBAT_RATING_UPDATE")
events:RegisterEvent("DAMAGE_METER_COMBAT_SESSION_UPDATED")
events:RegisterEvent("DAMAGE_METER_CURRENT_SESSION_UPDATED")
events:RegisterEvent("DAMAGE_METER_RESET")
events:RegisterUnitEvent("UNIT_DAMAGE", "player")
events:RegisterUnitEvent("UNIT_RESISTANCES", "player")
events:RegisterUnitEvent("UNIT_INVENTORY_CHANGED", "player")
events:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
events:RegisterUnitEvent("UNIT_RANGEDDAMAGE", "player")
events:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "player")
events:RegisterUnitEvent("UNIT_MODEL_CHANGED", "player")
events:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
events:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
events:RegisterUnitEvent("UNIT_HEALTH", "player")
events:RegisterUnitEvent("UNIT_MAXHEALTH", "player")
events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
events:RegisterUnitEvent("UNIT_POWER_FREQUENT", "player")
events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
events:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
events:RegisterUnitEvent("UNIT_FACTION", "player")
events:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", "player")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        initialize()
    elseif console then
        if event == "UPDATE_EXHAUSTION" or event == "PLAYER_UPDATE_RESTING" then
            addon.UpdateExperience(console)
            addon.UpdateProfileStats(console, "restedXp")
            addon.UpdatePlayerStatus(console)
            return
        elseif event == "PLAYER_REGEN_DISABLED" then
            addon.ResetCombatStats(console)
            addon.UpdatePlayerStatus(console)
            return
        elseif event == "PLAYER_FLAGS_CHANGED"
            or event == "UNIT_FACTION" or event == "UNIT_THREAT_SITUATION_UPDATE" then
            addon.UpdatePlayerStatus(console)
            return
        elseif event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
            updateHealth()
            return
        elseif event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT"
            or event == "UNIT_MAXPOWER" or event == "UNIT_DISPLAYPOWER" then
            updatePower()
            return
        elseif event == "UNIT_PORTRAIT_UPDATE" then
            SetPortraitTexture(console.portrait, "player", true)
            if console.portraitModel:GetAlpha() > 0 then
                restorePortraitCamera(console.portraitModel)
                applyPortraitOffsets(console.portraitModel)
            end
            return
        elseif event == "UNIT_MODEL_CHANGED" then
            updatePortrait()
            return
        elseif event == "BAG_UPDATE_DELAYED" or event == "UNIT_INVENTORY_CHANGED" then
            addon.UpdateProfileStats(console, "ammo")
            addon.UpdateProfileStats(console, "armor")
            return
        elseif event == "DAMAGE_METER_RESET" then
            addon.ResetCombatStats(console)
            addon.UpdateProfileStats(console, "fightDps")
            return
        elseif event == "DAMAGE_METER_COMBAT_SESSION_UPDATED" or event == "DAMAGE_METER_CURRENT_SESSION_UPDATED" then
            local meterType = ...
            if event == "DAMAGE_METER_CURRENT_SESSION_UPDATED"
                or meterType == Enum.DamageMeterType.Dps or meterType == Enum.DamageMeterType.DamageDone then
                addon.UpdateCombatStats(console, true)
            end
            addon.UpdateProfileStats(console, "fightDps")
            return
        elseif event == "COMBAT_RATING_UPDATE" then
            addon.UpdateProfileStats(console, "crit")
            return
        elseif event == "UNIT_ATTACK_SPEED" then
            addon.UpdateProfileStats(console, "meleeDps")
            return
        elseif event == "UNIT_RANGEDDAMAGE" then
            addon.UpdateProfileStats(console, "rangedDps")
            return
        elseif event == "PLAYER_XP_UPDATE" or event == "PLAYER_LEVEL_CHANGED"
            or event == "PLAYER_EQUIPMENT_CHANGED" or event == "SPELL_POWER_CHANGED"
            or event == "UNIT_DAMAGE" or event == "UNIT_RESISTANCES" then
            if event == "PLAYER_LEVEL_CHANGED" and character.portraitLocked ~= false then
                restorePortraitCamera(console.portraitModel)
                applyPortraitOffsets(console.portraitModel)
            end
            addon.UpdateProfile(console)
            if event == "PLAYER_LEVEL_CHANGED" then restoreDockAfterNativeUpdate() end
            return
        elseif event == "PLAYER_ENTERING_WORLD" then
            updatePortrait()
            updateHealth()
            updatePower()
        end
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" then
            addon.UpdateCombatStats(console)
            addon.UpdateProfile(console)
        end
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" then
            addon.UpdatePlayerStatus(console)
        end
        if event == "PLAYER_REGEN_ENABLED" and layoutPending then
            applyLayout()
        else
            queueLayout()
        end
    end
end)
