TierSystem = {
    MAX_TIER = 12,
    MIN_TIER = 1,
    
    -- БАЗОВЫЕ диапазоны для Tier 12 (худший)
    BASE_RANGES_TIER_12 = {
        -- Основные статы (плоские значения)
        attack = {3, 8},
        defense = {2, 6},
        hp = {10, 25},
        
        -- Боевые статы (проценты)
        attackSpeed = {0.05, 0.10},
        lifesteal = {0.01, 0.03},
        critChance = {0.02, 0.05},
        critDamage = {0.10, 0.20},
        armorPen = {0.05, 0.12},
        bleedChance = {0.02, 0.04},
        poisonDamage = {0.05, 0.10},
        
        -- Защитные статы (проценты)
        fireResist = {0.08, 0.15},
        dodgeChance = {0.01, 0.03},
        damageReflect = {0.04, 0.10},
        
        -- Утилиты (проценты)
        moveSpeed = {0.01, 0.03},
        expBonus = {0.05, 0.12},
        cooldownReduction = {0.03, 0.08},
        magicFind = {0.06, 0.15},
        goldFind = {0.08, 0.18},
        skillDamage = {0.05, 0.12},
        resourceCostReduction = {0.02, 0.05},
        
        -- Регенерация (плоские значения)
        manaRegen = {1, 3},
        thorns = {3, 8},
        healthRegen = {2, 5}
    }
}

function TierSystem:initialize()
    if self.initialized then return end
    
    -- Генерируем диапазоны для всех тиров на основе Tier 12
    -- Каждый следующий тир начинается с max предыдущего + 1
    self.BASE_RANGES = {}
    
    for statName, tier12Range in pairs(self.BASE_RANGES_TIER_12) do
        self.BASE_RANGES[statName] = self:generateProgressiveTierRanges(statName, tier12Range)
    end
    
    self.initialized = true
end

function TierSystem:generateProgressiveTierRanges(statName, tier12Range)
    local ranges = {}
    local min12, max12 = tier12Range[1], tier12Range[2]
    
    -- Tier 12 (базовый)
    ranges[12] = {min12, max12}
    
    -- Генерируем тиры от 11 до 1
    for tier = 11, 1, -1 do
        local prevMin, prevMax = ranges[tier + 1][1], ranges[tier + 1][2]
        
        -- Увеличиваем диапазон на 20-30%
        local increasePercent = 0.25 + (math.random() * 0.1) -- 25-35%
        
        local newMin = prevMax + 1
        local rangeSize = prevMax - prevMin
        local newRangeSize = math.floor(rangeSize * (1 + increasePercent))
        local newMax = newMin + newRangeSize
        
        -- Для процентных значений округляем до 2 знаков
        if prevMin < 1 then
            newMin = math.floor(newMin * 100) / 100
            newMax = math.floor(newMax * 100) / 100
        else
            newMin = math.floor(newMin)
            newMax = math.floor(newMax)
        end
        
        ranges[tier] = {newMin, newMax}
    end
    
    return ranges
end

function TierSystem:getValueForTier(statName, tier)
    self:initialize()
    
    local ranges = self.BASE_RANGES[statName]
    if not ranges or not ranges[tier] then
        return math.random(1, 5) -- fallback
    end
    
    local minVal, maxVal = ranges[tier][1], ranges[tier][2]
    
    -- Для процентных значений возвращаем случайное значение между min и max
    if minVal < 1 then
        -- Линейная интерполяция для дробных значений
        return minVal + (maxVal - minVal) * math.random()
    else
        -- Целочисленные значения
        return math.random(minVal, maxVal)
    end
end

function TierSystem:getTierRange(statName, tier)
    self:initialize()
    
    local ranges = self.BASE_RANGES[statName]
    if not ranges or not ranges[tier] then
        return {1, 5}
    end
    
    return ranges[tier]
end

function TierSystem:getAllAvailableTiers(floorLevel)
    local availableTiers = {}
    local minTier = math.max(1, 12 - math.floor((floorLevel - 1) / 10))
    
    for tier = 12, minTier, -1 do
        table.insert(availableTiers, tier)
    end
    
    return availableTiers
end

-- Функция для отладки - посмотреть все диапазоны
function TierSystem:printAllRanges()
    self:initialize()
    for statName, ranges in pairs(self.BASE_RANGES) do
        print("=== " .. statName .. " ===")
        for tier = 1, 12 do
            if ranges[tier] then
                local minVal, maxVal = ranges[tier][1], ranges[tier][2]
                if minVal < 1 then
                    print(string.format("Tier %d: %.1f%% - %.1f%%", tier, minVal * 100, maxVal * 100))
                else
                    print("Tier " .. tier .. ": " .. minVal .. "-" .. maxVal)
                end
            end
        end
    end
end

return TierSystem