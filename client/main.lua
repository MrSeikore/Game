function love.load()
    -- Инициализация файлового логгера
    logger = {
        log = function(message)
            local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
            local logMessage = timestamp .. " MAIN: " .. tostring(message)
            print(logMessage)
            
            -- Запись в файл
            local success, file = pcall(love.filesystem.newFile, "game_log.txt", "a")
            if success and file then
                pcall(function()
                    file:open("a")
                    file:write(logMessage .. "\n")
                    file:close()
                end)
            end
        end
    }
    
    logger:log("=== RPG ONLINE GAME ===")
    
    -- Инициализация игровых систем
    logger:log("Initializing game systems...")
    
    -- Загрузка библиотек
    local success, json_lib = pcall(require, "json")
    if success then
        json = json_lib
        logger:log("JSON library loaded")
    else
        json = {
            encode = function(t) return "{}" end,
            decode = function(s) return {} end
        }
        logger:log("❌ JSON library not found, using dummy")
    end
    
    -- Загрузка NetworkManager
    local success, nm = pcall(require, "NetworkManager")
    if success then
        NetworkManager = nm
        NetworkManager:initialize()
        logger:log("NetworkManager initialized")
    else
        logger:log("❌ NetworkManager not found, using offline mode")
        NetworkManager = {
            connected = false,
            isWaitingForNameInput = function() return true end,
            getNameInputText = function() return "" end,
            setNameInputText = function(text) end,
            confirmNameInput = function() end,
            connect = function() return false end
        }
    end
    
    -- Флаг что игра инициализирована
    gameInitialized = false
    
    logger:log("All game systems initialization completed")
end

-- Функция для инициализации игры после успешного логина
function initializeGame()
    if gameInitialized then
        print("[INIT] Game already initialized")
        return true
    end

    print("[INIT] Initializing game after login...")
    print("[INIT] Logger type: " .. type(logger))

    -- Загрузка оригинального GameState
    print("[INIT] Loading GameState...")
    local success, gs = pcall(require, "src/core/GameState")
    if success then
        GameState = gs
        print("[INIT] ✅ Original GameState loaded")
    else
        print("[INIT] ❌ Original GameState not found: " .. tostring(gs))
        return false
    end

    -- Загрузка Player
    print("[INIT] Loading Player...")
    local success, player = pcall(require, "src/entities/Player")
    if success then
        Player = player
        print("[INIT] ✅ Player class loaded")
    else
        print("[INIT] ❌ Player class not found: " .. tostring(player))
        return false
    end

    -- Загрузка базового класса Scene
    print("[INIT] Loading Scene base class...")
    local success, scene = pcall(require, "src/scenes/Scene")
    if success then
        Scene = scene
        print("[INIT] ✅ Scene base class loaded")
    else
        print("[INIT] ❌ Scene base class not found: " .. tostring(scene))
        return false
    end

    -- Загрузка оригинальных сцен
    print("[INIT] Loading game scenes...")

    -- Загрузка GameScene
    print("[INIT] Loading GameScene...")
    local success, gscene = pcall(require, "src/scenes/GameScene")
    if success then
        GameScene = gscene
        print("[INIT] ✅ Original GameScene loaded")
    else
        print("[INIT] ❌ Original GameScene not found: " .. tostring(gscene))
        return false
    end

    -- Загрузка InventoryScene
    print("[INIT] Loading InventoryScene...")
    local success, iscene = pcall(require, "src/scenes/InventoryScene")
    if success then
        InventoryScene = iscene
        print("[INIT] ✅ Original InventoryScene loaded")
    else
        print("[INIT] ❌ Original InventoryScene not found: " .. tostring(iscene))
        -- Не блокируем игру если инвентарь не загрузился
    end

    -- Загрузка StatsScene
    print("[INIT] Loading StatsScene...")
    local success, sscene = pcall(require, "src/scenes/StatsScene")
    if success then
        StatsScene = sscene
        print("[INIT] ✅ Original StatsScene loaded")
    else
        print("[INIT] ❌ Original StatsScene not found: " .. tostring(sscene))
        -- Не блокируем игру если статистика не загрузилась
    end

    -- Инициализация GameState
    print("[INIT] Initializing GameState...")
    if GameState.initialize then
        GameState:initialize()
        print("[INIT] ✅ GameState initialized")
    else
        print("[INIT] ❌ GameState.initialize method not found")
        return false
    end

    -- Создание игрока
    print("[INIT] Creating player...")
    if Player and Player.new then
        GameState.player = Player:new()
        print("[INIT] ✅ Player created")
    else
        print("[INIT] ❌ Cannot create player - Player.new not found")
        return false
    end

    -- Создание сцен
    print("[INIT] Creating scenes...")
    if GameScene and GameScene.new then
        GameState.scenes = GameState.scenes or {}
        GameState.scenes.game = GameScene:new()
        print("[INIT] ✅ GameScene created")
    else
        print("[INIT] ❌ Cannot create GameScene - GameScene.new not found")
        return false
    end

    if InventoryScene and InventoryScene.new then
        GameState.scenes.inventory = InventoryScene:new()
        print("[INIT] ✅ InventoryScene created")
    else
        print("[INIT] ⚠️ Cannot create InventoryScene")
    end

    if StatsScene and StatsScene.new then
        GameState.scenes.stats = StatsScene:new()
        print("[INIT] ✅ StatsScene created")
    else
        print("[INIT] ⚠️ Cannot create StatsScene")
    end

    -- Устанавливаем GameScene как текущую сцену
    print("[INIT] Setting current scene...")
    GameState.currentScene = GameState.scenes.game
    if GameState.currentScene then
        print("[INIT] ✅ Game scene set as current")
    else
        print("[INIT] ❌ Failed to set current scene")
        return false
    end

    gameInitialized = true
    print("[INIT] 🎮 Game initialization completed successfully!")
    return true
