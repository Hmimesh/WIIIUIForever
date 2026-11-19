local _, addon = ...

local boxes = {
    { key = "map", label = "Minimap", x = 0, width = 201, height = 224 },
    { key = "character", label = "Character panel", x = 201, width = 311, height = 150 },
    { key = "actions", label = "Action bars", x = addon.grid.x, width = addon.grid.width, height = 280 },
    { key = "quick", label = "Quick slots", x = addon.quickSlots.x, width = addon.quickSlots.width, height = 148 },
    { key = "chat", label = "Chat", x = addon.chat.x, width = addon.chat.width, height = 230 },
}
local byKey = {}
for _, box in ipairs(boxes) do byKey[box.key] = box end
addon.dockBoxes = boxes
local seamGap = 6

local function sharesBorder(left, right)
    return left and right and left.x + left.width == right.x
end

local function getDockOrder(character)
    local order, seen = {}, {}
    local saved = character.dockOrder
    if type(saved) == "table" then
        for index = 1, #boxes do
            local key = saved[index]
            if type(key) == "string" and byKey[key] and not seen[key] then
                order[#order + 1], seen[key] = key, true
            end
        end
    end
    for _, box in ipairs(boxes) do
        if not seen[box.key] then order[#order + 1] = box.key end
    end
    return order
end

local function getHiddenDockBoxes(character)
    return type(character.hiddenDockBoxes) == "table" and character.hiddenDockBoxes or {}
end

function addon.GetDockLayout(character)
    local order, hidden = getDockOrder(character), getHiddenDockBoxes(character)
    local layout, visible = {}, {}
    local width, height = 0, 0
    local previous
    for _, key in ipairs(order) do
        if hidden[key] ~= true then
            local box = byKey[key]
            if previous and not sharesBorder(previous, box) then width = width + seamGap end
            layout[key] = { dx = width - box.x }
            width = width + box.width
            height = math.max(height, box.height)
            visible[#visible + 1] = key
            previous = box
        end
    end
    local left = (addon.width - width) / 2
    for index, key in ipairs(visible) do
        local position = layout[key]
        position.dx = position.dx + left
        local previous, nextBox = byKey[visible[index - 1]], byKey[visible[index + 1]]
        local box = byKey[key]
        position.joinLeft = sharesBorder(previous, box)
        position.joinRight = sharesBorder(box, nextBox)
    end
    return layout, height, width
end

function addon.CreateDockOptions(panel, anchor, character, apply)
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -26)
    title:SetText("Console layout")
    local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    help:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    help:SetText("Move whole boxes left or right. Uncheck a box to remove it from the console.")

    local rows = {}
    local function refresh()
        local order, hidden = getDockOrder(character), getHiddenDockBoxes(character)
        for index, row in ipairs(rows) do
            local key = order[index]
            row.key = key
            row.visible.Text:SetText(byKey[key].label)
            row.visible:SetChecked(hidden[key] ~= true)
            row.left:SetEnabled(index > 1)
            row.right:SetEnabled(index < #rows)
        end
    end
    local function changed()
        refresh()
        apply()
    end
    for index = 1, #boxes do
        local row = {}
        local position = index
        rows[index] = row
        row.visible = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        row.visible:SetPoint("TOPLEFT", help, "BOTTOMLEFT", -4, -8 - (index - 1) * 30)
        row.visible:SetScript("OnClick", function(self)
            local hidden = getHiddenDockBoxes(character)
            hidden[row.key] = not self:GetChecked()
            character.hiddenDockBoxes = hidden
            changed()
        end)
        local function move(label, direction, x)
            local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
            button:SetSize(84, 24)
            button:SetPoint("LEFT", row.visible, "LEFT", x, 0)
            button:SetText(label)
            button:SetScript("OnClick", function()
                local order = getDockOrder(character)
                local target = position + direction
                order[position], order[target] = order[target], order[position]
                character.dockOrder = order
                changed()
            end)
            return button
        end
        row.left = move("Move left", -1, 200)
        row.right = move("Move right", 1, 290)
    end

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", rows[#rows].visible, "BOTTOMLEFT", 4, -12)
    reset:SetText("Reset console layout")
    reset:SetScript("OnClick", function()
        character.dockOrder, character.hiddenDockBoxes = nil, nil
        changed()
    end)
    panel:HookScript("OnShow", refresh)
    refresh()
end
