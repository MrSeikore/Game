InventoryFilters = {}

function InventoryFilters:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventoryFilters:updateMouse(x, y, system)
    local header = Display.INVENTORY.INVENTORY_HEADER
    
    -- Check filters - правильные координаты
    for i = 1, 4 do
        local btnX = header.x + (i-1) * 70
        local btnY = header.y + 15  -- Исправлено с 100 на 15
        if system:isMouseInRect(btnX, btnY, 65, 18) then
            system.hoveredElement = "filter_" .. i
            return
        end
    end
end

function InventoryFilters:handleClick(x, y, button, system)
    if button == 1 then
        local header = Display.INVENTORY.INVENTORY_HEADER
        
        -- Check filters - правильные координаты
        for i = 1, 4 do
            local btnX = header.x + (i-1) * 70
            local btnY = header.y + 15  -- Исправлено с 100 на 15
            if system:isMouseInRect(btnX, btnY, 65, 18) then
                if i == 1 then system.itemTypeFilter = nil
                elseif i == 2 then system.itemTypeFilter = "weapon"
                elseif i == 3 then system.itemTypeFilter = "helmet"
                elseif i == 4 then system.itemTypeFilter = "armor" end
                
                system.scrollOffset = 0
                print("Filter set to: " .. (system.itemTypeFilter or "All"))
                return true
            end
        end
    end
    
    return false
end

function InventoryFilters:getFilteredItems(inventory, itemTypeFilter)
    local filtered = {}
    for _, item in ipairs(inventory) do
        if item and (not itemTypeFilter or item.type == itemTypeFilter) then
            table.insert(filtered, item)
        end
    end
    return filtered
end

return InventoryFilters