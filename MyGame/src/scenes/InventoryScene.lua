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
    self.inventorySystem.visible = true
    print("Entered inventory scene")
end

function InventoryScene:onExit()
    self.inventorySystem.visible = false
    self.inventorySystem.selectedItem = nil
    print("Exited inventory scene")
end

function InventoryScene:update(dt)
    -- Update inventory system if needed
end

function InventoryScene:draw()
    self.inventorySystem:draw(GameState.player)
end

function InventoryScene:keypressed(key)
    if key == "i" or key == "escape" then
        GameState:switchScene('game')
    end
end

function InventoryScene:mousepressed(x, y, button)
    if button == 1 then
        self.inventorySystem:handleClick(x, y, GameState.player)
    end
end

function InventoryScene:mousemoved(x, y, dx, dy)
    self.inventorySystem:updateMouse(x, y, GameState.player)
end