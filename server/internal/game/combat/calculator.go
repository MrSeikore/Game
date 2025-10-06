package combat

import "server/types"

// Calculator повторяет боевую логику из Player.lua и Monster.lua
type Calculator struct{}

func NewCalculator() *Calculator {
	return &Calculator{}
}

// CalculateCombat повторяет логику боя из GameScene.lua
func (c *Calculator) CalculateCombat(player *types.Player, monster *types.Monster) *types.CombatResult {
	result := &types.CombatResult{}
	
	// Игрок атакует (повторяем Player:attackMonster())
	playerDamage := c.calculatePlayerDamage(player, monster)
	monster.HP -= playerDamage
	result.DamageDealt = playerDamage
	result.MonsterKilled = monster.HP <= 0
	
	// Монстр атакует в ответ если жив (повторяем Monster:attackPlayer())
	if !result.MonsterKilled {
		monsterDamage := c.calculateMonsterDamage(monster, player)
		player.HP -= monsterDamage
		result.DamageTaken = monsterDamage
	}
	
	result.PlayerHP = player.HP
	result.MonsterHP = monster.HP
	result.ExpGained = monster.ExpValue
	
	return result
}

// calculatePlayerDamage повторяет Player:attackMonster() из Player.lua
func (c *Calculator) calculatePlayerDamage(player *types.Player, monster *types.Monster) int {
	// Базовый урон с учетом защиты как в оригинале
	baseDamage := player.Attack - (monster.Defense / 2)
	if baseDamage < 1 {
		baseDamage = 1
	}
	return baseDamage
}

// calculateMonsterDamage повторяет Monster:attackPlayer() из Monster.lua  
func (c *Calculator) calculateMonsterDamage(monster *types.Monster, player *types.Player) int {
	// Базовый урон с учетом защиты как в оригинале
	baseDamage := monster.Attack - (player.Defense / 2)
	if baseDamage < 1 {
		baseDamage = 1
	}
	return baseDamage
}

// Вспомогательная функция для совместимости
func CalculatePlayerAttack(player *types.Player, monster *types.Monster) *types.CombatResult {
	calculator := NewCalculator()
	return calculator.CalculateCombat(player, monster)
}