InventoryRenderer = {}

function InventoryRenderer:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventoryRenderer:draw(player, system)
    local inv = Display.INVENTORY
    
    -- Inventory background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", 700, 0, 300, Display.baseHeight)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", 700, 0, 300, Display.baseHeight)
    
    -- Equipment section
    self:drawEquipmentSection(player, system)
    
    -- Inventory section
    self:drawInventorySection(player, system)
    
    -- Bulk delete section
    self:drawBulkDeleteSection(system)
    
    -- Item tooltip
    if system.selectedItem then
        self:drawItemTooltip(player, system.selectedItem, system.mouseX, system.mouseY)
    end
end

function InventoryRenderer:drawEquipmentSection(player, system)
    local eq = Display.INVENTORY.EQUIPMENT
    
    -- Section title
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("EQUIPMENT", eq.x, eq.y + 80)
    
    -- Equipment slots
    local slots = {
        {type = "weapon", name = "Weapon", row = 0, col = 0},
        {type = "helmet", name = "Helmet", row = 0, col = 1},
        {type = "armor", name = "Armor", row = 1, col = 0}
    }
    
    for _, slot in ipairs(slots) do
        local x = eq.x + slot.col * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        local y = eq.y + 110 + slot.row * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        self:drawEquipmentSlot(player, slot, x, y, eq.SLOT_SIZE, system)
    end
end

function InventoryRenderer:drawEquipmentSlot(player, slot, x, y, size, system)
    local item = player.equipment[slot.type]
    local isHovered = system:isMouseInRect(x, y, size, size)
    
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
        local color = self:getItemColor(item)
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", x + 10, y + 25, size - 20, size - 35)
        
        -- Icon
        love.graphics.setColor(1, 1, 1)
        local icon = self:getItemIcon(item)
        local iconWidth = love.graphics.getFont():getWidth(icon)
        love.graphics.print(icon, x + (size - iconWidth) / 2, y + 45)
        
        -- Item stats
        love.graphics.setColor(0.9, 0.9, 0.9)
        if item.attackBonus and item.attackBonus > 0 then
            love.graphics.print("ATK:" .. item.attackBonus, x + 5, y + size - 25)
        end
        if item.defenseBonus and item.defenseBonus > 0 then
            love.graphics.print("DEF:" .. item.defenseBonus, x + 5, y + size - 15)
        end
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Empty", x + size/2 - 15, y + size/2 - 5)
    end
end

function InventoryRenderer:drawInventorySection(player, system)
    local header = Display.INVENTORY.INVENTORY_HEADER
    local grid = Display.INVENTORY.INVENTORY_GRID
    
    -- Section title
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("INVENTORY", header.x, header.y + 80)
    
    -- Filters - правильное расположение
    self:drawFilters(header.x, header.y + 100, system)
    
    -- Items grid with scroll
    local filteredItems = system:getFilteredItems(player.inventory)
    local visibleSlots = grid.COLUMNS * grid.ROWS
    
    -- Scroll bar
    if #filteredItems > visibleSlots then
        self:drawScrollBar(grid, filteredItems, visibleSlots, system.scrollOffset, system.hoveredElement)
    end
    
    -- Items grid
    for i = 1, visibleSlots do
        local itemIndex = i + system.scrollOffset
        local col = (i-1) % grid.COLUMNS
        local row = math.floor((i-1) / grid.COLUMNS)
        local x = grid.x + col * grid.CELL_SIZE
        local y = grid.y + 80 + row * grid.CELL_SIZE
        
        if itemIndex <= #filteredItems then
            local item = filteredItems[itemIndex]
            if item then
                self:drawInventoryItem(item, x, y, grid.CELL_SIZE, player, system)
            end
        else
            -- Empty slot
            love.graphics.setColor(0.2, 0.2, 0.3)
            love.graphics.rectangle("fill", x, y, grid.CELL_SIZE, grid.CELL_SIZE)
            love.graphics.setColor(0.4, 0.4, 0.5)
            love.graphics.rectangle("line", x, y, grid.CELL_SIZE, grid.CELL_SIZE)
        end
    end
