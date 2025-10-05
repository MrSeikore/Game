Player = {}

function Player:new()
    local o = {
        -- Position and appearance
        x = 100, 
        y = 500, 
        width = 40, 
        height = 60,
        color = {0, 0.4, 1},
        facingRight = true,
        
        -- Core stats
        level = 1,
        exp = 0,
        expToNextLevel = 100,
        
        -- Base stats (without equipment)
        baseHp = Constants.PLAYER_BASE_HP,
        baseAttack = Constants.PLAYER_BASE_ATTACK,
        baseDefense = Constants.PLAYER_BASE_DEFENSE,
        
        -- Current stats (with equipment bonuses)
        maxHp = Constants.PLAYER_BASE_HP,
        hp = Constants.PLAYER_BASE_HP,
        attack = Constants.PLAYER_BASE_ATTACK,
        defense = Constants.PLAYER_BASE_DEFENSE,
        
        -- Secondary stats
        lifesteal = 0,
        attackSpeed = 1.0,
        expBonus = 0,
        critChance = 0,
        fireResist = 0,
        moveSpeed = 0,
        manaRegen = 0,
        cooldownReduction = 0,
        critDamage = 0,
        armorPen = 0,
        bleedChance = 0,
        poisonDamage = 0,
        damageReflect = 0,
        thorns = 0,
        healthRegen = 0,
        dodgeChance = 0,
        magicFind = 0,
        goldFind = 0,
        skillDamage = 0,
        resourceCostReduction = 0,
        
        -- Combat timing
        lastAttackTime = 0,
        
        -- Equipment and inventory
        equipment = {
            weapon = nil,
            helmet = nil, 
            armor = nil
        },
        inventory = {}
    }
    
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:moveRight(dt)
    local speed = Constants.PLAYER_SPEED * (1 + self.moveSpeed)
    self.x = self.x + speed * dt
    self.facingRight = true
    
    -- Debug movement
    if math.random() < 0.01 then  -- Print occasionally to avoid spam
        print(string.format("Player moving: x=%.1f, speed=%.1f", self.x, speed))
    end
end

function Player:moveLeft(dt)
    local speed = Constants.PLAYER_SPEED * (1 + self.moveSpeed)
    self.x = self.x - speed * dt
    self.facingRight = false
end

function Player:canAttack(currentTime)
    return currentTime - self.lastAttackTime >= 1.0 / self.attackSpeed
end

function Player:attackMonster(monster, currentTime)
    if self:canAttack(currentTime) then
        local baseDamage = math.max(1, self.attack - math.floor(monster.defense / 2))
        
        -- Critical hit chance
        local isCritical = math.random() < self.critChance
        local damage = isCritical and math.floor(baseDamage * (1.5 + self.critDamage)) or baseDamage
        
        -- Armor penetration
        if self.armorPen > 0 then
            damage = damage + math.floor(damage * self.armorPen)
        end
        
        -- Apply damage
        monster.hp = monster.hp - damage
        self.lastAttackTime = currentTime
        
        -- Lifesteal
        if self.lifesteal > 0 then
            local healAmount = math.floor(damage * self.lifesteal)
            self.hp = math.min(self.maxHp, self.hp + healAmount)
        end
        
        -- Status effects (bleed, poison chance)
        local statusEffects = {}
        if math.random() < self.bleedChance then
            table.insert(statusEffects, "bleed")
        end
        if math.random() < self.poisonDamage then
            table.insert(statusEffects, "poison")
        end
        
        return damage, isCritical, statusEffects
    end
    return 0, false, {}
end

function Player:takeDamage(damage, damageType)
    -- Damage type resistance (future expansion)
    local resistance = 0
    if damageType == "fire" then
        resistance = self.fireResist
    end
    
    local finalDamage = math.max(1, math.floor(damage * (1 - resistance)))
    self.hp = self.hp - finalDamage
    
    -- Damage reflection
    if self.damageReflect > 0 then
        local reflectedDamage = math.floor(finalDamage * self.damageReflect)
        return finalDamage, reflectedDamage
    end
    
    return finalDamage, 0
