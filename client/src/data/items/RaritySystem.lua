RaritySystem = {
    RARITIES = {
        COMMON = {
            name = "Common",
            color = {0.8, 0.8, 0.8},
            affixCount = 0,
            weight = 70
        },
        UNCOMMON = {
            name = "Uncommon", 
            color = {0, 1, 0},
            affixCount = 1,
            weight = 50
        },
        RARE = {
            name = "Rare",
            color = {0, 0, 1},
            affixCount = 2, 
            weight = 25
        },
        EPIC = {
            name = "Epic",
            color = {0.5, 0, 0.5},
            affixCount = 3,
            weight = 10
        },
        LEGENDARY = {
            name = "Legendary",
            color = {1, 0.65, 0},
            affixCount = 4,
            weight = 5
        }
    }
}

function RaritySystem:generateRarity(floorLevel)
    -- Прогрессия шансов с ростом этажей
    local levelBonus = floorLevel * 0.5
    local weights = {}
    
    for rarityName, rarityData in pairs(self.RARITIES) do
        weights[rarityName] = math.max(1, rarityData.weight + levelBonus)
    end
    
    -- Взвешенный случайный выбор
    local totalWeight = 0
    for _, weight in pairs(weights) do
        totalWeight = totalWeight + weight
    end
    
    local randomValue = math.random() * totalWeight
    local currentWeight = 0
    
    for rarityName, rarityData in pairs(self.RARITIES) do
        currentWeight = currentWeight + weights[rarityName]
        if randomValue <= currentWeight then
            return rarityData
        end
    end
    
    return self.RARITIES.COMMON
end

return RaritySystem