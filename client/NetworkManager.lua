local json = require("json")

NetworkManager = {
    connected = false,
    playerId = nil,
    instanceId = nil,
    socket = nil,
    lastError = "",
    playerName = nil,
    waitingForNameInput = true,
    nameInputText = ""
}

function NetworkManager:initialize()
    print("=== NETWORK MANAGER ===")
    self.connected = false
    self.playerId = nil
    self.instanceId = nil
    self.lastError = ""
    self.playerName = ""
    self.waitingForNameInput = true
    self.nameInputText = ""

    print("✅ NetworkManager ready - waiting for name input")
end

function NetworkManager:connect(serverUrl)
    if self.playerName == "" then
        print("❌ Cannot connect: player name not set")
        return false
    end
    
    print("🔗 Connecting to: " .. serverUrl)
    
    local socket = require("socket")
    local tcp = socket.tcp()
    
    -- Парсим URL
    local host, port = self:parseUrl(serverUrl)
    if not host then
        self.lastError = "Invalid URL: " .. serverUrl
        return false
    end
    
    -- Устанавливаем соединение
    tcp:settimeout(2)
    local success, err = tcp:connect(host, port)
    if not success then
        self.lastError = "Connection failed: " .. err
        tcp:close()
        return false
    end
    
    -- WebSocket handshake
    local key = self:generateKey()
    local handshake = "GET /ws HTTP/1.1\r\n" ..
                     "Host: " .. host .. ":" .. port .. "\r\n" ..
                     "Upgrade: websocket\r\n" ..
                     "Connection: Upgrade\r\n" ..
                     "Sec-WebSocket-Key: " .. key .. "\r\n" ..
                     "Sec-WebSocket-Version: 13\r\n" ..
                     "\r\n"
    
    success, err = tcp:send(handshake)
    if not success then
        self.lastError = "Handshake failed: " .. err
        tcp:close()
        return false
    end
    
    -- Читаем ответ
    local response = ""
    tcp:settimeout(5)
    while true do
        local data, err = tcp:receive("*l")
        if not data then break end
        response = response .. data .. "\r\n"
        if data == "" then break end
    end
    
    -- Проверяем успешность handshake
    if not response:match("HTTP/1.1 101") then
        self.lastError = "WebSocket handshake failed. Response: " .. response
        print("❌ " .. self.lastError)
        tcp:close()
        return false
    end
    
    -- Успешное подключение
    self.socket = tcp
    self.socket:settimeout(0) -- Неблокирующий режим
    self.connected = true
    self.lastError = ""
    
    print("✅ Connected to server successfully")
    print("🔍 Socket status: " .. tostring(self.socket))
    
    self:sendLogin()
    return true
end

function NetworkManager:update(dt)
    if not self.connected then return end
    
    -- print("🔄 NetworkManager update - checking for incoming messages...")
    
    -- Пытаемся получить сообщение (только одно за кадр чтобы не блокировать)
    local message = self:receive()
    if message then
        print("✅ Received and processed message")
    end
end

