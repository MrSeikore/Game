ItemFactory = {}

function ItemFactory:createItem(itemType, floorLevel)
    local ItemBase = require('src/data/items/ItemBase')
    local RaritySystem = require('src/data/items/RaritySystem')
    local AffixSystem = require('src/data/items/AffixSystem')
    
    -- Генерируем редкость
    local rarity = RaritySystem:generateRarity(floorLevel)
    
    -- Генерируем базовые статы С ТИРАМИ
    local baseStats, statTiers = ItemBase:generateBaseStats(itemType, floorLevel)
    
    -- Базовый Attack Speed для оружия
    local baseAttackSpeed = 0
    if itemType == "weapon" then
        baseAttackSpeed = 1.5  -- Базовый ATS для меча
    end
    
    -- Создаем объект предмета с РАЗДЕЛЕННЫМИ статами
    local item = {
        type = itemType,
        rarity = rarity.name,
        name = rarity.name .. " " .. itemType:gsub("^%l", string.upper),
        icon = self:getIcon(itemType),
        iconType = itemType,
        affixes = {},
        
        -- БАЗОВЫЕ статы (генерируются из ItemBase)
        baseAttack = baseStats.attack or 0,
        baseDefense = baseStats.defense or 0,
        baseHP = baseStats.hp or 0,
        baseAttackSpeed = baseAttackSpeed,  -- Базовый ATS (не тирится)
        
        statTiers = statTiers or {}, -- ТИРЫ базовых статов
        affixTiers = {}, -- ТИРЫ аффиксов
        
        -- Бонусы от аффиксов (отдельно, изначально нули)
        bonusAttack = 0,
        bonusDefense = 0,
        bonusHP = 0,
        bonusAttackSpeed = 0
    }
    
    -- Инициализируем все остальные статы нулями
    local allStats = {
        "lifesteal", "expBonus", "critChance", "fireResist", "moveSpeed", "manaRegen",
        "cooldownReduction", "critDamage", "armorPen", "bleedChance", "poisonDamage",
        "damageReflect", "thorns", "healthRegen", "dodgeChance", "magicFind",
        "goldFind", "skillDamage", "resourceCostReduction"
    }
    
    for _, stat in ipairs(allStats) do
        item[stat] = 0
    end
    
    -- Добавляем аффиксы С ТИРАМИ
    if rarity.affixCount > 0 then
        item.affixes, item.affixTiers = AffixSystem:getRandomAffixes(itemType, rarity.affixCount, floorLevel)
        self:applyAffixes(item, item.affixes)
    end
    
    -- Устанавливаем цвет в зависимости от редкости
    item.color = rarity.color
    
    setmetatable(item, {__index = self.itemMeta})
    setmetatable(item, ItemFactory.itemMeta)
    return item
end


