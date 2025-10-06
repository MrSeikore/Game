package player

import (
	"server/internal/game/monsters"
	"server/types"
)

// PlayerManager управляет состоянием игрока
type PlayerManager struct {
	Player         *types.Player
	currentFloor   int
	killedCount    int
	monsterSpawner *monsters.Manager
}

func NewPlayerManager(playerID, playerName string) *PlayerManager {
	player := &types.Player{
		ID:          playerID,
		Name:        playerName,
		Level:       1,
		Exp:         0,
		ExpToNext:   100,
		BaseHP:      100,
		BaseAttack:  10,
		BaseDefense: 5,
		HP:          100,
		MaxHP:       100,
		Attack:      10,
		Defense:     5,
		AttackSpeed: 1.0,
		Equipment:   make(map[string]*types.Item),
		Inventory:   []types.Item{},
		CurrentFloor: 1,
	}

	mgr := &PlayerManager{
		Player:         player,
		currentFloor:   1,
		killedCount:    0,
		monsterSpawner: monsters.NewManager(),
	}
	
	mgr.monsterSpawner.SpawnMonster(mgr.currentFloor, mgr.killedCount)
	return mgr
}

func (m *PlayerManager) GetPlayer() *types.Player {
	return m.Player
}

func (m *PlayerManager) GetCurrentMonster() *types.Monster {
	return m.monsterSpawner.GetCurrentMonster()
}

func (m *PlayerManager) GetCurrentFloor() int {
	return m.currentFloor
}

func (m *PlayerManager) AddExperience(exp int) {
	m.Player.Exp += exp
}

func (m *PlayerManager) CheckLevelUp() bool {
	return m.Player.Exp >= m.Player.ExpToNext
}

func (m *PlayerManager) LevelUp() {
	m.Player.Level++
	m.Player.Exp -= m.Player.ExpToNext
	m.Player.ExpToNext = int(float64(m.Player.ExpToNext) * 1.5)
	
	// Увеличиваем базовые статы
	m.Player.BaseHP += 20
	m.Player.BaseAttack += 5  
	m.Player.BaseDefense += 2
	
	// Восстанавливаем HP
	m.Player.HP = m.Player.MaxHP
}

func (m *PlayerManager) AddToInventory(item types.Item) {
	m.Player.Inventory = append(m.Player.Inventory, item)
}

func (m *PlayerManager) IncrementKillCount() {
	m.killedCount++
	m.monsterSpawner.SpawnMonster(m.currentFloor, m.killedCount)
}

func (m *PlayerManager) ShouldAdvanceFloor() bool {
	return m.killedCount >= 10
}

func (m *PlayerManager) GetKilledCount() int {
	return m.killedCount
}

func (m *PlayerManager) IsBossFloor() bool {
	return m.killedCount == 9
}