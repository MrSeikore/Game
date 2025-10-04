InventorySystem = {
    visible = true,
    selectedItem = nil,
    scrollOffset = 0,
    itemTypeFilter = nil,
    mouseX = 0,
    mouseY = 0,
    hoveredElement = nil
}

function InventorySystem:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventorySystem:draw(player)
    local inv = Display.INVENTORY
    
    -- Inventory background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", inv.EQUIPMENT.x - inv.PADDING, 0, inv.WIDTH, Display.baseHeight)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", inv.EQUIPMENT.x - inv.PADDING, 0, inv.WIDTH, Display.baseHeight)
    
    -- Layout sections
    self:drawEquipmentSection(player)
    self:drawInventorySection(player)
    self:drawBulkDeleteSection()
    self:drawDropChancesSection()
end

function InventorySystem:drawEquipmentSection(player)
    local eq = Display.INVENTORY.EQUIPMENT
    local slotSize = eq.SLOT_SIZE
    local margin = eq.SLOT_MARGIN
    
    -- Section title
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("EQUIPMENT", eq.x, eq.y)
    
    -- Equipment slots grid
    local slots = {
        {type = "weapon", name = "Weapon", row = 0, col = 0},
        {type = "helmet", name = "Helmet", row = 0, col = 1},
        {type = "armor", name = "Armor", row = 1, col = 0}
    }
    
    for _, slot in ipairs(slots) do
        local x = eq.x + slot.col * (slotSize + margin)
        local y = eq.y + 30 + slot.row * (slotSize + margin)
        self:drawEquipmentSlot(player, slot, x, y, slotSize)
    end
    
    -- Player stats
    self:drawPlayerStats(player, eq.x + 160, eq.y + 30)
end

function InventorySystem:drawEquipmentSlot(player, slot, x, y, size)
    local item = player.equipment[slot.type]
    local isHovered = self:isMouseInRect(x, y, size, size)
    
    -- Slot background
    love.graphics.setColor(isHovered and {0.4, 0.4, 0.4} or {0.3, 0.3, 0.3})
    love.graphics.rectangle("fill", x, y, size, size)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.rectangle("line", x, y, size, size)
    
    -- Slot name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(slot.name, x + 5, y + 5)
    
    -- Item in slot
    if item then
        local color = item:getColor()
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x + 10, y + 25, size - 20, size - 35)
        
        -- Icon
        love.graphics.setColor(1, 1, 1)
        local iconWidth = love.graphics.getFont():getWidth(item.icon)
        love.graphics.print(item.icon, x + (size - iconWidth) / 2, y + 45)
    end
end

function InventorySystem:drawPlayerStats(player, x, y)
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("STATS", x, y)
    
    local stats = {
        "Lv: " .. player.level,
        "HP: " .. math.floor(player.hp) .. "/" .. player.maxHp,
        "ATK: " .. player.attack,
        "DEF: " .. player.defense,
        "SPD: " .. string.format("%.1f", player.attackSpeed),
        "LS: " .. string.format("%.1f%%", player.lifesteal * 100)
    }
    
    love.graphics.setColor(1, 1, 1)
    for i, stat in ipairs(stats) do
        love.graphics.print(stat, x, y + 20 + (i-1) * 18)
    end
end

function InventorySystem:drawInventorySection(player)
    local header = Display.INVENTORY.INVENTORY_HEADER
    local grid = Display.INVENTORY.INVENTORY_GRID
    local cellSize = grid.CELL_SIZE
    
    -- Section title (в отдельной секции header)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("INVENTORY", header.x, header.y)
    
    -- Filters (в отдельной секции header)
    self:drawFilters(header.x, header.y + 25)
    
    -- Items grid with scroll
    local filteredItems = self:getFilteredItems(player.inventory)
    local visibleSlots = grid.COLUMNS * grid.ROWS
    
    -- Scroll bar
    if #filteredItems > visibleSlots then
        self:drawScrollBar(grid.x + grid.COLUMNS * cellSize + 5, grid.y, 160, filteredItems)
    end
    
    -- Items grid
    for i = 1, visibleSlots do
        local itemIndex = i + self.scrollOffset
        local col = (i-1) % grid.COLUMNS
        local row = math.floor((i-1) / grid.COLUMNS)
        local x = grid.x + col * cellSize
        local y = grid.y + row * cellSize
        
        if itemIndex <= #filteredItems then
            local item = filteredItems[itemIndex]
            self:drawInventoryItem(item, x, y, cellSize, player)
        else
            -- Empty slot
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", x, y, cellSize, cellSize)
            love.graphics.setColor(0.4, 0.4, 0.5)
            love.graphics.rectangle("line", x, y, cellSize, cellSize)
        end
    end
    
    -- Item tooltip
    if self.selectedItem then
        self:drawItemTooltip(player, self.selectedItem)
    end
