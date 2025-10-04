InventoryScene = {
    name = "inventory",
    inventorySystem = nil
}

function InventoryScene:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.inventorySystem = InventorySystem:new()
    return o
end

function InventoryScene:onEnter()
end

function InventoryScene:onExit()
end

function InventoryScene:update(dt)
    -- Inventory updates if needed
end

function InventoryScene:draw()
    -- Always draw inventory
    self.inventorySystem:draw(GameState.player)
end

function InventoryScene:keypressed(key)
    -- Inventory key handling
end

function InventoryScene:mousepressed(x, y, button)
    if button == 1 then
        self.inventorySystem:handleClick(x, y, GameState.player)
    end
end

function InventoryScene:mousemoved(x, y, dx, dy)
    self.inventorySystem:updateMouse(x, y, GameState.player)
end