AffixSystem = {
    modifierPools = {
        "StatModifiers",
        "EffectModifiers"
    }
}

function AffixSystem:getAvailableModifiers(itemType)
    local allModifiers = {}
    
    for _, poolName in ipairs(self.modifierPools) do
        local success, pool = pcall(require, 'src/data/items/modifiers/' .. poolName)
        if success then
            local modifiers = pool:getModifiersForItem(itemType)
            for _, modifier in ipairs(modifiers) do
                table.insert(allModifiers, modifier)
            end
        else
            print("WARNING: Failed to load modifier pool: " .. poolName)
        end
    end
    
    return allModifiers
end

function AffixSystem:getRandomAffixes(itemType, count, floorLevel)
    local available = self:getAvailableModifiers(itemType)
    local selected = {}
    local selectedTiers = {}
    
    if #available == 0 then return selected, selectedTiers end
    
    local TierRollSystem = require('src/data/items/TierRollSystem')
    
    -- Взвешенный выбор
    local totalWeight = 0
    for _, modifier in ipairs(available) do
        totalWeight = totalWeight + (modifier.weight or 1)
    end
    
    for i = 1, count do
        if #available == 0 then break end
        
        local randomValue = math.random() * totalWeight
        local currentWeight = 0
        local selectedIndex = nil
        
        for j = 1, #available do
            local modifier = available[j]
            currentWeight = currentWeight + (modifier.weight or 1)
            
            if randomValue <= currentWeight then
                selectedIndex = j
                break
            end
        end
        
        if selectedIndex then
            local modifier = available[selectedIndex]
            
            -- Роллим тир для этого аффикса с учетом этажа
            local tier = TierRollSystem:rollTierForStat(modifier.stat, floorLevel)
            
            -- Получаем значение через функцию модификатора
            local value = modifier.value(tier)
            
            -- Округляем значение
            if modifier.type == "percent" then
                value = math.floor(value * 100 + 0.5) / 100  -- 2 знака после запятой
            else
                value = math.floor(value + 0.5)  -- целое число
            end
            
            table.insert(selected, {
                name = modifier.name,
                type = modifier.type,
                stat = modifier.stat,
                value = value,
                baseRange = modifier.baseRange
            })
            
            table.insert(selectedTiers, {
                stat = modifier.stat,
                tier = tier
            })
            
            -- Обновляем веса
            totalWeight = totalWeight - (modifier.weight or 1)
            table.remove(available, selectedIndex)
        end
    end
    
    return selected, selectedTiers
end

-- Получить диапазон для аффикса и тира
function AffixSystem:getAffixRange(affix, tier)
    if not affix.baseRange then return nil end
    
    local min12, max12 = affix.baseRange[1], affix.baseRange[2]
    
    -- Tier 12 = base, Tier 1 = лучший
    local tierMultiplier = math.pow(1.25, 12 - tier)
    
    local newMin = min12 * tierMultiplier
    local newMax = max12 * tierMultiplier
    
    if affix.type == "percent" then
        newMin = math.floor(newMin * 100 + 0.5) / 100
        newMax = math.floor(newMax * 100 + 0.5) / 100
    else
        newMin = math.floor(newMin + 0.5)
        newMax = math.floor(newMax + 0.5)
    end
    
    return {newMin, newMax}
end

return AffixSystem