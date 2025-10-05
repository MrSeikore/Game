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
    
    print("Initializing InventorySystem with modules...")
    
    -- Загружаем модули
    local rendererSuccess, renderer = pcall(function()
        return require('src/systems/inventory/InventoryRenderer'):new()
    end)
    
    local interactionSuccess, interaction = pcall(function()
        return require('src/systems/inventory/InventoryInteraction'):new()
    end)
    
    local scrollSuccess, scroll = pcall(function()
        return require('src/systems/inventory/InventoryScroll'):new()
    end)
    
    local filtersSuccess, filters = pcall(function()
        return require('src/systems/inventory/InventoryFilters'):new()
    end)
    
    if rendererSuccess then
        o.renderer = renderer
        print("✓ Renderer loaded")
    else
        print("✗ Renderer failed: " .. tostring(renderer))
        o.renderer = { draw = function() end }
    end
    
    if interactionSuccess then
        o.interaction = interaction
        print("✓ Interaction loaded")
    else
        print("✗ Interaction failed: " .. tostring(interaction))
        o.interaction = { 
            updateMouse = function() end,
            handleClick = function() return false end 
        }
    end
    
    if scrollSuccess then
        o.scroll = scroll
        print("✓ Scroll loaded")
    else
        print("✗ Scroll failed: " .. tostring(scroll))
        o.scroll = {
            updateMouse = function() end,
            handleClick = function() return false end,
            handleMouseRelease = function() end,
            handleMouseDrag = function() end,
            handleWheel = function() return false end
        }
    end
    
    if filtersSuccess then
        o.filters = filters
        print("✓ Filters loaded")
    else
        print("✗ Filters failed: " .. tostring(filters))
        o.filters = {
            updateMouse = function() end,
            handleClick = function() return false end,
            getFilteredItems = function(inv) return inv end
        }
    end
    
    print("InventorySystem initialized successfully")
    return o
end

function InventorySystem:draw(player)
    if not player then return end
    
    if self.renderer and self.renderer.draw then
        self.renderer:draw(player, self)
    else
        -- Fallback
        love.graphics.setColor(0.1, 0.1, 0.2, 0.95)
        love.graphics.rectangle("fill", 700, 0, 300, Display.baseHeight)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("INVENTORY (Renderer not available)", 710, 50)
    end
end

function InventorySystem:updateMouse(x, y, player)
    if not player then return end
    
    self.mouseX = x
    self.mouseY = y
    self.hoveredElement = nil
    self.selectedItem = nil
    
    if self.scroll then self.scroll:updateMouse(x, y, player, self) end
    if self.filters then self.filters:updateMouse(x, y, self) end
    if self.interaction then self.interaction:updateMouse(x, y, player, self) end
end

function InventorySystem:handleClick(x, y, button, player)
    if not player then return false end
    
    if self.scroll and self.scroll:handleClick(x, y, button, player, self) then return true end
    if self.filters and self.filters:handleClick(x, y, button, self) then return true end
    if self.interaction and self.interaction:handleClick(x, y, button, player, self) then return true end
    
    return false
end

function InventorySystem:handleMouseRelease(x, y, button)
    if self.scroll then self.scroll:handleMouseRelease(x, y, button) end
end

function InventorySystem:handleMouseDrag(x, y, dx, dy)
    if self.scroll then self.scroll:handleMouseDrag(x, y, dx, dy, self) end
end

function InventorySystem:handleWheel(x, y, dx, dy)
    if self.scroll then return self.scroll:handleWheel(x, y, dx, dy, self) end
    return false
end

function InventorySystem:getFilteredItems(inventory)
    if self.filters then return self.filters:getFilteredItems(inventory, self.itemTypeFilter) end
    return inventory
end

function InventorySystem:isMouseInRect(x, y, width, height)
    return self.mouseX >= x and self.mouseX <= x + width and
           self.mouseY >= y and self.mouseY <= y + height
end

return InventorySystem