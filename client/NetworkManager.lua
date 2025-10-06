NetworkManager = {
    connected = false,
    playerId = nil,
    instanceId = nil,
    isIsolatedInstance = true,
    socket = nil,
    reconnectAttempts = 0,
    maxReconnectAttempts = 5
}

function NetworkManager:initialize()
    print("NetworkManager: Initializing real WebSocket connection...")
    self.connected = false
    self.playerId = "player_" .. tostring(math.random(10000, 99999))
    self.instanceId = self.playerId
    
    -- Загружаем WebSocket библиотеку
    local success, websocket = pcall(require, 'lua-websockets.websocket')
    if success then
        self.websocket = websocket
        print("WebSocket library loaded successfully")
    else
        print("ERROR: Failed to load WebSocket library: " .. tostring(websocket))
        print("Make sure lua-websockets is installed in client folder")
        return
    end
    
    print("NetworkManager: Ready for real WebSocket connection")
end

function NetworkManager:connect(serverUrl)
    print("NetworkManager: Attempting real WebSocket connection to " .. serverUrl)
    
    local connectSuccess, err = pcall(function()
        -- Создаем реальное WebSocket соединение
        self.socket = self.websocket.client.easy(serverUrl)
        
        -- Устанавливаем обработчики событий
        self.socket:on_connect(function()
            print("WebSocket: Connected to server successfully!")
            self.connected = true
            self.reconnectAttempts = 0
            
            -- Отправляем данные игрока при подключении
            self:sendPlayerJoin()
        end)
        
        self.socket:on_message(function(message)
            self:handleIncomingMessage(message)
        end)
        
        self.socket:on_error(function(err)
            print("WebSocket error: " .. tostring(err))
            self.connected = false
        end)
        
        self.socket:on_close(function()
            print("WebSocket: Connection closed")
            self.connected = false
            self:attemptReconnect(serverUrl)
        end)
        
        -- Запускаем соединение
        self.socket:connect()
    end)
    
    if not connectSuccess then
        print("ERROR: WebSocket connection failed: " .. tostring(err))
        self.connected = false
        self:attemptReconnect(serverUrl)
    end
    
    return self.connected
end

function NetworkManager:attemptReconnect(serverUrl)
    if self.reconnectAttempts < self.maxReconnectAttempts then
        self.reconnectAttempts = self.reconnectAttempts + 1
        local delay = math.min(5, self.reconnectAttempts)  -- Максимум 5 секунд задержки
        
        print("Attempting reconnect " .. self.reconnectAttempts .. "/" .. self.maxReconnectAttempts .. " in " .. delay .. "s")
        
        -- Планируем переподключение
        self.reconnectTimer = delay
    else
        print("Max reconnection attempts reached. Please restart the game.")
    end
end

function NetworkManager:update(dt)
    -- Обновляем таймер переподключения
    if self.reconnectTimer and self.reconnectTimer > 0 then
        self.reconnectTimer = self.reconnectTimer - dt
        if self.reconnectTimer <= 0 then
            self:connect("ws://localhost:3000")
            self.reconnectTimer = nil
        end
    end
    
    -- Обрабатываем входящие сообщения если подключены
    if self.connected and self.socket then
        self.socket:dispatch(1)  -- Обрабатываем сообщения с таймаутом 1ms
    end
end

function NetworkManager:sendPlayerJoin()
    if not self.connected or not self.socket then return end
    
    local joinData = {
        type = "player_join",
        playerId = self.playerId,
        playerData = {
            name = "Player_" .. self.playerId:sub(-4),
            level = GameState.player and GameState.player.level or 1,
            hp = GameState.player and GameState.player.hp or 100,
            maxHp = GameState.player and GameState.player.maxHp or 100
        }
    }
    
    self:sendToServer(joinData)
end

function NetworkManager:sendToServer(data)
    if not self.connected or not self.socket then 
        print("Cannot send data - not connected to server")
        return false
    end
    
    local success, err = pcall(function()
        local jsonData = self:serializeToJSON(data)
        self.socket:send(jsonData)
    end)
    
    if not success then
        print("Error sending data to server: " .. tostring(err))
        return false
    end
    
    return true
