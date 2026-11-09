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
        -- Both ends fall in the low mortar course, between raised stones.
        rail = { 512, 64, 141, 15, 378, 56 },
        railStart = -8,
        railY = 119,
        divider = { 256, 512, 21, 230, 256, 512 },
        chatTop = { 512, 128, 0, 73, 372, 128 },
        -- One complete stone span bridges two mortar gaps. Do not repeat a
        -- tiny low-course fragment or leave the corner's last stone behind it.
        chatBody = { 512, 128, 8, 73, 140, 128 },
        chatBodyFile = "bottom right\\BottomRight_Top",
        chatCornerClip = 314,
        chatBlend = 8,
        chatPostRight = 69, chatCornerRight = 314, chatBeamBottom = 84,
        chatBottom = { 512, 64, 0, 52, 341, 64 },
        chatSide = { 32, 512, 0, 0, 32, 310 },
    },
    orc = {
        label = "Orc",
        mapButtons = { x = 166, 134, 112, 89, 67, 37 },
        -- Start beyond the first clamp; the original clamp inside the span
        -- supplies the joint without reflecting the bolts or metal grain.
        rail = { 512, 64, 137, 17, 510, 64 },
        railStart = -38,
        railY = 115,
        divider = { 256, 512, 0, 208, 256, 512 },
        chatTop = { 512, 128, 0, 46, 371, 128 },
        chatBody = { 256, 128, 18, 45, 150, 128 },
        chatPostRight = 78, chatCornerRight = 353, chatBeamBottom = 84,
        chatBottom = { 512, 64, 0, 51, 371, 64 },
        chatSide = { 32, 512, 0, 0, 32, 310 },
    },
    undead = {
        label = "Undead",
        mapButtons = { x = 166, 134, 112, 89, 67, 39 },
        rail = { 512, 64, 89, 1, 275, 52 },
        railStart = -8,
        divider = { 256, 512, 0, 215, 256, 512 },
        chatTop = { 512, 128, 45, 50, 373, 128 },
        -- Bridge with the plain bone after the large fracture. The corner
        -- and right end already contain that fracture; repeating it crowds
        -- the join and exposes the cut between sheets.
        chatBody = { 512, 128, 166, 50, 295, 128 },
        chatBodyFile = "bottom right\\BottomRight_Top",
        chatCornerClip = 361,
        chatBlend = 8,
        chatPostRight = 75, chatCornerRight = 361, chatBeamBottom = 84,
        chatBottom = { 512, 64, 0, 50, 341, 64 },
        chatSide = { 32, 512, 0, 0, 32, 310 },
    },
    nightelf = {
        label = "Night Elf",
        mapButtons = { x = 166, 136, 114, 91, 69, 39 },
        rail = { 512, 128, 45, 50, 467, 128 },
        railStart = -25,
        railY = 111,
        divider = { 256, 512, 0, 168, 256, 512 },
        -- End the corner between leaf clusters; use one uninterrupted beam
        -- before the original right-hand ornament instead of stacking foliage.
        chatTop = { 512, 128, 280, 54, 422, 127 },
        chatBody = { 512, 128, 90, 54, 356, 127 },
        chatBodyFile = "bottom right\\BottomRight_Top",
        chatCornerClip = 395,
        chatBlend = 8,
        chatPostRight = 71, chatCornerRight = 395, chatBeamBottom = 94,
        chatBottom = { 512, 64, 0, 52, 341, 64 },
        chatSide = { 64, 512, 27, 22, 64, 332 },
    },
}
addon.themes = themes