end

function Player:addExp(amount)
    local bonusAmount = math.floor(amount * (1 + self.expBonus))
    local oldLevel = self.level
    self.exp = self.exp + bonusAmount
    
    print(string.format("Gained %d EXP (%d with bonus)", amount, bonusAmount))
    
    -- Level up if enough EXP
    while self.exp >= self.expToNextLevel do
        self:levelUp()
    end
end

function Player:levelUp()
    self.level = self.level + 1
    self.exp = self.exp - self.expToNextLevel
    self.expToNextLevel = math.floor(self.expToNextLevel * 1.5)
    
    -- Increase base stats
    self.baseHp = self.baseHp + 20
    self.baseAttack = self.baseAttack + 5
    self.baseDefense = self.baseDefense + 2
    
    -- Recalculate all stats with new base values
    self:recalculateStats()
    
    -- Heal to full on level up
    self.hp = self.maxHp
    
    print("Level UP! Now level " .. self.level)
    print(string.format("New stats: HP=%d, ATK=%d, DEF=%d", self.maxHp, self.attack, self.defense))
    
    -- Trigger level up event
    if GameState.triggerEvent then
        GameState:triggerEvent("playerLevelUp", {level = self.level})
    end
end

function Player:recalculateStats()
    -- Reset to base stats
    self.maxHp = self.baseHp
    self.attack = self.baseAttack
    self.defense = self.baseDefense
    
    -- Reset secondary stats
    self.lifesteal = 0
    self.attackSpeed = 1.0
    self.expBonus = 0
    self.critChance = 0
    self.fireResist = 0
    self.moveSpeed = 0
    self.manaRegen = 0
    self.cooldownReduction = 0
    self.critDamage = 0
    self.armorPen = 0
    self.bleedChance = 0
    self.poisonDamage = 0
    self.damageReflect = 0
    self.thorns = 0
    self.healthRegen = 0
    self.dodgeChance = 0
    self.magicFind = 0
    self.goldFind = 0
    self.skillDamage = 0
    self.resourceCostReduction = 0
    
    -- Add equipment bonuses
    for slot, item in pairs(self.equipment) do
        if item then
            self.maxHp = self.maxHp + (item.hpBonus or 0)
            self.attack = self.attack + (item.attackBonus or 0)
            self.defense = self.defense + (item.defenseBonus or 0)
            self.lifesteal = self.lifesteal + (item.lifesteal or 0)
            self.attackSpeed = self.attackSpeed + (item.attackSpeed or 0)
            self.expBonus = self.expBonus + (item.expBonus or 0)
            self.critChance = self.critChance + (item.critChance or 0)
            self.fireResist = self.fireResist + (item.fireResist or 0)
            self.moveSpeed = self.moveSpeed + (item.moveSpeed or 0)
            self.manaRegen = self.manaRegen + (item.manaRegen or 0)
            self.cooldownReduction = self.cooldownReduction + (item.cooldownReduction or 0)
            self.critDamage = self.critDamage + (item.critDamage or 0)
            self.armorPen = self.armorPen + (item.armorPen or 0)
            self.bleedChance = self.bleedChance + (item.bleedChance or 0)
            self.poisonDamage = self.poisonDamage + (item.poisonDamage or 0)
            self.damageReflect = self.damageReflect + (item.damageReflect or 0)
            self.thorns = self.thorns + (item.thorns or 0)
            self.healthRegen = self.healthRegen + (item.healthRegen or 0)
            self.dodgeChance = self.dodgeChance + (item.dodgeChance or 0)
            self.magicFind = self.magicFind + (item.magicFind or 0)
            self.goldFind = self.goldFind + (item.goldFind or 0)
            self.skillDamage = self.skillDamage + (item.skillDamage or 0)
            self.resourceCostReduction = self.resourceCostReduction + (item.resourceCostReduction or 0)
        end
    end
    
    -- Ensure minimum values
    self.attack = math.max(1, self.attack)
    self.defense = math.max(0, self.defense)
    self.maxHp = math.max(1, self.maxHp)
    self.attackSpeed = math.max(0.1, self.attackSpeed)
    
    -- Cap percentages at reasonable values
    self.critChance = math.min(0.8, self.critChance)
    self.dodgeChance = math.min(0.5, self.dodgeChance)
    self.lifesteal = math.min(0.3, self.lifesteal)
    
    -- Adjust current HP if maximum decreased
    if self.hp > self.maxHp then
        self.hp = self.maxHp
    end
