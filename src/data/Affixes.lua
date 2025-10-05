Affixes = {
    AFFIX_POOL = {
        weapon = {
            {name = "Damage: +", type = "percent", stat = "attack", value = 0.15},
            {name = "Life Steal: +", type = "percent", stat = "lifesteal", value = 0.06},
            {name = "Attack Speed: +", type = "percent", stat = "attackSpeed", value = 0.12},
            {name = "Critical Chance: +", type = "percent", stat = "critChance", value = 0.08},
            {name = "Critical Damage: +", type = "percent", stat = "critDamage", value = 0.25},
            {name = "Armor Penetration: +", type = "percent", stat = "armorPen", value = 0.18},
            {name = "Bleed Chance: +", type = "percent", stat = "bleedChance", value = 0.07},
            {name = "Poison Damage: +", type = "percent", stat = "poisonDamage", value = 0.14}
        },
        armor = {
            {name = "Health: +", type = "percent", stat = "hp", value = 0.11},
            {name = "Defense: +", type = "percent", stat = "defense", value = 0.09},
            {name = "Fire Resistance: +", type = "percent", stat = "fireResist", value = 0.22},
            {name = "Movement Speed: +", type = "percent", stat = "moveSpeed", value = 0.04},
            {name = "Damage Reflection: +", type = "percent", stat = "damageReflect", value = 0.13},
            {name = "Thorns: +", type = "percent", stat = "thorns", value = 0.16},
            {name = "Health Regeneration: +", type = "flat", stat = "healthRegen", value = 3},
            {name = "Dodge Chance: +", type = "percent", stat = "dodgeChance", value = 0.03}
        },
        helmet = {
            {name = "Health: +", type = "percent", stat = "hp", value = 0.07},
            {name = "Experience: +", type = "percent", stat = "expBonus", value = 0.17},
            {name = "Mana Regeneration: +", type = "flat", stat = "manaRegen", value = 2},
            {name = "Cooldown Reduction: +", type = "percent", stat = "cooldownReduction", value = 0.11},
            {name = "Magic Find: +", type = "percent", stat = "magicFind", value = 0.19},
            {name = "Gold Find: +", type = "percent", stat = "goldFind", value = 0.23},
            {name = "Skill Damage: +", type = "percent", stat = "skillDamage", value = 0.15},
            {name = "Resource Cost Reduction: +", type = "percent", stat = "resourceCostReduction", value = 0.05}
        }
    }
}

function Affixes:getRandomAffixes(itemType, count)
    local availableAffixes = {}
    
    -- Copy available affixes for this item type
    for _, affix in ipairs(self.AFFIX_POOL[itemType]) do
        table.insert(availableAffixes, affix)
    end
    
    local selectedAffixes = {}
    
    for i = 1, count do
        if #availableAffixes == 0 then break end
        
        local randomIndex = math.random(1, #availableAffixes)
        local selectedAffix = availableAffixes[randomIndex]
        
        table.insert(selectedAffixes, {
            name = selectedAffix.name,
            type = selectedAffix.type,
            stat = selectedAffix.stat,
            value = selectedAffix.value
        })
        
        -- Remove to avoid duplicates
        table.remove(availableAffixes, randomIndex)
    end
    
    return selectedAffixes
end

function Affixes:getAffixCountByRarity(rarity)
    if rarity == "Common" then return 0
    elseif rarity == "Uncommon" then return 1
    elseif rarity == "Rare" then return 2
    elseif rarity == "Epic" then return 3
    elseif rarity == "Legendary" then return 4
    else return 0 end
end

return Affixes