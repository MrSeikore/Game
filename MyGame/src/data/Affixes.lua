Affixes = {
    AFFIX_POOL = {
        weapon = {
            {name = "+% Damage", type = "percent", stat = "attack", value = 0.1},
            {name = "Life Steal %", type = "percent", stat = "lifesteal", value = 0.05},
            {name = "Attack Speed %", type = "percent", stat = "attackSpeed", value = 0.15},
            {name = "Critical Chance %", type = "percent", stat = "critChance", value = 0.1}
        },
        armor = {
            {name = "+% Health", type = "percent", stat = "hp", value = 0.1},
            {name = "+% Defense", type = "percent", stat = "defense", value = 0.1},
            {name = "Fire Resistance %", type = "percent", stat = "fireResist", value = 0.2},
            {name = "Movement Speed %", type = "percent", stat = "moveSpeed", value = 0.05}
        },
        helmet = {
            {name = "+% Health", type = "percent", stat = "hp", value = 0.08},
            {name = "+% Experience", type = "percent", stat = "expBonus", value = 0.1},
            {name = "Mana Regeneration", type = "flat", stat = "manaRegen", value = 1},
            {name = "Cooldown Reduction %", type = "percent", stat = "cooldownReduction", value = 0.1}
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