package types

// Player представляет игрока (обновленная структура)
type Player struct {
	ID           string            `json:"id"`
	Name         string            `json:"name"`
	Level        int               `json:"level"`
	Exp          int               `json:"exp"`
	ExpToNext    int               `json:"exp_to_next"`
	BaseHP       int               `json:"base_hp"`
	BaseAttack   int               `json:"base_attack"`
	BaseDefense  int               `json:"base_defense"`
	HP           int               `json:"hp"`
	MaxHP        int               `json:"max_hp"`
	Attack       int               `json:"attack"`
	Defense      int               `json:"defense"`
	AttackSpeed  float64           `json:"attack_speed"`
	Equipment    map[string]*Item  `json:"equipment"` // weapon, helmet, armor
	Inventory    []Item            `json:"inventory"`
	CurrentFloor int               `json:"current_floor"`
	
	// Вторичные статы как в оригинале
	Lifesteal              float64 `json:"lifesteal"`
	ExpBonus               float64 `json:"exp_bonus"`
	CritChance             float64 `json:"crit_chance"`
	FireResist             float64 `json:"fire_resist"`
	MoveSpeed              float64 `json:"move_speed"`
	ManaRegen              float64 `json:"mana_regen"`
	CooldownReduction      float64 `json:"cooldown_reduction"`
	CritDamage             float64 `json:"crit_damage"`
	ArmorPen               float64 `json:"armor_pen"`
	BleedChance            float64 `json:"bleed_chance"`
	PoisonDamage           float64 `json:"poison_damage"`
	DamageReflect          float64 `json:"damage_reflect"`
	Thorns                 float64 `json:"thorns"`
	HealthRegen            float64 `json:"health_regen"`
	DodgeChance            float64 `json:"dodge_chance"`
	MagicFind              float64 `json:"magic_find"`
	GoldFind               float64 `json:"gold_find"`
	SkillDamage            float64 `json:"skill_damage"`
	ResourceCostReduction  float64 `json:"resource_cost_reduction"`
}

// Item представляет предмет (обновленная структура)
type Item struct {
	ID               string            `json:"id"`
	Type             string            `json:"type"` // weapon, helmet, armor
	Rarity           string            `json:"rarity"`
	Name             string            `json:"name"`
	Color            [3]float64        `json:"color"`
	
	// Базовые статы
	BaseAttack       int               `json:"base_attack"`
	BaseDefense      int               `json:"base_defense"`
	BaseHP           int               `json:"base_hp"`
	BaseAttackSpeed  float64           `json:"base_attack_speed"`
	
	// Бонусные статы
	BonusAttack      int               `json:"bonus_attack"`
	BonusDefense     int               `json:"bonus_defense"`
	BonusHP          int               `json:"bonus_hp"`
	BonusAttackSpeed float64           `json:"bonus_attack_speed"`
	
	// Тир системы
	StatTiers        map[string]int    `json:"stat_tiers"`
	AffixTiers       []AffixTier       `json:"affix_tiers"`
	
	// Аффиксы
	Affixes          []Affix           `json:"affixes"`
	
	// Вторичные статы как в оригинале
	Lifesteal              float64 `json:"lifesteal"`
	ExpBonus               float64 `json:"exp_bonus"`
	CritChance             float64 `json:"crit_chance"`
	FireResist             float64 `json:"fire_resist"`
	MoveSpeed              float64 `json:"move_speed"`
	ManaRegen              float64 `json:"mana_regen"`
	CooldownReduction      float64 `json:"cooldown_reduction"`
	CritDamage             float64 `json:"crit_damage"`
	ArmorPen               float64 `json:"armor_pen"`
	BleedChance            float64 `json:"bleed_chance"`
	PoisonDamage           float64 `json:"poison_damage"`
	DamageReflect          float64 `json:"damage_reflect"`
	Thorns                 float64 `json:"thorns"`
	HealthRegen            float64 `json:"health_regen"`
	DodgeChance            float64 `json:"dodge_chance"`
	MagicFind              float64 `json:"magic_find"`
	GoldFind               float64 `json:"gold_find"`
	SkillDamage            float64 `json:"skill_damage"`
	ResourceCostReduction  float64 `json:"resource_cost_reduction"`
}

// Affix представляет аффикс предмета
type Affix struct {
	Name  string  `json:"name"`
	Type  string  `json:"type"` // flat, percent
	Stat  string  `json:"stat"`
	Value float64 `json:"value"`
}

