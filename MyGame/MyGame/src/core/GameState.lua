GameState = {
    currentScene = nil,
    scenes = {},
    player = nil,
    dropChanceSystem = nil,
    saveSystem = nil,
    showStats = false
}

function GameState:initialize()
    print("Initializing GameState...")
    
    -- Пока просто создаем пустые ссылки
    self.player = nil
    self.scenes = {}
    self.currentScene = nil
    
    print("GameState base initialized")
end

function GameState:update(dt)
    -- Всегда обновляем игровую сцену (бой продолжается даже когда открыта статистика)
    if self.scenes.game then
        self.scenes.game:update(dt)
    end
    
    -- Всегда обновляем инвентарь
    if self.scenes.inventory then
        self.scenes.inventory:update(dt)
    end
    
    -- Обновляем систему шансов дропа
    if self.dropChanceSystem and self.dropChanceSystem.update then
        self.dropChanceSystem:update(dt)
    end
end

function GameState:draw()
    -- Рисуем игровую сцену первой
    if self.scenes.game then
        self.scenes.game:draw()
    end
    
    -- Рисуем инвентарь поверх
    if self.scenes.inventory then
        self.scenes.inventory:draw()
    end
    
    -- Рисуем шансы дропа
    if self.dropChanceSystem then
        self.dropChanceSystem:draw()
    end
    
    -- Рисуем основные характеристики справа
    self:drawPlayerStats()
    
    -- Рисуем статистику поверх всего (если открыта)
    if self.showStats then
        self.scenes.stats:draw()
    end
end

function GameState:keypressed(key)
    -- Глобальные горячие клавиши
    if key == "t" then
        -- Toggle статистики
        self.showStats = not self.showStats
        print("Stats " .. (self.showStats and "opened" or "closed"))
    elseif key == "escape" then
        -- Закрываем статистику при нажатии ESC
        self.showStats = false
    end
    
    -- Передаем нажатие в текущую сцену
    if self.currentScene then
        self.currentScene:keypressed(key)
    end
end

function GameState:mousepressed(x, y, button)
    -- Если открыта статистика, блокируем все остальные клики
    if self.showStats then
        self.scenes.stats:mousepressed(x, y, button)
        return
    end
    
    -- Иначе проверяем область инвентаря
    if x >= 700 and self.scenes.inventory then
        self.scenes.inventory:mousepressed(x, y, button)
    else
        -- Передаем в игровую сцену
        if self.scenes.game then
            self.scenes.game:mousepressed(x, y, button)
        end
    end
end

function GameState:mousemoved(x, y, dx, dy)
    -- Если открыта статистика, передаем только в статистику
    if self.showStats then
        self.scenes.stats:mousemoved(x, y, dx, dy)
    else
        -- Иначе обновляем обе сцены
        if self.scenes.game then
            self.scenes.game:mousemoved(x, y, dx, dy)
        end
        if self.scenes.inventory then
            self.scenes.inventory:mousemoved(x, y, dx, dy)
        end
    end
end

function GameState:drawPlayerStats()
    if not self.player then return end
    
    local player = self.player
    local startX = 710
    local startY = 10
    
    -- Фон для статистики
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", startX, startY, 280, 60)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", startX, startY, 280, 60)
    
    -- Основные характеристики
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Level: " .. player.level, startX + 10, startY + 5)
    love.graphics.print("XP: " .. player.exp .. "/" .. player.expToNextLevel, startX + 10, startY + 25)
    love.graphics.print("DMG: " .. player.attack, startX + 150, startY + 5)
    love.graphics.print("HP: " .. math.floor(player.hp) .. "/" .. player.maxHp, startX + 150, startY + 25)
    
    -- Подсказка для статистики
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("Press T for detailed stats", startX + 10, startY + 45)
end

function GameState:switchScene(sceneName)
    if self.scenes[sceneName] and self.currentScene ~= self.scenes[sceneName] then
        if self.currentScene and self.currentScene.onExit then
            self.currentScene:onExit()
        end
        
        self.currentScene = self.scenes[sceneName]
        
        if self.currentScene and self.currentScene.onEnter then
            self.currentScene:onEnter()
        end
        
        print("Switched to scene: " .. sceneName)
    end
end

function GameState:getCurrentFloor()
    if self.scenes.game then
        return self.scenes.game.currentFloor or 1
    end
    return 1
end

function GameState:getGameState()
    if self.scenes.game then
        return self.scenes.game.gameState or "moving"
    end
    return "moving"
end

function GameState:isInBattle()
    return self:getGameState() == "battle"
end

function GameState:isGameOver()
    return self:getGameState() == "gameOver"
end

function GameState:saveProgress()
    if self.saveSystem then
        return self.saveSystem:saveGame()
    end
    return false
end

function GameState:loadProgress()
    if self.saveSystem then
        return self.saveSystem:loadGame()
    end
    return false
end

function GameState:resetGame()
    print("Resetting game...")
    
    self.player = Player:new()
    self.scenes.game = GameScene:new()
    self.scenes.inventory = InventoryScene:new()
    self.currentScene = self.scenes.game
    self.showStats = false
    
    if self.currentScene.onEnter then
        self.currentScene:onEnter()
    end
    
    print("Game reset complete")
end

function GameState:isInGameArea(x, y)
    return x < 700
end

function GameState:isInInventoryArea(x, y)
    return x >= 700
end

function GameState:triggerEvent(eventType, data)
    print("Event triggered: " .. eventType)
    
    if eventType == "monsterKilled" then
        if self.dropChanceSystem and self.dropChanceSystem.onMonsterKilled then
            self.dropChanceSystem:onMonsterKilled(data)
        end
    elseif eventType == "playerLevelUp" then
        print("Player reached level " .. (data.level or "unknown"))
    elseif eventType == "itemEquipped" then
        print("Item equipped: " .. (data.itemName or "unknown"))
    end
    
    for _, scene in pairs(self.scenes) do
        if scene.onEvent then
            scene:onEvent(eventType, data)
        end
    end
end