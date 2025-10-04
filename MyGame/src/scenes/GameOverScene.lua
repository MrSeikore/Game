GameOverScene = {
    name = "gameOver"
}

function GameOverScene:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function GameScene:draw()
    -- ... предыдущий код отрисовки ...

    -- Экран Game Over
    if self.gameState == "gameOver" then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, 1000, 700)
        
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("ВЫ УМЕРЛИ", 400, 300)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Нажмите R для возрождения на предыдущем этаже", 300, 360)
        
        local respawnFloor = math.max(1, self.currentFloor - 1)
        love.graphics.print("Вы возродитесь на этаже: " .. respawnFloor, 400, 390)
        love.graphics.print("Весь ваш инвентарь и прогресс сохранены", 350, 420)
    end
end

function GameScene:keypressed(key)
    if key == "i" then
        GameState:switchScene('inventory')
    elseif key == "r" and self.gameState == "gameOver" then
        -- Возрождение
        GameState:loadProgress()
        GameState.player:resetPosition()
        self.killedMonsters = 0
        self.currentFloor = math.max(1, self.currentFloor - 1)
        self.gameState = "playing"
        self.currentMonster = nil
    end
end