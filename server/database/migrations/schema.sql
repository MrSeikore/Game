-- Таблица игроков
CREATE TABLE IF NOT EXISTS players (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    level INTEGER DEFAULT 1,
    exp INTEGER DEFAULT 0,
    exp_to_next INTEGER DEFAULT 100,
    base_hp INTEGER DEFAULT 100,
    base_attack INTEGER DEFAULT 10,
    base_defense INTEGER DEFAULT 5,
    hp INTEGER DEFAULT 100,
    max_hp INTEGER DEFAULT 100,
    attack INTEGER DEFAULT 10,
    defense INTEGER DEFAULT 5,
    attack_speed FLOAT DEFAULT 1.0,
    current_floor INTEGER DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица предметов в инвентаре
CREATE TABLE IF NOT EXISTS player_items (
    id SERIAL PRIMARY KEY,
    player_id VARCHAR(50) REFERENCES players(id) ON DELETE CASCADE,
    item_data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Таблица экипировки
CREATE TABLE IF NOT EXISTS player_equipment (
    player_id VARCHAR(50) PRIMARY KEY REFERENCES players(id) ON DELETE CASCADE,
    weapon_data JSONB,
    helmet_data JSONB,
    armor_data JSONB,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);