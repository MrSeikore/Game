GameScene = {
    name = "game",
    currentMonster = nil,
    killedMonsters = 0,
    currentFloor = 1,
    gameState = "playing",
    groundY = 550
}

function GameScene:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function GameScene:onEnter()
    GameState.player:resetPosition()
    self.currentMonster = nil
    self.killedMonsters = 0
    self.currentFloor = 1
    self.gameState = "playing"
end

function GameScene:onExit()
end

function GameScene:update(dt)
    local player = GameState.player
    
    love.graphics.setColor(0.4, 0.4, 1)
    love.graphics.rectangle("fill", 0, 0, 700, Display.baseHeight)

    if self.gameState == "playing" then
        player:moveRight(dt)

        -- Limit player to left area
        if player.x > 650 then
            player.x = 650
        end

        if not self.currentMonster and player.x > 400 then
            self.currentMonster = Monster:new(self.currentFloor)
            self.gameState = "battle"
        end

    elseif self.gameState == "battle" then
        if self.currentMonster then
            -- Limit monster to left area
            if self.currentMonster.x > 650 then
                self.currentMonster.x = 650
            end
            
            self.currentMonster:moveTowardsPlayer(player.x, dt)
            
            local distance = math.abs(player.x - self.currentMonster.x)
            if distance <= 80 then
                if player.x > 300 then
                    player.x = 300
                end
                
                local currentTime = love.timer.getTime()
                player:attackMonster(self.currentMonster, currentTime)
                self.currentMonster:attackPlayer(player, currentTime)
                
                if self.currentMonster.hp <= 0 then
                    player:addExp(self.currentMonster.expValue)
                    self.killedMonsters = self.killedMonsters + 1
                    self.currentMonster = nil

                    if self.killedMonsters >= 3 then
                        self.currentFloor = self.currentFloor + 1
                        self.killedMonsters = 0
                        player.hp = player.maxHp
                        print("Advanced to floor " .. self.currentFloor)
                    end

                    -- Item drop with affixes
                    if math.random() < 0.6 then
                        local itemTypes = {"weapon", "helmet", "armor"}
                        local itemType = itemTypes[math.random(1, 3)]
                        local newItem = Item:new(itemType, self.currentFloor)
                        player:addToInventory(newItem)
                        print("Dropped: " .. newItem.name)
                        if #newItem.affixes > 0 then
                            print("Affixes: " .. #newItem.affixes)
                        end
                    end

                    player:resetPosition()
                    self.gameState = "playing"
                end

                if player.hp <= 0 then
                    self.gameState = "gameOver"
                end
            end
        end
    end
end

function GameScene:draw()
    local player = GameState.player
    
    -- Background (left area only)
    love.graphics.setColor(0.4, 0.4, 1)
    love.graphics.rectangle("fill", 0, 0, 700, 700)
    
    -- Ground (left area only)
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
    
    -- UI (left side, away from inventory)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("HP: " .. player.hp .. "/" .. player.maxHp, 10, 10)
    love.graphics.print("ATK: " .. player.attack, 10, 30)
    love.graphics.print("DEF: " .. player.defense, 10, 50)
    love.graphics.print("Level: " .. player.level, 10, 70)
    love.graphics.print("EXP: " .. player.exp .. "/" .. player.expToNextLevel, 10, 90)
    love.graphics.print("Floor: " .. self.currentFloor, 10, 110)
    love.graphics.print("Killed: " .. self.killedMonsters .. "/3", 10, 130)
    
    -- Game state
    if self.gameState == "battle" then
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("BATTLE!", 600, 20)
    else
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("MOVING", 600, 20)
    end
    
    -- Game over screen
    if self.gameState == "gameOver" then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 150, 200, 400, 200)
        
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("GAME OVER", 280, 230)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Press R to respawn", 250, 280)
        love.graphics.print("You keep your inventory", 230, 310)
    end
end

function GameScene:keypressed(key)
    if key == "r" and self.gameState == "gameOver" then
        -- Respawn logic
        GameState.player.hp = GameState.player.maxHp
        self.currentFloor = math.max(1, self.currentFloor - 1)
        self.currentMonster = nil
        GameState.player:resetPosition()
        self.gameState = "playing"
    end
end

function GameScene:mousepressed(x, y, button)
    -- Game scene mouse handling
end

function GameScene:mousemoved(x, y, dx, dy)
    -- Game scene mouse movement
end