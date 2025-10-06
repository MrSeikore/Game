function love.conf(t)
    t.window.title = "RPG Game"
    t.window.width = 1000
    t.window.height = 700
    t.window.resizable = false
end

local debugLog = {}
local debugScrollOffset = 0
local maxDebugLines = 15
local showDebug = false
local networkInitialized = falses

function love.load()
    -- Переопределяем print для отображения в игре
    local originalPrint = print
    print = function(...)
        originalPrint(...)
        local message = table.concat({...}, " ")
        table.insert(debugLog, message)
        if #debugLog > 50 then
            table.remove(debugLog, 1)
        end
    end
    
    print("=== RPG ONLINE GAME ===")
    print("Initializing game systems...")
    
    -- Load core modules first
    require('src/core/Constants')
    require('src/core/Utils')
    require('src/core/Display')
    require('src/core/GameState')
    
    -- Load base scene class
    require('src/scenes/Scene')
    
    -- Load new item system with tiers
    require('src/data/items/ItemBase')
    require('src/data/items/RaritySystem')
    require('src/data/items/AffixSystem')
    require('src/data/items/ItemFactory')
    require('src/data/items/TierSystem')
    require('src/data/items/TierRollSystem')
    
    -- Load modifiers
    require('src/data/items/modifiers/StatModifiers')
    require('src/data/items/modifiers/EffectModifiers')
    
    -- Load entities
    require('src/entities/Player')
    require('src/entities/Monster')
    require('src/entities/Boss')
    require('src/entities/Item')
    
    -- Load systems and scenes
    require('src/systems/DropChanceSystem')
    require('src/systems/SaveSystem')
    require('src/scenes/GameScene')
    require('src/scenes/InventoryScene')
    require('src/scenes/StatsScene')
    
    -- Initialize display first
    Display:initialize()
    
    -- Initialize base game state
    GameState:initialize()
    
    -- Initialize all systems
    require('src/core/GameInitializer')
    GameInitializer:initializeAll()
    
    -- Initialize Network Manager (обязательно для онлайн игры)
    require('NetworkManager')
    require('config')  -- Добавляем конфиг

    NetworkManager:initialize()

    -- Автоматическое подключение к серверу
    print("Searching for game server...")
    local connected = false
    local servers = Config:discoverServer()

    for i, serverUrl in ipairs(servers) do
        print("Trying: " .. serverUrl)
        local connectSuccess = pcall(function()
            NetworkManager:connect(serverUrl)
            networkInitialized = true
            if NetworkManager.connected then
                connected = true
                print("✓ Connected to: " .. serverUrl)
            end
        end)

        if connected then break end
    end

    if not connected then
        print("❌ ERROR: Could not connect to any game server!")
        print("Please ensure the server is running")
        NetworkManager.connected = false
        networkInitialized = true
    end
    
    print("Game fully loaded")
    print("Controls: T - Toggle Stats, ` - Toggle Debug")
    print("Network: " .. (NetworkManager.connected and "ONLINE" or "DISCONNECTED"))
end

function love.update(dt)
    -- Update game state
    GameState:update(dt)
    
    -- Update network (если инициализирован)
    if networkInitialized and NetworkManager.update then
        NetworkManager:update(dt)
    end
    
    -- Steamworks integration placeholder (для будущей интеграции)
    updateSteamworks(dt)
end

function love.draw()
    -- Apply scaling
    love.graphics.push()
    love.graphics.translate(Display.offsetX, Display.offsetY)
    love.graphics.scale(Display.scale, Display.scale)
    
    -- Draw game content
    GameState:draw()
    
    -- Draw other players (если в онлайн режиме)
    if networkInitialized and NetworkManager.drawOtherPlayers then
        NetworkManager:drawOtherPlayers()
    end
    
    -- Draw Steam overlay info
    drawSteamOverlay()
    
    -- Draw debug logs
    if showDebug then
        drawDebugLogs()
    end
    
    love.graphics.pop()
end

