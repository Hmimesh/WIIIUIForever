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
        for _, currency in ipairs(traits.GetTreeCurrencyInfo(configID, treeID, false) or {}) do
            if currencies[currency.traitCurrencyID] == nil then
                currencies[currency.traitCurrencyID] = currency.quantity
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
                            icon = icon, name = name, spell = spell,
                            rank = node.currentRank or node.activeRank, maxRank = node.maxRanks,
                            entryID = entryID, entries = node.entryIDs, edges = node.visibleEdges,
                            activeEntry = node.activeEntry, nextEntry = node.nextEntry,
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
    return groups, nodes, points, configID, currencies
end

local function editingAllowed(configID)
    if InCombatLockdown() then return false, "Talents cannot be changed in combat." end
    if not configID or not C_Traits.CanEditConfig then return false, "Open the full talent tree to edit talents." end
    return C_Traits.CanEditConfig(configID)
end

local function canPurchase(configID, node, currencies)
    -- Selection nodes must be chosen in the full tree; never buy an arbitrary first choice.
    if not node or #node.entries ~= 1 or not C_Traits.CanPurchaseRank or not C_Traits.GetNodeCost
        or not C_Traits.CanPurchaseRank(configID, node.id, node.entryID) then return false end
    -- CanPurchaseRank checks requirements separately from affordability, as in the native UI.
    for _, cost in ipairs(C_Traits.GetNodeCost(configID, node.id) or {}) do
        if (currencies[cost.ID] or 0) < cost.amount then return false end
    end
    return true
end

local function reportError(message)
    if UIErrorsFrame then UIErrorsFrame:AddExternalErrorMessage(message or "Unable to change talents.") end
end

