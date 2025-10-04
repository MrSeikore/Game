GameState = {
    currentScene = nil,
    scenes = {},
    player = nil
}

function GameState:initialize()
    print("Initializing GameState...")
    
    -- Load data first
    require('src/data/Affixes')
    
    -- Create player
    self.player = Player:new()
    
    -- Initialize scenes
    self.scenes = {
        game = GameScene:new(),
        inventory = InventoryScene:new()
    }
    
    -- Start with game scene
    self.currentScene = self.scenes.game
    if self.currentScene.onEnter then
        self.currentScene:onEnter()
    end
    
    print("GameState initialized")
end

function GameState:update(dt)
    -- Always update game scene
    if self.scenes.game then
        self.scenes.game:update(dt)
    end
    
    -- Always update inventory (it's always visible now)
    if self.scenes.inventory then
        self.scenes.inventory:update(dt)
    end
end

function GameState:draw()
    -- Always draw game scene first
    if self.scenes.game then
        self.scenes.game:draw()
    end
    
    -- Always draw inventory on top
    if self.scenes.inventory then
        self.scenes.inventory:draw()
    end
end

function GameState:keypressed(key)
    -- Pass to current scene
    if self.currentScene then
        self.currentScene:keypressed(key)
    end
end

function GameState:mousepressed(x, y, button)
    -- Check if click is in inventory area (right 300px)
    if x >= 700 and self.scenes.inventory then
        self.scenes.inventory:mousepressed(x, y, button)
    else
        -- Pass to game scene
        if self.scenes.game then
            self.scenes.game:mousepressed(x, y, button)
        end
    end
end

function GameState:mousemoved(x, y, dx, dy)
    -- Update both scenes
    if self.scenes.game then
        self.scenes.game:mousemoved(x, y, dx, dy)
    end
    if self.scenes.inventory then
        self.scenes.inventory:mousemoved(x, y, dx, dy)
    end
end

function GameState:saveProgress()
    -- Save game progress
end

function GameState:loadProgress()
    -- Load game progress
end