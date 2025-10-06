package loot

import (
	"math"
	"math/rand"
	"server/types"  // ИЗМЕНИТЬ эту строку
)

// AffixSystem повторяет AffixSystem.lua
type AffixSystem struct {
	modifierPools []string
	statModifiers map[string]Modifier
	effectModifiers map[string]Modifier
}

type Modifier struct {
	Name      string
	Type      string
	ItemTypes []string
	Stat      string
	BaseRange [2]float64
	Weight    int
}

func NewAffixSystem() *AffixSystem {
	as := &AffixSystem{
		modifierPools: []string{"StatModifiers", "EffectModifiers"},
		statModifiers: make(map[string]Modifier),
		effectModifiers: make(map[string]Modifier),
	}
	
	as.initializeModifiers()
	return as
}

// initializeModifiers повторяет модификаторы из StatModifiers.lua и EffectModifiers.lua
func (as *AffixSystem) initializeModifiers() {
	// Stat Modifiers (из StatModifiers.lua)
	as.statModifiers = map[string]Modifier{
		"WEAPON_DAMAGE_FLAT": {
			Name:      "Adds # Damage",
			Type:      "flat",
			ItemTypes: []string{"weapon"},
			Stat:      "attack",
			BaseRange: [2]float64{3, 8},
			Weight:    30,
		},
		"ARMOR_DEFENSE_FLAT": {
			Name:      "Adds # Defense",
			Type:      "flat", 
			ItemTypes: []string{"armor", "helmet"},
			Stat:      "defense",
			BaseRange: [2]float64{2, 6},
			Weight:    30,
		},
		"ARMOR_HP_FLAT": {
			Name:      "Adds # HP",
			Type:      "flat",
			ItemTypes: []string{"armor", "helmet"},
			Stat:      "hp", 
			BaseRange: [2]float64{10, 25},
			Weight:    25,
		},
		"WEAPON_DAMAGE_PERCENT": {
			Name:      "#% Damage",
			Type:      "percent",
			ItemTypes: []string{"weapon"},
			Stat:      "attackPercent",
			BaseRange: [2]float64{0.05, 0.10},
			Weight:    20,
		},
		"ARMOR_DEFENSE_PERCENT": {
			Name:      "#% Defense", 
			Type:      "percent",
			ItemTypes: []string{"armor", "helmet"},
			Stat:      "defensePercent",
			BaseRange: [2]float64{0.05, 0.08},
			Weight:    20,
		},
		"ARMOR_HP_PERCENT": {
			Name:      "#% HP",
			Type:      "percent",
			ItemTypes: []string{"armor", "helmet"},
			Stat:      "hpPercent",
			BaseRange: [2]float64{0.08, 0.12},
			Weight:    15,
		},
		"WEAPON_ATTACK_SPEED": {
			Name:      "#% Attack Speed",
			Type:      "percent", 
			ItemTypes: []string{"weapon"},
			Stat:      "attackSpeed",
			BaseRange: [2]float64{0.05, 0.08},
			Weight:    25,
		},
	}
	
	// Effect Modifiers (из EffectModifiers.lua)
	as.effectModifiers = map[string]Modifier{
		"LIFESTEAL": {
			Name:      "#% Life Steal",
			Type:      "percent",
			ItemTypes: []string{"weapon"},
			Stat:      "lifesteal",
			BaseRange: [2]float64{0.01, 0.03},
			Weight:    20,
		},
		"CRIT_CHANCE": {
			Name:      "#% Critical Chance",
			Type:      "percent",
			ItemTypes: []string{"weapon"},
			Stat:      "critChance", 
			BaseRange: [2]float64{0.02, 0.04},
			Weight:    15,
		},
		"CRIT_DAMAGE": {
			Name:      "#% Critical Damage",
			Type:      "percent",
			ItemTypes: []string{"weapon"},
			Stat:      "critDamage",
			BaseRange: [2]float64{0.10, 0.15},
			Weight:    12,
		},
		"DODGE_CHANCE": {
			Name:      "#% Dodge Chance", 
			Type:      "percent",
			ItemTypes: []string{"armor"},
			Stat:      "dodgeChance",
			BaseRange: [2]float64{0.01, 0.03},
			Weight:    15,
		},
		"MANA_REGEN": {
			Name:      "# Mana Regeneration",
			Type:      "flat",
			ItemTypes: []string{"helmet"},
			Stat:      "manaRegen",
			BaseRange: [2]float64{1, 3},
			Weight:    10,
		},
	}
}