// AffixTier представляет тир аффикса
type AffixTier struct {
	Stat string `json:"stat"`
	Tier int    `json:"tier"`
}

// Monster представляет монстра/босса
type Monster struct {
	ID           string  `json:"id"`
	Type         string  `json:"type"` // normal, boss
	Name         string  `json:"name"`
	Affix        string  `json:"affix,omitempty"`
	Level        int     `json:"level"`
	HP           int     `json:"hp"`
	MaxHP        int     `json:"max_hp"`
	Attack       int     `json:"attack"`
	Defense      int     `json:"defense"`
	ExpValue     int     `json:"exp_value"`
	IsBoss       bool    `json:"is_boss"`
	
	// Аффиксы боссов как в оригинале
	CritChance           float64 `json:"crit_chance,omitempty"`
	MoveSpeedReduction   float64 `json:"move_speed_reduction,omitempty"`
	DotDamage            int     `json:"dot_damage,omitempty"`
	ArmorPenetration     float64 `json:"armor_penetration,omitempty"`
	StunChance           float64 `json:"stun_chance,omitempty"`
	MaxHpReduction       float64 `json:"max_hp_reduction,omitempty"`
	PoisonDamage         int     `json:"poison_damage,omitempty"`
	SilenceChance        float64 `json:"silence_chance,omitempty"`
	HealingReduction     float64 `json:"healing_reduction,omitempty"`
	FearChance           float64 `json:"fear_chance,omitempty"`
	RageMultiplier       float64 `json:"rage_multiplier,omitempty"`
	AttackSpeed          float64 `json:"attack_speed,omitempty"`
	DamageReflect        float64 `json:"damage_reflect,omitempty"`
	InvulnerabilityChance float64 `json:"invulnerability_chance,omitempty"`
	VisionReduction      float64 `json:"vision_reduction,omitempty"`
	ManaBurn             int     `json:"mana_burn,omitempty"`
	Lifesteal            float64 `json:"lifesteal,omitempty"`
	ResistanceReduction  float64 `json:"resistance_reduction,omitempty"`
}

// GameState представляет состояние игры
type GameState struct {
	CurrentFloor  int  `json:"current_floor"`
	KilledCount   int  `json:"killed_count"`
	TotalMonsters int  `json:"total_monsters"`
	IsBossFloor   bool `json:"is_boss_floor"`
}

// CombatResult представляет результат боя
type CombatResult struct {
	PlayerHP        int      `json:"player_hp"`
	MonsterHP       int      `json:"monster_hp"`
	DamageDealt     int      `json:"damage_dealt"`
	DamageTaken     int      `json:"damage_taken"`
	MonsterKilled   bool     `json:"monster_killed"`
	ExpGained       int      `json:"exp_gained"`
	Loot            []Item   `json:"loot,omitempty"`
	LevelUp         bool     `json:"level_up"`
	NewLevel        int      `json:"new_level,omitempty"`
	FloorCompleted  bool     `json:"floor_completed"`
}

// AttackRequest запрос на атаку
type AttackRequest struct {
	MonsterID string `json:"monster_id"`
}

// ClientMessage общее сообщение от клиента
type ClientMessage struct {
    Type        string                 `json:"type"`
    PlayerID    string                 `json:"player_id,omitempty"`
    PlayerName  string                 `json:"player_name,omitempty"`
    MonsterID   string                 `json:"monster_id,omitempty"`
    Data        map[string]interface{} `json:"data,omitempty"`
}

// ServerMessage общее сообщение от сервера
type ServerMessage struct {
	Type    string      `json:"type"`
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// AttackResponse ответ на атаку
type AttackResponse struct {
	Success bool         `json:"success"`
	Combat  CombatResult `json:"combat"`
	Error   string       `json:"error,omitempty"`
}

// LoginRequest запрос на вход
type LoginRequest struct {
	PlayerID   string `json:"player_id,omitempty"`  // Для существующих игроков
	PlayerName string `json:"player_name"`          // Обязательно для новых
}

// LoginResponse ответ на вход
type LoginResponse struct {
	Success   bool      `json:"success"`
	Player    Player    `json:"player"`
	GameState GameState `json:"game_state"`
	PlayerID  string    `json:"player_id"` // Добавляем ID игрока
}