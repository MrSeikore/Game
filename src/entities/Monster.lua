Monster = {}

function Monster:new(floorLevel)
    local o = {
        x = 800, y = 500, width = 35, height = 50,
        level = math.max(1, floorLevel),
        maxHp = 40 + (floorLevel * 10),
        hp = 40 + (floorLevel * 10),
        attackDamage = 5 + floorLevel,
        defense = floorLevel,
        expValue = 20 + floorLevel * 5,
        attackSpeed = 1.0,
        lastAttackTime = 0,
        color = {math.min(1, 0.4 + floorLevel * 0.1), 0, 0}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Monster:moveTowardsPlayer(playerX, dt)
    if self.x > playerX + 60 then
        self.x = self.x - 100 * dt
    end
end

function Monster:canAttack(currentTime)
    return currentTime - self.lastAttackTime >= 1.0 / self.attackSpeed
end

function Monster:attackPlayer(player, currentTime)
    if self:canAttack(currentTime) then
        local damage = math.max(1, self.attackDamage - math.floor(player.defense / 3))
        player.hp = player.hp - damage
        self.lastAttackTime = currentTime
        return damage
    end
    return 0
end

function Monster:draw()
    -- Monster body
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Head
    love.graphics.setColor(0.6, 0, 0)
    love.graphics.rectangle("fill", self.x + 5, self.y - 15, 25, 20)
    
    -- Health bar
    local healthWidth = (self.hp / self.maxHp) * self.width
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, self.width, 5)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, healthWidth, 5)
    
    -- Level
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(tostring(self.level), self.x + 12, self.y - 12)
end