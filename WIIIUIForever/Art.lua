local addonName, addon = ...
addon.artPath = "Interface\\AddOns\\" .. addonName .. "\\art\\"

addon.width = 1440
addon.grid = { x = 512, width = 480, rowHeight = 40 }
addon.chat = { x = 1080, width = 360, height = 153 }
addon.quickSlots = { x = 992, width = 88, height = 148 }
addon.portrait = { x = 216, y = 28, width = 72, height = 77 }

-- Pixel crops in the original WIIIUI TGA sheets. The four themes share
-- the layout, but their stone, wood, bone and foliage have different margins.
local themes = {
    human = {
        label = "Human",
        mapButtons = { x = 166, 133, 111, 89, 66, 39 },
        rail = { 512, 64, 61, 15, 512, 56 },
        divider = { 256, 512, 21, 230, 256, 512 },
        chatTop = { 256, 128, 0, 73, 162, 128 },
        chatBottom = { 256, 32, 0, 18, 157, 32 },
        chatSide = { 32, 512, 0, 0, 32, 512 },
    },
    orc = {
        label = "Orc",
        mapButtons = { x = 166, 134, 112, 89, 67, 37 },
        rail = { 512, 64, 0, 17, 512, 64 },
        divider = { 256, 512, 0, 208, 256, 512 },
        chatTop = { 256, 128, 0, 45, 163, 128 },
        chatBottom = { 256, 32, 0, 18, 157, 32 },
        chatSide = { 32, 512, 0, 0, 32, 512 },
    },
    undead = {
        label = "Undead",
        mapButtons = { x = 166, 134, 112, 89, 67, 39 },
        rail = { 512, 64, 0, 1, 295, 64 },
        divider = { 256, 512, 0, 215, 256, 512 },
        chatTop = { 256, 128, 0, 84, 162, 128 },
        chatBottom = { 256, 32, 0, 18, 141, 32 },
        chatSide = { 32, 512, 0, 0, 32, 512 },
    },
    nightelf = {
        label = "Night Elf",
        mapButtons = { x = 166, 136, 114, 91, 69, 39 },
        rail = { 512, 128, 0, 50, 512, 128 },
        divider = { 256, 512, 0, 168, 256, 512 },
        chatTop = { 256, 128, 0, 63, 215, 127 },
        chatBottom = { 256, 32, 0, 20, 144, 32 },
        chatSide = { 64, 512, 27, 22, 64, 512 },
    },
}
addon.themes = themes

