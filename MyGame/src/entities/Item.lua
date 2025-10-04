Item = {}

function Item:new(itemType, floorLevel)
    local o = {
        type = itemType,
        rarity = self:generateRarity(floorLevel),
        name = "",
        attackBonus = 0,
        defenseBonus = 0,
        hpBonus = 0,
        lifesteal = 0,
        attackSpeed = 0,
        expBonus = 0,
        critChance = 0,
        fireResist = 0,
        moveSpeed = 0,
        manaRegen = 0,
        cooldownReduction = 0,
        affixes = {},
        icon = self:getIcon(itemType),
        iconType = itemType
    }
    
    setmetatable(o, self)
    self.__index = self
    
    o:generateBaseStats()
    o:generateAffixes()
    o.name = o.rarity .. " " .. itemType:gsub("^%l", string.upper)
    
    return o
end

function Item:generateRarity(floorLevel)
    local chances = {
        {rarity = "Common", chance = 0.7},
        {rarity = "Uncommon", chance = 0.25},
        {rarity = "Rare", chance = 0.05},
        {rarity = "Epic", chance = 0.0},
        {rarity = "Legendary", chance = 0.0}
    }
    
    if floorLevel >= 2 then
        chances[3].chance = 0.08
        chances[4].chance = 0.02
    end
    if floorLevel >= 3 then
        chances[3].chance = 0.12
        chances[4].chance = 0.06
        chances[5].chance = 0.02
    end
    if floorLevel >= 4 then
        chances[3].chance = 0.15
        chances[4].chance = 0.10
        chances[5].chance = 0.05
    end
    
    local rand = math.random()
    local cumulative = 0
    
    for _, rarityData in ipairs(chances) do
        cumulative = cumulative + rarityData.chance
        if rand <= cumulative then
            return rarityData.rarity
        end
    end
    
    return "Common"
end

function Item:generateBaseStats()
    local rarityMultiplier = 1
    if self.rarity == "Uncommon" then rarityMultiplier = 1.5
    elseif self.rarity == "Rare" then rarityMultiplier = 2
    elseif self.rarity == "Epic" then rarityMultiplier = 3
    elseif self.rarity == "Legendary" then rarityMultiplier = 4 end
    
    if self.type == "weapon" then
        self.attackBonus = math.random(3, 8) * rarityMultiplier
        self.attackSpeed = 0.1 * (rarityMultiplier - 1)
    elseif self.type == "armor" then
        self.defenseBonus = math.random(2, 5) * rarityMultiplier
        self.hpBonus = math.random(10, 25) * rarityMultiplier
    elseif self.type == "helmet" then
        self.defenseBonus = math.random(1, 3) * rarityMultiplier
        self.hpBonus = math.random(5, 15) * rarityMultiplier
    end
end

function Item:generateAffixes()
    local affixCount = Affixes:getAffixCountByRarity(self.rarity)
    self.affixes = Affixes:getRandomAffixes(self.type, affixCount)
    
    -- Apply affix bonuses
    for _, affix in ipairs(self.affixes) do
        if affix.type == "percent" then
            if affix.stat == "attack" then
                self.attackBonus = self.attackBonus + (self.attackBonus * affix.value)
            elseif affix.stat == "hp" then
                self.hpBonus = self.hpBonus + (self.hpBonus * affix.value)
            elseif affix.stat == "defense" then
                self.defenseBonus = self.defenseBonus + (self.defenseBonus * affix.value)
            elseif affix.stat == "lifesteal" then
                self.lifesteal = self.lifesteal + affix.value
            elseif affix.stat == "attackSpeed" then
                self.attackSpeed = self.attackSpeed + affix.value
            elseif affix.stat == "expBonus" then
                self.expBonus = self.expBonus + affix.value
            elseif affix.stat == "critChance" then
                self.critChance = self.critChance + affix.value
            elseif affix.stat == "fireResist" then
                self.fireResist = self.fireResist + affix.value
            elseif affix.stat == "moveSpeed" then
                self.moveSpeed = self.moveSpeed + affix.value
            elseif affix.stat == "cooldownReduction" then
                self.cooldownReduction = self.cooldownReduction + affix.value
            end
        elseif affix.type == "flat" then
            if affix.stat == "manaRegen" then
                self.manaRegen = self.manaRegen + affix.value
            end
        end
    end
    
    -- Round values for display
    self.attackBonus = math.floor(self.attackBonus)
    self.defenseBonus = math.floor(self.defenseBonus)
    self.hpBonus = math.floor(self.hpBonus)
end

function Item:getIcon(itemType)
    if itemType == "weapon" then return "W"
    elseif itemType == "helmet" then return "H"
    elseif itemType == "armor" then return "A"
    else return "?" end
end

function Item:getColor()
    if self.rarity == "Common" then return {0.8, 0.8, 0.8}
    elseif self.rarity == "Uncommon" then return {0, 1, 0}
    elseif self.rarity == "Rare" then return {0, 0, 1}
    elseif self.rarity == "Epic" then return {0.5, 0, 0.5}
    elseif self.rarity == "Legendary" then return {1, 0.65, 0}
    else return {1, 1, 1} end
end

function Item:getAffixDescription()
    local descriptions = {}
    for _, affix in ipairs(self.affixes) do
        local valueText = affix.type == "percent" and string.format("%.1f%%", affix.value * 100) or tostring(affix.value)
        local description = affix.name:gsub("%%", valueText)
        table.insert(descriptions, description)
    end
    return descriptions
end