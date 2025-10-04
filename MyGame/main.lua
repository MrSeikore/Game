function love.load()
    print("=== RPG GAME ===")
    
    -- Load core modules
    require('src/core/Constants')
    require('src/core/Utils')
    require('src/core/GameState')
    
    -- Load entities
    require('src/entities/Player')
    require('src/entities/Monster')
    require('src/entities/Item')
    
    -- Load systems and scenes
    require('src/systems/InventorySystem')
    require('src/scenes/GameScene')
    require('src/scenes/InventoryScene')
    
    -- Initialize game state with scenes
    GameState:initialize()
    
    print("Game fully loaded")
end

function love.update(dt)
    GameState:update(dt)
end

function love.draw()
    GameState:draw()
end

function love.keypressed(key)
    GameState:keypressed(key)
end

function love.mousepressed(x, y, button)
    GameState:mousepressed(x, y, button)
end

function love.mousemoved(x, y, dx, dy)
    GameState:mousemoved(x, y, dx, dy)
end