function addon.CreateArt()
    local console = CreateFrame("Frame", nil, UIParent)
    console:SetFrameStrata("BACKGROUND")
    console:SetPoint("BOTTOM")
    console:SetSize(addon.width, 256)
    console:Hide()

    local pieces = {}
    local function piece(file, x, y, width, height, crop, layer, parent)
        parent = parent or console
        local texture = parent:CreateTexture(nil, layer or "ARTWORK")
        texture:SetSize(width, height)
        texture:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
        if file then
            pieces[#pieces + 1] = { texture = texture, file = file, crop = crop }
        end
        return texture
    end

    local grid, chat = addon.grid, addon.chat
    -- Overlap the three interior backings so transparent seams between the
    -- original sheets never show the world through the console.
    piece(nil, 7, 0, 196, 150, nil, "BACKGROUND"):SetColorTexture(0.014, 0.012, 0.01, 1)
    piece(nil, 197, 0, 894, 125, nil, "BACKGROUND"):SetColorTexture(0.014, 0.012, 0.01, 1)
    piece(nil, chat.x - 4, 0, chat.width + 4, chat.height + 3, nil, "BACKGROUND")
        :SetColorTexture(0.014, 0.012, 0.01, 1)
    piece("minimap_portrait\\minimap", 0, 0, 256, 256)
    local mapTrim = CreateFrame("Frame", nil, console)
    mapTrim:SetFrameStrata("LOW")
    mapTrim:SetSize(150, 256)
    mapTrim:SetPoint("BOTTOMLEFT")
    local rim = mapTrim:CreateTexture(nil, "OVERLAY")
    rim:SetAllPoints()
    pieces[#pieces + 1] = {
        texture = rim, file = "minimap_portrait\\minimap",
        crop = { 512, 512, 0, 0, 300, 512 },
    }
    console.mapTrim = mapTrim
    piece("minimap_portrait\\portrait", 256, 0, 256, 256)

    local bounds = addon.portrait
    local viewport = CreateFrame("Frame", nil, console)
    viewport:SetSize(bounds.width, bounds.height)
    viewport:SetPoint("BOTTOMLEFT", console, "BOTTOMLEFT", bounds.x, bounds.y)
    viewport:SetFrameLevel(console:GetFrameLevel() + 1)
    viewport:SetClipsChildren(true)
    console.portraitViewport = viewport

    -- The portrait opening crosses both source sheets. Draw just this part
    -- of their transparent trim above the model, including the inward spikes.
    local trim = CreateFrame("Frame", nil, console)
    trim:SetAllPoints(viewport)
    trim:SetFrameLevel(viewport:GetFrameLevel() + 2)
    local split = 256 - bounds.x
    local top, bottom = 512 - (bounds.y + bounds.height) * 2, 512 - bounds.y * 2
    piece("minimap_portrait\\minimap", 0, 0, split, bounds.height,
        { 512, 512, bounds.x * 2, top, 512, bottom }, "OVERLAY", trim)
    piece("minimap_portrait\\portrait", split, 0, bounds.width - split, bounds.height,
        { 512, 512, 0, top, (bounds.width - split) * 2, bottom }, "OVERLAY", trim)
    console.portraitTrim = trim

    local optionalRows = { {}, {} }
    for row = 0, 2 do
        local top = 427 - row * 85
        for index = 0, 2 do
            local tile = piece("actionbar\\actionslots_grid", grid.x + index * 160, row * grid.rowHeight,
                160, grid.rowHeight, { 512, 512, 0, top, 341, top + 85 })
            if row > 0 then
                optionalRows[row][index + 1] = tile
            end
        end
    end
    function console:SetOptionalRows(second, third)
        for index, shown in ipairs({ second, third }) do
            for _, tile in ipairs(optionalRows[index]) do
                tile:SetShown(shown)
            end
        end
    end
    for index = 0, 1 do
        piece("actionbar\\ext1", grid.x + index * 234, 117, 246, 25, "rail", "OVERLAY")
    end

    for index = 0, 2 do
        local x = chat.x + index * 117
        piece("bottom right\\BottomRightFillerTop", x, 146, 126, 21, "chatTop")
        piece("bottom right\\BottomRightFillerBottom", x, 0, 126, 7, "chatBottom")
    end
    piece("bottom right\\BottomRight_Middle", addon.width - 12, 0, 12, 155, "chatSide")
    local inventory = piece("inventory\\inventory", addon.quickSlots.x, 0, addon.quickSlots.width, addon.quickSlots.height,
        { 512, 512, 0, 200, 224, 512 }, "OVERLAY")
    local divider = piece("inventory\\no_inventory", 983, 0, 107, 148, "divider", "OVERLAY")
    divider:Hide()

    function console:SetQuickSlotsShown(shown)
        inventory:SetShown(shown)
        divider:SetShown(not shown)
    end

    function console:SetTheme(themeName)
        self.theme = themeName
        local theme = themes[themeName]
        for _, entry in ipairs(pieces) do
            local crop = entry.crop
            if type(crop) == "string" then
                crop = theme[crop]
            end
            entry.texture:SetTexture(addon.artPath .. themeName .. "\\" .. entry.file .. ".tga")
            if crop then
                local width, height, left, top, right, bottom = unpack(crop)
                entry.texture:SetTexCoord(left / width, right / width, top / height, bottom / height)
            end
        end
        if self.statusIndicators then addon.UpdatePlayerStatus(self) end
        if self.sessionRibbon then self.sessionRibbon:Refresh() end
    end

    return console
end

-- Warcraft III's UpperButtonBar.fdf uses the upper 170 x 44 pixels of
-- its 256 x 256 button sheet. Exclude the transparent atlas padding and keep
-- the caps intact while stretching its middle.
function addon.CreateConsoleChrome(parent)
    local chrome = { textures = {} }
    for index = 1, 3 do
        chrome.textures[index] = parent:CreateTexture(nil, "BACKGROUND")
    end
    chrome.textures[1]:SetTexCoord(4 / 256, 16 / 256, 4 / 256, 36 / 256)
    chrome.textures[2]:SetTexCoord(16 / 256, 154 / 256, 4 / 256, 36 / 256)
    chrome.textures[3]:SetTexCoord(154 / 256, 166 / 256, 4 / 256, 36 / 256)
    function chrome:SetSize(width, height)
        local cap = math.min(width / 3, height * 12 / 32)
        local widths, offsets = { cap, width - cap * 2, cap }, { 0, cap, width - cap }
        for index, texture in ipairs(self.textures) do
            texture:ClearAllPoints()
            texture:SetPoint("TOPLEFT", parent, "TOPLEFT", offsets[index], 0)
            texture:SetSize(widths[index], height)
        end
    end
    function chrome:SetTheme(theme)
        if self.theme == theme then return end
        self.theme = theme
        for _, texture in ipairs(self.textures) do
            texture:SetTexture(addon.artPath .. theme .. "\\chrome\\upper.tga")
        end
    end
    function chrome:SetShown(shown)
        for _, texture in ipairs(self.textures) do texture:SetShown(shown) end
    end
    return chrome
end
