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
    -- Бесконечная прогрессия шансов
    local baseChances = {
        Common = math.max(0.1, 0.7 - (floorLevel * 0.05)),
        Uncommon = math.min(0.4, 0.25 + (floorLevel * 0.03)),
        Rare = math.min(0.3, 0.05 + (floorLevel * 0.02)),
        Epic = math.min(0.2, 0.0 + (floorLevel * 0.015)),
        Legendary = math.min(0.1, 0.0 + (floorLevel * 0.01))
    }
    
    -- Нормализуем шансы чтобы сумма была 1
    local total = baseChances.Common + baseChances.Uncommon + baseChances.Rare + baseChances.Epic + baseChances.Legendary
    local chances = {
        {rarity = "Common", chance = baseChances.Common / total},
        {rarity = "Uncommon", chance = baseChances.Uncommon / total},
        {rarity = "Rare", chance = baseChances.Rare / total},
        {rarity = "Epic", chance = baseChances.Epic / total},
        {rarity = "Legendary", chance = baseChances.Legendary / total}
    }
    
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
    
    -- Базовые статы в зависимости от типа предмета
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
    
    -- Временные переменные для базовых статов до применения аффиксов
    local baseAttack = self.attackBonus
    local baseDefense = self.defenseBonus
    local baseHP = self.hpBonus
    
    -- Применяем аффиксы
    for _, affix in ipairs(self.affixes) do
        if affix.type == "percent" then
            if affix.stat == "attack" then
                self.attackBonus = self.attackBonus + math.floor(baseAttack * affix.value)
            elseif affix.stat == "hp" then
                self.hpBonus = self.hpBonus + math.floor(baseHP * affix.value)
            elseif affix.stat == "defense" then
                self.defenseBonus = self.defenseBonus + math.floor(baseDefense * affix.value)
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
            elseif affix.stat == "critDamage" then
                self.critDamage = self.critDamage + affix.value
            elseif affix.stat == "armorPen" then
                self.armorPen = self.armorPen + affix.value
            elseif affix.stat == "bleedChance" then
                self.bleedChance = self.bleedChance + affix.value
            elseif affix.stat == "poisonDamage" then
                self.poisonDamage = self.poisonDamage + affix.value
            elseif affix.stat == "damageReflect" then
                self.damageReflect = self.damageReflect + affix.value
            elseif affix.stat == "dodgeChance" then
                self.dodgeChance = self.dodgeChance + affix.value
            elseif affix.stat == "magicFind" then
                self.magicFind = self.magicFind + affix.value
            elseif affix.stat == "goldFind" then
                self.goldFind = self.goldFind + affix.value
            elseif affix.stat == "skillDamage" then
                self.skillDamage = self.skillDamage + affix.value
            elseif affix.stat == "resourceCostReduction" then
                self.resourceCostReduction = self.resourceCostReduction + affix.value
            end
        elseif affix.type == "flat" then
            if affix.stat == "manaRegen" then
                self.manaRegen = self.manaRegen + affix.value
            elseif affix.stat == "thorns" then
                self.thorns = self.thorns + affix.value
            elseif affix.stat == "healthRegen" then
                self.healthRegen = self.healthRegen + affix.value
            end
        end
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

function Item:getAffixDescription()
    local descriptions = {}
    for _, affix in ipairs(self.affixes) do
        local valueText = affix.type == "percent" and string.format("%.1f%%", affix.value * 100) or tostring(affix.value)
        local description = affix.name:gsub("%%", valueText)
        table.insert(descriptions, description)
    end
    return descriptions
end