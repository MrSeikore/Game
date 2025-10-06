StatModifiers = {
    modifiers = {
        -- ПЛОСКИЕ аффиксы (Adds # Damage)
        WEAPON_DAMAGE_FLAT = {
            name = "Adds # Damage",
            type = "flat",
            itemTypes = {"weapon"},
            stat = "attack",
            baseRange = {3, 8},
            value = function(tier)
                local min12, max12 = 3, 8
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 30
        },
        
        ARMOR_DEFENSE_FLAT = {
            name = "Adds # Defense", 
            type = "flat",
            itemTypes = {"armor", "helmet"},
            stat = "defense",
            baseRange = {2, 6},
            value = function(tier)
                local min12, max12 = 2, 6
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 30
        },
        
        ARMOR_HP_FLAT = {
            name = "Adds # HP",
            type = "flat", 
            itemTypes = {"armor", "helmet"},
            stat = "hp",
            baseRange = {10, 25},
            value = function(tier)
                local min12, max12 = 10, 25
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 25
        },
        
        -- ПРОЦЕНТНЫЕ аффиксы (#% Damage)
        WEAPON_DAMAGE_PERCENT = {
            name = "#% Damage",
            type = "percent", 
            itemTypes = {"weapon"},
            stat = "attackPercent",
            baseRange = {0.05, 0.10},
            value = function(tier)
                local min12, max12 = 0.05, 0.10
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 20
        },
        
        ARMOR_DEFENSE_PERCENT = {
            name = "#% Defense",
            type = "percent",
            itemTypes = {"armor", "helmet"}, 
            stat = "defensePercent",
            baseRange = {0.05, 0.08},
            value = function(tier)
                local min12, max12 = 0.05, 0.08
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 20
        },
        
        ARMOR_HP_PERCENT = {
            name = "#% HP",
            type = "percent",
            itemTypes = {"armor", "helmet"},
            stat = "hpPercent", 
            baseRange = {0.08, 0.12},
            value = function(tier)
                local min12, max12 = 0.08, 0.12
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 15
        },
        
        WEAPON_ATTACK_SPEED = {
            name = "#% Attack Speed", 
            type = "percent",
            itemTypes = {"weapon"},
            stat = "attackSpeed", 
            baseRange = {0.05, 0.08},
            value = function(tier)
                local min12, max12 = 0.05, 0.08
                local tierMultiplier = math.pow(1.25, 12 - tier)
                local value = min12 + (max12 - min12) * math.random()
                return value * tierMultiplier
            end,
            weight = 25
        }
    }
}

function StatModifiers:getModifiersForItem(itemType)
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

return StatModifiers