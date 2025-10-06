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
    o.progressBarWidth = 200
    o.progressBarHeight = 20
    o.isDead = false
    o.targetFloor = 1
    o.totalMonstersPerFloor = 10  -- 9 обычных + 1 босс
    o.isBossFloor = false
    
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
    self.isDead = false
    self.targetFloor = self.currentFloor + 1
    self.isBossFloor = false
    
    -- ВРЕМЕННО ОТКЛЮЧАЕМ ЗАГРУЗКУ
    -- if GameState.saveSystem then
    --     GameState.saveSystem:loadGame()
    -- end
end

function GameScene:update(dt)
    local player = GameState.player
    
    if self.gameState == "moving" then
        player:moveRight(dt)

        if player.x > 650 then
            player.x = 650
        end

        if not self.currentMonster and player.x >= self.monsterSpawnX then
            if GameState.saveSystem then
                GameState.saveSystem:saveGame()
            end
            
            self:spawnNewMonster()
            self.gameState = "battle"
        end

    elseif self.gameState == "battle" then
        if self.currentMonster then
            self.currentMonster:moveTowardsPlayer(player.x, dt)
            
            if player.x > 250 then
                player.x = 250
            end
            
            if self.currentMonster.x < 350 then
                self.currentMonster.x = 350
            end
            
            local currentTime = love.timer.getTime()
            local playerDamage, isCritical = player:attackMonster(self.currentMonster, currentTime)
            local monsterDamage = self.currentMonster:attackPlayer(player, currentTime)
            
            if self.currentMonster.hp <= 0 then
                player:addExp(self.currentMonster.expValue)
                self.killedMonsters = self.killedMonsters + 1
                self.currentMonster = nil

                -- Дроп предмета с увеличенным шансом для босса
                local dropChance = self.isBossFloor and 0.9 or 0.6
                if math.random() < dropChance then
                    local itemTypes = {"weapon", "helmet", "armor"}
                    local itemType = itemTypes[math.random(1, 3)]
                    local newItem = Item:new(itemType, self.currentFloor)
                    player:addToInventory(newItem)
                    print((self.isBossFloor and "BOSS " or "") .. "Dropped: " .. newItem.name)
                end

                if self.killedMonsters >= self.totalMonstersPerFloor then
                    self:completeFloor()
                else
                    player:resetPosition()
                    self.gameState = "moving"
                end
            end

            if player.hp <= 0 then
                self:handleDeath()
            end
        end
    end
end

function GameScene:spawnNewMonster()
    self.currentMonster = nil
    
    -- Определяем тип монстра: босс на 10-м монстре (когда killedMonsters = 9)
    self.isBossFloor = (self.killedMonsters == 9)  -- 0-8 обычные, 9-й - босс (будет 10/10)
    
    if self.isBossFloor then
        self.currentMonster = Boss:new(self.currentFloor)
        print("BOSS SPAWNED: " .. self.currentMonster.name .. " (" .. self.currentMonster.affix .. ")")
    else
        self.currentMonster = Monster:new(self.currentFloor)
    end
    
    self.currentMonster.x = 400
    self.currentMonster.hp = self.currentMonster.maxHp
end

function GameScene:monsterKilled(monster)
    local player = GameState.player
    
    player:addExp(monster.expValue)
    
    -- Отправляем данные об убийстве на сервер
    if NetworkManager.connected then
        NetworkManager:sendMonsterKill({
            monsterType = monster.isBoss and "boss" or "normal",
            floor = self.currentFloor,
            exp = monster.expValue,
            isBoss = monster.isBoss or false
        })
    end
    
    -- Генерируем лут локально (сервер тоже отправит свой)
    if math.random() < 0.6 then
        local itemTypes = {"weapon", "helmet", "armor"}
        local itemType = itemTypes[math.random(1, 3)]
        local newItem = Item:new(itemType, self.currentFloor)
        player:addToInventory(newItem)
        print("Local loot dropped: " .. newItem.name)
    end
    
    self.killedMonsters = self.killedMonsters + 1
    
    if self.killedMonsters >= self.totalMonstersPerFloor then
        self:completeFloor()
    else
        player:resetPosition()
        self.gameState = "moving"
    end
end


function GameScene:completeFloor()
    local player = GameState.player
    
    -- Прогресс ТОЛЬКО для этого игрока
    player.hp = player.maxHp
    self.killedMonsters = 0
    self.currentMonster = nil
    
    if not self.isDead then
        self.currentFloor = self.currentFloor + 1
        self.targetFloor = self.currentFloor + 1
    else
        self.showAdvanceButton = true
        self.canAdvance = true
    end
    
    -- Награда за этаж ТОЛЬКО для этого игрока
    local floorReward = Item:new("weapon", self.currentFloor)
    player:addToInventory(floorReward)
    print("Floor completion reward: " .. floorReward.name)
    
    player:resetPosition()
    self.gameState = "moving"
