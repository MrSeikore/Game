Config = {
    SERVER_URLS = {
        "ws://localhost:3000",
        "ws://192.168.0.101:3000",  -- Замени на IP твоего ПК в сети
        "ws://127.0.0.1:3000"
    },
    AUTO_DISCOVERY = true
}

function Config:getServerList()
    -- Проверяем наличие файла с кастомным сервером
    local customServer = self:loadCustomServer()
    local servers = {}
    
    -- Добавляем кастомный сервер первым если есть
    if customServer then
        table.insert(servers, customServer)
    end
    
    -- Добавляем остальные серверы
    for _, url in ipairs(self.SERVER_URLS) do
        table.insert(servers, url)
    end
    
    return servers
end

function Config:loadCustomServer()
    local success, contents = pcall(function()
        return love.filesystem.read("server_config.txt")
    end)
    
    if success and contents and contents ~= "" then
        return contents:gsub("%s+", ""):gsub('"', '')
    end
    return nil
end

return Config