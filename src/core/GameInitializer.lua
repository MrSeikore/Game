GameInitializer = {}

function GameInitializer:initializeAll()
    print("Initializing all game systems...")
    
    -- Load serpent library for serialization
    local serpentSuccess, serpent = pcall(require, 'src/lib/serpent')
    if serpentSuccess then
        _G.serpent = serpent
        print("Serpent library loaded successfully")
    else
        print("WARNING: Failed to load serpent library: " .. tostring(serpent))
    end
    
    -- Load data first
    local affixesSuccess = pcall(require, 'src/data/Affixes')
    if affixesSuccess then
        print("Affixes loaded successfully")
    else
        print("WARNING: Failed to load Affixes")
    end
    
    -- Create player
    GameState.player = Player:new()
    print("Player created: " .. tostring(GameState.player))
    
    -- Initialize scenes
    print("Initializing game scenes...")
    local gameSceneSuccess, gameScene = pcall(function() return GameScene:new() end)
    local inventorySceneSuccess, inventoryScene = pcall(function() return InventoryScene:new() end)
    local statsSceneSuccess, statsScene = pcall(function() return StatsScene:new() end)
    
    if gameSceneSuccess and gameScene then
        GameState.scenes.game = gameScene
        print("GameScene initialized successfully")
    else
        print("ERROR: Failed to initialize GameScene: " .. tostring(gameScene))
    end
    
    if inventorySceneSuccess and inventoryScene then
        GameState.scenes.inventory = inventoryScene
        print("InventoryScene initialized successfully")
    else
        print("ERROR: Failed to initialize InventoryScene: " .. tostring(inventoryScene))
    end
    
    if statsSceneSuccess and statsScene then
        GameState.scenes.stats = statsScene
        print("StatsScene initialized successfully")
    else
        print("ERROR: Failed to initialize StatsScene: " .. tostring(statsScene))
    end
    
    -- Initialize systems
    print("Initializing game systems...")
    local dropChanceSuccess, dropChanceSystem = pcall(function() return DropChanceSystem:new() end)
    local saveSystemSuccess, saveSystem = pcall(function() return SaveSystem:new() end)
    
    if dropChanceSuccess and dropChanceSystem then
        GameState.dropChanceSystem = dropChanceSystem
        print("DropChanceSystem initialized successfully")
    else
        print("ERROR: Failed to initialize DropChanceSystem: " .. tostring(dropChanceSystem))
    end
    
    if saveSystemSuccess and saveSystem then
        GameState.saveSystem = saveSystem
        print("SaveSystem initialized successfully")
    else
        print("ERROR: Failed to initialize SaveSystem: " .. tostring(saveSystem))
    end
    
    -- Start with game scene
    if GameState.scenes.game then
        GameState.currentScene = GameState.scenes.game
        if GameState.currentScene.onEnter then
            GameState.currentScene:onEnter()
        end
        print("Game scene set as current")
    else
        print("ERROR: No game scene available to set as current")
    end
    
    print("All game systems initialization completed")
end