function NetworkManager:receive()
    if not self.connected or not self.socket then 
        print("❌ Cannot receive - not connected or no socket")
        return nil 
    end
    
    -- Вместо getreceive используем прямое чтение с таймаутом
    -- Сохраняем текущий таймаут
    local original_timeout = self.socket:gettimeout()
    
    -- Устанавливаем очень короткий таймаут для проверки
    self.socket:settimeout(0.001) -- 1ms timeout
    
    local data, err, partial = self.socket:receive(1) -- Пробуем прочитать 1 байт
    
    -- Восстанавливаем оригинальный таймаут
    self.socket:settimeout(original_timeout)
    
    if not data and err == "timeout" then
        -- Нет данных для чтения
        -- print("⏳ No data available to receive")
        return nil
    elseif err and err ~= "timeout" then
        self.lastError = "Receive error: " .. (err or "unknown")
        self.connected = false
        print("❌ Receive failed: " .. self.lastError)
        return nil
    end
    
    -- Если мы получили хотя бы 1 байт, читаем остальные байты заголовка
    if data or partial then
        local first_byte = data or partial
        
        -- Читаем второй байт заголовка
        local second_byte, err = self.socket:receive(1)
        if not second_byte then
            print("❌ Failed to read second byte: " .. (err or "unknown"))
            return nil
        end
        
        local byte1 = first_byte:byte(1)
        local byte2 = second_byte:byte(1)
        local payload_len = bit.band(byte2, 0x7F)
        
        print("📦 WebSocket frame - payload length: " .. payload_len)
        
        -- Читаем extended length если нужно
        local extended_len_bytes = 0
        if payload_len == 126 then
            local extra, err = self.socket:receive(2)
            if not extra then
                print("❌ Failed to read extended length: " .. (err or "unknown"))
                return nil
            end
            payload_len = bit.bor(bit.lshift(extra:byte(1), 8), extra:byte(2))
            extended_len_bytes = 2
            print("📦 Extended payload length: " .. payload_len)
        elseif payload_len == 127 then
            print("❌ 64-bit payload not supported")
            return nil
        end
        
        -- Читаем маску
        local mask, err = self.socket:receive(4)
        if not mask then
            print("❌ Failed to read mask: " .. (err or "unknown"))
            return nil
        end
        
        -- Читаем данные
        local payload, err = self.socket:receive(payload_len)
        if not payload then
            print("❌ Failed to read payload: " .. (err or "unknown"))
            return nil
        end
        
        -- Демаскируем данные
        local unmasked = ""
        for i = 1, #payload do
            local j = ((i-1) % 4) + 1
            unmasked = unmasked .. string.char(bit.bxor(payload:byte(i), mask:byte(j)))
        end
        
        print("🎯 RAW WebSocket message received (" .. #unmasked .. " bytes): " .. unmasked)
        self:handleServerMessage(unmasked)
        return unmasked
    end
    
    return nil
end

function NetworkManager:handleServerMessage(message)
    print("📥 Processing server message: " .. tostring(message and message:sub(1, 200) or "nil"))
    
    local success, data = pcall(json.decode, message)
    if success then
        print("✅ JSON parsed successfully")
        print("📋 Message type: " .. tostring(data.type))
        print("📋 Success flag: " .. tostring(data.success))
        
        if data.data and data.data.player_id then
            print("🎯 Player ID in response: " .. data.data.player_id)
        end
        
        if data.type == "login" then
            print("🔑 Handling login response...")
            self:handleLoginResponse(data)
        elseif data.type == "combat_result" then
            self:handleCombatResult(data)
        end
    else
        print("❌ JSON parse failed: " .. tostring(data))
        print("📋 Raw message that failed: " .. message)
    end
end

function NetworkManager:handleLoginResponse(data)
    print("🔑 Login response received")
    print("📋 Data success: " .. tostring(data.success))
    print("📋 Server error: " .. tostring(data.error))
    
    if data.success then
        if data.data and data.data.player_id then
            self.playerId = data.data.player_id
            self.instanceId = data.data.player_id
            print("✅ Server assigned UUID: " .. self.playerId)
        else
            print("❌ No player_id in response data")
            if data.data then
                print("📋 Data content:")
                for k, v in pairs(data.data) do
                    print("  " .. k .. ": " .. tostring(v))
                end
            end
        end
        
        self.lastError = ""
        print("✅ Login successful!")
        
        -- ИНИЦИАЛИЗИРУЕМ ИГРУ ПОСЛЕ УСПЕШНОГО ЛОГИНА
        if not gameInitialized then
            print("🔄 Triggering game initialization after successful login...")
            if initializeGame then
                local success = initializeGame()
                if success then
                    print("🎮 Game initialized successfully!")
                else
                    print("❌ Game initialization failed!")
                end
            else
                print("❌ ERROR: initializeGame function not found!")
            end
        end
        
    else
        self.lastError = "Login failed: " .. (data.error or "unknown")
        self.connected = false
        print("❌ " .. self.lastError)
    end
end

function NetworkManager:setPlayerName(name)
    if name and name ~= "" then
        self.playerName = name
        self.waitingForNameInput = false
        print("✅ Player name set: " .. name)
        return true
    end
    return false
end

function NetworkManager:parseUrl(url)
    local host, port = url:match("ws://([^:]+):(%d+)")
    if host then
        return host, tonumber(port)
    end
    return nil
end

function NetworkManager:generateKey()
    local random = ""
    for i = 1, 16 do
        random = random .. string.char(math.random(65, 90))
    end
    
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = ""
    for i = 1, #random, 3 do
        local a, b, c = random:byte(i, i+2)
        a = a or 0
        b = b or 0
        c = c or 0
        
        local n = a * 0x10000 + b * 0x100 + c
        for j = 1, 4 do
            if i + j - 1 <= #random + 1 then
                result = result .. b64chars:sub(bit.rshift(n, 18 - 6 * j) % 64 + 1, bit.rshift(n, 18 - 6 * j) % 64 + 1)
            else
                result = result .. '='
            end
        end
    end
    
    return result
end

function NetworkManager:sendLogin()
    if not self.connected then return end
    
    local loginData = {
        type = "login",
        player_name = self.playerName
    }
    
    print("📤 Sending login...")
    print("Login data - Name: " .. self.playerName)
    self:sendToServer(loginData)
end

function NetworkManager:sendToServer(data)
    if not self.connected then
        return false
    end
    
    local success, jsonData = pcall(json.encode, data)
    if not success then
        print("❌ JSON encode failed")
        return false
    end
    
    print("📤 Sending JSON: " .. jsonData)
    
    local frame = self:createWebSocketFrame(jsonData)
    
    local success, err = self.socket:send(frame)
    if success then
        print("✅ Sent: " .. data.type)
        return true
    else
        self.lastError = "Send failed: " .. (err or "unknown")
        self.connected = false
        return false
    end
end

function NetworkManager:createWebSocketFrame(data)
    local header = string.char(0x81)
    local len = #data
    
    local mask_bit = 0x80
    
    if len <= 125 then
        header = header .. string.char(bit.bor(len, mask_bit))
    elseif len <= 65535 then
        header = header .. string.char(bit.bor(126, mask_bit)) .. string.char(bit.rshift(len, 8)) .. string.char(bit.band(len, 0xFF))
    else
        error("Message too long")
    end
    
    local mask = {
        math.random(0, 255),
        math.random(0, 255), 
        math.random(0, 255),
        math.random(0, 255)
    }
    
    for i = 1, 4 do
        header = header .. string.char(mask[i])
    end
    
    local masked_data = ""
    for i = 1, #data do
        local j = ((i-1) % 4) + 1
        masked_data = masked_data .. string.char(bit.bxor(data:byte(i), mask[j]))
    end
    
    return header .. masked_data
end

function NetworkManager:handleCombatResult(data)
    print("⚔️ Combat result:")
    print("  Damage: " .. tostring(data.damage_dealt))
    print("  Killed: " .. tostring(data.monster_killed))
    
    if data.monster_killed and GameState.player then
        if data.loot and #data.loot > 0 then
            GameState.player:addToInventory(data.loot[1])
        end
    end
end

function NetworkManager:drawOtherPlayers() end

function NetworkManager:getPlayerCount() 
    return self.connected and 1 or 0
end

function NetworkManager:isWaitingForNameInput()
    return self.waitingForNameInput
end

function NetworkManager:getNameInputText()
    return self.nameInputText
end

function NetworkManager:setNameInputText(text)
    self.nameInputText = text
end

function NetworkManager:confirmNameInput()
    if self.nameInputText ~= "" then
        return self:setPlayerName(self.nameInputText)
    end
    return false
end

function NetworkManager:disconnect()
    if self.socket then
        self.socket:close()
        self.socket = nil
    end
    self.connected = false
    print("🔌 Disconnected from server")
end

-- Битовые операции
bit = {
    band = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 == 1 and b % 2 == 1 then
                result = result + bitval
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            bitval = bitval * 2
        end
        return result
    end,
    
    bxor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 ~= b % 2 then
                result = result + bitval
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            bitval = bitval * 2
        end
        return result
    end,
    
    bor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if a % 2 == 1 or b % 2 == 1 then
                result = result + bitval
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            bitval = bitval * 2
        end
        return result
    end,
    
    lshift = function(a, b)
        return a * (2 ^ b)
    end,
    
    rshift = function(a, b)
        return math.floor(a / (2 ^ b))
    end
}

return NetworkManager