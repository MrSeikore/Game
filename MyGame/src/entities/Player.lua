Player = {}

function Player:new()
    local o = {
        x = 100, y = 500, width = 40, height = 60,
        level = 1, exp = 0, expToNextLevel = 100,
        baseHp = 100, baseAttack = 10, baseDefense = 5,
        maxHp = 100, hp = 100, attack = 10, defense = 5,
        lifesteal = 0, attackSpeed = 1.0, expBonus = 0,
        lastAttackTime = 0, facingRight = true,
        equipment = {weapon = nil, helmet = nil, armor = nil},
        inventory = {},
        color = {0, 0.4, 1}
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Add this method to properly add items to inventory
function Player:addToInventory(item)
    table.insert(self.inventory, item)
    print("Added to inventory: " .. item.name)
end

-- Update equipItem method to remove from inventory
function Player:equipItem(item)
    print("Equipping item:", item.name)
    
    -- Remove from inventory if it exists there
    for i = #self.inventory, 1, -1 do
        if self.inventory[i] == item then
            table.remove(self.inventory, i)
            break
        end
    end
    
    -- Handle previous equipment
    local oldItem = self.equipment[item.type]
    if oldItem then
        -- Return old item to inventory
        table.insert(self.inventory, oldItem)
        print("Returned to inventory: " .. oldItem.name)
    end
    
    -- Equip new item
    self.equipment[item.type] = item
    self:recalculateStats()
    
    print("Equipped: " .. item.name)
    return oldItem
end

-- Update unequipItem method
function Player:unequipItem(itemType)
    local item = self.equipment[itemType]
    if item then
        print("Unequipping:", item.name)
        self.equipment[itemType] = nil
        -- Add to inventory
        table.insert(self.inventory, item)
        self:recalculateStats()
    end
    return item
end

function Player:moveRight(dt)
    self.x = self.x + 100 * dt
    self.facingRight = true
end

function Player:canAttack(currentTime)
    return currentTime - self.lastAttackTime >= 1.0 / self.attackSpeed
end

function Player:attackMonster(monster, currentTime)
    if self:canAttack(currentTime) then
        local damage = math.max(1, self.attack - math.floor(monster.defense / 2))
        monster.hp = monster.hp - damage
        self.lastAttackTime = currentTime
        
        -- Lifesteal
        if self.lifesteal > 0 then
            local healAmount = math.floor(damage * self.lifesteal)
            self.hp = math.min(self.maxHp, self.hp + healAmount)
        end
        
        return damage
    end
    return 0
end

function Player:addExp(amount)
    local bonusAmount = math.floor(amount * (1 + self.expBonus))
    self.exp = self.exp + bonusAmount
    if self.exp >= self.expToNextLevel then
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    self.exp = 0
    self.expToNextLevel = math.floor(self.expToNextLevel * 1.5)
    
    self.baseHp = self.baseHp + 20
    self.baseAttack = self.baseAttack + 5
    self.baseDefense = self.baseDefense + 2
    
    self:recalculateStats()
    self.hp = self.maxHp
    print("Level UP! Now level " .. self.level)
end

function Player:recalculateStats()
    -- Reset to base stats
    self.maxHp = self.baseHp
    self.attack = self.baseAttack
    self.defense = self.baseDefense
    self.lifesteal = 0
    self.attackSpeed = 1.0
    self.expBonus = 0
    
    -- Add equipment bonuses
    for slot, item in pairs(self.equipment) do
        if item then
            self.maxHp = self.maxHp + (item.hpBonus or 0)
            self.attack = self.attack + (item.attackBonus or 0)
            self.defense = self.defense + (item.defenseBonus or 0)
            self.lifesteal = self.lifesteal + (item.lifesteal or 0)
            self.attackSpeed = self.attackSpeed + (item.attackSpeed or 0)
            self.expBonus = self.expBonus + (item.expBonus or 0)
        end
    end
    
    -- Ensure minimum values
    self.attack = math.max(1, self.attack)
    self.defense = math.max(0, self.defense)
    self.maxHp = math.max(1, self.maxHp)
    
    if self.hp > self.maxHp then
        self.hp = self.maxHp
    end
    
    print(string.format("Stats updated - HP: %d, ATK: %d, DEF: %d", self.maxHp, self.attack, self.defense))
end

function Player:equipItem(item)
    print("Equipping item:", item.name)
    
    -- Add to inventory if not already there
    if not self:hasItem(item) then
        table.insert(self.inventory, item)
        print("Added to inventory")
    end
    
    -- Equip the item
    local oldItem = self.equipment[item.type]
    self.equipment[item.type] = item
    self:recalculateStats()
    
    if oldItem then
        print("Replaced:", oldItem.name)
    else
        print("Equipped:", item.name)
    end
    
    return oldItem
end

function Player:hasItem(item)
    for _, invItem in ipairs(self.inventory) do
        if invItem == item then
            return true
        end
    end
    return false
end

function Player:unequipItem(itemType)
    local item = self.equipment[itemType]
    if item then
        print("Unequipping:", item.name)
        self.equipment[itemType] = nil
        self:recalculateStats()
    end
    return item
end

function Player:draw()
    -- Player body
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Head
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.rectangle("fill", self.x + 10, self.y - 15, 20, 20)
    
    -- Health bar
    local healthWidth = (self.hp / self.maxHp) * self.width
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, self.width, 5)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, healthWidth, 5)
end

function Player:resetPosition()
    self.x = 100
end