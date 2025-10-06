package monsters

import "server/types"  // ИЗМЕНИТЬ эту строку

// Manager управляет монстрами игрока
type Manager struct {
	currentMonster *types.Monster
}

func NewManager() *Manager {
	return &Manager{}
}

// SpawnMonster создает монстра согласно оригинальной логике GameScene.lua
func (m *Manager) SpawnMonster(floorLevel, killedCount int) {
	isBoss := killedCount == 9 // Как в оригинале: 0-8 обычные, 9-й - босс
	
	if isBoss {
		m.currentMonster = createBoss(floorLevel)
	} else {
		m.currentMonster = createNormalMonster(floorLevel)
	}
}

// GetCurrentMonster возвращает текущего монстра
func (m *Manager) GetCurrentMonster() *types.Monster {
	return m.currentMonster
}

// createNormalMonster повторяет логику Monster:new() из Monster.lua
func createNormalMonster(floorLevel int) *types.Monster {
	level := max(1, floorLevel)
	maxHp := int(float64(40 + (floorLevel * 10)) * 0.6) // *0.6 как в оригинале
	
	return &types.Monster{
		ID:       generateID(),
		Type:     "normal", 
		Level:    level,
		MaxHP:    maxHp,
		HP:       maxHp,
		Attack:   5 + floorLevel, // Как в оригинале
		Defense:  floorLevel,     // Как в оригинале
		ExpValue: 20 + floorLevel * 5,
		IsBoss:   false,
	}
}

// createBoss повторяет логику Boss:new() из Boss.lua
func createBoss(floorLevel int) *types.Monster {
	maxHp := int(float64(120 + (floorLevel * 25)) * 0.6) // *0.6 как в оригинале
	attack := int(float64(12 + floorLevel * 2) * 0.6)    // *0.6 как в оригинале
	defense := int(float64(floorLevel * 2) * 0.6)        // *0.6 как в оригинале
	
	boss := &types.Monster{
		ID:       generateID(),
		Type:     "boss",
		Level:    max(1, floorLevel),
		MaxHP:    maxHp,
		HP:       maxHp,
		Attack:   attack,
		Defense:  defense,
		ExpValue: 50 + floorLevel * 15,
		IsBoss:   true,
	}
	
	// Применяем аффикс босса (как в оригинале)
	applyBossAffix(boss, floorLevel)
	return boss
}

func generateID() string {
	return "mob_" + string(rune(65)) // Заглушка
}

// Вспомогательная функция
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}