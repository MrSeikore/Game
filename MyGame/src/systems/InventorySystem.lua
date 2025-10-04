InventorySystem = {
    visible = false,
    selectedItem = nil,
    scrollOffset = 0,
    itemTypeFilter = nil,
    rarityFilter = nil,
    mouseX = 0,
    mouseY = 0
}

function InventorySystem:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventorySystem:draw(player)
    if not self.visible then return end
    
    -- Inventory background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.9)
    love.graphics.rectangle("fill", 100, 50, 800, 600)
    love.graphics.setColor(0.4, 0.4, 0.4)
    love.graphics.rectangle("line", 100, 50, 800, 600)
    
    -- Title
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("INVENTORY (I - close)", 110, 60)
    
    -- Divider line
    love.graphics.line(500, 100, 500, 640)
    
    -- Left side - equipment
    self:drawEquipment(player, 120, 100)
    
    -- Right side - items
    self:drawInventory(player, 520, 100)
    
    -- Item tooltip
    self:drawItemTooltip(player)
end

function InventorySystem:drawEquipment(player, x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("EQUIPMENT", x, y)
    
    local slots = {
        {type = "weapon", name = "Weapon", x = x, y = y + 40},
        {type = "helmet", name = "Helmet", x = x, y = y + 120},
        {type = "armor", name = "Armor", x = x, y = y + 200}
    }
    
    for _, slot in ipairs(slots) do
        -- Slot
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.rectangle("fill", slot.x, slot.y, 80, 80)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", slot.x, slot.y, 80, 80)
        
        -- Name
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(slot.name, slot.x, slot.y - 20)
        
        -- Item
        local item = player.equipment[slot.type]
        if item then
            local color = item:getColor()
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", slot.x + 10, slot.y + 10, 60, 60)
            
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(item.icon, slot.x + 35, slot.y + 35)
        end
        
        -- Unequip button
        if item then
            love.graphics.setColor(0.6, 0, 0)
            love.graphics.rectangle("fill", slot.x, slot.y + 85, 80, 25)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Unequip", slot.x + 10, slot.y + 90)
        end
    end
    
    -- Stats
    love.graphics.setColor(0, 1, 1)
    love.graphics.print("STATS:", x + 120, y)
    
    local stats = {
        "Level: " .. player.level,
        "HP: " .. player.hp .. "/" .. player.maxHp,
        "Attack: " .. player.attack,
        "Defense: " .. player.defense,
        "Atk Speed: " .. string.format("%.1f", player.attackSpeed),
        "Lifesteal: " .. string.format("%.1f%%", player.lifesteal * 100)
    }
    
    love.graphics.setColor(1, 1, 1)
    for i, stat in ipairs(stats) do
        love.graphics.print(stat, x + 120, y + 25 + (i-1) * 25)
    end
end

function InventorySystem:drawInventory(player, x, y)
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("INVENTORY", x, y)
    
    -- Filters
    self:drawFilters(x, y + 30)
    
    -- Items
    local filteredItems = self:getFilteredItems(player.inventory)
    self:drawItemsGrid(filteredItems, player, x, y + 80)
    
    -- Bulk delete buttons
    self:drawBulkDeleteButtons(x, y + 430)
end

function InventorySystem:drawFilters(x, y)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Filters:", x, y)
    
    -- Type filter
    local types = {"All", "Weapon", "Helmet", "Armor"}
    for i, typeName in ipairs(types) do
        local btnX = x + (i-1) * 85
        local btnY = y + 20
        local isActive = (i == 1 and not self.itemTypeFilter) or 
                       (i == 2 and self.itemTypeFilter == "weapon") or
                       (i == 3 and self.itemTypeFilter == "helmet") or
                       (i == 4 and self.itemTypeFilter == "armor")
        
        love.graphics.setColor(isActive and {0, 0.4, 0.8} or {0.3, 0.3, 0.3})
        love.graphics.rectangle("fill", btnX, btnY, 80, 25)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(typeName, btnX + 10, btnY + 5)
    end
end

function InventorySystem:drawItemsGrid(items, player, x, y)
    for i = 1, 12 do
        local itemIndex = i + self.scrollOffset
        local itemX = x + ((i-1) % 3) * 100
        local itemY = y + math.floor((i-1) / 3) * 100
        
        if itemIndex > #items then
            -- Empty cell
            love.graphics.setColor(0.2, 0.2, 0.2)
            love.graphics.rectangle("fill", itemX, itemY, 80, 80)
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", itemX, itemY, 80, 80)
            goto continue
        end
        
        local item = items[itemIndex]
        
        -- Item cell background
        if item == self.selectedItem then
            love.graphics.setColor(0.5, 0.5, 0.2)
        else
            love.graphics.setColor(0.3, 0.3, 0.3)
        end
        love.graphics.rectangle("fill", itemX, itemY, 80, 80)
        
        -- Item color
        local color = item:getColor()
        love.graphics.setColor(color)
        love.graphics.rectangle("fill", itemX + 10, itemY + 10, 60, 60)
        
        -- Icon
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(item.icon, itemX + 35, itemY + 35)
        
        -- Border
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.rectangle("line", itemX, itemY, 80, 80)
        
        -- Buttons
        local isEquipped = player.equipment[item.type] == item
        local equipColor = isEquipped and {0.4, 0.4, 0.4} or {0, 0.6, 0}
        
        love.graphics.setColor(equipColor)
        love.graphics.rectangle("fill", itemX, itemY + 85, 40, 20)
        love.graphics.setColor(0.6, 0, 0)
        love.graphics.rectangle("fill", itemX + 42, itemY + 85, 38, 20)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(isEquipped and "Off" or "On", itemX + 8, itemY + 87)
        love.graphics.print("Del", itemX + 50, itemY + 87)
        
        ::continue::
    end
    
    -- Scroll indicators
    if #items > 12 then
        love.graphics.setColor(0.4, 0.4, 0.4)
        -- Up arrow
        if self.scrollOffset > 0 then
            love.graphics.rectangle("fill", x + 250, y - 25, 30, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("↑", x + 260, y - 23)
        end
        -- Down arrow
        if self.scrollOffset < #items - 12 then
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("fill", x + 250, y + 385, 30, 20)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("↓", x + 260, y + 387)
        end
    end
end

function InventorySystem:drawBulkDeleteButtons(x, y)
    love.graphics.setColor(1, 0.4, 0.4)
    love.graphics.print("Bulk Delete:", x, y)
    
    local buttons = {
        {text = "All Common", rarity = "Common", x = x, y = y + 25, color = {0.8, 0.8, 0.8}},
        {text = "All Uncommon", rarity = "Uncommon", x = x + 120, y = y + 25, color = {0, 1, 0}},
        {text = "All Rare", rarity = "Rare", x = x + 240, y = y + 25, color = {0, 0, 1}},
        {text = "All Epic", rarity = "Epic", x = x, y = y + 50, color = {0.5, 0, 0.5}},
        {text = "All Legendary", rarity = "Legendary", x = x + 120, y = y + 50, color = {1, 0.65, 0}},
        {text = "DELETE ALL", rarity = "ALL", x = x + 240, y = y + 50, color = {1, 0, 0}}
    }
    
    for _, btn in ipairs(buttons) do
        love.graphics.setColor(btn.color[1] * 0.6, btn.color[2] * 0.6, btn.color[3] * 0.6)
        love.graphics.rectangle("fill", btn.x, btn.y, 115, 25)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(btn.text, btn.x + 5, btn.y + 5)
    end
end

function InventorySystem:drawItemTooltip(player)
    if not self.selectedItem then return end
    
    local x, y = self.mouseX + 10, self.mouseY + 10
    local currentItem = player.equipment[self.selectedItem.type]
    
    -- Tooltip background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", x, y, 300, 150)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", x, y, 300, 150)
    
    -- Item name
    local nameColor = self.selectedItem:getColor()
    love.graphics.setColor(nameColor)
    love.graphics.print(self.selectedItem.name, x + 10, y + 10)
    
    -- Stats
    love.graphics.setColor(1, 1, 1)
    local statsY = y + 35
    
    if self.selectedItem.attackBonus > 0 then
        local currentAttack = currentItem and currentItem.attackBonus or 0
        local diff = self.selectedItem.attackBonus - currentAttack
        local color = {1, 1, 1}
        local sign = ""
        if diff > 0 then color = {0, 1, 0}; sign = " (+" .. diff .. ")"
        elseif diff < 0 then color = {1, 0, 0}; sign = " (" .. diff .. ")" end
        
        love.graphics.setColor(color)
        love.graphics.print("Attack: " .. self.selectedItem.attackBonus .. sign, x + 10, statsY)
        statsY = statsY + 20
    end
    
    if self.selectedItem.defenseBonus > 0 then
        local currentDefense = currentItem and currentItem.defenseBonus or 0
        local diff = self.selectedItem.defenseBonus - currentDefense
        local color = {1, 1, 1}
        local sign = ""
        if diff > 0 then color = {0, 1, 0}; sign = " (+" .. diff .. ")"
        elseif diff < 0 then color = {1, 0, 0}; sign = " (" .. diff .. ")" end
        
        love.graphics.setColor(color)
        love.graphics.print("Defense: " .. self.selectedItem.defenseBonus .. sign, x + 10, statsY)
        statsY = statsY + 20
    end
    
    if self.selectedItem.hpBonus > 0 then
        local currentHP = currentItem and currentItem.hpBonus or 0
        local diff = self.selectedItem.hpBonus - currentHP
        local color = {1, 1, 1}
        local sign = ""
        if diff > 0 then color = {0, 1, 0}; sign = " (+" .. diff .. ")"
        elseif diff < 0 then color = {1, 0, 0}; sign = " (" .. diff .. ")" end
        
        love.graphics.setColor(color)
        love.graphics.print("HP: " .. self.selectedItem.hpBonus .. sign, x + 10, statsY)
        statsY = statsY + 20
    end
    
    -- Special stats
    love.graphics.setColor(1, 1, 1)
    if self.selectedItem.attackSpeed > 0 then
        love.graphics.print("Atk Speed: +" .. self.selectedItem.attackSpeed, x + 10, statsY)
        statsY = statsY + 20
    end
    
    if self.selectedItem.lifesteal > 0 then
        love.graphics.print("Lifesteal: +" .. (self.selectedItem.lifesteal * 100) .. "%", x + 10, statsY)
        statsY = statsY + 20
    end
end

function InventorySystem:getFilteredItems(inventory)
    local filtered = {}
    for _, item in ipairs(inventory) do
        if self.itemTypeFilter and item.type ~= self.itemTypeFilter then
            goto continue
        end
        if self.rarityFilter and item.rarity ~= self.rarityFilter then
            goto continue
        end
        table.insert(filtered, item)
        ::continue::
    end
    return filtered
end

function InventorySystem:updateMouse(x, y, player)
    self.mouseX = x
    self.mouseY = y
    
    -- Auto-select item under mouse
    if not self.visible then return end
    
    local filteredItems = self:getFilteredItems(player.inventory)
    for i = 1, 12 do
        local itemIndex = i + self.scrollOffset
        if itemIndex > #filteredItems then break end
        
        local itemX = 520 + ((i-1) % 3) * 100
        local itemY = 180 + math.floor((i-1) / 3) * 100
        
        if x >= itemX and x <= itemX + 80 and y >= itemY and y <= itemY + 80 then
            self.selectedItem = filteredItems[itemIndex]
            return
        end
    end
    
    -- Check equipment slots
    local slots = {
        {type = "weapon", x = 120, y = 140},
        {type = "helmet", x = 120, y = 220},
        {type = "armor", x = 120, y = 300}
    }
    
    for _, slot in ipairs(slots) do
        if x >= slot.x and x <= slot.x + 80 and y >= slot.y and y <= slot.y + 80 then
            self.selectedItem = player.equipment[slot.type]
            return
        end
    end
end

function InventorySystem:handleClick(x, y, player)
    print("Click at:", x, y)
    
    -- Left panel - equipment
    if x >= 120 and x <= 400 then
        return self:handleEquipmentClick(x, y, player)
    -- Right panel - inventory  
    elseif x >= 520 and x <= 900 then
        return self:handleInventoryClick(x, y, player)
    end
    return false
end

function InventorySystem:handleEquipmentClick(x, y, player)
    local slots = {
        {type = "weapon", x = 120, y = 140, width = 80, height = 80},
        {type = "helmet", x = 120, y = 220, width = 80, height = 80},
        {type = "armor", x = 120, y = 300, width = 80, height = 80}
    }
    
    for _, slot in ipairs(slots) do
        -- Click on slot or unequip button
        if (x >= slot.x and x <= slot.x + slot.width and 
            y >= slot.y and y <= slot.y + slot.height) or
           (x >= slot.x and x <= slot.x + slot.width and 
            y >= slot.y + 85 and y <= slot.y + 110) then
            
            if player.equipment[slot.type] then
                local item = player:unequipItem(slot.type)
                -- Return item to inventory
                if item and not self:playerHasItem(player, item) then
                    table.insert(player.inventory, item)
                end
                return true
            end
        end
    end
    
    return false
end

function InventorySystem:playerHasItem(player, item)
    for _, invItem in ipairs(player.inventory) do
        if invItem == item then
            return true
        end
    end
    return false
end

function InventorySystem:handleInventoryClick(x, y, player)
    local filteredItems = self:getFilteredItems(player.inventory)
    
    -- Scroll buttons
    if #filteredItems > 12 then
        if x >= 770 and x <= 800 then
            if y >= 155 and y <= 175 and self.scrollOffset > 0 then
                self.scrollOffset = self.scrollOffset - 1
                return true
            elseif y >= 565 and y <= 585 and self.scrollOffset < #filteredItems - 12 then
                self.scrollOffset = self.scrollOffset + 1
                return true
            end
        end
    end
    
    -- Type filter buttons (larger click areas)
    for i = 1, 4 do
        local btnX = 520 + (i-1) * 85
        local btnY = 130
        if x >= btnX and x <= btnX + 80 and y >= btnY and y <= btnY + 25 then
            if i == 1 then self.itemTypeFilter = nil
            elseif i == 2 then self.itemTypeFilter = "weapon"
            elseif i == 3 then self.itemTypeFilter = "helmet"
            elseif i == 4 then self.itemTypeFilter = "armor" end
            self.scrollOffset = 0
            print("Filter changed to:", self.itemTypeFilter or "all")
            return true
        end
    end
    
    -- Bulk delete buttons
    local bulkButtons = {
        {rarity = "Common", x = 520, y = 455, width = 115, height = 25},
        {rarity = "Uncommon", x = 640, y = 455, width = 115, height = 25},
        {rarity = "Rare", x = 760, y = 455, width = 115, height = 25},
        {rarity = "Epic", x = 520, y = 480, width = 115, height = 25},
        {rarity = "Legendary", x = 640, y = 480, width = 115, height = 25},
        {rarity = "ALL", x = 760, y = 480, width = 115, height = 25}
    }
    
    for _, btn in ipairs(bulkButtons) do
        if x >= btn.x and x <= btn.x + btn.width and y >= btn.y and y <= btn.y + btn.height then
            local count = 0
            for i = #player.inventory, 1, -1 do
                local item = player.inventory[i]
                if (btn.rarity == "ALL") or (item.rarity == btn.rarity) then
                    -- Unequip if equipped
                    if player.equipment[item.type] == item then
                        player:unequipItem(item.type)
                    end
                    table.remove(player.inventory, i)
                    count = count + 1
                end
            end
            local rarityText = btn.rarity == "ALL" and "items" or btn.rarity .. " items"
            print("Deleted " .. count .. " " .. rarityText)
            return true
        end
    end
    
    -- Items in grid
    for i = 1, 12 do
        local itemIndex = i + self.scrollOffset
        if itemIndex > #filteredItems then break end
        
        local itemX = 520 + ((i-1) % 3) * 100
        local itemY = 180 + math.floor((i-1) / 3) * 100
        
        local item = filteredItems[itemIndex]
        
        -- Click on "On/Off" button
        if x >= itemX and x <= itemX + 40 and y >= itemY + 85 and y <= itemY + 105 then
            if player.equipment[item.type] == item then
                -- Unequip and return to inventory
                player:unequipItem(item.type)
                if not self:playerHasItem(player, item) then
                    table.insert(player.inventory, item)
                end
            else
                -- Equip (item stays in inventory but is marked as equipped)
                player:equipItem(item)
            end
            return true
        end
        
        -- Click on "Delete" button
        if x >= itemX + 42 and x <= itemX + 80 and y >= itemY + 85 and y <= itemY + 105 then
            -- Remove from inventory
            for j = #player.inventory, 1, -1 do
                if player.inventory[j] == item then
                    table.remove(player.inventory, j)
                    -- Unequip if equipped
                    if player.equipment[item.type] == item then
                        player:unequipItem(item.type)
                    end
                    break
                end
            end
            return true
        end
    end
    
    return false
end