// GetRandomAffixes повторяет AffixSystem:getRandomAffixes() из AffixSystem.lua
func (as *AffixSystem) GetRandomAffixes(itemType string, count int, floorLevel int) ([]types.Affix, []types.AffixTier) {
	available := as.getAvailableModifiers(itemType)
	selected := []types.Affix{}
	selectedTiers := []types.AffixTier{}
	
	if len(available) == 0 {
		return selected, selectedTiers
	}
	
	// Взвешенный выбор как в оригинале
	totalWeight := 0
	for _, modifier := range available {
		totalWeight += modifier.Weight
	}
	
	for i := 0; i < count; i++ {
		if len(available) == 0 {
			break
		}
		
		randomValue := rand.Float64() * float64(totalWeight)
		currentWeight := 0.0
		selectedIndex := -1
		
		for j, modifier := range available {
			currentWeight += float64(modifier.Weight)
			if randomValue <= currentWeight {
				selectedIndex = j
				break
			}
		}
		
		if selectedIndex != -1 {
			modifier := available[selectedIndex]
			
			// Роллим тир для аффикса как в оригинале
			tier := as.rollTierForAffix(modifier.Stat, floorLevel)
			
			// Получаем значение через функцию модификатора как в оригинале
			value := as.calculateAffixValue(modifier, tier)
			
			// Округляем значение как в оригинале
			if modifier.Type == "percent" {
				value = math.Round(value*100) / 100
			} else {
				value = math.Round(value)
			}
			
			affix := types.Affix{
				Name:  modifier.Name,
				Type:  modifier.Type,
				Stat:  modifier.Stat,
				Value: value,
			}
			
			selected = append(selected, affix)
			selectedTiers = append(selectedTiers, types.AffixTier{
				Stat: modifier.Stat,
				Tier: tier,
			})
			
			// Обновляем веса как в оригинале
			totalWeight -= modifier.Weight
			available = append(available[:selectedIndex], available[selectedIndex+1:]...)
		}
	}
	
	return selected, selectedTiers
}

// getAvailableModifiers повторяет AffixSystem:getAvailableModifiers()
func (as *AffixSystem) getAvailableModifiers(itemType string) []Modifier {
	available := []Modifier{}
	
	// Проверяем stat modifiers
	for _, modifier := range as.statModifiers {
		for _, allowedType := range modifier.ItemTypes {
			if allowedType == itemType {
				available = append(available, modifier)
				break
			}
		}
	}
	
	// Проверяем effect modifiers
	for _, modifier := range as.effectModifiers {
		for _, allowedType := range modifier.ItemTypes {
			if allowedType == itemType {
				available = append(available, modifier)
				break
			}
		}
	}
	
	return available
}

// calculateAffixValue повторяет логику расчета значения аффикса
func (as *AffixSystem) calculateAffixValue(modifier Modifier, tier int) float64 {
	min12, max12 := modifier.BaseRange[0], modifier.BaseRange[1]
	
	// Tier multiplier как в оригинале: math.pow(1.25, 12 - tier)
	tierMultiplier := math.Pow(1.25, float64(12-tier))
	
	// Случайное значение между min и max
	value := min12 + (max12-min12)*rand.Float64()
	return value * tierMultiplier
}

// rollTierForAffix повторяет логику ролла тира для аффикса
func (as *AffixSystem) rollTierForAffix(stat string, floorLevel int) int {
	// Простая реализация - равномерное распределение
	// В оригинале используется TierRollSystem:rollTierForStat()
	availableTiers := as.getAvailableTiersForFloor(floorLevel)
	tierIndex := rand.Intn(len(availableTiers))
	return availableTiers[tierIndex]
}

// getAvailableTiersForFloor повторяет TierRollSystem:getAvailableTiersForFloor()
func (as *AffixSystem) getAvailableTiersForFloor(floorLevel int) []int {
	available := []int{}
	
	// Каждый тир добавляется раз в 10 этажей как в оригинале
	minTier := max(1, 12 - (floorLevel-1)/10)
	
	for tier := 12; tier >= minTier; tier-- {
		available = append(available, tier)
	}
	
	return available
}