end

function love.update(dt)
    -- Проверяем что dt число
    if type(dt) ~= "number" then
        dt = 0.016 -- fallback 60 FPS
    end
    
    -- Если ждем ввод имени, не обновляем игру
    if NetworkManager:isWaitingForNameInput() then
        return
    end
    
    -- Подключаемся к серверу если не подключены
    if not NetworkManager.connected then
        if NetworkManager.connect then
            local success = NetworkManager:connect("ws://localhost:3000")
            if not success then
                logger:log("❌ Connection failed: " .. (NetworkManager.lastError or "unknown error"))
            end
        end
        return
    end
    
    -- Обновляем сеть если подключены (это вызовет receive())
    if NetworkManager.connected and NetworkManager.update then
        NetworkManager:update(dt)
    end
    
    -- Инициализируем игру после получения player_id от сервера
    if not gameInitialized and NetworkManager.connected and NetworkManager.playerId then
        print("🎯 Player ID received, initializing game...")
        if initializeGame() then
            logger:log("✅ Game ready to play!")
        else
            logger:log("❌ Failed to initialize game")
        end
    end
    
    -- Обновляем текущую сцену
    if gameInitialized and GameState and GameState.currentScene and GameState.currentScene.update then
        GameState.currentScene:update(dt)
    end
end

function love.draw()
    -- Если ждем ввод имени, показываем интерфейс ввода
    if NetworkManager:isWaitingForNameInput() then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Enter your character name:", 100, 100)
        love.graphics.print(NetworkManager:getNameInputText(), 100, 130)
        love.graphics.print("Press ENTER to confirm", 100, 160)
        love.graphics.print("Name must be 3-15 characters, English letters/numbers only", 100, 190)
        return
    end
    
    -- Если игра не инициализирована, показываем загрузку
    if not gameInitialized then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        love.graphics.print("Connecting to server...", 100, 100)
        love.graphics.print("Network: " .. (NetworkManager.connected and "ONLINE" or "OFFLINE"), 100, 130)
        love.graphics.print("Status: " .. (NetworkManager.lastError or "Connected, waiting for login response..."), 100, 160)
        love.graphics.print("Player ID: " .. (NetworkManager.playerId or "Not assigned"), 100, 190)
        love.graphics.print("Game Initialized: " .. tostring(gameInitialized), 100, 220)
        love.graphics.print("Initializing game...", 100, 250)
        return
    end
    
    -- Проверяем что GameState и текущая сцена существуют
    if not GameState then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("ERROR: GameState is nil!", 100, 100)
        return
    end
    
    if not GameState.currentScene then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("ERROR: No current scene!", 100, 100)
        return
    end
    
    -- Оригинальная отрисовка игры
    if GameState.currentScene.draw then
        GameState.currentScene:draw()
    else
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.print("ERROR: Scene has no draw method!", 100, 100)
    end
    
    -- Отрисовка сетевого статуса
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Network: " .. (NetworkManager.connected and "ONLINE" or "OFFLINE"), 10, love.graphics.getHeight() - 30)
    love.graphics.print("Player: " .. (NetworkManager.playerName or "Unknown"), 10, love.graphics.getHeight() - 50)
end

function love.textinput(t)
    -- Обработка ввода текста для имени персонажа
    if NetworkManager:isWaitingForNameInput() then
        local current = NetworkManager:getNameInputText()
        
        -- Фильтруем только английские символы, цифры и некоторые спецсимволы
        local allowed = string.match(t, "[%a%d%-_ ]")
        if allowed and #current < 15 then  -- Ограничение длины
            NetworkManager:setNameInputText(current .. allowed)
        end
        return
    end
    
    -- Обычная обработка текстового ввода для игры
    if gameInitialized and GameState.currentScene and GameState.currentScene.textinput then
        GameState.currentScene:textinput(t)
    end
end

function love.keypressed(key)
    -- Обработка ввода имени персонажа
    if NetworkManager:isWaitingForNameInput() then
        if key == "backspace" then
            local current = NetworkManager:getNameInputText()
            NetworkManager:setNameInputText(current:sub(1, -2))
        elseif key == "return" then
            local name = NetworkManager:getNameInputText()
            if #name >= 3 and #name <= 15 then
                if NetworkManager.confirmNameInput then
                    NetworkManager:confirmNameInput()
                end
                logger:log("Character name confirmed: " .. name)
            else
                logger:log("❌ Invalid name length: " .. tostring(#name) .. " characters")
            end
        end
        return
    end
    
    -- Передача клавиши текущей сцене
    if gameInitialized and GameState.currentScene and GameState.currentScene.keypressed then
        GameState.currentScene:keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    -- Безопасная обработка мыши
    if type(x) == "number" and type(y) == "number" then
        if gameInitialized and GameState.currentScene and GameState.currentScene.mousepressed then
            GameState.currentScene:mousepressed(x, y, button)
        end
    end
end

function love.quit()
    -- Отключаемся от сервера
    if NetworkManager.connected and NetworkManager.disconnect then
        NetworkManager:disconnect()
    end
    
    return false
end