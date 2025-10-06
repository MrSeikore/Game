Config = {
    SERVER_URL = "ws://localhost:3000",  -- По умолчанию локальный сервер
    AUTO_DISCOVERY = true
}

-- Функция для автоматического поиска сервера
function Config:discoverServer()
    -- Попробуем несколько вариантов автоматически
    local possibleServers = {
        "ws://localhost:3000",
        "ws://192.168.0.101:3000",  -- Замени на IP твоего ПК в сети
        "ws://127.0.0.1:3000"
    }
    
    -- Можно добавить файл конфигурации для легкой настройки
    if love.filesystem.getInfo("server_config.txt") then
        local customServer = love.filesystem.read("server_config.txt")
        if customServer and customServer ~= "" then
            table.insert(possibleServers, 1, customServer:gsub("%s+", ""))
        end
    end
    
    return possibleServers
end

return Config