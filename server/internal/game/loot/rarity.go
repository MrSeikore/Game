package loot

import "math/rand"

// RarityData повторяет RARITIES из RaritySystem.lua
type RarityData struct {
	Name       string
	Color      [3]float64
	AffixCount int
	Weight     int
}

// RaritySystem повторяет RaritySystem.lua
type RaritySystem struct {
	Rarities map[string]RarityData
}

func NewRaritySystem() *RaritySystem {
	return &RaritySystem{
		Rarities: map[string]RarityData{
			"COMMON": {
				Name:       "Common",
				Color:      [3]float64{0.8, 0.8, 0.8},
				AffixCount: 0,
				Weight:     70,
			},
			"UNCOMMON": {
				Name:       "Uncommon", 
				Color:      [3]float64{0, 1, 0},
				AffixCount: 1,
				Weight:     50,
			},
			"RARE": {
				Name:       "Rare",
				Color:      [3]float64{0, 0, 1},
				AffixCount: 2,
				Weight:     25,
			},
			"EPIC": {
				Name:       "Epic",
				Color:      [3]float64{0.5, 0, 0.5},
				AffixCount: 3,
				Weight:     10,
			},
			"LEGENDARY": {
				Name:       "Legendary",
				Color:      [3]float64{1, 0.65, 0},
				AffixCount: 4,
				Weight:     5,
			},
		},
	}
}

// GenerateRarity повторяет RaritySystem:generateRarity() из RaritySystem.lua
func (rs *RaritySystem) GenerateRarity(floorLevel int) RarityData {
	// Прогрессия шансов с ростом этажей как в оригинале
	levelBonus := float64(floorLevel) * 0.5
	weights := make(map[string]float64)
	
	for rarityName, rarityData := range rs.Rarities {
		weights[rarityName] = maxFloat(1, float64(rarityData.Weight)+levelBonus)
	}
	
	// Взвешенный случайный выбор как в оригинале
	totalWeight := 0.0
	for _, weight := range weights {
		totalWeight += weight
	}
	
	randomValue := rand.Float64() * totalWeight
	currentWeight := 0.0
	
	for rarityName, rarityData := range rs.Rarities {
		currentWeight += weights[rarityName]
		if randomValue <= currentWeight {
			return rarityData
		}
	}
	
	return rs.Rarities["COMMON"] // Fallback как в оригинале
}

// Вспомогательные функции
func maxFloat(a, b float64) float64 {
	if a > b {
		return a
	}
	return b
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}