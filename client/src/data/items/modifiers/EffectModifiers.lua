EffectModifiers = {
    modifiers = {
        LIFESTEAL = {
            name = "#% Life Steal",
            type = "percent",
            itemTypes = {"weapon"},
            stat = "lifesteal",
            baseRange = {0.01, 0.03},
            value = function(tier)
                local min12, max12 = 0.01, 0.03
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 20
        },
        
        CRIT_CHANCE = {
            name = "#% Critical Chance", 
            type = "percent",
            itemTypes = {"weapon"},
            stat = "critChance",
            baseRange = {0.02, 0.04},
            value = function(tier)
                local min12, max12 = 0.02, 0.04
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 15
        },
        
        CRIT_DAMAGE = {
            name = "#% Critical Damage",
            type = "percent",
            itemTypes = {"weapon"},
            stat = "critDamage",
            baseRange = {0.10, 0.15},
            value = function(tier)
                local min12, max12 = 0.10, 0.15
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 12
        },
        
        DODGE_CHANCE = {
            name = "#% Dodge Chance",
            type = "percent",
            itemTypes = {"armor"},
            stat = "dodgeChance", 
            baseRange = {0.01, 0.03},
            value = function(tier)
                local min12, max12 = 0.01, 0.03
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 15
        },
        
        MANA_REGEN = {
            name = "# Mana Regeneration",
            type = "flat",
            itemTypes = {"helmet"},
            stat = "manaRegen",
            baseRange = {1, 3},
            value = function(tier)
                local min12, max12 = 1, 3
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 10
        }
    }
}

function EffectModifiers:getModifiersForItem(itemType)
    local available = {}
    for _, modifier in pairs(self.modifiers) do
        for _, allowedType in ipairs(modifier.itemTypes) do
            if allowedType == itemType then
                table.insert(available, modifier)
                break
            end
        end
    end
    return available
end

return EffectModifiers