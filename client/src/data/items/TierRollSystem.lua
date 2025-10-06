TierRollSystem = {}

function TierRollSystem:rollTierForStat(statName, floorLevel)
    local TierSystem = require('src/data/items/TierSystem')
    local availableTiers = self:getAvailableTiersForFloor(floorLevel)
    
    -- Равномерное распределение по доступным тирам
    local tierIndex = math.random(1, #availableTiers)
    return availableTiers[tierIndex]
end

function TierRollSystem:getAvailableTiersForFloor(floorLevel)
    local available = {}
    
    -- Каждый тир добавляется раз в 10 этажей
    -- Tier 12 = худший, Tier 1 = лучший
    local minTier = math.max(1, 12 - math.floor((floorLevel - 1) / 10))
    
    for tier = 12, minTier, -1 do
        table.insert(available, tier)
    end
    
    return available
end

function TierRollSystem:rollStatValue(statName, tier)
    local TierSystem = require('src/data/items/TierSystem')
    return TierSystem:getValueForTier(statName, tier)
end

-- Для уникальных предметов с фиксированными тирами
function TierRollSystem:rollStatWithFixedTier(statName, fixedTier)
    local TierSystem = require('src/data/items/TierSystem')
    return TierSystem:getValueForTier(statName, fixedTier), fixedTier
end

return TierRollSystem