NetworkConstants = {
    MESSAGE_TYPES = {
        PLAYER_JOIN = "player_join",
        PLAYER_LEAVE = "player_leave",
        PLAYER_MOVE = "player_move",
        PLAYER_ATTACK = "player_attack",
        MONSTER_UPDATE = "monster_update",
        ITEM_PICKUP = "item_pickup",
        REALM_UPDATE = "realm_update"
    },
    
    REALM_CONFIG = {
        MAX_PLAYERS_PER_REALM = 50,
        REALM_TICK_RATE = 0.1,  -- 10 раз в секунду
        PLAYER_TIMEOUT = 30000  -- 30 секунд
    }
}