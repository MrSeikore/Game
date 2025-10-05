SaveSystem = {}

function SaveSystem:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function SaveSystem:saveGame()
    local saveData = {
        version = 2,  -- Увеличиваем версию для исправления бага
        timestamp = os.time(),
        player = self:serializePlayer(GameState.player),
        gameScene = self:serializeGameScene(GameState.scenes.game),
        inventory = self:serializeInventory(GameState.player.inventory),
        equipment = self:serializeEquipment(GameState.player.equipment)
    }
    
    local serialized = serpent.block(saveData, {comment = false})
    local success = love.filesystem.write("savegame.dat", serialized)
    
    if success then
        print("Game saved successfully!")
        return true
    else
        print("Error saving game!")
        return false
    end
end

function SaveSystem:loadGame()
    if not love.filesystem.getInfo("savegame.dat") then
        print("No save file found")
        return false
    end
    
    local success, data = pcall(function()
        return love.filesystem.read("savegame.dat")
    end)
    
    if not success or not data then
        print("Error reading save file")
        return false
    end
    
    local ok, saveData = serpent.load(data)
    
    if not ok then
        print("Error parsing save file")
        return false
    end
    
    -- Исправляем старые сейвы с багом
    if saveData.version == 1 then
        print("Fixing old save file...")
        saveData.gameScene.gameState = "moving"
        saveData.gameScene.currentMonster = nil
    end
    
    self:deserializePlayer(GameState.player, saveData.player)
    self:deserializeGameScene(GameState.scenes.game, saveData.gameScene)
    self:deserializeInventory(GameState.player, saveData.inventory)
    self:deserializeEquipment(GameState.player, saveData.equipment)
    
    print("Game loaded successfully!")
    return true
end

function SaveSystem:serializePlayer(player)
    return {
        level = player.level,
        exp = player.exp,
        expToNextLevel = player.expToNextLevel,
        baseHp = player.baseHp,
        baseAttack = player.baseAttack,
        baseDefense = player.baseDefense,
        hp = player.hp,
        maxHp = player.maxHp,
        attack = player.attack,
        defense = player.defense,
        lifesteal = player.lifesteal,
        attackSpeed = player.attackSpeed,
        expBonus = player.expBonus,
        critChance = player.critChance,
        fireResist = player.fireResist,
        moveSpeed = player.moveSpeed,
        manaRegen = player.manaRegen,
        cooldownReduction = player.cooldownReduction,
        critDamage = player.critDamage,
        armorPen = player.armorPen,
        bleedChance = player.bleedChance,
        poisonDamage = player.poisonDamage,
        damageReflect = player.damageReflect,
        thorns = player.thorns,
        healthRegen = player.healthRegen,
        dodgeChance = player.dodgeChance,
        magicFind = player.magicFind,
        goldFind = player.goldFind,
        skillDamage = player.skillDamage,
        resourceCostReduction = player.resourceCostReduction
    }
end

function SaveSystem:serializeGameScene(gameScene)
    return {
        currentFloor = gameScene.currentFloor,
        killedMonsters = gameScene.killedMonsters,
        gameState = "moving",  -- Всегда сохраняем moving чтобы избежать бага
        showAdvanceButton = gameScene.showAdvanceButton or false,
        respawnFloor = gameScene.respawnFloor or 1
    }
end

function SaveSystem:serializeInventory(inventory)
    local serializedInventory = {}
    for _, item in ipairs(inventory) do
        if item then  -- Защита от nil
            table.insert(serializedInventory, self:serializeItem(item))
        end
    end
    return serializedInventory
end

function SaveSystem:serializeEquipment(equipment)
    local serializedEquipment = {}
    for slot, item in pairs(equipment) do
        if item then  -- Защита от nil
            serializedEquipment[slot] = self:serializeItem(item)
        end
    end
    return serializedEquipment
end

function SaveSystem:serializeItem(item)
    return {
        type = item.type,
        rarity = item.rarity,
        name = item.name,
        attackBonus = item.attackBonus or 0,
        defenseBonus = item.defenseBonus or 0,
        hpBonus = item.hpBonus or 0,
        lifesteal = item.lifesteal or 0,
        attackSpeed = item.attackSpeed or 0,
        expBonus = item.expBonus or 0,
        critChance = item.critChance or 0,
        fireResist = item.fireResist or 0,
        moveSpeed = item.moveSpeed or 0,
        manaRegen = item.manaRegen or 0,
        cooldownReduction = item.cooldownReduction or 0,
        critDamage = item.critDamage or 0,
        armorPen = item.armorPen or 0,
        bleedChance = item.bleedChance or 0,
        poisonDamage = item.poisonDamage or 0,
        damageReflect = item.damageReflect or 0,
        thorns = item.thorns or 0,
        healthRegen = item.healthRegen or 0,
        dodgeChance = item.dodgeChance or 0,
        magicFind = item.magicFind or 0,
        goldFind = item.goldFind or 0,
        skillDamage = item.skillDamage or 0,
        resourceCostReduction = item.resourceCostReduction or 0,
        affixes = item.affixes or {},
        icon = item.type == "weapon" and "W" or item.type == "helmet" and "H" or item.type == "armor" and "A" or "?",
        iconType = item.type
    }