function love.wheelmoved(x, y)
    -- Получаем позицию мыши
    local mouseX, mouseY = love.mouse.getPosition()
    
    -- Скроллинг логов отладки (только если дебаг открыт и мышка над логами)
    if showDebug then
        if mouseX >= 5 and mouseX <= 605 and mouseY >= 5 and mouseY <= 285 then
            if y ~= 0 then
                local maxScroll = math.max(0, #debugLog - maxDebugLines)
                debugScrollOffset = math.max(0, math.min(maxScroll, debugScrollOffset - y * 3))
                return
            end
        end
    end
    
    -- Обработка колесика для инвентаря и статистики
    if y ~= 0 then
        local baseX = Display:inverseScaleX(mouseX)
        local baseY = Display:inverseScaleY(mouseY)
        
        -- Обработка колесика для статистики (только если открыта и мышка в правой области)
        if GameState.showStats and baseX >= 700 then
            if GameState.scenes.stats then
                GameState.scenes.stats:handleWheel(baseX, baseY, x, y)
            end
        -- Обработка колесика для инвентаря (только если мышка в правой области)
        elseif baseX >= 700 and GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
            GameState.scenes.inventory.inventorySystem:handleWheel(baseX, baseY, x, y)
        end
    end
end

function love.keypressed(key)
    -- Добавляем переключение дебага на тильду (`) или ё
    if key == "`" or key == "ё" then
        showDebug = not showDebug
        print("Debug " .. (showDebug and "enabled" or "disabled"))
    end
    
    -- Steam overlay activation (placeholder)
    if key == "f1" then
        activateSteamOverlay()
    end
    
    GameState:keypressed(key)
end

function love.mousepressed(x, y, button)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    if button == 1 then
        GameState:mousepressed(baseX, baseY, button)
    end
end

function love.mousereleased(x, y, button)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    -- Обработка отпускания мыши для статистики
    if GameState.showStats and GameState.scenes.stats then
        GameState.scenes.stats:handleMouseRelease(baseX, baseY, button)
    end
    
    -- Обработка отпускания мыши для инвентаря
    if GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
        GameState.scenes.inventory.inventorySystem:handleMouseRelease(baseX, baseY, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    -- Обработка drag для статистики
    if GameState.showStats and GameState.scenes.stats then
        GameState.scenes.stats:handleMouseDrag(baseX, baseY, dx, dy)
    end
    
    -- Обработка drag для инвентаря
    if love.mouse.isDown(1) and GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
        GameState.scenes.inventory.inventorySystem:handleMouseDrag(baseX, baseY, dx, dy)
    end
    
    GameState:mousemoved(baseX, baseY, dx, dy)
end

function love.resize(width, height)
    Display:initialize()
end

function love.quit()
    -- Save game before quitting
    if GameState.saveSystem then
        GameState.saveSystem:saveGame()
    end
    
    -- Network cleanup
    if networkInitialized and NetworkManager.disconnect then
        NetworkManager:disconnect()
    end
    
    -- Steamworks shutdown
    shutdownSteamworks()
    
    print("Game saved and shutdown complete")
    return false
end

-- Steamworks integration functions (заглушки для будущей реализации)
function updateSteamworks(dt)
    -- Будет обновлять Steamworks API
    -- if steamworks then
    --     steamworks.runCallbacks()
    -- end
end

function drawSteamOverlay()
    -- Показываем что миры изолированы
    love.graphics.setColor(0.8, 0.8, 0.2)  -- Желтый для изолированных миров
    love.graphics.print("ISOLATED INSTANCE", 10, Display.baseHeight - 30)
    
    -- Player count (только информационно)
    love.graphics.setColor(1, 1, 1)
    local playerCount = NetworkManager.connected and NetworkManager:getPlayerCount() or 1
    love.graphics.print("Visible: " .. playerCount .. " players", 150, Display.baseHeight - 30)
    
    -- Информация о нашем мире
    love.graphics.print("Your World: " .. (NetworkManager.instanceId or "local"), 300, Display.baseHeight - 30)
end

function activateSteamOverlay()
    -- Активирует Steam Overlay
    print("Steam Overlay activated (placeholder)")
    -- if steamworks then
    --     steamworks.activateOverlay("friends")
    -- end
end

function shutdownSteamworks()
    -- Завершает работу Steamworks
    print("Steamworks shutdown (placeholder)")
    -- if steamworks then
    --     steamworks.shutdown()
    -- end
end

function drawDebugLogs()
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 5, 5, 600, 280)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("DEBUG LOGS (Scroll with mouse wheel):", 10, 10)
    
    local startIndex = math.max(1, #debugLog - maxDebugLines - debugScrollOffset + 1)
    local endIndex = math.min(#debugLog, startIndex + maxDebugLines - 1)
    
    for i = startIndex, endIndex do
        local logIndex = i
        local displayIndex = i - startIndex + 1
        love.graphics.print(debugLog[logIndex], 10, 30 + (displayIndex-1) * 16)
    end
    
    -- Показываем индикатор скролла
    if #debugLog > maxDebugLines then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Scroll: " .. debugScrollOffset .. "/" .. (#debugLog - maxDebugLines), 10, 265)
    end
    
    -- Network status
    love.graphics.setColor(NetworkManager.connected and {0, 1, 0} or {1, 0, 0})
    love.graphics.print("NETWORK: " .. (NetworkManager.connected and "CONNECTED" or "DISCONNECTED"), 400, 265)
end

-- Steam Achievement placeholder functions
function unlockAchievement(achievementId)
    print("Achievement unlocked: " .. achievementId)
    -- if steamworks then
    --     steamworks.unlockAchievement(achievementId)
    -- end
end

function setStat(statId, value)
    print("Stat updated: " .. statId .. " = " .. value)
    -- if steamworks then
    --     steamworks.setStat(statId, value)
    --     steamworks.storeStats()
    -- end
end