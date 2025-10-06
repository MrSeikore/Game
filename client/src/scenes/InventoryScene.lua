InventoryScene = {
    name = "inventory",
    inventorySystem = nil
}

function InventoryScene:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    
    print("Creating InventoryScene...")
    
    -- Простая загрузка
    local success, system = pcall(function()
        return require('src/systems/inventory/InventorySystem'):new()
    end)
    
    if success then
        o.inventorySystem = system
        print("✓ InventorySystem loaded in scene")
    else
        print("✗ InventorySystem failed: " .. tostring(system))
        o.inventorySystem = {
            draw = function(player) 
                love.graphics.setColor(1, 0, 0)
                love.graphics.print("FALLBACK SYSTEM", 710, 50)
            end
        }
    end
    
    return o
end

function InventoryScene:draw()
    if GameState.player and self.inventorySystem then
        self.inventorySystem:draw(GameState.player)
    end
end

function InventoryScene:mousepressed(x, y, button)
    if button == 1 and GameState.player and self.inventorySystem then
        self.inventorySystem:handleClick(x, y, button, GameState.player)
    end
end

function InventoryScene:mousemoved(x, y, dx, dy)
    if GameState.player and self.inventorySystem then
        self.inventorySystem:updateMouse(x, y, GameState.player)
    end
end

function InventoryScene:onEnter() end
function InventoryScene:onExit() end
function InventoryScene:update(dt) end
function InventoryScene:keypressed(key) end