end

function SaveSystem:deserializePlayer(player, data)
    player.level = data.level or 1
    player.exp = data.exp or 0
    player.expToNextLevel = data.expToNextLevel or 100
    player.baseHp = data.baseHp or 100
    player.baseAttack = data.baseAttack or 10
    player.baseDefense = data.baseDefense or 5
    player.hp = data.hp or player.baseHp
    player.maxHp = data.maxHp or player.baseHp
    
    player.lifesteal = data.lifesteal or 0
    player.attackSpeed = data.attackSpeed or 1.0
    player.expBonus = data.expBonus or 0
    player.critChance = data.critChance or 0
    player.fireResist = data.fireResist or 0
    player.moveSpeed = data.moveSpeed or 0
    player.manaRegen = data.manaRegen or 0
    player.cooldownReduction = data.cooldownReduction or 0
    player.critDamage = data.critDamage or 0
    player.armorPen = data.armorPen or 0
    player.bleedChance = data.bleedChance or 0
    player.poisonDamage = data.poisonDamage or 0
    player.damageReflect = data.damageReflect or 0
    player.thorns = data.thorns or 0
    player.healthRegen = data.healthRegen or 0
    player.dodgeChance = data.dodgeChance or 0
    player.magicFind = data.magicFind or 0
    player.goldFind = data.goldFind or 0
    player.skillDamage = data.skillDamage or 0
    player.resourceCostReduction = data.resourceCostReduction or 0
    
    player:recalculateStats()
end

function SaveSystem:deserializeGameScene(gameScene, data)
    gameScene.currentFloor = data.currentFloor or 1
    gameScene.killedMonsters = data.killedMonsters or 0
    gameScene.gameState = data.gameState or "moving"
    gameScene.showAdvanceButton = data.showAdvanceButton or false
    gameScene.respawnFloor = data.respawnFloor or 1
    gameScene.currentMonster = nil  -- Всегда сбрасываем монстра при загрузке
end

function SaveSystem:deserializeInventory(player, data)
    player.inventory = {}
    for _, itemData in ipairs(data) do
        local item = self:deserializeItem(itemData)
        if item then
            table.insert(player.inventory, item)
        end
    end
end

function SaveSystem:deserializeEquipment(player, data)
    player.equipment = {}
    for slot, itemData in pairs(data) do
        local item = self:deserializeItem(itemData)
        if item then
            player.equipment[slot] = item
        end
    end
    player:recalculateStats()
end

function SaveSystem:deserializeItem(data)
    local item = {
        type = data.type,
        rarity = data.rarity,
        name = data.name,
        attackBonus = data.attackBonus or 0,
        defenseBonus = data.defenseBonus or 0,
        hpBonus = data.hpBonus or 0,
        lifesteal = data.lifesteal or 0,
        attackSpeed = data.attackSpeed or 0,
        expBonus = data.expBonus or 0,
        critChance = data.critChance or 0,
        fireResist = data.fireResist or 0,
        moveSpeed = data.moveSpeed or 0,
        manaRegen = data.manaRegen or 0,
        cooldownReduction = data.cooldownReduction or 0,
        critDamage = data.critDamage or 0,
        armorPen = data.armorPen or 0,
        bleedChance = data.bleedChance or 0,
        poisonDamage = data.poisonDamage or 0,
        damageReflect = data.damageReflect or 0,
        thorns = data.thorns or 0,
        healthRegen = data.healthRegen or 0,
        dodgeChance = data.dodgeChance or 0,
        magicFind = data.magicFind or 0,
        goldFind = data.goldFind or 0,
        skillDamage = data.skillDamage or 0,
        resourceCostReduction = data.resourceCostReduction or 0,
        affixes = data.affixes or {},
        icon = data.type == "weapon" and "W" or data.type == "helmet" and "H" or data.type == "armor" and "A" or "?",
        iconType = data.type
    }
    
    setmetatable(item, Item)
    return item
end