end

function Player:equipItem(item)
    if not item then return nil end
    
    print("Equipping item: " .. item.name)
    
    -- Remove from inventory
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
    
    -- Trigger equipment event
    if GameState.triggerEvent then
        GameState:triggerEvent("itemEquipped", {itemName = item.name, itemType = item.type})
    end
    
    return oldItem
end

function Player:unequipItem(itemType)
    local item = self.equipment[itemType]
    if item then
        print("Unequipping: " .. item.name)
        self.equipment[itemType] = nil
        
        -- Add to inventory
        table.insert(self.inventory, item)
        
        -- Recalculate stats
        self:recalculateStats()
        
        print("Unequipped: " .. item.name)
    end
    return item
end

function Player:addToInventory(item)
    if not item then return false end
    
    table.insert(self.inventory, item)
    print("Added to inventory: " .. item.name)
    print("Inventory size: " .. #self.inventory)
    
    return true
end

function Player:removeFromInventory(item)
    for i = #self.inventory, 1, -1 do
        if self.inventory[i] == item then
            table.remove(self.inventory, i)
            print("Removed from inventory: " .. item.name)
            return true
        end
    end
    return false
end

function Player:hasItem(item)
    for _, invItem in ipairs(self.inventory) do
        if invItem == item then
            return true
        end
    end
    return false
end

function Player:getInventoryCount()
    return #self.inventory
end

function Player:getEquipmentStats()
    local stats = {
        hp = 0,
        attack = 0,
        defense = 0
    }
    
    for slot, item in pairs(self.equipment) do
        if item then
            stats.hp = stats.hp + (item.hpBonus or 0)
            stats.attack = stats.attack + (item.attackBonus or 0)
            stats.defense = stats.defense + (item.defenseBonus or 0)
        end
    end
    
    return stats
end

function Player:resetPosition()
    self.x = 100
    print("Player position reset to x=100")
end

function Player:heal(amount)
    local healAmount = amount or self.maxHp
    self.hp = math.min(self.maxHp, self.hp + healAmount)
    return healAmount
end

function Player:isAlive()
    return self.hp > 0
end

function Player:draw()
    -- Player body
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Head
    love.graphics.setColor(0.8, 0.6, 0.4)
    love.graphics.rectangle("fill", self.x + 10, self.y - 15, 20, 20)
    
    -- Health bar background
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, self.width, 5)
    
    -- Health bar fill
    local healthWidth = (self.hp / self.maxHp) * self.width
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.x, self.y - 25, healthWidth, 5)
    
    -- Health bar border
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y - 25, self.width, 5)
    
    -- Level indicator
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Lv." .. self.level, self.x + 12, self.y - 40)
end

function Player:getStatsSummary()
    return {
        level = self.level,
        hp = string.format("%d/%d", math.floor(self.hp), self.maxHp),
        attack = self.attack,
        defense = self.defense,
        exp = string.format("%d/%d", self.exp, self.expToNextLevel),
        critChance = string.format("%.1f%%", self.critChance * 100),
        lifesteal = string.format("%.1f%%", self.lifesteal * 100),
        attackSpeed = string.format("%.1f", self.attackSpeed)
    }
end

-- Serialization for saving (simplified)
function Player:serialize()
    local data = {
        level = self.level,
        exp = self.exp,
        expToNextLevel = self.expToNextLevel,
        baseHp = self.baseHp,
        baseAttack = self.baseAttack,
        baseDefense = self.baseDefense,
        hp = self.hp,
        maxHp = self.maxHp,
        inventoryCount = #self.inventory
    }
    
    return data
end