end

function NetworkManager:handleIncomingMessage(message)
    print("Received message from server: " .. message)
    
    local success, data = pcall(function()
        return self:parseJSON(message)
    end)
    
    if success and data then
        self:handleServerMessage(data)
    else
        print("Error parsing server message: " .. tostring(data))
    end
end

function NetworkManager:handleServerMessage(data)
    if data.type == "player_joined" then
        print("Server confirmed player join: " .. data.playerId)
        self.playerId = data.playerId
        self.instanceId = data.instanceId
        
    elseif data.type == "player_loot" then
        print("Received loot from server: " .. data.item.type)
        self:processLoot(data.item)
        
    elseif data.type == "monster_kill_confirmed" then
        print("Server confirmed monster kill")
        
    elseif data.type == "player_progress_updated" then
        print("Server updated player progress")
        
    elseif data.type == "error" then
        print("Server error: " .. (data.message or "unknown error"))
        
    else
        print("Unknown message type from server: " .. (data.type or "unknown"))
    end
end

function NetworkManager:sendMonsterKill(monsterData)
    if not self.connected then 
        print("ERROR: Cannot send monster kill - not connected to server")
        return
    end
    
    local killData = {
        type = "monster_kill",
        playerId = self.playerId,
        instanceId = self.instanceId,
        monsterData = monsterData,
        timestamp = os.time()
    }
    
    self:sendToServer(killData)
    print("Sent monster kill to server")
end

function NetworkManager:sendPlayerProgress(progressData)
    if not self.connected then return end
    
    local progress = {
        type = "player_progress",
        playerId = self.playerId,
        instanceId = self.instanceId,
        progress = progressData,
        timestamp = os.time()
    }
    
    self:sendToServer(progress)
end

function NetworkManager:disconnect()
    if self.socket then
        print("Closing WebSocket connection...")
        self.socket:close()
        self.socket = nil
    end
    self.connected = false
end

-- Простые JSON функции (в реальной игре используй библиотеку)
function NetworkManager:serializeToJSON(data)
    -- Простая сериализация для тестирования
    if type(data) == "table" then
        local parts = {}
        for k, v in pairs(data) do
            local key = type(k) == "string" and '"' .. k .. '"' or k
            local value = type(v) == "string" and '"' .. v .. '"' or v
            if type(v) == "table" then
                value = self:serializeToJSON(v)
            end
            table.insert(parts, key .. ":" .. value)
        end
        return "{" .. table.concat(parts, ",") .. "}"
    end
    return tostring(data)
end

function NetworkManager:parseJSON(jsonStr)
    -- Простой парсинг для тестирования
    local data = {}
    jsonStr = jsonStr:gsub("{", ""):gsub("}", "")
    local pairs = {}
    for pair in jsonStr:gmatch("[^,]+") do
        table.insert(pairs, pair)
    end
    
    for _, pair in ipairs(pairs) do
        local key, value = pair:match('"([^"]+)":"([^"]+)"')
        if key and value then
            data[key] = value
        end
    end
    
    return data
end

function NetworkManager:processLoot(item)
    print("Processing server loot: " .. item.type)
    if GameState.player then
        -- Создаем предмет из данных сервера
        local newItem = {
            type = item.type,
            name = item.type:gsub("^%l", string.upper) .. " Item",
            rarity = "Common",
            baseAttack = item.stats and item.stats.attack or 0,
            baseDefense = item.stats and item.stats.defense or 0,
            baseHP = item.stats and item.stats.hp or 0
        }
        GameState.player:addToInventory(newItem)
    end
end

function NetworkManager:drawOtherPlayers()
    -- По-прежнему не показываем других игроков
end

function NetworkManager:getPlayerCount()
    return 1
end

function NetworkManager:getInstanceInfo()
    return {
        playerId = self.playerId,
        instanceId = self.instanceId,
        connected = self.connected,
        isIsolated = self.isIsolatedInstance
    }
end