local function layoutAxis(nodes, axis)
    local values, seen = {}, {}
    for _, node in ipairs(nodes) do
        local value = node[axis]
        if not seen[value] then values[#values + 1] = value; seen[value] = true end
    end
    table.sort(values)
    local function typicalSpacing(list)
        local deltas = {}
        for index = 2, #list do deltas[#deltas + 1] = list[index] - list[index - 1] end
        table.sort(deltas)
        return deltas[math.ceil(#deltas / 2)]
    end
    local spacing, corrected = typicalSpacing(values), {}
    for index, value in ipairs(values) do
        local nearest = math.min(index > 1 and value - values[index - 1] or math.huge,
            index < #values and values[index + 1] - value or math.huge)
        -- Forever's Hunter data contains isolated tenfold coordinates (39300 vs 3930,
        -- 102800 vs 10280). Repair only an isolated value with an exact existing peer.
        corrected[value] = spacing and nearest > spacing * 4 and seen[value / 10] and value / 10 or value
    end
    local normalized, normalizedSet = {}, {}
    for _, value in ipairs(values) do
        value = corrected[value]
        if not normalizedSet[value] then normalized[#normalized + 1] = value; normalizedSet[value] = true end
    end
    table.sort(normalized)
    spacing = typicalSpacing(normalized)
    local clusters, snapped = {}, {}
    for _, value in ipairs(normalized) do
        local previous = clusters[#clusters]
        -- Minor offsets within a native row/column must not become an entire grid step.
        if previous and spacing and value - previous <= spacing * 0.1 then snapped[value] = previous
        else clusters[#clusters + 1] = value; snapped[value] = value end
    end
    local positions, minimumGap = {}, nil
    for index = 2, #clusters do
        local delta = clusters[index] - clusters[index - 1]
        minimumGap = minimumGap and math.min(minimumGap, delta) or delta
    end
    for _, node in ipairs(nodes) do positions[node.id] = snapped[corrected[node[axis]]] end
    return positions, clusters[1] or 0, clusters[#clusters] or 0, minimumGap
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

    local apply = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    apply:SetSize((width - 44) / 2, 22)
    apply:SetPoint("BOTTOMLEFT", 18, 40)
    apply:SetText("Apply")
    local undo = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    undo:SetSize((width - 44) / 2, 22)
    undo:SetPoint("BOTTOMRIGHT", -18, 40)
    undo:SetText("Undo all")
    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", 0, 68)
    hint:SetWidth(width - 36)

    local tree = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    tree:SetSize(width - 36, 22)
    tree:SetPoint("TOP", 0, -55)
    local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 18, -86)
    scroll:SetPoint("BOTTOMRIGHT", -28, 88)
    scroll.ScrollBar:SetHideIfUnscrollable(true)
    local grid = CreateFrame("Frame", nil, scroll)
    grid:SetSize(width - 46, 1)
    scroll:SetScrollChild(grid)
    local empty = grid:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    empty:SetPoint("TOP", 0, -12)
    empty:SetText("Talent data unavailable")

    local tiles, lines, groups, nodes, selected = {}, {}, {}, {}, {}, nil
    local configID, committing
    local currencies = {}
    local contentWidth = width - 46

    local function showTooltip(tile)
        GameTooltip:SetOwner(tile, "ANCHOR_RIGHT")
        local node = tile.node
        GameTooltip:SetText(node.name)
        if GameTooltip.AppendInfo then
            local entry = node.activeEntry or node.nextEntry or {entryID = node.entryID, rank = 1}
            GameTooltip:AppendInfo("GetTraitEntry", entry.entryID, math.max(1, entry.rank))
            if node.activeEntry and node.nextEntry then
                GameTooltip:AddLine("Next rank", 1, 0.82, 0)
                GameTooltip:AppendInfo("GetTraitEntry", node.nextEntry.entryID, node.nextEntry.rank)
            end
        elseif node.spell and node.spell > 0 then
            GameTooltip:SetSpellByID(node.spell)
        end
        GameTooltip:AddLine(string.format("Rank %d / %d", node.rank, node.maxRank), 1, 0.82, 0)
        local allowed, reason = editingAllowed(configID)
        if not allowed then
            GameTooltip:AddLine(reason or "Talents cannot be changed right now.", 1, 0.3, 0.3, true)
        elseif #node.entries > 1 then
            GameTooltip:AddLine("Choose this talent in the full talent tree.", 1, 0.82, 0, true)
        elseif canPurchase(configID, node, currencies) then
            GameTooltip:AddLine("Click to add a point, then Apply to learn.", 0.2, 1, 0.2, true)
        elseif node.rank < node.maxRank then
            GameTooltip:AddLine("Requires available points and the talent's prerequisites.", 1, 0.3, 0.3, true)
        end
        GameTooltip:Show()
    end

    local function newTile()
        local tile = CreateFrame("Button", nil, grid)
        tile:RegisterForClicks("LeftButtonUp")
        tile.background = tile:CreateTexture(nil, "BACKGROUND")
        tile.background:SetAllPoints()
        tile.icon = tile:CreateTexture(nil, "ARTWORK")
        tile.icon:SetPoint("TOPLEFT", 3, -3)
        tile.icon:SetPoint("BOTTOMRIGHT", -3, 3)
        tile.rank = tile:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        tile.rank:SetPoint("BOTTOMRIGHT", -2, 2)
        tile:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        tile:SetScript("OnEnter", showTooltip)
        tile:SetScript("OnClick", function(self)
            -- Re-read eligibility and the active config at click time, including after spec changes.
            local clickedConfig, clickedNode = configID, self.node.id
            panel:Refresh()
            local allowed, reason = editingAllowed(configID)
            if committing then return end
            if not allowed then reportError(reason); return end
            if configID ~= clickedConfig or self.node.id ~= clickedNode or not self:IsShown()
                or not canPurchase(configID, self.node, currencies) then return end
            if not C_Traits.PurchaseRank(configID, self.node.id) then reportError() end
            panel:Refresh()
            if self:IsShown() then showTooltip(self) end
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
        local visible, byID = {}, {}
        for _, node in ipairs(nodes) do
            if not groupID or not node.groups or #node.groups == 0 or tContains(node.groups, groupID) then
                visible[#visible + 1] = node
            end
        end
        local positionsX, minX, maxX, gapX = layoutAxis(visible, "x")
        local positionsY, minY, maxY, gapY = layoutAxis(visible, "y")
        local columns = math.max(4, gapX and (maxX - minX) / gapX + 1 or 1)
        local size = math.min(36, math.floor(contentWidth / columns) - 8)
        local stepX = (contentWidth - size - 8) / (columns - 1)
        local rowSpan = gapY and (maxY - minY) / gapY or 0
        local stepY, viewHeight = size + 14, scroll:GetHeight()
        if rowSpan > 0 and viewHeight > 0 then
            stepY = math.max(size + 6, math.min(stepY, (viewHeight - size - 8) / rowSpan))
        end
        local scaleX, scaleY = gapX and stepX / gapX or 0, stepY / (gapY or gapX or 1)
        local offsetX = (contentWidth - size - (maxX - minX) * scaleX) / 2
        local height = 30
        local allowed = not committing and editingAllowed(configID)
        for index, node in ipairs(visible) do
            local tile = tiles[index] or newTile()
            tiles[index], byID[node.id] = tile, tile
            tile.node = node
            tile.x, tile.y = offsetX + (positionsX[node.id] - minX) * scaleX, -4 - (positionsY[node.id] - minY) * scaleY
            tile:SetSize(size, size)
            tile:ClearAllPoints()
            tile:SetPoint("TOPLEFT", grid, "TOPLEFT", tile.x, tile.y)
            addon.SetCharacterSlotArt(tile.background, settings.theme)
            tile.icon:SetTexture(node.icon)
            local purchasable = allowed and canPurchase(configID, node, currencies)
            tile.icon:SetDesaturated(node.rank == 0 and not purchasable)
            tile.icon:SetAlpha((node.rank > 0 or purchasable) and 1 or 0.5)
            tile.rank:SetText(string.format("%d/%d", node.rank, node.maxRank))
            if node.rank == node.maxRank then tile.rank:SetTextColor(1, 0.82, 0)
            elseif purchasable then tile.rank:SetTextColor(0.2, 1, 0.2)
            else tile.rank:SetTextColor(0.65, 0.65, 0.65) end
            tile:Show()
            height = math.max(height, -tile.y + size + 4)
        end
        local usedLines = 0
        for _, node in ipairs(visible) do
            local from = byID[node.id]
            for _, edge in ipairs(node.edges or {}) do
                local target = byID[edge.targetNode]
                if target then
                    usedLines = usedLines + 1
                    local line = lines[usedLines] or grid:CreateLine(nil, "BACKGROUND")
                    lines[usedLines] = line
                    line:SetThickness(2)
                    line:SetStartPoint("TOPLEFT", from.x + size / 2, from.y - size / 2)
                    line:SetEndPoint("TOPLEFT", target.x + size / 2, target.y - size / 2)
                    if edge.isActive then line:SetColorTexture(0.75, 0.62, 0.25, 0.9)
                    else line:SetColorTexture(0.35, 0.35, 0.35, 0.7) end
                    line:Show()
                end
            end
        end
        for index = usedLines + 1, #lines do lines[index]:Hide() end
        for index = #visible + 1, #tiles do tiles[index]:Hide() end
        grid:SetHeight(height)
        scroll:UpdateScrollChildRect()
        scroll:SetVerticalScroll(math.max(0, math.min(scroll:GetVerticalScroll(), math.max(0, height - viewHeight))))
        empty:SetShown(#visible == 0)
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
        local newGroups, newNodes, points, newConfigID, newCurrencies = readTalents()
        groups, nodes = newGroups or {}, newNodes or {}
        currencies = newCurrencies or {}
        if configID ~= newConfigID then committing = nil end
        configID = newConfigID
        local oldID = selected and selected.groupID
        selected = groups[1]
        for _, group in ipairs(groups) do
            if group.groupID == oldID then selected = group; break end
        end
        if oldID ~= (selected and selected.groupID) then scroll:SetVerticalScroll(0) end
        pointsLabel:SetText(points and string.format("Points available: %d", points) or "")
        edit:SetEnabled(TalentMicroButton ~= nil and TalentMicroButton:IsEnabled())
        local staged = configID and C_Traits.ConfigHasStagedChanges and C_Traits.ConfigHasStagedChanges(configID)
        if not staged then committing = nil end
        local allowed, reason = editingAllowed(configID)
        local canApply = staged and allowed and not committing
        if canApply and C_ClassTalents and C_ClassTalents.CanChangeTalents then
            local canChange, canAdd, changeError = C_ClassTalents.CanChangeTalents()
            canApply, reason = canChange or canAdd, changeError
        end
        apply:SetEnabled(not not canApply)
        undo:SetEnabled(not not (staged and allowed and not committing))
        apply:SetText(committing and "Applying..." or "Apply")
        hint:SetText(InCombatLockdown() and "Read only in combat" or committing and "Applying talents..."
            or staged and "Pending changes" or points and points <= 0 and "No talent points available" or "Click to add points")
        apply.reason = reason
        showTree()
    end

    apply:SetScript("OnClick", function()
        local clickedConfig = configID
        panel:Refresh()
        if configID ~= clickedConfig then return end
        if not apply:IsEnabled() then reportError(apply.reason); return end
        local committingID = configID
        committing = committingID
        local success
        if C_ClassTalents and C_ClassTalents.CommitConfig then success = C_ClassTalents.CommitConfig()
        else success = C_Traits.CommitConfig(committingID) end
        if not success then committing = nil; reportError("Unable to apply talents. Your pending changes are still available.") end
        panel:Refresh()
        if success and committing then
            C_Timer.After(10, function()
                if committing == committingID then committing = nil; panel:Refresh() end
            end)
        end
    end)
    undo:SetScript("OnClick", function()
        local clickedConfig = configID
        panel:Refresh()
        if configID ~= clickedConfig then return end
        if not undo:IsEnabled() then return end
        if not C_Traits.RollbackConfig(configID) then reportError() end
        panel:Refresh()
    end)
    undo:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Discard all pending talent changes")
        GameTooltip:AddLine("Includes changes staged in the full talent tree. Learned talents are kept.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    undo:SetScript("OnLeave", function() GameTooltip:Hide() end)
    apply:SetMotionScriptsWhileDisabled(true)
    apply:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Learn pending talents")
        GameTooltip:AddLine(self.reason or "Applies all pending changes, including those staged in the full talent tree.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    apply:SetScript("OnLeave", function() GameTooltip:Hide() end)
    panel:SetScript("OnShow", function() panel:Refresh() end)
    for _, event in ipairs({"TRAIT_NODE_CHANGED", "TRAIT_NODE_CHANGED_PARTIAL", "TRAIT_NODE_ENTRY_UPDATED",
        "TRAIT_TREE_CURRENCY_INFO_UPDATED", "TRAIT_CONFIG_UPDATED", "CONFIG_COMMIT_FAILED",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}) do panel:RegisterEvent(event) end
    panel:SetScript("OnEvent", function(self, event, updatedID)
        if (event == "CONFIG_COMMIT_FAILED" or event == "TRAIT_CONFIG_UPDATED") and updatedID == committing then committing = nil end
        if not self:IsVisible() then return end
        -- Trait changes arrive in bursts; rebuild once on the next frame.
        self:SetScript("OnUpdate", function()
            self:SetScript("OnUpdate", nil)
            self:Refresh()
        end)
    end)
    panel:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    function panel:UpdateTheme()
        addon.SetWindowTheme(self, settings.theme, true)
        for _, tile in ipairs(tiles) do addon.SetCharacterSlotArt(tile.background, settings.theme) end
    end
    return panel
end
