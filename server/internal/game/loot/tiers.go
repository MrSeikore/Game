package loot

import "math/rand"

// TierSystem повторяет TierSystem.lua
type TierSystem struct {
	baseRanges map[string]map[int][2]float64
	initialized bool
}

func NewTierSystem() *TierSystem {
	ts := &TierSystem{
		baseRanges: make(map[string]map[int][2]float64),
	}
	ts.initialize()
	return ts
}

// initialize повторяет TierSystem:initialize() из TierSystem.lua
func (ts *TierSystem) initialize() {
	if ts.initialized {
		return
	}
	
	// Базовые диапазоны для Tier 12 (худший) как в оригинале
	baseRangesTier12 := map[string][2]float64{
		"attack":       {3, 8},
		"defense":      {2, 6},
		"hp":           {10, 25},
		"attackSpeed":  {0.05, 0.10},
		"lifesteal":    {0.01, 0.03},
		"critChance":   {0.02, 0.05},
		"critDamage":   {0.10, 0.20},
		"armorPen":     {0.05, 0.12},
		"bleedChance":  {0.02, 0.04},
		"poisonDamage": {0.05, 0.10},
		"fireResist":   {0.08, 0.15},
		"dodgeChance":  {0.01, 0.03},
		"moveSpeed":    {0.01, 0.03},
		"expBonus":     {0.05, 0.12},
		"cooldownReduction": {0.03, 0.08},
		"magicFind":    {0.06, 0.15},
		"goldFind":     {0.08, 0.18},
		"skillDamage":  {0.05, 0.12},
		"resourceCostReduction": {0.02, 0.05},
		"manaRegen":    {1, 3},
		"thorns":       {3, 8},
		"healthRegen":  {2, 5},
	}
	
	// Генерируем диапазоны для всех тиров как в оригинале
	for statName, tier12Range := range baseRangesTier12 {
		ts.baseRanges[statName] = ts.generateProgressiveTierRanges(statName, tier12Range)
	}
	
	ts.initialized = true
}

// generateProgressiveTierRanges повторяет оригинальную логику
func (ts *TierSystem) generateProgressiveTierRanges(statName string, tier12Range [2]float64) map[int][2]float64 {
	ranges := make(map[int][2]float64)
	min12, max12 := tier12Range[0], tier12Range[1]
	
	// Tier 12 (базовый)
	ranges[12] = [2]float64{min12, max12}
	
	// Генерируем тиры от 11 до 1 как в оригинале
	for tier := 11; tier >= 1; tier-- {
		prevMin, prevMax := ranges[tier+1][0], ranges[tier+1][1]
		
		// Увеличиваем диапазон на 20-30% как в оригинале
		increasePercent := 0.25 + (rand.Float64() * 0.1) // 25-35%
		
		newMin := prevMax + 1
		rangeSize := prevMax - prevMin
		newRangeSize := rangeSize * (1 + increasePercent)
		newMax := newMin + newRangeSize
		
		// Округляем как в оригинале
		if prevMin < 1 {
			newMin = roundToDecimal(newMin, 2)
			newMax = roundToDecimal(newMax, 2)
		} else {
			newMin = roundToInt(newMin)
			newMax = roundToInt(newMax)
		}
		
		ranges[tier] = [2]float64{newMin, newMax}
	}
	
	return ranges
}

// RollTierForStat повторяет TierRollSystem:rollTierForStat()
func (ts *TierSystem) RollTierForStat(statName string, floorLevel int) int {
	availableTiers := ts.GetAvailableTiersForFloor(floorLevel)
	tierIndex := rand.Intn(len(availableTiers))
	return availableTiers[tierIndex]
}

// RollStatValue повторяет TierRollSystem:rollStatValue()
func (ts *TierSystem) RollStatValue(statName string, tier int) int {
	ranges, exists := ts.baseRanges[statName]
	if !exists || ranges[tier][0] == 0 {
		return rand.Intn(5) + 1 // fallback как в оригинале
	}
	
	minVal, maxVal := ranges[tier][0], ranges[tier][1]
	
	if minVal < 1 {
		// Линейная интерполяция для дробных значений
		value := minVal + (maxVal-minVal)*rand.Float64()
		return int(value * 100) // Конвертируем в проценты
	} else {
		// Целочисленные значения
		return rand.Intn(int(maxVal)-int(minVal)+1) + int(minVal)
	}
}

// GetAvailableTiersForFloor повторяет оригинальную логику
func (ts *TierSystem) GetAvailableTiersForFloor(floorLevel int) []int {
	available := []int{}
	minTier := max(1, 12 - (floorLevel-1)/10)
	
	for tier := 12; tier >= minTier; tier-- {
		available = append(available, tier)
	}
	
	return available
}

// Вспомогательные функции
func roundToInt(val float64) float64 {
	return float64(int(val + 0.5))
}

func roundToDecimal(val float64, decimals int) float64 {
	multiplier := 1.0
	for i := 0; i < decimals; i++ {
		multiplier *= 10
	}
	return float64(int(val*multiplier+0.5)) / multiplier
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}