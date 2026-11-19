local _, addon = ...

local function readTalents()
    local spec, traits = C_SpecializationInfo, C_Traits
    if not traits then return end
    local group = spec and spec.GetActiveSpecGroup and spec.GetActiveSpecGroup()
    local configID = group and spec.GetCombatConfigIDForSpecGroup and spec.GetCombatConfigIDForSpecGroup(group)
    if not configID and C_ClassTalents and C_ClassTalents.GetActiveConfigID then
        configID = C_ClassTalents.GetActiveConfigID()
    end
    local config = configID and traits.GetConfigInfo(configID)
    if not config or not config.treeIDs then return end

    local groups, nodes, currencies, seenGroups = {}, {}, {}, {}
    local points
    for _, treeID in ipairs(config.treeIDs) do
        local display = traits.GetGroupDisplayInfoByTreeID and traits.GetGroupDisplayInfoByTreeID(treeID)
        for _, info in ipairs(display or {}) do
            if not seenGroups[info.groupID] then
                groups[#groups + 1] = info
                seenGroups[info.groupID] = true
            end
        end
        for _, currency in ipairs(traits.GetTreeCurrencyInfo(configID, treeID, true) or {}) do
            if not currencies[currency.traitCurrencyID] then
                currencies[currency.traitCurrencyID] = true
                points = (points or 0) + currency.quantity
            end
        end
        for _, nodeID in ipairs(traits.GetTreeNodes(treeID) or {}) do
            local node = traits.GetNodeInfo(configID, nodeID)
            if node and node.isVisible and node.maxRanks > 0 then
                local entryID = node.activeEntry and node.activeEntry.entryID or node.entryIDs[1]
                local entry = entryID and traits.GetEntryInfo(configID, entryID)
                local definition = entry and entry.definitionID and traits.GetDefinitionInfo(entry.definitionID)
                if definition then
                    local spell = definition.spellID
                    local icon = definition.overrideIcon or (spell and C_Spell.GetSpellTexture(spell))
                    local name = definition.overrideName or (spell and C_Spell.GetSpellName(spell))
                    if icon and name then
                        nodes[#nodes + 1] = {
                            id = nodeID, x = node.posX, y = node.posY, groups = node.groupIDs,
                            icon = icon, name = name, spell = spell, rank = node.activeRank, maxRank = node.maxRanks,
                        }
                    end
                end
            end
        end
    end
    table.sort(groups, function(a, b) return a.orderIndex < b.orderIndex end)
    table.sort(nodes, function(a, b)
        if a.y ~= b.y then return a.y < b.y end
        if a.x ~= b.x then return a.x < b.x end
        return a.id < b.id
    end)
    return groups, nodes, points
end

function addon.CreateCharacterTalents(sheet, settings, width)
    local panel = CreateFrame("Frame", nil, sheet, "BackdropTemplate")
    panel:SetWidth(width)
    panel:Hide()
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOP", 0, -17)
    heading:SetText(TALENTS or "Talents")
    local pointsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    pointsLabel:SetPoint("TOP", heading, "BOTTOM", 0, -6)

    local edit = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    edit:SetSize(126, 22)
    edit:SetPoint("BOTTOM", 0, 13)
    edit:SetText("Open talent tree")
    edit:SetScript("OnClick", function()
        if TalentMicroButton and TalentMicroButton:IsEnabled() then TalentMicroButton:Click() end
    end)

    local tree = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    tree:SetSize(width - 36, 22)
    tree:SetPoint("TOP", 0, -55)
    local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -86)
    scroll:SetPoint("BOTTOMRIGHT", -28, 46)
    scroll.ScrollBar:SetHideIfUnscrollable(true)
    local grid = CreateFrame("Frame", nil, scroll)
    grid:SetSize(width - 46, 1)
    scroll:SetScrollChild(grid)
    local empty = grid:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", 0, -12)
    empty:SetText("Talent data unavailable")

    local tiles, groups, nodes, selected = {}, {}, {}, nil
    local columns, step = 4, (width - 46) / 4
    local function newTile()
        local tile = CreateFrame("Frame", nil, grid)
        tile:SetSize(step - 6, step - 6)
        tile:EnableMouse(true)
        tile.background = tile:CreateTexture(nil, "BACKGROUND")
        tile.background:SetAllPoints()
        tile.icon = tile:CreateTexture(nil, "ARTWORK")
        tile.icon:SetPoint("TOPLEFT", 3, -3)
        tile.icon:SetPoint("BOTTOMRIGHT", -3, 3)
        tile.rank = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        tile.rank:SetPoint("BOTTOMRIGHT", -2, 2)
        tile:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local node = self.node
            if node.spell and node.spell > 0 then
                GameTooltip:SetSpellByID(node.spell)
            else
                GameTooltip:SetText(node.name)
            end
            GameTooltip:AddLine(string.format("Rank %d / %d", node.rank, node.maxRank), 1, 0.82, 0)
            GameTooltip:Show()
        end)
        local function hideTooltip(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end
        tile:SetScript("OnLeave", hideTooltip)
        tile:SetScript("OnHide", hideTooltip)
        return tile
    end

    local function showTree()
        local groupID = selected and selected.groupID
        tree:SetText(selected and selected.displayName or "All talents")
        tree:SetEnabled(#groups > 1)
        local used = 0
        for _, node in ipairs(nodes) do
            if not groupID or not node.groups or #node.groups == 0 or tContains(node.groups, groupID) then
                used = used + 1
                local tile = tiles[used] or newTile()
                tiles[used] = tile
                tile.node = node
                tile:SetPoint("TOPLEFT", grid, "TOPLEFT", (used - 1) % columns * step, -math.floor((used - 1) / columns) * step)
                addon.SetCharacterSlotArt(tile.background, settings.theme)
                tile.icon:SetTexture(node.icon)
                tile.icon:SetDesaturated(node.rank == 0)
                tile.rank:SetText(node.rank > 0 and string.format("%d/%d", node.rank, node.maxRank) or "")
                tile:Show()
            end
        end
        for index = used + 1, #tiles do tiles[index]:Hide() end
        grid:SetHeight(math.max(30, math.ceil(used / columns) * step))
        empty:SetShown(used == 0)
    end
    tree:SetScript("OnClick", function(button)
        MenuUtil.CreateContextMenu(button, function(_, menu)
            local function isSelected(group) return selected == group end
            local function selectGroup(group)
                selected = group
                scroll:SetVerticalScroll(0)
                showTree()
            end
            for _, group in ipairs(groups) do
                menu:CreateRadio(group.displayName, isSelected, selectGroup, group)
            end
        end)
    end)

    function panel:Refresh()
        local newGroups, newNodes, points = readTalents()
        groups, nodes = newGroups or {}, newNodes or {}
        local oldID = selected and selected.groupID
        selected = groups[1]
        for _, group in ipairs(groups) do
            if group.groupID == oldID then selected = group; break end
        end
        if oldID ~= (selected and selected.groupID) then scroll:SetVerticalScroll(0) end
        pointsLabel:SetText(points and string.format("Points available: %d", points) or "")
        edit:SetEnabled(TalentMicroButton ~= nil and TalentMicroButton:IsEnabled())
        showTree()
    end
    function panel:UpdateTheme()
        addon.SetWindowTheme(self, settings.theme, true)
        for _, tile in ipairs(tiles) do addon.SetCharacterSlotArt(tile.background, settings.theme) end
    end
    return panel
end