end

function InventorySystem:drawFilters(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Filters:", x, y)
    
    local filters = {
        {type = nil, text = "All"},
        {type = "weapon", text = "Weapons"},
        {type = "helmet", text = "Helmets"}, 
        {type = "armor", text = "Armor"}
    }
    
    for i, filter in ipairs(filters) do
        local btnX = x + (i-1) * 65
        local isActive = self.itemTypeFilter == filter.type
        local isHovered = self.hoveredElement == "filter_" .. i
        
        -- Button background
        love.graphics.setColor(isActive and {0.2, 0.6, 1} or (isHovered and {0.5, 0.5, 0.5} or {0.3, 0.3, 0.3}))
        love.graphics.rectangle("fill", btnX, y + 15, 60, 18)
        
        -- Button text
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(filter.text)
        love.graphics.print(filter.text, btnX + (60 - textWidth) / 2, y + 17)
    end
end

function InventorySystem:drawInventoryItem(item, x, y, size, player)
    local isHovered = self:isMouseInRect(x, y, size, size)
    local isEquipped = player.equipment[item.type] == item
    
    -- Item background
    love.graphics.setColor(isHovered and {0.4, 0.4, 0.4} or {0.3, 0.3, 0.3})
    love.graphics.rectangle("fill", x, y, size, size)
    
    -- Item color based on rarity
    local color = item:getColor()
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x + 5, y + 5, size - 10, size - 10)
    
    -- Item icon
    love.graphics.setColor(1, 1, 1)
    local iconWidth = love.graphics.getFont():getWidth(item.icon)
    love.graphics.print(item.icon, x + (size - iconWidth) / 2, y + 20)
    
    -- Border
    love.graphics.setColor(isEquipped and {1, 1, 0} or {0.8, 0.8, 0.8})
    love.graphics.rectangle("line", x, y, size, size)
    
    -- Equipped indicator
    if isEquipped then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("E", x + 5, y + 5)
    end
end

