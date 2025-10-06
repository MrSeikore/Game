ItemBase = {
    WEAPON = {
        type = "weapon",
        baseStats = {
            attack = {method = "tiered"},
            attackSpeed = {method = "tiered"}
        },
        allowedAffixTypes = {"stat", "combat", "elemental"},
        weight = 1.0
    },
    
    ARMOR = {
        type = "armor", 
        baseStats = {
            defense = {method = "tiered"},
            hp = {method = "tiered"}
        },
        allowedAffixTypes = {"stat", "defense", "utility"},
        weight = 1.0
    },
    
    HELMET = {
        type = "helmet",
        baseStats = {
            defense = {method = "tiered"},
            hp = {method = "tiered"}
        },
        allowedAffixTypes = {"stat", "utility", "magic"},
        weight = 1.0
    }
}

function ItemBase:getBaseItem(itemType)
    return self[itemType:upper()] or self.WEAPON
end

function ItemBase:generateBaseStats(itemType, floorLevel)
    local base = self:getBaseItem(itemType)
    local stats = {}
    local statTiers = {}
    
    local TierRollSystem = require('src/data/items/TierRollSystem')
    
    for statName, statConfig in pairs(base.baseStats) do
        if statConfig.method == "tiered" then
            local tier = TierRollSystem:rollTierForStat(statName, floorLevel)
            local value = TierRollSystem:rollStatValue(statName, tier)
            
            -- Сохраняем значение и тир
            stats[statName] = value
            statTiers[statName] = tier
        end
    end
    
    return stats, statTiers
end

-- Старый метод для обратной совместимости (если нужен)
function ItemBase:generateBaseStatsOld(itemType)
    local base = self:getBaseItem(itemType)
    local stats = {}
    
    for stat, range in pairs(base.baseStats) do
        if range.min and range.max then
            stats[stat] = math.random(range.min, range.max)
        end
    end
    
    return stats
end

return ItemBase