package world

import (
	"log"
	"server/internal/database"
	"server/internal/game/combat"
	"server/internal/game/loot"
	"server/internal/game/player"
	"server/types"
	"sync"
)

type World struct {
	playerInstances map[string]*player.PlayerManager
	mu              sync.RWMutex
	lootSystem      *loot.Generator
	combatSystem    *combat.Calculator
	repo            *database.Repository
}

// ИЗМЕНЕНО: принимаем репозиторий
func NewWorld(repo *database.Repository) *World {
	return &World{
		playerInstances: make(map[string]*player.PlayerManager),
		lootSystem:      loot.NewGenerator(),
		combatSystem:    combat.NewCalculator(),
		repo:            repo,
	}
}

// Остальные методы без изменений...
func (w *World) PlayerLogin(playerID, playerName string) (*player.PlayerManager, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	if instance, exists := w.playerInstances[playerID]; exists {
		return instance, nil
	}

	savedPlayer, exists, err := w.repo.GetPlayer(playerID)
	if err != nil {
		return nil, err
	}
	var playerMgr *player.PlayerManager

	if exists {
		log.Printf("Loading saved player: %s (Level %d)", savedPlayer.Name, savedPlayer.Level)
		playerMgr = w.createPlayerManagerFromPlayer(savedPlayer)
	} else {
		log.Printf("Creating new player: %s", playerName)
		playerMgr = player.NewPlayerManager(playerID, playerName)
		
		if err := w.repo.SavePlayer(playerMgr.GetPlayer()); err != nil {
			log.Printf("Failed to save new player: %v", err)
		} else {
			log.Printf("Successfully saved new player: %s", playerName)
		}
	}

	w.playerInstances[playerID] = playerMgr
	return playerMgr, nil
}

func (w *World) PlayerAttack(playerMgr *player.PlayerManager, monsterID string) (*types.CombatResult, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	currentMonster := playerMgr.GetCurrentMonster()
	if currentMonster == nil {
		return nil, nil
	}

	combatResult := w.combatSystem.CalculateCombat(playerMgr.GetPlayer(), currentMonster)
	
	if combatResult.MonsterKilled {
		w.handleMonsterKill(playerMgr, currentMonster, combatResult)
	}

	if err := w.repo.SavePlayer(playerMgr.GetPlayer()); err != nil {
		log.Printf("Failed to save player progress: %v", err)
	}

	return combatResult, nil
}

func (w *World) handleMonsterKill(playerMgr *player.PlayerManager, monster *types.Monster, result *types.CombatResult) {
	playerMgr.AddExperience(monster.ExpValue)
	result.ExpGained = monster.ExpValue

	if playerMgr.CheckLevelUp() {
		playerMgr.LevelUp()
		result.LevelUp = true
		result.NewLevel = playerMgr.GetPlayer().Level
	}

	if w.lootSystem.ShouldDropLoot() {
		item := w.lootSystem.GenerateItem(playerMgr.GetCurrentFloor())
		playerMgr.AddToInventory(item)
		result.Loot = []types.Item{item}
	}

	playerMgr.IncrementKillCount()

	if playerMgr.ShouldAdvanceFloor() {
		result.FloorCompleted = true
	}
}

func (w *World) PlayerLogout(playerID string) {
	w.mu.Lock()
	defer w.mu.Unlock()

	if playerMgr, exists := w.playerInstances[playerID]; exists {
		if err := w.repo.SavePlayer(playerMgr.GetPlayer()); err != nil {
			log.Printf("Failed to save player on logout: %v", err)
		} else {
			log.Printf("Successfully saved player on logout: %s", playerID)
		}
		
		delete(w.playerInstances, playerID)
		log.Printf("Player %s logged out and saved", playerID)
	}
}

func (w *World) createPlayerManagerFromPlayer(savedPlayer *types.Player) *player.PlayerManager {
	playerMgr := player.NewPlayerManager(savedPlayer.ID, savedPlayer.Name)
	
	currentPlayer := playerMgr.GetPlayer()
	*currentPlayer = *savedPlayer
	
	playerMgr.IncrementKillCount()
	
	return playerMgr
}