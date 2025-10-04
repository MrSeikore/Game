function love.load()
    print("=== RPG GAME ===")
    
    -- Load core modules
    require('src/core/Constants')
    require('src/core/Utils')
    require('src/core/Display')
    require('src/core/GameState')
    
    -- Load data modules
    require('src/data/Affixes')
    
    -- Load entities
    require('src/entities/Player')
    require('src/entities/Monster')
    require('src/entities/Item')
    
    -- Load systems and scenes
    require('src/systems/InventorySystem')
    require('src/scenes/GameScene')
    require('src/scenes/InventoryScene')
    
    -- Initialize display first
    Display:initialize()
    
    -- Initialize game state
    GameState:initialize()
    
    print("Game fully loaded")
end

function love.update(dt)
    GameState:update(dt)
end

function love.draw()
    -- Apply scaling
    love.graphics.push()
    love.graphics.translate(Display.offsetX, Display.offsetY)
    love.graphics.scale(Display.scale, Display.scale)
    
    GameState:draw()
    
    love.graphics.pop()
end

function love.keypressed(key)
    GameState:keypressed(key)
end

function love.mousepressed(x, y, button)
    -- Convert scaled coordinates back to base coordinates
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    GameState:mousepressed(baseX, baseY, button)
end

function love.mousemoved(x, y, dx, dy)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    GameState:mousemoved(baseX, baseY, dx, dy)
end

function love.resize(width, height)
    Display:initialize()
end