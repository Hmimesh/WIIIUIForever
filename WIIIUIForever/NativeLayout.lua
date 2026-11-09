local _, addon = ...

local layoutName = "WIIIUI Forever Bars"

local function getLayouts()
    local info = C_EditMode.GetLayouts()
    local layouts = EditModePresetLayoutManager:GetCopyOfPresetLayouts()
    for _, saved in ipairs(info.layouts) do
        layouts[#layouts + 1] = saved
    end
    info.layouts = layouts
    return info
end

local function findLayout(info, name, layoutType)
    for index, layout in ipairs(info.layouts) do
        if layout.layoutName == name and layout.layoutType == layoutType then
            return index
        end
    end
end

local function setAnchor(layout, frame, row)
    if not frame then
        return
    end
    local point, relative, relativePoint, x, y = frame:GetPoint(1)
    if relative ~= UIParent or not frame.system then
        return
    end
    for _, system in ipairs(layout.systems) do
        if system.system == frame.system and system.systemIndex == frame.systemIndex then
            local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
            system.anchorInfo = {
                point = point, relativeTo = "UIParent", relativePoint = relativePoint,
                offsetX = x * scale, offsetY = y * scale,
            }
            system.anchorInfo2 = nil
            -- The secure frame manager leaves custom anchors alone in combat.
            system.isInDefaultPosition = false
            if row then
                local options = Enum.EditModeActionBarSetting
                for _, setting in ipairs(system.settings) do
                    if setting.setting == options.IconPadding then
                        setting.value = 4
                    elseif setting.setting == options.HideBarArt then
                        setting.value = 1
                    end
                end
            elseif frame == PlayerCastingBarFrame then
                for _, setting in ipairs(system.settings) do
                    if setting.setting == Enum.EditModeCastBarSetting.LockToPlayerFrame then
                        setting.value = 0
                    end
                end
            end
            return true
        end
    end
end

local function setDockAnchors(layout)
    if not setAnchor(layout, MinimapCluster) or not setAnchor(layout, MicroMenuContainer) then
        return false
    end
    setAnchor(layout, BagsBar)
    return true
end

function addon.EnableNativeLayout(character)
    local info = getLayouts()
    local current = info.layouts[info.activeLayout]
    if not current then
        return nil
    end
    local characterType = Enum.EditModeLayoutType.Character
    local existing = findLayout(info, layoutName, characterType)
    if not existing and EditModeManagerFrame:AreLayoutsOfTypeMaxed(characterType) then
        return false, "Free a character layout slot in Edit Mode, then run /wiiiui on to lock the bars in place."
    end

    if existing ~= info.activeLayout then
        character.previousLayoutName = current.layoutName
        character.previousLayoutType = current.layoutType
    end
    if existing then
        if not character.dockAnchorsSaved then
            if not setDockAnchors(info.layouts[existing]) then
                return nil
            end
            C_EditMode.SaveLayouts(info)
            character.dockAnchorsSaved = true
        end
        if existing ~= info.activeLayout then
            C_EditMode.SetActiveLayout(existing)
        end
        return true
    end

    local layout = CopyTable(current)
    layout.layoutName = layoutName
    layout.layoutType = characterType
    if not setAnchor(layout, MainActionBar, true) then
        return nil
    end
    setAnchor(layout, MultiBarBottomLeft, true)
    setAnchor(layout, MultiBarBottomRight, true)
    setAnchor(layout, MultiBarRight)
    setAnchor(layout, MultiBarLeft)
    setAnchor(layout, PetActionBar)
    setAnchor(layout, StanceBar)
    setAnchor(layout, PlayerCastingBarFrame)
    setAnchor(layout, MainStatusTrackingBarContainer)
    setAnchor(layout, SecondaryStatusTrackingBarContainer)
    if not setDockAnchors(layout) then
        return nil
    end

    local index = #info.layouts + 1
    info.layouts[index] = layout
    C_EditMode.SaveLayouts(info)
    C_EditMode.OnLayoutAdded(index, true, false)
    character.dockAnchorsSaved = true
    return true, "Created the WIIIUI Forever Bars character layout in Edit Mode."
end

function addon.DisableNativeLayout(character)
    local info = getLayouts()
    local active = info.layouts[info.activeLayout]
    if active and active.layoutName == layoutName and active.layoutType == Enum.EditModeLayoutType.Character then
        local previous = findLayout(info, character.previousLayoutName, character.previousLayoutType)
        C_EditMode.SetActiveLayout(previous or 1)
    end
end