function addon.CreateArt()
    local console = CreateFrame("Frame", nil, UIParent)
    console:SetFrameStrata("BACKGROUND")
    console:SetPoint("BOTTOM")
    console:SetSize(addon.width, 256)
    console:SetRoundLayoutToNearestPixel(true)
    console:Hide()

    local pieces = {}
    local strips = {}
    local function rect(texture, parent, x, y, width, height)
        texture:ClearAllPoints()
        texture:SetSize(width, height)
        texture:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", x, y)
        -- Round shared edges, not a separately rounded origin plus width.
        texture:SetPoint("TOPRIGHT", parent, "BOTTOMLEFT", x + width, y + height)
    end
    local function piece(file, x, y, width, height, crop, layer, parent)
        parent = parent or console
        local texture = parent:CreateTexture(nil, layer or "ARTWORK")
        texture:SetRoundLayoutToNearestPixel(true)
        rect(texture, parent, x, y, width, height)
        if file then
            pieces[#pieces + 1] = { texture = texture, file = file, crop = crop }
        end
        return texture
    end

    local function strip(file, x, y, width, cropKey, layer)
        local entry = { file = file, x = x, y = y, width = width, cropKey = cropKey, textures = {} }
        for index = 1, 8 do
            entry.textures[index] = console:CreateTexture(nil, layer or "ARTWORK")
            entry.textures[index]:SetRoundLayoutToNearestPixel(true)
        end
        strips[#strips + 1] = entry
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
    -- The source beam overlaps the portrait's right-hand cap. Keep it behind
    -- that cap so the join does not create a second rivet or cover the arch.
    strip("actionbar\\ext1", grid.x, 117, grid.width, "rail", "ARTWORK")
    for _, texture in ipairs(strips[#strips].textures) do texture:SetDrawLayer("ARTWORK", -1) end

    -- Each theme owns its chat textures. Once built, their source sheets,
    -- UVs, gradients and geometry are immutable; a theme switch only changes
    -- visibility. Human/Undead repairs cannot retarget Night Elf's regions.
    local chatArt = {}
    local function createChatArt(themeName)
        local theme, textures = themes[themeName], {}
        local function texture(file, x, y, width, height, crop, sub)
            local region = console:CreateTexture(nil, "ARTWORK", nil, sub or 0)
            region:SetRoundLayoutToNearestPixel(true)
            region:SetTexture(addon.artPath .. themeName .. "\\bottom right\\" .. file .. ".tga")
            rect(region, console, x, y, width, height)
            if crop then
                local atlasWidth, atlasHeight, left, top, right, bottom = unpack(crop)
                region:SetTexCoord(left / atlasWidth, right / atlasWidth, top / atlasHeight, bottom / atlasHeight)
            end
            textures[#textures + 1] = region
            return region
        end
        local function repeatBody(file, x, y, width, crop)
            local atlasWidth, atlasHeight, left, top, right, bottom = unpack(crop)
            local tileWidth, height = (right - left) / 2, (bottom - top) / 2
            local offset = 0
            while offset < width do
                local partWidth = math.min(tileWidth, width - offset)
                texture(file, x + offset, y, partWidth, height,
                    { atlasWidth, atlasHeight, left, top, left + partWidth * 2, bottom })
                offset = offset + partWidth
            end
        end
        local cornerX = chat.x + 15 - theme.chatPostRight / 2
        local cornerY = 142 + theme.chatBeamBottom / 2 - 256
        local width, height, left, top, right, bottom = unpack(theme.chatTop)
        local topWidth, topHeight = (right - left) / 2, (bottom - top) / 2
        local topX, topY = addon.width - topWidth, theme.chatTopY or 142
        local blend = theme.chatBlend or 0
        local bodyX = cornerX + theme.chatCornerRight / 2 - 8
        local bodyWidth = math.max(0, topX + 8 - bodyX)
        local bodyFile = theme.chatBodyFile and "BottomRight_Top" or "BottomRightFillerTop"
        repeatBody(bodyFile, bodyX, 142, bodyWidth, theme.chatBody)
        texture("BottomRight_Top", topX + blend, topY, topWidth - blend, topHeight,
            { width, height, left + blend * 2, top, right, bottom })
        repeatBody("BottomRight_Bottom", chat.x, 0, chat.width, theme.chatBottom)
        local cornerRight = theme.chatCornerClip or 512
        local cornerCore = cornerRight - blend * 2
        -- Keep each corner's post at native size; trim only its beam overlap.
        texture("right_part_lid", cornerX, cornerY, cornerCore / 2, 256,
            cornerCore < 512 and { 512, 512, 0, 0, cornerCore, 512 } or nil)
        if blend > 0 then
            local cornerBlend = texture("right_part_lid", cornerX + cornerCore / 2, cornerY, blend, 256,
                { 512, 512, cornerCore, 0, cornerRight, 512 }, 1)
            cornerBlend:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 1), CreateColor(1, 1, 1, 0))
            local topBlend = texture("BottomRight_Top", topX, topY, blend, topHeight,
                { width, height, left, top, left + blend * 2, bottom }, 1)
            topBlend:SetGradient("HORIZONTAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 1))
        end
        local sideWidth = (theme.chatSide[5] - theme.chatSide[3]) / 2
        texture("BottomRight_Middle", addon.width - sideWidth, 0, sideWidth, 155, theme.chatSide)
        chatArt[themeName] = textures
    end
    -- Two native 40-unit wells, with the shared right-hand post supplied by
    -- the chat corner. Do not squeeze another copy of that post into 88 units.
    local inventory = piece("inventory\\inventory", addon.quickSlots.x, 0, 80, 256,
        { 512, 512, 0, 0, 160, 512 }, "OVERLAY")
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
        -- All source pixels have the same half-size density. Rail crops end
        -- on matching cross-sections of mortar, metal, bone or foliage, so
        -- repeats keep their original direction without overlapping motifs.
        for _, entry in ipairs(strips) do
            local width, height, left, top, right, bottom = unpack(theme[entry.cropKey])
            local tileWidth, tileHeight = (right - left) / 2, (bottom - top) / 2
            local inset = entry.cropKey == "rail" and (theme.railStart or 0) or 0
            local stripWidth = entry.width - inset + (entry.cropKey == "rail" and 8 or 0)
            local startX = entry.x + inset
            local offset = 0
            for index, texture in ipairs(entry.textures) do
                local remaining = stripWidth - offset
                texture:SetShown(remaining > 0)
                if remaining > 0 then
                    local partWidth = math.min(tileWidth, remaining)
                    local last = remaining <= tileWidth
                    local sourceLeft = left
                    texture:SetTexture(addon.artPath .. themeName .. "\\" .. entry.file .. ".tga")
                    local y = theme.railY or entry.y
                    rect(texture, self, startX + offset, y, partWidth, tileHeight)
                    texture:SetTexCoord(sourceLeft / width, (sourceLeft + partWidth * 2) / width, top / height, bottom / height)
                    offset = last and stripWidth or (offset + tileWidth)
                end
            end
        end
        if not chatArt[themeName] then createChatArt(themeName) end
        for name, textures in pairs(chatArt) do
            for _, texture in ipairs(textures) do
                texture:SetShown(name == themeName)
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
