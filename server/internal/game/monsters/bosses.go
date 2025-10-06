package monsters

import "server/types"  // ИЗМЕНИТЬ эту строку

// BossNames повторяет оригинальный массив BOSS_NAMES из Boss.lua
var BossNames = []struct {
	Name        string
	Affix       string
	Description string
}{
	{"Aestus, Dreamer's Bane", "Nightmare Weaver", "+30% DMG, 15% Crit"},
	{"Arachneel, Weaver of the Abyss", "Abyssal Bindings", "Slows, DoT Damage"},
	{"The Mallet of Oblivion", "Soul Crusher", "Armor Pen, Stun Chance"},
	{"The Seraph of Decay", "Corrupting Touch", "-Max HP, Poison"},
	{"The Dominus of Silence", "Void Resonance", "Silence, -Healing"},
	{"The Scrivener of Nightmares", "Fear Incarnate", "Fear, +25% DMG"},
	{"The Seething Primordial", "Primordial Rage", "Rage at low HP, Fast Attacks"},
	{"The Wrath of the Eternal", "Eternal Fury", "Damage Reflect, Invuln"},
	{"The One Who Whispers in Ash", "Ashen Whisper", "-Vision, Mana Burn"},
	{"The Executor of Defiled Souls", "Soul Defiler", "Lifesteal, -Resist"},
}

// applyBossAffix повторяет логику Boss:applyBossAffix() из Boss.lua
func applyBossAffix(boss *types.Monster, floorLevel int) {
	bossIndex := ((floorLevel - 1) % len(BossNames)) // Циклически как в оригинале
	bossData := BossNames[bossIndex]
	
	boss.Name = bossData.Name
	boss.Affix = bossData.Affix
	
	// Применяем эффекты аффиксов как в оригинале
	switch bossData.Affix {
	case "Nightmare Weaver":
		boss.Attack = int(float64(boss.Attack) * 1.3) // +30% урона
		boss.CritChance = 0.15 // 15% крит
	case "Abyssal Bindings":
		boss.MoveSpeedReduction = 0.3 // Замедление 30%
		boss.DotDamage = int(float64(boss.Attack) * 0.2) // ДоТ урон
	case "Soul Crusher":
		boss.ArmorPenetration = 0.4 // 40% пенетрация
		boss.StunChance = 0.1       // 10% стан
	case "Corrupting Touch":
		boss.MaxHpReduction = 0.2   // -20% макс HP
		boss.PoisonDamage = int(float64(boss.Attack) * 0.25) // Урон ядом
	case "Void Resonance":
		boss.SilenceChance = 0.2    // 20% тишина
		boss.HealingReduction = 0.5 // -50% лечения
	case "Fear Incarnate":
		boss.FearChance = 0.15      // 15% страх
		boss.Attack = int(float64(boss.Attack) * 1.25) // +25% урона
	case "Primordial Rage":
		boss.RageMultiplier = 2.0   // ×2 урон при низком HP
		boss.AttackSpeed = 0.5      // Быстрая атака
	case "Eternal Fury":
		boss.DamageReflect = 0.3    // 30% отражение
		boss.InvulnerabilityChance = 0.1 // 10% неуязвимость
	case "Ashen Whisper":
		boss.VisionReduction = 0.4  // -40% видимости
		boss.ManaBurn = int(float64(boss.Attack) * 0.3) // Сжигание маны
	case "Soul Defiler":
		boss.Lifesteal = 0.25       // 25% вампиризм
		boss.ResistanceReduction = 0.3 // -30% сопротивлений
	}
	
	// Увеличиваем награду как в оригинале
	boss.ExpValue = int(float64(boss.ExpValue) * 1.5)
}