GameState = {
    currentScene = nil,
    scenes = {},
    player = nil
}

function GameState:initialize()
    print("Initializing GameState...")
    
    -- Create player first
    self.player = Player:new()
    
    -- Initialize scenes
    self.scenes = {
        game = GameScene:new(),
        inventory = InventoryScene:new()
    }
    
    -- Start with game scene
    self:switchScene('game')
    
    print("GameState initialized")
end

function GameState:switchScene(sceneName)
    if self.currentScene then
        self.currentScene:onExit()
    end
    
    self.currentScene = self.scenes[sceneName]
    
    if self.currentScene then
        self.currentScene:onEnter()
        print("Switched to scene: " .. sceneName)
    end
end

function GameState:update(dt)
    if self.currentScene then
        self.currentScene:update(dt)
    end
end

function GameState:draw()
    if self.currentScene then
        self.currentScene:draw()
    end
end

function GameState:keypressed(key)
    if self.currentScene then
        self.currentScene:keypressed(key)
    end
end

function GameState:mousepressed(x, y, button)
    if self.currentScene then
        self.currentScene:mousepressed(x, y, button)
    end
end

function GameState:mousemoved(x, y, dx, dy)
    if self.currentScene then
        self.currentScene:mousemoved(x, y, dx, dy)
    end
end

-- Save/load system
function GameState:saveProgress()
    -- Implementation for saving game progress
end

function GameState:loadProgress()
    -- Implementation for loading game progress
end