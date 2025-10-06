PlayerNetworkData = {
    -- Данные для синхронизации по сети
    syncFields = {
        "x", "y", "level", "hp", "maxHp", 
        "attack", "defense", "equipment", "currentFloor"
    }
}

function PlayerNetworkData:serializeForNetwork(player)
    local data = {}
    for _, field in ipairs(self.syncFields) do
        data[field] = player[field]
    end
    data.id = player.networkId
    data.name = player.name or "Player"
    data.lastUpdate = love.timer.getTime()
    return data
end