function ItemFactory:applyAffixes(item, affixes)
    -- Временные переменные для хранения процентных бонусов
    local attackPercentBonus = 0
    local defensePercentBonus = 0
    local hpPercentBonus = 0
    
    -- Сначала собираем все процентные бонусы
    for _, affix in ipairs(affixes) do
        local value = affix.value
        
        if affix.stat == "attackPercent" then
            attackPercentBonus = attackPercentBonus + value
        elseif affix.stat == "defensePercent" then
            defensePercentBonus = defensePercentBonus + value
        elseif affix.stat == "hpPercent" then
            hpPercentBonus = hpPercentBonus + value
        end
    end
    
    -- Затем применяем все аффиксы к БОНУСНЫМ статам
    for _, affix in ipairs(affixes) do
        local value = affix.value
        
        -- Плоские аффиксы к базовым статам (добавляем к бонусам)
        if affix.stat == "attack" then
            item.bonusAttack = item.bonusAttack + value
        elseif affix.stat == "defense" then
            item.bonusDefense = item.bonusDefense + value
        elseif affix.stat == "hp" then
            item.bonusHP = item.bonusHP + value
        elseif affix.stat == "attackSpeed" then
            item.bonusAttackSpeed = (item.bonusAttackSpeed or 0) + value
        
        -- Остальные статы (добавляем напрямую)
        elseif affix.stat == "lifesteal" then
            item.lifesteal = item.lifesteal + value
        elseif affix.stat == "critChance" then
            item.critChance = item.critChance + value
        elseif affix.stat == "critDamage" then
            item.critDamage = item.critDamage + value
        elseif affix.stat == "armorPen" then
            item.armorPen = item.armorPen + value
        elseif affix.stat == "bleedChance" then
            item.bleedChance = item.bleedChance + value
        elseif affix.stat == "poisonDamage" then
            item.poisonDamage = item.poisonDamage + value
        elseif affix.stat == "fireResist" then
            item.fireResist = item.fireResist + value
        elseif affix.stat == "moveSpeed" then
            item.moveSpeed = item.moveSpeed + value
        elseif affix.stat == "expBonus" then
            item.expBonus = item.expBonus + value
        elseif affix.stat == "manaRegen" then
            item.manaRegen = item.manaRegen + value
        elseif affix.stat == "cooldownReduction" then
            item.cooldownReduction = item.cooldownReduction + value
        elseif affix.stat == "damageReflect" then
            item.damageReflect = item.damageReflect + value
        elseif affix.stat == "thorns" then
            item.thorns = item.thorns + value
        elseif affix.stat == "healthRegen" then
            item.healthRegen = item.healthRegen + value
        elseif affix.stat == "dodgeChance" then
            item.dodgeChance = item.dodgeChance + value
        elseif affix.stat == "magicFind" then
            item.magicFind = item.magicFind + value
        elseif affix.stat == "goldFind" then
            item.goldFind = item.goldFind + value
        elseif affix.stat == "skillDamage" then
            item.skillDamage = item.skillDamage + value
        elseif affix.stat == "resourceCostReduction" then
            item.resourceCostReduction = item.resourceCostReduction + value
        
        -- Процентные аффиксы к базовым статам (применяем в конце)
        elseif affix.stat == "attackPercent" then
            -- Уже собрали выше, применим позже
        elseif affix.stat == "defensePercent" then
            -- Уже собрали выше, применим позже
        elseif affix.stat == "hpPercent" then
            -- Уже собрали выше, применим позже
        else
            -- Для неизвестных статов просто добавляем значение
            item[affix.stat] = (item[affix.stat] or 0) + value
        end
    end
    
    -- Применяем процентные бонусы к базовым статам (добавляем к бонусам)
    if attackPercentBonus > 0 then
        local baseAttack = item.baseAttack
        local bonus = math.floor(baseAttack * attackPercentBonus)
        item.bonusAttack = item.bonusAttack + bonus
    end
    
    if defensePercentBonus > 0 then
        local baseDefense = item.baseDefense
        local bonus = math.floor(baseDefense * defensePercentBonus)
        item.bonusDefense = item.bonusDefense + bonus
    end
    
    if hpPercentBonus > 0 then
        local baseHP = item.baseHP
        local bonus = math.floor(baseHP * hpPercentBonus)
        item.bonusHP = item.bonusHP + bonus
    end
end

function ItemFactory:getIcon(itemType)
    if itemType == "weapon" then return "W"
    elseif itemType == "helmet" then return "H"
    elseif itemType == "armor" then return "A"
    else return "?" end
end

-- Метатаблица для методов предмета
ItemFactory.itemMeta = {
    getColor = function(self)
        return self.color or {1, 1, 1}
    end,
    
    getAffixDescription = function(self)
        local descriptions = {}
        for _, affix in ipairs(self.affixes) do
            local valueText = affix.type == "percent" and 
                string.format("%.1f%%", affix.value * 100) or tostring(math.floor(affix.value))
            local description = affix.name:gsub("%%", valueText)
            table.insert(descriptions, description)
        end
        return descriptions
    end,
    
    -- Геттеры для итоговых значений (для Player)
    getTotalAttack = function(self)
        return (self.baseAttack or 0) + (self.bonusAttack or 0)
    end,
    
    getTotalDefense = function(self)
        return (self.baseDefense or 0) + (self.bonusDefense or 0)
    end,
    
    getTotalHP = function(self)
        return (self.baseHP or 0) + (self.bonusHP or 0)
    end,
    
    getTotalAttackSpeed = function(self)
        return (self.baseAttackSpeed or 0) + (self.bonusAttackSpeed or 0)
    end,
    
    -- Геттеры для бонусов (для Player)
    getAttackBonus = function(self)
        return self.bonusAttack or 0
    end,
    
    getDefenseBonus = function(self)
        return self.bonusDefense or 0
    end,
    
    getHPBonus = function(self)
        return self.bonusHP or 0
    end,
    
    getAttackSpeedBonus = function(self)
        return self.bonusAttackSpeed or 0
    end
}

return ItemFactory