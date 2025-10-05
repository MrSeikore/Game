GameScene = Scene:new("game")

function GameScene:new()
    local o = Scene.new(self, "game")
    
    o.currentMonster = nil
    o.killedMonsters = 0
    o.currentFloor = 1
    o.gameState = "moving"
    o.groundY = 550
    o.monsterSpawnX = 200
    o.battleStartX = 150
    o.playerStartX = 100
    o.canAdvance = false
    o.respawnFloor = 1
    o.showAdvanceButton = false
    
    setmetatable(o, self)
    self.__index = self
    return o
end

function GameScene:onEnter()
    GameState.player:resetPosition()
    self.currentMonster = nil
    self.gameState = "moving"
    self.canAdvance = false
    self.showAdvanceButton = false
    
    -- Автозагрузка при входе в игру
    if GameState.saveSystem then
        GameState.saveSystem:loadGame()
    end
end

function GameScene:update(dt)
    local player = GameState.player
    
    if self.gameState == "moving" then
        player:moveRight(dt)

        if player.x > 650 then
            player.x = 650
        end

        if not self.currentMonster and player.x >= self.monsterSpawnX then
            -- Автосохранение при начале боя
            if GameState.saveSystem then
                GameState.saveSystem:saveGame()
            end
            
            self.currentMonster = Monster:new(self.currentFloor)
            self.currentMonster.x = 400
            print("Monster spawned at floor " .. self.currentFloor)
            self.gameState = "battle"
        end

    elseif self.gameState == "battle" then
        if self.currentMonster then
            self.currentMonster:moveTowardsPlayer(player.x, dt)
            
            local distance = math.abs(player.x - self.currentMonster.x)
            
            if player.x > 250 then
                player.x = 250
            end
            
            if self.currentMonster.x < 350 then
                self.currentMonster.x = 350
            end
            
            local currentTime = love.timer.getTime()
            local playerDamage, isCritical = player:attackMonster(self.currentMonster, currentTime)
            if playerDamage > 0 then
                print("Player hits monster for " .. playerDamage .. (isCritical and " CRITICAL!" or ""))
            end
            
            local monsterDamage = self.currentMonster:attackPlayer(player, currentTime)
            if monsterDamage > 0 then
                print("Monster hits player for " .. monsterDamage)
            end
            
            if self.currentMonster.hp <= 0 then
                player:addExp(self.currentMonster.expValue)
                self.killedMonsters = self.killedMonsters + 1
                print("Monster killed! Total: " .. self.killedMonsters .. "/3")
                self.currentMonster = nil

                -- Дроп предмета
                if math.random() < 0.6 then
                    local itemTypes = {"weapon", "helmet", "armor"}
                    local itemType = itemTypes[math.random(1, 3)]
                    local newItem = Item:new(itemType, self.currentFloor)
                    player:addToInventory(newItem)
                    print("Dropped: " .. newItem.name)
                end

                -- Автоматический переход на следующий этаж после 3 убийств
                if self.killedMonsters >= 3 then
                    self:advanceToNextFloor()
                else
                    player:resetPosition()
                    self.gameState = "moving"
                end
            end

            if player.hp <= 0 then
                self.gameState = "gameOver"
                self.respawnFloor = math.max(1, self.currentFloor - 1)
                self.showAdvanceButton = true
                print("Player died! Respawning at floor " .. self.respawnFloor)
            end
        end
    end
end

function GameScene:draw()
    local player = GameState.player
    
    -- Background
    love.graphics.setColor(0.4, 0.4, 1)
    love.graphics.rectangle("fill", 0, 0, 700, Display.baseHeight)
    
    -- Ground
    love.graphics.setColor(0.4, 0.3, 0.2)
    love.graphics.rectangle("fill", 0, self.groundY, 700, 150)
    love.graphics.setColor(0, 0.6, 0)
    love.graphics.rectangle("fill", 0, self.groundY, 700, 10)
    
    -- Monster
    if self.currentMonster then
        self.currentMonster:draw()
    end
    
    -- Player
    player:draw()
    
    -- Game state
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("State: " .. self.gameState:upper(), 600, 20)
    
    -- Кнопка перехода на следующий этаж (только после смерти)
    if self.showAdvanceButton and self.gameState == "gameOver" then
        self:drawAdvanceButton()
    end
    
    -- Game over screen
    if self.gameState == "gameOver" then
        self:drawGameOverScreen()
    end
end

function GameScene:drawAdvanceButton()
    local button = {
        x = 250, y = 350, width = 200, height = 50
    }
    
    local isHovered = Utils.pointInRect(self.mouseX or 0, self.mouseY or 0, button)
    
    -- Фон кнопки
    love.graphics.setColor(isHovered and {0.2, 0.8, 0.2} or {0.1, 0.6, 0.1})
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    
    -- Текст кнопки
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("GO TO NEXT FLOOR", button.x + 30, button.y + 15)
end

function GameScene:drawGameOverScreen()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 150, 200, 400, 200)
    
    love.graphics.setColor(1, 0, 0)
    love.graphics.print("GAME OVER", 280, 230)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press R to respawn at floor " .. self.respawnFloor, 220, 280)
    love.graphics.print("You keep your inventory and progress", 180, 310)
    
    if self.showAdvanceButton then
        love.graphics.print("Or click button below to advance", 210, 340)
    end
end

function GameScene:keypressed(key)
    if key == "r" and self.gameState == "gameOver" then
        self:respawn()
    end
end

function GameScene:mousepressed(x, y, button)
    if button == 1 then
        -- Проверяем клик по кнопке перехода (только после смерти)
        if self.showAdvanceButton and self.gameState == "gameOver" then
            local buttonRect = {x = 250, y = 350, width = 200, height = 50}
            if Utils.pointInRect(x, y, buttonRect) then
                self:advanceToNextFloor()
                return
            end
        end
    end
end

function GameScene:mousemoved(x, y, dx, dy)
    self.mouseX = x
    self.mouseY = y
end

function GameScene:advanceToNextFloor()
    self.currentFloor = self.currentFloor + 1
    self.killedMonsters = 0
    self.canAdvance = false
    self.showAdvanceButton = false
    GameState.player.hp = GameState.player.maxHp
    GameState.player:resetPosition()
    self.gameState = "moving"
    
    print("Advanced to floor " .. self.currentFloor)
end

function GameScene:respawn()
    GameState.player.hp = GameState.player.maxHp
    self.currentFloor = self.respawnFloor
    self.killedMonsters = 0
    self.currentMonster = nil
    self.showAdvanceButton = false
    GameState.player:resetPosition()
    self.gameState = "moving"
    
    print("Player respawned at floor " .. self.currentFloor)
end