end

function InventoryRenderer:drawScrollBar(grid, filteredItems, visibleSlots, scrollOffset, hoveredElement)
    local scrollX = grid.x + grid.COLUMNS * grid.CELL_SIZE + 5
    local scrollY = grid.y + 80
    local scrollHeight = grid.ROWS * grid.CELL_SIZE
    
    -- Scroll track
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", scrollX, scrollY, 15, scrollHeight)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", scrollX, scrollY, 15, scrollHeight)
    
    -- Scroll thumb
    local totalItems = #filteredItems
    local thumbHeight = math.max(20, (visibleSlots / totalItems) * scrollHeight)
    local maxScrollOffset = math.max(0, totalItems - visibleSlots)
    local thumbPosition = 0
    
    if maxScrollOffset > 0 then
        thumbPosition = (scrollOffset / maxScrollOffset) * (scrollHeight - thumbHeight)
    end
    
    local isThumbHovered = hoveredElement == "scroll_thumb"
    love.graphics.setColor(isThumbHovered and {0.7, 0.7, 0.9} or {0.5, 0.5, 0.7})
    love.graphics.rectangle("fill", scrollX, scrollY + thumbPosition, 15, thumbHeight)
    
    -- Scroll buttons
    local upHovered = hoveredElement == "scroll_up"
    local downHovered = hoveredElement == "scroll_down"
    
    -- Up button
    love.graphics.setColor(upHovered and {0.6, 0.6, 0.6} or {0.4, 0.4, 0.4})
    love.graphics.rectangle("fill", scrollX, scrollY - 20, 15, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("↑", scrollX + 3, scrollY - 18)
    
    -- Down button
    love.graphics.setColor(downHovered and {0.6, 0.6, 0.6} or {0.4, 0.4, 0.4})
    love.graphics.rectangle("fill", scrollX, scrollY + scrollHeight + 5, 15, 15)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("↓", scrollX + 3, scrollY + scrollHeight + 7)
end

function InventoryRenderer:drawFilters(x, y, system)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Filters:", x, y)
    
    local filters = {
        {type = nil, text = "All"},
        {type = "weapon", text = "Weapons"},
        {type = "helmet", text = "Helmets"}, 
        {type = "armor", text = "Armor"}
    }
    
    for i, filter in ipairs(filters) do
        local btnX = x + (i-1) * 70
        local btnY = y + 15
        local isActive = system.itemTypeFilter == filter.type
        local isHovered = system.hoveredElement == "filter_" .. i
        
        -- Button background
        love.graphics.setColor(isActive and {0.2, 0.6, 1} or (isHovered and {0.5, 0.5, 0.5} or {0.3, 0.3, 0.3}))
        love.graphics.rectangle("fill", btnX, btnY, 65, 18)
        
        -- Button text
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(filter.text)
        love.graphics.print(filter.text, btnX + (65 - textWidth) / 2, btnY + 4)
    end
end

function InventoryRenderer:drawInventoryItem(item, x, y, size, player, system)
    local isHovered = system:isMouseInRect(x, y, size, size)
    local isEquipped = player.equipment[item.type] == item
    
    -- Item background
    love.graphics.setColor(isHovered and {0.4, 0.4, 0.4} or {0.3, 0.3, 0.3})
    love.graphics.rectangle("fill", x, y, size, size)
    
    -- Item color based on rarity
    local color = self:getItemColor(item)
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", x + 5, y + 5, size - 10, size - 10)
    
    -- Item icon
    love.graphics.setColor(1, 1, 1)
    local icon = self:getItemIcon(item)
    local iconWidth = love.graphics.getFont():getWidth(icon)
    love.graphics.print(icon, x + (size - iconWidth) / 2, y + 25)
    
    -- Border
    love.graphics.setColor(isEquipped and {1, 1, 0} or {0.8, 0.8, 0.8})
    love.graphics.rectangle("line", x, y, size, size)
    
    -- Equipped indicator
    if isEquipped then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("E", x + 5, y + 5)
    end
end

function InventoryRenderer:drawBulkDeleteSection(system)
    local bulk = Display.INVENTORY.BULK_DELETE
    
    love.graphics.setColor(1, 0.5, 0.5)
    love.graphics.print("BULK DELETE:", bulk.x, bulk.y + 80)
    
    local buttons = {
        {rarity = "Common", text = "Common", row = 0, col = 0, color = {0.8, 0.8, 0.8}},
        {rarity = "Uncommon", text = "Uncommon", row = 0, col = 1, color = {0, 0.8, 0}},
        {rarity = "Rare", text = "Rare", row = 0, col = 2, color = {0, 0, 1}},
        {rarity = "Epic", text = "Epic", row = 1, col = 0, color = {0.6, 0, 0.8}},
        {rarity = "Legendary", text = "Legendary", row = 1, col = 1, color = {1, 0.65, 0}},
        {rarity = "ALL", text = "DELETE ALL", row = 1, col = 2, color = {1, 0, 0}}
    }
    
    for i, btn in ipairs(buttons) do
        local x = bulk.x + btn.col * 75
        local y = bulk.y + 100 + btn.row * 30
        local isHovered = system.hoveredElement == "bulk_" .. i
        
        love.graphics.setColor(isHovered and {btn.color[1], btn.color[2], btn.color[3]} or 
                              {btn.color[1] * 0.6, btn.color[2] * 0.6, btn.color[3] * 0.6})
        love.graphics.rectangle("fill", x, y, 70, 22)
        
        love.graphics.setColor(1, 1, 1)
        local textWidth = love.graphics.getFont():getWidth(btn.text)
        love.graphics.print(btn.text, x + (70 - textWidth) / 2, y + 6)
    end
end

function InventoryRenderer:drawItemTooltip(player, item, mouseX, mouseY)
    local currentEquipped = player.equipment[item.type]
    local isEquipped = currentEquipped == item
    
    -- Если есть одетый предмет для сравнения - показываем два тултипа
    if currentEquipped and not isEquipped then
        self:drawComparisonTooltips(item, currentEquipped, mouseX, mouseY)
    else
        -- Иначе показываем один тултип
        self:drawSingleItemTooltip(item, mouseX + 10, mouseY + 10)
    end
end

function InventoryRenderer:drawComparisonTooltips(hoveredItem, equippedItem, mouseX, mouseY)
    local tooltipWidth = 280
    local spacing = 20
    local totalWidth = (tooltipWidth * 2) + spacing
    
    -- Calculate heights for both tooltips
    local hoveredHeight = self:calculateTooltipHeight(hoveredItem)
    local equippedHeight = self:calculateTooltipHeight(equippedItem)
    local maxHeight = math.max(hoveredHeight, equippedHeight)
    
    local startX = mouseX + 10
    local startY = mouseY + 10
    
    -- Keep tooltips on screen
    if startX + totalWidth > Display.baseWidth then
        startX = Display.baseWidth - totalWidth - 10
    end
    if startY + maxHeight > Display.baseHeight then
        startY = Display.baseHeight - maxHeight - 10
    end
    
    -- Equipped item (left)
    self:drawSingleTooltip(equippedItem, startX, startY, tooltipWidth, "EQUIPPED")
    
    -- Hovered item (right)
    self:drawSingleTooltip(hoveredItem, startX + tooltipWidth + spacing, startY, tooltipWidth, "NEW ITEM")
end

function InventoryRenderer:drawSingleItemTooltip(item, x, y)
    local height = self:calculateTooltipHeight(item)
    
    -- Keep tooltip on screen
    if x + 280 > Display.baseWidth then x = Display.baseWidth - 280 - 10 end
    if y + height > Display.baseHeight then y = Display.baseHeight - height - 10 end
    
    self:drawSingleTooltip(item, x, y, 280, "")
end

function InventoryRenderer:drawSingleTooltip(item, x, y, width, title)
    local height = self:calculateTooltipHeight(item)
    
    -- Tooltip background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(0.4, 0.4, 0.6)
    love.graphics.rectangle("line", x, y, width, height)
    
    local currentY = y + 10
    
    -- Title (если есть)
    if title ~= "" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(title, x + 10, currentY)
        currentY = currentY + 20
    end
    
    -- Item name with rarity color
    local nameColor = self:getItemColor(item)
    love.graphics.setColor(nameColor)
    love.graphics.print(item.name, x + 10, currentY)
    currentY = currentY + 20
    
    -- Item type
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Type: " .. item.type:gsub("^%l", string.upper), x + 10, currentY)
    currentY = currentY + 20
    
    -- Stats
    if item.attackBonus and item.attackBonus > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Attack: " .. item.attackBonus, x + 10, currentY)
        currentY = currentY + 18
    end
    
    if item.defenseBonus and item.defenseBonus > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Defense: " .. item.defenseBonus, x + 10, currentY)
        currentY = currentY + 18
    end
    
    if item.hpBonus and item.hpBonus > 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("HP: " .. item.hpBonus, x + 10, currentY)
        currentY = currentY + 18
    end
    
    -- Affixes
-- В методе drawSingleTooltip замени блок аффиксов на:

-- Affixes
    if item.affixes and #item.affixes > 0 then
        currentY = currentY + 10
        love.graphics.setColor(0.8, 0.8, 1)
        love.graphics.print("Affixes:", x + 10, currentY)
        currentY = currentY + 18
        
        for _, affix in ipairs(item.affixes) do
            local description = self:formatAffixDescription(affix)
            if description ~= "" then
                love.graphics.setColor(0.6, 1, 0.6)
                love.graphics.print(description, x + 20, currentY)
                currentY = currentY + 16
            end
        end
    end
end

function InventoryRenderer:calculateTooltipHeight(item)
    local height = 60  -- Base height (name, type, spacing)
    
    -- Add height for stats
    if item.attackBonus then height = height + 18 end
    if item.defenseBonus then height = height + 18 end
    if item.hpBonus then height = height + 18 end
    
    -- Add height for affixes
    if item.affixes and #item.affixes > 0 then
        height = height + 28 + (#item.affixes * 16)  -- Title + spacing + affix lines
    end
    
    return height
end

-- Вспомогательные методы
function InventoryRenderer:getItemColor(item)
    if not item or not item.rarity then return {1, 1, 1} end
    
    if item.rarity == "Common" then return {0.8, 0.8, 0.8}
    elseif item.rarity == "Uncommon" then return {0, 1, 0}
    elseif item.rarity == "Rare" then return {0, 0, 1}
    elseif item.rarity == "Epic" then return {0.5, 0, 0.5}
    elseif item.rarity == "Legendary" then return {1, 0.65, 0}
    else return {1, 1, 1} end
end

function InventoryRenderer:getItemIcon(item)
    if not item or not item.type then return "?" end
    
    if item.type == "weapon" then return "W"
    elseif item.type == "helmet" then return "H"
    elseif item.type == "armor" then return "A"
    else return "?" end
end

-- В конец InventoryRenderer.lua добавь этот метод (перед return):

function InventoryRenderer:formatAffixDescription(affix)
    if not affix or not affix.name or not affix.value then
        return ""
    end
    
    local value = affix.value
    local formattedValue
    
    if affix.type == "percent" then
        -- Для процентных значений умножаем на 100 и округляем до целого
        local percentValue = value * 100
        formattedValue = tostring(math.floor(percentValue))
        formattedValue = formattedValue .. "%"
    else
        -- Для плоских значений просто целое число
        formattedValue = tostring(math.floor(value))
    end
    
    -- Просто добавляем отформатированное значение к названию
    local description = affix.name .. formattedValue
    
    return description
end

return InventoryRenderer