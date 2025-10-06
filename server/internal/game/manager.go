package game

import (
	"log"
	"sync"
	"server/internal/database"
	"server/internal/game/loot"
	"server/internal/game/monsters"
	"server/internal/game/player"
	"server/internal/game/world"
	"server/internal/network"
	"server/types"
	"server/utils"
)

type GameManager struct {
	players        map[string]*types.Player
	playersMux     sync.RWMutex
	world          *world.World
	monsterManager *monsters.Manager
	playerManager  *player.PlayerManager
	lootGenerator  *loot.Generator
	repo           *database.Repository
}

func NewGameManager(repo *database.Repository) *GameManager {
	return &GameManager{
		players:        make(map[string]*types.Player),
		world:          world.NewWorld(repo),
		monsterManager: monsters.NewManager(),
		playerManager:  player.NewPlayerManager("", ""),
		lootGenerator:  loot.NewGenerator(),
		repo:           repo,
	}
}

func (gm *GameManager) HandleLogin(conn *network.WebSocketConnection, playerID, playerName string) {
	log.Printf("Login attempt - ID: '%s', Name: '%s'", playerID, playerName)

	gm.playersMux.Lock()
	defer gm.playersMux.Unlock()

	if playerName == "" {
		conn.Send(types.ServerMessage{
			Type:    "login",
			Success: false,
			Error:   "Player name cannot be empty",
		})
		return
	}

	// Если playerID пустой - создаем нового игрока с UUID
	if playerID == "" {
		playerID = utils.GenerateUUID()
		log.Printf("Generated new UUID for player: %s", playerID)
	}

	// Используем World систему для логина
	playerMgr, err := gm.world.PlayerLogin(playerID, playerName)
	if err != nil {
		log.Printf("World login failed: %v", err)
		conn.Send(types.ServerMessage{
			Type:    "login",
			Success: false,
			Error:   "Login failed: " + err.Error(),
		})
		return
	}

	player := playerMgr.GetPlayer()
	gameState := types.GameState{
		CurrentFloor:  playerMgr.GetCurrentFloor(),
		KilledCount:   playerMgr.GetKilledCount(),
		TotalMonsters: 10,
		IsBossFloor:   playerMgr.IsBossFloor(),
	}

	response := types.LoginResponse{
		Success:   true,
		Player:    *player,
		GameState: gameState,
		PlayerID:  playerID,
	}

	// Сохраняем связь между соединением и игроком
	gm.players[playerID] = player

	// ОТПРАВЛЯЕМ ОТВЕТ КЛИЕНТУ
	loginResponse := types.ServerMessage{
		Type:    "login",
		Success: true,
		Data:    response,
	}

	log.Printf("Sending login response to client: %+v", loginResponse)
	
	if err := conn.Send(loginResponse); err != nil {
		log.Printf("Failed to send login response: %v", err)
	} else {
		log.Printf("Login response sent successfully for player: %s", playerName)
	}

	log.Printf("Player %s (UUID: %s) logged in (Level %d, Floor %d)", 
		player.Name, playerID, player.Level, player.CurrentFloor)
}

func (gm *GameManager) HandleAttack(conn *network.WebSocketConnection, monsterID string) {
	gm.playersMux.RLock()
	defer gm.playersMux.RUnlock()

	var currentPlayer *types.Player
	var playerID string
	for id, p := range gm.players {
		currentPlayer = p
		playerID = id
		break
	}

	if currentPlayer == nil {
		conn.Send(types.ServerMessage{
			Type:    "combat_result",
			Success: false,
			Error:   "Player not found",
		})
		return
	}

	playerMgr := gm.getPlayerManager(playerID)
	if playerMgr == nil {
		conn.Send(types.ServerMessage{
			Type:    "combat_result",
			Success: false,
			Error:   "Player manager not found",
		})
		return
	}

	combatResult, err := gm.world.PlayerAttack(playerMgr, monsterID)
	if err != nil {
		conn.Send(types.ServerMessage{
			Type:    "combat_result",
			Success: false,
			Error:   "Attack failed: " + err.Error(),
		})
		return
	}

	currentPlayer.HP = combatResult.PlayerHP
	currentPlayer.Exp += combatResult.ExpGained
	
	if combatResult.LevelUp {
		currentPlayer.Level = combatResult.NewLevel
	}

	response := types.AttackResponse{
		Success: true,
		Combat:  *combatResult,
	}

	conn.Send(types.ServerMessage{
		Type:    "combat_result",
		Success: true,
		Data:    response,
	})

	log.Printf("Combat: %s - Damage: %d, Killed: %t, Exp: %d", 
		currentPlayer.Name, combatResult.DamageDealt, combatResult.MonsterKilled, combatResult.ExpGained)
}

func (gm *GameManager) HandleDisconnect(conn *network.WebSocketConnection) {
	gm.playersMux.Lock()
	defer gm.playersMux.Unlock()

	for playerID, player := range gm.players {
		log.Printf("Saving progress for %s before disconnect", player.Name)
		
		gm.world.PlayerLogout(playerID)
		
		delete(gm.players, playerID)
		break
	}

	log.Println("Player disconnected")
}

func (gm *GameManager) getOrCreatePlayer(playerID, playerName string) *types.Player {
	if player, exists := gm.players[playerID]; exists {
		return player
	}

	playerMgr, err := gm.world.PlayerLogin(playerID, playerName)
	if err != nil {
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
		gm.players[playerID] = player
		return player
	}

	player := playerMgr.GetPlayer()
	gm.players[playerID] = player
	return player
}

func (gm *GameManager) getPlayerManager(playerID string) *player.PlayerManager {
	return player.NewPlayerManager(playerID, "TempPlayer")
}