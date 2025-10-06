InventoryScroll = {
    isDraggingScroll = false,
    dragStartY = 0,
    dragStartOffset = 0,
    scrollSensitivity = 0.8
}

function InventoryScroll:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function InventoryScroll:updateMouse(x, y, player, system)
    local grid = Display.INVENTORY.INVENTORY_GRID
    local filteredItems = system:getFilteredItems(player.inventory)
    local visibleSlots = grid.COLUMNS * grid.ROWS
    
    if #filteredItems > visibleSlots then
        local scrollX = grid.x + grid.COLUMNS * grid.CELL_SIZE + 5
        local scrollY = grid.y + 80
        local scrollHeight = grid.ROWS * grid.CELL_SIZE
        
        -- Check scroll thumb
        local totalItems = #filteredItems
        local thumbHeight = math.max(20, (visibleSlots / totalItems) * scrollHeight)
        local maxScrollOffset = math.max(0, totalItems - visibleSlots)
        local thumbPosition = 0
        
        if maxScrollOffset > 0 then
            thumbPosition = (system.scrollOffset / maxScrollOffset) * (scrollHeight - thumbHeight)
        end
        
        if system:isMouseInRect(scrollX, scrollY + thumbPosition, 15, thumbHeight) then
            system.hoveredElement = "scroll_thumb"
            return
        end
        
        -- Check scroll up button
        if system:isMouseInRect(scrollX, scrollY - 20, 15, 15) then
            system.hoveredElement = "scroll_up"
            return
        end
        
        -- Check scroll down button
        if system:isMouseInRect(scrollX, scrollY + scrollHeight + 5, 15, 15) then
            system.hoveredElement = "scroll_down"
            return
        end
    end
end

function InventoryScroll:handleClick(x, y, button, player, system)
    if button == 1 then
        local grid = Display.INVENTORY.INVENTORY_GRID
        local filteredItems = system:getFilteredItems(player.inventory)
        local visibleSlots = grid.COLUMNS * grid.ROWS
        
        if #filteredItems > visibleSlots then
            local scrollX = grid.x + grid.COLUMNS * grid.CELL_SIZE + 5
            local scrollY = grid.y + 80
            local scrollHeight = grid.ROWS * grid.CELL_SIZE
            
            -- Check scroll up button
            if system:isMouseInRect(scrollX, scrollY - 20, 15, 15) then
                if system.scrollOffset > 0 then
                    system.scrollOffset = system.scrollOffset - 1
                    print("Scrolled up to " .. (system.scrollOffset + 1) .. "-" .. 
                          math.min(system.scrollOffset + visibleSlots, #filteredItems))
                end
                return true
            end
            
            -- Check scroll down button
            if system:isMouseInRect(scrollX, scrollY + scrollHeight + 5, 15, 15) then
                if system.scrollOffset < #filteredItems - visibleSlots then
                    system.scrollOffset = system.scrollOffset + 1
                    print("Scrolled down to " .. (system.scrollOffset + 1) .. "-" .. 
                          math.min(system.scrollOffset + visibleSlots, #filteredItems))
                end
                return true
            end
            
            -- Check scroll thumb for drag start
            local totalItems = #filteredItems
            local thumbHeight = math.max(20, (visibleSlots / totalItems) * scrollHeight)
            local maxScrollOffset = math.max(0, totalItems - visibleSlots)
            local thumbPosition = 0
            
            if maxScrollOffset > 0 then
                thumbPosition = (system.scrollOffset / maxScrollOffset) * (scrollHeight - thumbHeight)
            end
            
            if system:isMouseInRect(scrollX, scrollY + thumbPosition, 15, thumbHeight) then
                self.isDraggingScroll = true
                self.dragStartY = y
                self.dragStartOffset = system.scrollOffset
                print("Started scrolling drag")
                return true
            end
        end
    end
    
    return false
end

function InventoryScroll:handleMouseRelease(x, y, button)
    if button == 1 then
        if self.isDraggingScroll then
            print("Stopped scrolling drag")
            self.isDraggingScroll = false
        end
    end
end

function InventoryScroll:handleMouseDrag(x, y, dx, dy, system)
    if self.isDraggingScroll then
        local grid = Display.INVENTORY.INVENTORY_GRID
        local player = GameState.player
        if not player then return end
        
        local filteredItems = system:getFilteredItems(player.inventory)
        local visibleSlots = grid.COLUMNS * grid.ROWS
        
        if #filteredItems > visibleSlots then
            local scrollHeight = grid.ROWS * grid.CELL_SIZE
            local maxScrollOffset = math.max(0, #filteredItems - visibleSlots)
            local dragDelta = y - self.dragStartY
            
            -- Улучшенный расчет скролла
            if maxScrollOffset > 0 then
                local scrollPercent = dragDelta / scrollHeight
                local scrollDelta = math.floor(scrollPercent * maxScrollOffset)
                local newOffset = math.max(0, math.min(maxScrollOffset, self.dragStartOffset + scrollDelta))
                
                if newOffset ~= system.scrollOffset then
                    system.scrollOffset = newOffset
                end
            end
        end
    end
end

function InventoryScroll:handleWheel(x, y, dx, dy, system)
    local player = GameState.player
    if not player then return false end
    
    local grid = Display.INVENTORY.INVENTORY_GRID
    local filteredItems = system:getFilteredItems(player.inventory)
    local visibleSlots = grid.COLUMNS * grid.ROWS
    
    if #filteredItems > visibleSlots then
        local maxScrollOffset = #filteredItems - visibleSlots
        
        -- Плавный скролл колесиком
        local scrollAmount = math.max(1, math.floor(visibleSlots / 2))
        if dy > 0 then -- Scroll up
            local newOffset = math.max(0, system.scrollOffset - scrollAmount)
            if newOffset ~= system.scrollOffset then
                system.scrollOffset = newOffset
                print("Mouse wheel scrolled up to " .. (system.scrollOffset + 1) .. "-" .. 
                      math.min(system.scrollOffset + visibleSlots, #filteredItems))
                return true
            end
        elseif dy < 0 then -- Scroll down
            local newOffset = math.min(maxScrollOffset, system.scrollOffset + scrollAmount)
            if newOffset ~= system.scrollOffset then
                system.scrollOffset = newOffset
                print("Mouse wheel scrolled down to " .. (system.scrollOffset + 1) .. "-" .. 
                      math.min(system.scrollOffset + visibleSlots, #filteredItems))
                return true
            end
        end
    end
    return false
end

return InventoryScroll