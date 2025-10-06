package database

import (
	"database/sql"
	"encoding/json"
	"log"
	"server/config"
	"server/types"

	_ "github.com/lib/pq"
)

type Repository struct {
	db *sql.DB
}

func NewRepository() *Repository {
	cfg := config.Load()
	
	db, err := sql.Open("postgres", cfg.GetDBConnectionString())
	if err != nil {
		log.Fatal("Failed to connect to database:", err)
	}

	// Проверяем соединение
	if err := db.Ping(); err != nil {
		log.Fatal("Failed to ping database:", err)
	}

	log.Println("Connected to PostgreSQL database")
	return &Repository{db: db}
}

// SavePlayer сохраняет игрока в БД
func (r *Repository) SavePlayer(player *types.Player) error {
	query := `
		INSERT INTO players (id, name, level, exp, exp_to_next, base_hp, base_attack, base_defense, hp, max_hp, attack, defense, attack_speed, current_floor)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		ON CONFLICT (id) DO UPDATE SET
			name = $2, level = $3, exp = $4, exp_to_next = $5, base_hp = $6, base_attack = $7, base_defense = $8,
			hp = $9, max_hp = $10, attack = $11, defense = $12, attack_speed = $13, current_floor = $14,
			updated_at = CURRENT_TIMESTAMP
	`

	_, err := r.db.Exec(query,
		player.ID, player.Name, player.Level, player.Exp, player.ExpToNext,
		player.BaseHP, player.BaseAttack, player.BaseDefense,
		player.HP, player.MaxHP, player.Attack, player.Defense, player.AttackSpeed, player.CurrentFloor,
	)

	if err != nil {
		return err
	}

	// Сохраняем инвентарь
	return r.savePlayerInventory(player)
}

// GetPlayer загружает игрока из БД
func (r *Repository) GetPlayer(playerID string) (*types.Player, bool, error) {
	query := "SELECT name, level, exp, exp_to_next, base_hp, base_attack, base_defense, hp, max_hp, attack, defense, attack_speed, current_floor FROM players WHERE id = $1"
	
	row := r.db.QueryRow(query, playerID)
	
	player := &types.Player{ID: playerID}
	err := row.Scan(
		&player.Name, &player.Level, &player.Exp, &player.ExpToNext,
		&player.BaseHP, &player.BaseAttack, &player.BaseDefense,
		&player.HP, &player.MaxHP, &player.Attack, &player.Defense, &player.AttackSpeed, &player.CurrentFloor,
	)

	if err == sql.ErrNoRows {
		return nil, false, nil
	}
	if err != nil {
		return nil, false, err
	}

	// Загружаем инвентарь
	if err := r.loadPlayerInventory(player); err != nil {
		return nil, false, err
	}

	return player, true, nil
}

// savePlayerInventory сохраняет инвентарь игрока
func (r *Repository) savePlayerInventory(player *types.Player) error {
	// Удаляем старые предметы
	_, err := r.db.Exec("DELETE FROM player_items WHERE player_id = $1", player.ID)
	if err != nil {
		return err
	}

	// Сохраняем новые предметы
	for _, item := range player.Inventory {
		itemJSON, err := json.Marshal(item)
		if err != nil {
			return err
		}

		_, err = r.db.Exec("INSERT INTO player_items (player_id, item_data) VALUES ($1, $2)", player.ID, itemJSON)
		if err != nil {
			return err
		}
	}

	return nil
}

// loadPlayerInventory загружает инвентарь игрока
func (r *Repository) loadPlayerInventory(player *types.Player) error {
	rows, err := r.db.Query("SELECT item_data FROM player_items WHERE player_id = $1", player.ID)
	if err != nil {
		return err
	}
	defer rows.Close()

	player.Inventory = []types.Item{}
	player.Equipment = make(map[string]*types.Item)

	for rows.Next() {
		var itemJSON []byte
		if err := rows.Scan(&itemJSON); err != nil {
			return err
		}

		var item types.Item
		if err := json.Unmarshal(itemJSON, &item); err != nil {
			return err
		}

		player.Inventory = append(player.Inventory, item)
	}

	return rows.Err()
}