InventoryInteraction = {}

function InventoryInteraction:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventoryInteraction:updateMouse(x, y, player, system)
    local inv = Display.INVENTORY
    
    -- Check equipment slots
    local eq = inv.EQUIPMENT
    local slots = {
        {type = "weapon", row = 0, col = 0},
        {type = "helmet", row = 0, col = 1},
        {type = "armor", row = 1, col = 0}
    }
    
    for _, slot in ipairs(slots) do
        local slotX = eq.x + slot.col * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        local slotY = eq.y + 110 + slot.row * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
        
        if system:isMouseInRect(slotX, slotY, eq.SLOT_SIZE, eq.SLOT_SIZE) then
            system.selectedItem = player.equipment[slot.type]
            system.hoveredElement = "equipment_" .. slot.type
            return
        end
    end
    
    -- Check inventory items
    local grid = inv.INVENTORY_GRID
    local filteredItems = system:getFilteredItems(player.inventory)
    local visibleSlots = grid.COLUMNS * grid.ROWS
    
    for i = 1, visibleSlots do
        local itemIndex = i + system.scrollOffset
        if itemIndex > #filteredItems then break end
        
        local col = (i-1) % grid.COLUMNS
        local row = math.floor((i-1) / grid.COLUMNS)
        local itemX = grid.x + col * grid.CELL_SIZE
        local itemY = grid.y + 80 + row * grid.CELL_SIZE
        
        if system:isMouseInRect(itemX, itemY, grid.CELL_SIZE, grid.CELL_SIZE) then
            local item = filteredItems[itemIndex]
            if item then
                system.selectedItem = item
                system.hoveredElement = "inventory_" .. itemIndex
            end
            return
        end
    end
    
    -- Check filter buttons
    local header = inv.INVENTORY_HEADER
    for i = 1, 4 do
        local btnX = header.x + (i-1) * 70
        local btnY = header.y + 100
        if system:isMouseInRect(btnX, btnY, 65, 18) then
            system.hoveredElement = "filter_" .. i
            return
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
        local btnX = bulk.x + col * 75
        local btnY = bulk.y + 100 + row * 30
        
        if system:isMouseInRect(btnX, btnY, 70, 22) then
            system.hoveredElement = "bulk_" .. i
            return
        end
    end
end

function InventoryInteraction:handleClick(x, y, button, player, system)
    if button == 1 then
        local inv = Display.INVENTORY
        
        -- Check equipment slots for unequip
        local eq = inv.EQUIPMENT
        local slots = {
            {type = "weapon", row = 0, col = 0},
            {type = "helmet", row = 0, col = 1},
            {type = "armor", row = 1, col = 0}
        }
        
        for _, slot in ipairs(slots) do
            local slotX = eq.x + slot.col * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
            local slotY = eq.y + 110 + slot.row * (eq.SLOT_SIZE + eq.SLOT_MARGIN)
            
            if system:isMouseInRect(slotX, slotY, eq.SLOT_SIZE, eq.SLOT_SIZE) then
                if player.equipment[slot.type] then
                    local unequippedItem = player:unequipItem(slot.type)
                    if unequippedItem then
                        print("Unequipped: " .. unequippedItem.name .. " from " .. slot.type)
                    end
                end
                return true
            end
        end
        
        -- Check inventory items for equip/unequip
        local grid = inv.INVENTORY_GRID
        local filteredItems = system:getFilteredItems(player.inventory)
        local visibleSlots = grid.COLUMNS * grid.ROWS
        
        for i = 1, visibleSlots do
            local itemIndex = i + system.scrollOffset
            if itemIndex > #filteredItems then break end
            
            local col = (i-1) % grid.COLUMNS
            local row = math.floor((i-1) / grid.COLUMNS)
            local itemX = grid.x + col * grid.CELL_SIZE
            local itemY = grid.y + 80 + row * grid.CELL_SIZE
            
            if system:isMouseInRect(itemX, itemY, grid.CELL_SIZE, grid.CELL_SIZE) then
                local item = filteredItems[itemIndex]
                if item then
                    if player.equipment[item.type] == item then
                        -- Item is equipped - unequip it
                        local unequippedItem = player:unequipItem(item.type)
                        if unequippedItem then
                            print("Unequipped: " .. unequippedItem.name)
                        end
                    else
                        -- Item is not equipped - equip it
                        local oldItem = player:equipItem(item)
                        if oldItem then
                            print("Equipped: " .. item.name .. " (replaced: " .. oldItem.name .. ")")
                        else
                            print("Equipped: " .. item.name)
                        end
                    end
                end
                return true
            end
        end
        
        -- Check filter buttons
        local header = inv.INVENTORY_HEADER
        for i = 1, 4 do
            local btnX = header.x + (i-1) * 70
            local btnY = header.y + 100
            if system:isMouseInRect(btnX, btnY, 65, 18) then
                if i == 1 then 
                    system.itemTypeFilter = nil
                    print("Filter: All items")
                elseif i == 2 then 
                    system.itemTypeFilter = "weapon"
                    print("Filter: Weapons only")
                elseif i == 3 then 
                    system.itemTypeFilter = "helmet"
                    print("Filter: Helmets only")
                elseif i == 4 then 
                    system.itemTypeFilter = "armor"
                    print("Filter: Armor only")
                end
                
                system.scrollOffset = 0
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
            local btnX = bulk.x + col * 75
            local btnY = bulk.y + 100 + row * 30
            
            if system:isMouseInRect(btnX, btnY, 70, 22) then
                local count = 0
                local deletedItems = {}
                
                for j = #player.inventory, 1, -1 do
                    local item = player.inventory[j]
                    if item and player.equipment[item.type] ~= item then
                        local shouldDelete = false
                        
                        if btn.rarity == "ALL" then
                            shouldDelete = true
                        elseif item.rarity == btn.rarity then
                            shouldDelete = true
                        end
                        
                        if shouldDelete then
                            table.insert(deletedItems, item.name)
                            table.remove(player.inventory, j)
                            count = count + 1
                        end
                    end
                end
                
                local rarityText = btn.rarity == "ALL" and "all items" .. (count > 0 and " (" .. table.concat(deletedItems, ", ") .. ")" or "") or btn.rarity .. " items"
                print("Deleted " .. count .. " " .. rarityText .. " from inventory")
                return true
            end
        end
    end
    
    return false
end

return InventoryInteraction