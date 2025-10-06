Boss = {
    BOSS_NAMES = {
        {name = "Aestus, Dreamer's Bane", affix = "Nightmare Weaver", description = "+30% DMG, 15% Crit"},
        {name = "Arachneel, Weaver of the Abyss", affix = "Abyssal Bindings", description = "Slows, DoT Damage"},
        {name = "The Mallet of Oblivion", affix = "Soul Crusher", description = "Armor Pen, Stun Chance"},
        {name = "The Seraph of Decay", affix = "Corrupting Touch", description = "-Max HP, Poison"},
        {name = "The Dominus of Silence", affix = "Void Resonance", description = "Silence, -Healing"},
        {name = "The Scrivener of Nightmares", affix = "Fear Incarnate", description = "Fear, +25% DMG"},
        {name = "The Seething Primordial", affix = "Primordial Rage", description = "Rage at low HP, Fast Attacks"},
        {name = "The Wrath of the Eternal", affix = "Eternal Fury", description = "Damage Reflect, Invuln"},
        {name = "The One Who Whispers in Ash", affix = "Ashen Whisper", description = "-Vision, Mana Burn"},
        {name = "The Executor of Defiled Souls", affix = "Soul Defiler", description = "Lifesteal, -Resist"}
    }
}

function Boss:new(floorLevel)
    -- Определяем индекс босса по этажу (циклически)
    local bossIndex = ((floorLevel - 1) % #self.BOSS_NAMES) + 1
    
    local bossData = self.BOSS_NAMES[bossIndex]
    local bossName = bossData.name
    local bossAffix = bossData.affix
    local bossDescription = bossData.description
    
    local o = {
        x = 800, y = 450, width = 70, height = 100,
        level = math.max(1, floorLevel),
        maxHp = math.floor((120 + (floorLevel * 25)) * 0.6),
        hp = math.floor((120 + (floorLevel * 25)) * 0.6),
        attackDamage = math.floor((12 + floorLevel * 2) * 0.6),
        defense = math.floor(floorLevel * 2 * 0.6),
        expValue = 50 + floorLevel * 15,
        attackSpeed = 0.7,
        lastAttackTime = 0,
        color = {0.8, 0.1, 0.1},
        isBoss = true,
        name = bossName,
        affix = bossAffix,
        description = bossDescription,
        bossNumber = floorLevel
    }
    
    -- Применяем уникальный аффикс к боссу
    self:applyBossAffix(o, bossAffix)
    
    setmetatable(o, self)
    self.__index = self
    return o
end

function Boss:applyBossAffix(boss, affixName)
    if affixName == "Nightmare Weaver" then
        -- Увеличивает урон и шанс крита
        boss.attackDamage = math.floor(boss.attackDamage * 1.3)
        boss.critChance = 0.15
    elseif affixName == "Abyssal Bindings" then
        -- Замедляет игрока и наносит периодический урон
        boss.moveSpeedReduction = 0.3
        boss.dotDamage = math.floor(boss.attackDamage * 0.2)
    elseif affixName == "Soul Crusher" then
        -- Игнорирует часть защиты и оглушает
        boss.armorPenetration = 0.4
        boss.stunChance = 0.1
    elseif affixName == "Corrupting Touch" then
        -- Снижает максимальное HP игрока
        boss.maxHpReduction = 0.2
        boss.poisonDamage = math.floor(boss.attackDamage * 0.25)
    elseif affixName == "Void Resonance" then
        -- Тишина (блокирует способности) и снижает регенерацию
        boss.silenceChance = 0.2
        boss.healingReduction = 0.5
    elseif affixName == "Fear Incarnate" then
        -- Страх (игрок теряет контроль) и увеличенный урон
        boss.fearChance = 0.15
        boss.attackDamage = math.floor(boss.attackDamage * 1.25)
    elseif affixName == "Primordial Rage" then
        -- Увеличивает урон при низком HP и скорость атаки
        boss.rageMultiplier = 2.0
        boss.attackSpeed = 0.5  -- Быстрее атакует
    elseif affixName == "Eternal Fury" then
        -- Неуязвимость на короткое время и отражение урона
        boss.damageReflect = 0.3
        boss.invulnerabilityChance = 0.1
    elseif affixName == "Ashen Whisper" then
        -- Снижает видимость и наносит урон маны
        boss.visionReduction = 0.4
        boss.manaBurn = math.floor(boss.attackDamage * 0.3)
    elseif affixName == "Soul Defiler" then
        -- Крадет здоровье и снижает сопротивления
        boss.lifesteal = 0.25
        boss.resistanceReduction = 0.3
    end
    
    -- Увеличиваем награду за босса с аффиксом
    boss.expValue = math.floor(boss.expValue * 1.5)
end

function Boss:moveTowardsPlayer(playerX, dt)
    if self.x > playerX + 80 then
        self.x = self.x - 80 * dt
    end
end

function Boss:canAttack(currentTime)
    return currentTime - self.lastAttackTime >= 1.0 / self.attackSpeed
end

function Boss:attackPlayer(player, currentTime)
    if self:canAttack(currentTime) then
        local baseDamage = self.attackDamage
        local finalDamage = baseDamage
        
        -- Применяем пенетрацию брони если есть
        if self.armorPenetration then
            local effectiveDefense = player.defense * (1 - self.armorPenetration)
            finalDamage = math.max(1, baseDamage - math.floor(effectiveDefense / 2))
        else
            finalDamage = math.max(1, baseDamage - math.floor(player.defense / 2))
        end
        
        -- Применяем дополнительные эффекты аффиксов
        if self.critChance and math.random() < self.critChance then
            finalDamage = math.floor(finalDamage * 1.5)
            print("BOSS CRITICAL HIT!")
        end
        
        if self.poisonDamage then
            player.hp = player.hp - self.poisonDamage
            print("BOSS POISON DAMAGE: " .. self.poisonDamage)
        end
        
        player.hp = player.hp - finalDamage
        self.lastAttackTime = currentTime
        
        -- Лайфстил если есть
        if self.lifesteal then
            local healAmount = math.floor(finalDamage * self.lifesteal)
            self.hp = math.min(self.maxHp, self.hp + healAmount)
            print("BOSS HEALED: " .. healAmount)
        end
        
        return finalDamage
    end
    return 0
end

function Boss:draw()
    -- Сохраняем текущий шрифт
    local originalFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(12)  -- Мелкий шрифт для описания
    
    -- Тело босса (большое)
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- Голова босса (большая)
    love.graphics.setColor(0.9, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x + 10, self.y - 30, 50, 35)
    
    -- Полоска здоровья (толще)
    local healthWidth = (self.hp / self.maxHp) * self.width
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.x, self.y - 40, self.width, 8)
    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", self.x, self.y - 40, healthWidth, 8)
    
    -- Имя босса (поднимаем выше)
    love.graphics.setFont(originalFont)
    love.graphics.setColor(1, 0.8, 0)  -- Золотой цвет для имени
    local nameWidth = love.graphics.getFont():getWidth(self.name)
    love.graphics.print(self.name, self.x + (self.width - nameWidth) / 2, self.y - 90)
    
    -- Аффикс босса
    love.graphics.setColor(0.8, 0.8, 1)  -- Голубой цвет для аффикса
    local affixWidth = love.graphics.getFont():getWidth(self.affix)
    love.graphics.print(self.affix, self.x + (self.width - affixWidth) / 2, self.y - 75)
    
    -- Описание аффикса (мелким шрифтом)
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.7, 0.7, 0.7)  -- Серый цвет для описания
    local descWidth = smallFont:getWidth(self.description)
    love.graphics.print(self.description, self.x + (self.width - descWidth) / 2, self.y - 60)
    
    -- Возвращаем оригинальный шрифт
    love.graphics.setFont(originalFont)
    
    -- Уровень босса
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Lv." .. self.level, self.x + 25, self.y - 35)
    
    -- Корона босса (поднимаем выше)
    love.graphics.setColor(1, 0.84, 0)  -- Золотой цвет
    love.graphics.rectangle("fill", self.x + 25, self.y - 105, 20, 10)
    love.graphics.rectangle("fill", self.x + 20, self.y - 100, 30, 5)
end