end


function GameScene:handleDeath()
    local previousFloor = math.max(1, self.currentFloor - 1)
    self.currentFloor = previousFloor
    self.killedMonsters = self.totalMonstersPerFloor  -- Максимальный прогресс после смерти
    self.currentMonster = nil
    self.isBossFloor = false
    self.showAdvanceButton = true
    self.canAdvance = true
    self.isDead = true
    self.targetFloor = previousFloor + 1
    
    GameState.player.hp = GameState.player.maxHp
    GameState.player:resetPosition()
    self.gameState = "moving"
end

function GameScene:draw()
    local player = GameState.player
    
    love.graphics.setColor(0.4, 0.4, 1)
    love.graphics.rectangle("fill", 0, 0, 700, Display.baseHeight)
    
    love.graphics.setColor(0.4, 0.3, 0.2)
    love.graphics.rectangle("fill", 0, self.groundY, 700, 150)
    love.graphics.setColor(0, 0.6, 0)
    love.graphics.rectangle("fill", 0, self.groundY, 700, 10)
    
    if self.currentMonster then
        self.currentMonster:draw()
    end
    
    player:draw()
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("State: " .. self.gameState:upper(), 600, 20)
    
    self:drawFloorProgress()
    
    if self.isDead and self.showAdvanceButton then
        self:drawAdvanceButton()
    end
end

function GameScene:drawFloorProgress()
    local centerX = 350
    local topY = 20
    
    -- Прогресс = появившиеся монстры (1 за каждого обычного + 1 за босса)
    local appearedMonsters = self.killedMonsters
    if self.currentMonster then
        appearedMonsters = appearedMonsters + 1  -- +1 за текущего монстра
    end
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Floor: " .. self.currentFloor, centerX - 100, topY)
    love.graphics.print("Monsters: " .. appearedMonsters .. "/" .. self.totalMonstersPerFloor, centerX + 50, topY)
    
    local progressBarX = centerX - self.progressBarWidth / 2
    local progressBarY = topY + 25
    
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", progressBarX, progressBarY, self.progressBarWidth, self.progressBarHeight)
    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("line", progressBarX, progressBarY, self.progressBarWidth, self.progressBarHeight)
    
    -- Прогресс-бар по появившимся монстрам
    local progressWidth = (appearedMonsters / self.totalMonstersPerFloor) * self.progressBarWidth
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.rectangle("fill", progressBarX, progressBarY, progressWidth, self.progressBarHeight)
    
    -- Индикатор "BOSS BATTLE!" когда босс активен
    if self.isBossFloor and self.currentMonster then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("BOSS BATTLE!", centerX - 40, topY + 50)
    end
end

function GameScene:drawAdvanceButton()
    local centerX = 350
    local y = 150
    
    local button = {
        x = centerX - 100,
        y = y,
        width = 200,
        height = 40
    }
    
    local isHovered = Utils.pointInRect(self.mouseX or 0, self.mouseY or 0, button)
    
    love.graphics.setColor(isHovered and {0.2, 0.8, 0.2} or {0.1, 0.6, 0.1})
    love.graphics.rectangle("fill", button.x, button.y, button.width, button.height)
    
    love.graphics.setColor(1, 1, 1)
    local buttonText = "TRY NEXT FLOOR"
    local textWidth = love.graphics.getFont():getWidth(buttonText)
    love.graphics.print(buttonText, button.x + (button.width - textWidth) / 2, button.y + 12)
end

function GameScene:mousepressed(x, y, button)
    if button == 1 then
        if self.isDead and self.showAdvanceButton then
            local buttonRect = {
                x = 350 - 100,
                y = 150,
                width = 200,
                height = 40
            }
            if Utils.pointInRect(x, y, buttonRect) then
                self:advanceToTargetFloor()
                return
            end
        end
    end
end

function GameScene:mousemoved(x, y, dx, dy)
    self.mouseX = x
    self.mouseY = y
end

function GameScene:advanceToTargetFloor()
    self.currentFloor = self.targetFloor
    self.killedMonsters = 0
    self.currentMonster = nil
    self.canAdvance = false
    self.showAdvanceButton = false
    self.isDead = false
    self.isBossFloor = false
    self.targetFloor = self.currentFloor + 1
    
    GameState.player:resetPosition()
    GameState.player.hp = GameState.player.maxHp
    self.gameState = "moving"
end