function InventorySystem:drawScrollBar(x, y, height, items)
    local visibleSlots = Display.INVENTORY.INVENTORY_GRID.COLUMNS * Display.INVENTORY.INVENTORY_GRID.ROWS
    local totalItems = #items
    
    -- Scroll track
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", x, y, 15, height)
    
    -- Scroll thumb
    local thumbHeight = math.max(20, (visibleSlots / totalItems) * height)
    local thumbPosition = (self.scrollOffset / (totalItems - visibleSlots)) * (height - thumbHeight)
    
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.rectangle("fill", x, y + thumbPosition, 15, thumbHeight)
    
    -- Scroll buttons
    local upHovered = self.hoveredElement == "scroll_up"
    local downHovered = self.hoveredElement == "scroll_down"
    
    -- Up button
    love.graphics.setColor(upHovered and {0.6, 0.6, 0.6} or {0.4, 0.4, 0.4})
    love.graphics.rectangle("fill", x, y - 20, 15, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("↑", x + 3, y - 18)
    
    -- Down button
    love.graphics.setColor(downHovered and {0.6, 0.6, 0.6} or {0.4, 0.4, 0.4})
    love.graphics.rectangle("fill", x, y + height + 5, 15, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("↓", x + 3, y + height + 7)
end

function InventorySystem:drawBulkDeleteSection()
    local bulk = Display.INVENTORY.BULK_DELETE
    
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.print("BULK DELETE:", bulk.x, bulk.y)
    
    local buttons = {
        {rarity = "Common", text = "Common", row = 0, col = 0, color = {0.8, 0.8, 0.8}},
        {rarity = "Uncommon", text = "Uncommon", row = 0, col = 1, color = {0, 0.8, 0}},
        {rarity = "Rare", text = "Rare", row = 0, col = 2, color = {0, 0, 1}},
        {rarity = "Epic", text = "Epic", row = 1, col = 0, color = {0.6, 0, 0.8}},
        {rarity = "Legendary", text = "Legendary", row = 1, col = 1, color = {1, 0.65, 0}},
        {rarity = "ALL", text = "DELETE ALL", row = 1, col = 2, color = {1, 0, 0}}
    }
    
    for i, btn in ipairs(buttons) do
        local x = bulk.x + btn.col * 70
        local y = bulk.y + 20 + btn.row * 25
        local isHovered = self.hoveredElement == "bulk_" .. i
        
        love.graphics.setColor(isHovered and {btn.color[1], btn.color[2], btn.color[3]} or 
                              {btn.color[1] * 0.6, btn.color[2] * 0.6, btn.color[3] * 0.6})
        love.graphics.rectangle("fill", x, y, 65, 20)
        
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(btn.text)
        love.graphics.print(btn.text, x + (65 - textWidth) / 2, y + 4)
    end
end

function InventorySystem:drawDropChancesSection()
    local drop = Display.INVENTORY.DROP_CHANCES
    local currentFloor = GameState.scenes.game.currentFloor or 1
    
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("DROP CHANCES (F" .. currentFloor .. "):", drop.x, drop.y)
    
    local chances = self:getDropChances(currentFloor)
    local yOffset = 20
    
    local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
    for _, rarity in ipairs(rarities) do
        if chances[rarity] and chances[rarity] > 0 then
            local color = self:getRarityColor(rarity)
            love.graphics.setColor(color)
            love.graphics.print(rarity .. ": " .. string.format("%.1f%%", chances[rarity] * 100), drop.x, drop.y + yOffset)
            yOffset = yOffset + 15
        end
    end
end

function InventorySystem:drawItemTooltip(player, item)
    local x, y = self.mouseX + 10, self.mouseY + 10
    
    -- Keep tooltip on screen
    if x + 300 > Display.baseWidth then x = Display.baseWidth - 300 end
    if y + 220 > Display.baseHeight then y = Display.baseHeight - 220 end
    
    -- Tooltip background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", x, y, 300, 220)
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("line", x, y, 300, 220)
    
    -- Item name
    local nameColor = item:getColor()
    love.graphics.setColor(nameColor)
    love.graphics.print(item.name, x + 10, y + 10)
    
    -- Item type
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Type: " .. item.type:gsub("^%l", string.upper), x + 10, y + 30)
    
    -- Item stats
    local statsY = y + 50
    love.graphics.setColor(1, 1, 1)
    
    if item.attackBonus > 0 then
        love.graphics.print("Attack: " .. item.attackBonus, x + 10, statsY)
        statsY = statsY + 18
    end
    
    if item.defenseBonus > 0 then
        love.graphics.print("Defense: " .. item.defenseBonus, x + 10, statsY)
        statsY = statsY + 18
    end
    
    if item.hpBonus > 0 then
        love.graphics.print("HP: " .. item.hpBonus, x + 10, statsY)
        statsY = statsY + 18
    end
    
    -- Affixes
    if #item.affixes > 0 then
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Affixes:", x + 10, statsY)
        statsY = statsY + 18
        
        for _, affixDesc in ipairs(item:getAffixDescription()) do
            love.graphics.setColor(0.6, 1, 0.6)
            love.graphics.print(affixDesc, x + 20, statsY)
            statsY = statsY + 16
        end
    end
    
    -- Usage hint
    local isEquipped = player.equipment[item.type] == item
    love.graphics.setColor(1, 1, 0)
    love.graphics.print(isEquipped and "Click to unequip" or "Click to equip", x + 10, y + 190)
end

-- Utility methods
function InventorySystem:getDropChances(floorLevel)
    local chances = {
        Common = 0.7,
        Uncommon = 0.25,
        Rare = 0.05,
        Epic = 0.0,
        Legendary = 0.0
    }
    
    if floorLevel >= 2 then
        chances.Common = 0.6
        chances.Uncommon = 0.3
        chances.Rare = 0.08
        chances.Epic = 0.02
    end
    if floorLevel >= 3 then
        chances.Common = 0.5
        chances.Uncommon = 0.3
        chances.Rare = 0.12
        chances.Epic = 0.06
        chances.Legendary = 0.02
    end
    if floorLevel >= 4 then
        chances.Common = 0.4
        chances.Uncommon = 0.3
        chances.Rare = 0.15
        chances.Epic = 0.1
        chances.Legendary = 0.05
    end
    
    return chances
end

function InventorySystem:getRarityColor(rarity)
    if rarity == "Common" then return {0.8, 0.8, 0.8}
    elseif rarity == "Uncommon" then return {0, 1, 0}
    elseif rarity == "Rare" then return {0, 0, 1}
    elseif rarity == "Epic" then return {0.6, 0, 0.8}
    elseif rarity == "Legendary" then return {1, 0.65, 0}
    else return {1, 1, 1} end
end

function InventorySystem:isMouseInRect(x, y, width, height)
    return self.mouseX >= x and self.mouseX <= x + width and
           self.mouseY >= y and self.mouseY <= y + height
end

function InventorySystem:getFilteredItems(inventory)
    local filtered = {}
    for _, item in ipairs(inventory) do
        if not self.itemTypeFilter or item.type == self.itemTypeFilter then
            table.insert(filtered, item)
        end
    end
    return filtered
end

function InventorySystem:updateMouse(x, y, player)
    self.mouseX = x
    self.mouseY = y
    self.hoveredElement = nil
    self.selectedItem = nil
    
    local inv = Display.INVENTORY  -- Добавил определение inv

    -- Check filters (теперь в отдельной секции header)
    local header = inv.INVENTORY_HEADER
    for i = 1, 4 do
        local btnX = header.x + (i-1) * 65
        local btnY = header.y + 40
        if self:isMouseInRect(btnX, btnY, 60, 18) then
            self.hoveredElement = "filter_" .. i
            return
        end
    end
    
    -- Check bulk delete buttons
    local bulk = inv.BULK_DELETE
    for i = 1, 6 do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local btnX = bulk.x + col * 70
        local btnY = bulk.y + 20 + row * 25
        
        if self:isMouseInRect(btnX, btnY, 65, 20) then
            self.hoveredElement = "bulk_" .. i
            return
        end
    end
    
    -- Check equipment slots
    local eq = inv.EQUIPMENT
    local slots = {
        {type = "weapon", row = 0, col = 0},
        {type = "helmet", row = 0, col = 1},
        {type = "armor", row = 1, col = 0}
    }
    
    for _, slot in ipairs(slots) do
        local x = eq.x + slot.col * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        local y = eq.y + 30 + slot.row * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        
        if self:isMouseInRect(x, y, eq.SLOT_SIZE, eq.SLOT_SIZE) then
            self.selectedItem = player.equipment[slot.type]
            return
        end
    end
    
    -- Check scroll buttons
    local filteredItems = self:getFilteredItems(player.inventory)
    local grid = inv.INVENTORY_GRID
    if #filteredItems > grid.COLUMNS * grid.ROWS then
        local scrollX = grid.x + grid.COLUMNS * grid.CELL_SIZE + 5
        if self:isMouseInRect(scrollX, grid.y, 15, 15) then
            self.hoveredElement = "scroll_up"
            return
        end
        if self:isMouseInRect(scrollX, grid.y + 160 + 5, 15, 15) then
            self.hoveredElement = "scroll_down"
            return
        end
    end
    
    -- Check inventory items
    for i = 1, grid.COLUMNS * grid.ROWS do
        local itemIndex = i + self.scrollOffset
        if itemIndex > #filteredItems then break end
        
        local col = (i-1) % grid.COLUMNS
        local row = math.floor((i-1) / grid.COLUMNS)
        local x = grid.x + col * grid.CELL_SIZE
        local y = grid.y + row * grid.CELL_SIZE
        
        if self:isMouseInRect(x, y, grid.CELL_SIZE, grid.CELL_SIZE) then
            self.selectedItem = filteredItems[itemIndex]
            return
        end
    end
end

function InventorySystem:handleClick(x, y, player)
    local inv = Display.INVENTORY  -- Добавил определение inv

    -- Check filters (теперь выше)
    local header = inv.INVENTORY_HEADER
    for i = 1, 4 do
        local btnX = header.x + (i-1) * 65
        local btnY = header.y + 35
        if self:isMouseInRect(btnX, btnY, 60, 18) then
            if i == 1 then self.itemTypeFilter = nil
            elseif i == 2 then self.itemTypeFilter = "weapon"
            elseif i == 3 then self.itemTypeFilter = "helmet"
            elseif i == 4 then self.itemTypeFilter = "armor" end
            
            self.scrollOffset = 0
            return true
        end
    end
    
    -- Check bulk delete buttons
    local bulk = inv.BULK_DELETE
    local bulkButtons = {
        {rarity = "Common"}, {rarity = "Uncommon"}, {rarity = "Rare"},
        {rarity = "Epic"}, {rarity = "Legendary"}, {rarity = "ALL"}
    }
    
    for i, btn in ipairs(bulkButtons) do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local btnX = bulk.x + col * 70
        local btnY = bulk.y + 20 + row * 25
        
        if self:isMouseInRect(btnX, btnY, 65, 20) then
            local count = 0
            for i = #player.inventory, 1, -1 do
                local item = player.inventory[i]
                if player.equipment[item.type] ~= item and 
                   (btn.rarity == "ALL" or item.rarity == btn.rarity) then
                    table.remove(player.inventory, i)
                    count = count + 1
                end
            end
            local rarityText = btn.rarity == "ALL" and "items" or btn.rarity .. " items"
            print("Deleted " .. count .. " " .. rarityText .. " from inventory")
            return true
        end
    end
    
    -- Check scroll buttons
    local filteredItems = self:getFilteredItems(player.inventory)
    local grid = inv.INVENTORY_GRID
    if #filteredItems > grid.COLUMNS * grid.ROWS then
        local scrollX = grid.x + grid.COLUMNS * grid.CELL_SIZE + 5
        
        if self:isMouseInRect(scrollX, grid.y, 15, 15) and self.scrollOffset > 0 then
            self.scrollOffset = self.scrollOffset - 1
            return true
        end
        
        if self:isMouseInRect(scrollX, grid.y + 160 + 5, 15, 15) and 
           self.scrollOffset < #filteredItems - (grid.COLUMNS * grid.ROWS) then
            self.scrollOffset = self.scrollOffset + 1
            return true
        end
    end
    
    -- Check equipment slots
    local eq = inv.EQUIPMENT
    local slots = {
        {type = "weapon", row = 0, col = 0},
        {type = "helmet", row = 0, col = 1},
        {type = "armor", row = 1, col = 0}
    }
    
    for _, slot in ipairs(slots) do
        local x = eq.x + slot.col * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        local y = eq.y + 30 + slot.row * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        
        if self:isMouseInRect(x, y, eq.SLOT_SIZE, eq.SLOT_SIZE) then
            if player.equipment[slot.type] then
                player:unequipItem(slot.type)
            end
            return true
        end
    end
    
    -- Check inventory items
    for i = 1, grid.COLUMNS * grid.ROWS do
        local itemIndex = i + self.scrollOffset
        if itemIndex > #filteredItems then break end
        
        local col = (i-1) % grid.COLUMNS
        local row = math.floor((i-1) / grid.COLUMNS)
        local x = grid.x + col * grid.CELL_SIZE
        local y = grid.y + row * grid.CELL_SIZE
        
        if self:isMouseInRect(x, y, grid.CELL_SIZE, grid.CELL_SIZE) then
            local item = filteredItems[itemIndex]
            
            if player.equipment[item.type] == item then
                player:unequipItem(item.type)
            else
                player:equipItem(item)
            end
            return true
        end
    end
    
    return false
end