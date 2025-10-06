package loot

import (
	"math/rand"
	"server/types"  // ИЗМЕНИТЬ эту строку
	"time"
)

// Generator повторяет логику ItemFactory из ItemFactory.lua
type Generator struct {
	raritySystem *RaritySystem
	affixSystem  *AffixSystem
	tierSystem   *TierSystem
}

func NewGenerator() *Generator {
	rand.Seed(time.Now().UnixNano())
	return &Generator{
		raritySystem: NewRaritySystem(),
		affixSystem:  NewAffixSystem(),
		tierSystem:   NewTierSystem(),
	}
}

// GenerateItem повторяет ItemFactory:createItem() из ItemFactory.lua
func (g *Generator) GenerateItem(floorLevel int) types.Item {
	// Выбираем случайный тип как в оригинале
	itemTypes := []string{"weapon", "helmet", "armor"}
	itemType := itemTypes[rand.Intn(len(itemTypes))]
	
	// Генерируем редкость как в оригинале
	rarity := g.raritySystem.GenerateRarity(floorLevel)
	
	// Генерируем базовые статы с тирами как в оригинале
	baseStats, statTiers := g.generateBaseStats(itemType, floorLevel)
	
	// Базовый Attack Speed для оружия как в оригинале
	baseAttackSpeed := 0.0
	if itemType == "weapon" {
		baseAttackSpeed = 1.5 // Базовый ATS для меча
	}
	
	// Создаем предмет как в оригинале
	item := types.Item{
		ID:              generateItemID(),
		Type:            itemType,
		Rarity:          rarity.Name,
		Name:            rarity.Name + " " + itemType, // Как в оригинале
		BaseAttack:      baseStats["attack"],
		BaseDefense:     baseStats["defense"], 
		BaseHP:          baseStats["hp"],
		BaseAttackSpeed: baseAttackSpeed,
		StatTiers:       statTiers,
		Affixes:         []types.Affix{},
		BonusAttack:     0,
		BonusDefense:    0,
		BonusHP:         0,
		BonusAttackSpeed: 0,
	}
	
	// Добавляем аффиксы согласно редкости как в оригинале
	if rarity.AffixCount > 0 {
		affixes, affixTiers := g.affixSystem.GetRandomAffixes(itemType, rarity.AffixCount, floorLevel)
		item.Affixes = affixes
		item.AffixTiers = affixTiers
		g.applyAffixes(&item, affixes)
	}
	
	// Устанавливаем цвет в зависимости от редкости как в оригинале
	item.Color = rarity.Color
	
	return item
}

// generateBaseStats повторяет ItemBase:generateBaseStats() из ItemBase.lua
func (g *Generator) generateBaseStats(itemType string, floorLevel int) (map[string]int, map[string]int) {
	baseStats := make(map[string]int)
	statTiers := make(map[string]int)
	
	// Генерируем статы согласно типу предмета как в оригинале
	switch itemType {
	case "weapon":
		tier := g.tierSystem.RollTierForStat("attack", floorLevel)
		baseStats["attack"] = g.tierSystem.RollStatValue("attack", tier)
		statTiers["attack"] = tier
		
		tier = g.tierSystem.RollTierForStat("attackSpeed", floorLevel)
		baseStats["attackSpeed"] = g.tierSystem.RollStatValue("attackSpeed", tier)
		statTiers["attackSpeed"] = tier
		
	case "armor", "helmet":
		tier := g.tierSystem.RollTierForStat("defense", floorLevel)
		baseStats["defense"] = g.tierSystem.RollStatValue("defense", tier)
		statTiers["defense"] = tier
		
		tier = g.tierSystem.RollTierForStat("hp", floorLevel)
		baseStats["hp"] = g.tierSystem.RollStatValue("hp", tier)
		statTiers["hp"] = tier
	}
	
	return baseStats, statTiers
}

// applyAffixes повторяет ItemFactory:applyAffixes() из ItemFactory.lua
func (g *Generator) applyAffixes(item *types.Item, affixes []types.Affix) {
	// Собираем процентные бонусы как в оригинале
	attackPercentBonus := 0.0
	defensePercentBonus := 0.0
	hpPercentBonus := 0.0
	
	for _, affix := range affixes {
		if affix.Stat == "attackPercent" {
			attackPercentBonus += affix.Value
		} else if affix.Stat == "defensePercent" {
			defensePercentBonus += affix.Value
		} else if affix.Stat == "hpPercent" {
			hpPercentBonus += affix.Value
		}
	}
	
	// Применяем аффиксы как в оригинале
	for _, affix := range affixes {
		value := affix.Value
		
		switch affix.Stat {
		case "attack":
			item.BonusAttack += int(value)
		case "defense":
			item.BonusDefense += int(value)
		case "hp":
			item.BonusHP += int(value)
		case "attackSpeed":
			item.BonusAttackSpeed += value
		// TODO: Добавить остальные статы как в оригинале
		}
	}
	
	// Применяем процентные бонусы как в оригинале
	if attackPercentBonus > 0 {
		item.BonusAttack += int(float64(item.BaseAttack) * attackPercentBonus)
	}
	if defensePercentBonus > 0 {
		item.BonusDefense += int(float64(item.BaseDefense) * defensePercentBonus)
	}
	if hpPercentBonus > 0 {
		item.BonusHP += int(float64(item.BaseHP) * hpPercentBonus)
	}
}

// ShouldDropLoot повторяет логику дропа из GameScene.lua
func (g *Generator) ShouldDropLoot() bool {
	return rand.Float64() < 0.6 // 60% шанс как в оригинале
}

func generateItemID() string {
	return "item_" + string(rune(65)) // Заглушка
}