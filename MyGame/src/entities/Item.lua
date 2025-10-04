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
        affixes = {},
        icon = self:getIcon(itemType)
    }
    
    setmetatable(o, self)
    self.__index = self
    
    o:generateBaseStats()
    o.name = o.rarity .. " " .. itemType
    
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
    if self.rarity == "Uncommon" then rarityMultiplier = 2
    elseif self.rarity == "Rare" then rarityMultiplier = 3
    elseif self.rarity == "Epic" then rarityMultiplier = 4
    elseif self.rarity == "Legendary" then rarityMultiplier = 5 end
    
    if self.type == "weapon" then
        self.attackBonus = math.random(3, 8) * rarityMultiplier
        self.attackSpeed = 0.1 * rarityMultiplier
    elseif self.type == "armor" then
        self.defenseBonus = math.random(2, 5) * rarityMultiplier
        self.hpBonus = math.random(10, 25) * rarityMultiplier
    elseif self.type == "helmet" then
        self.defenseBonus = math.random(1, 3) * rarityMultiplier
        self.hpBonus = math.random(5, 15) * rarityMultiplier
    end
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