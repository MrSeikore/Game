StatsScene = {
    name = "stats",
    scrollOffset = 0,
    isDragging = false,
    dragStartY = 0,
    dragStartOffset = 0,
    scrollSensitivity = 0.8
}

function StatsScene:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function StatsScene:onEnter()
end

function StatsScene:onExit()
end

function StatsScene:update(dt)
end

function StatsScene:draw()
    local player = GameState.player
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.98)
    love.graphics.rectangle("fill", 700, 0, 300, Display.baseHeight)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", 700, 0, 300, Display.baseHeight)
    
    -- Title
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("PLAYER STATISTICS", 710, 20)
    
    local startX = 710
    local startY = 50 - self.scrollOffset
    local lineHeight = 18
    local visibleHeight = Display.baseHeight - 70
    
    -- Основные характеристики
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("CORE STATS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(0.8, 0.8, 1)
    love.graphics.print("Level: " .. player.level, startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("HP: " .. math.floor(player.hp) .. "/" .. player.maxHp, startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Attack: " .. player.attack, startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Defense: " .. player.defense, startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("EXP: " .. player.exp .. "/" .. player.expToNextLevel, startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Боевые характеристики
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("COMBAT STATS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("Critical Chance: " .. string.format("%.1f%%", player.critChance * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Critical Damage: " .. string.format("%.1f%%", player.critDamage * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Attack Speed: " .. string.format("%.2f", player.attackSpeed), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Lifesteal: " .. string.format("%.1f%%", player.lifesteal * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Armor Penetration: " .. string.format("%.1f%%", player.armorPen * 100), startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Защитные характеристики
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("DEFENSE STATS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(1, 0.8, 0.8)
    love.graphics.print("Fire Resistance: " .. string.format("%.1f%%", player.fireResist * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Dodge Chance: " .. string.format("%.1f%%", player.dodgeChance * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Damage Reflection: " .. string.format("%.1f%%", player.damageReflect * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Thorns Damage: " .. player.thorns, startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Статы статусов
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("STATUS EFFECTS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(0.8, 1, 1)
    love.graphics.print("Bleed Chance: " .. string.format("%.1f%%", player.bleedChance * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Poison Damage: " .. string.format("%.1f%%", player.poisonDamage * 100), startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Утилиты
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("UTILITY STATS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(1, 1, 0.8)
    love.graphics.print("Movement Speed: " .. string.format("%.1f%%", player.moveSpeed * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("EXP Bonus: " .. string.format("%.1f%%", player.expBonus * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Magic Find: " .. string.format("%.1f%%", player.magicFind * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Gold Find: " .. string.format("%.1f%%", player.goldFind * 100), startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Регенерация
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("REGENERATION:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(0.8, 1, 0.8)
    love.graphics.print("Health Regen: " .. player.healthRegen .. "/s", startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Mana Regen: " .. player.manaRegen .. "/s", startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Способности
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("ABILITY STATS:", startX, startY)
    startY = startY + lineHeight
    
    love.graphics.setColor(1, 0.8, 1)
    love.graphics.print("Skill Damage: " .. string.format("%.1f%%", player.skillDamage * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Cooldown Reduction: " .. string.format("%.1f%%", player.cooldownReduction * 100), startX + 20, startY)
    startY = startY + lineHeight
    love.graphics.print("Resource Cost Reduction: " .. string.format("%.1f%%", player.resourceCostReduction * 100), startX + 20, startY)
    startY = startY + lineHeight * 2
    
    -- Добавляем дополнительное пространство внизу чтобы "Press T to close" не перекрывалось
    local totalContentHeight = startY + self.scrollOffset + 50  -- +50 дополнительного пространства
    
    -- Scroll bar если контент не помещается
    if totalContentHeight > visibleHeight then
        self:drawScrollBar(totalContentHeight, visibleHeight)
    end
    
    -- Подсказка (всегда внизу, независимо от скролла)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Press T to close", 710, Display.baseHeight - 30)
end


function StatsScene:drawScrollBar(totalHeight, visibleHeight)
    local scrollX = 980
    local scrollY = 50
    local scrollHeight = visibleHeight
    
    -- Scroll track
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", scrollX, scrollY, 10, scrollHeight)
    
    -- Scroll thumb
    local maxScroll = math.max(0, totalHeight - visibleHeight)
    local thumbHeight = math.max(20, (visibleHeight / totalHeight) * scrollHeight)
    local thumbPosition = 0
    
    if maxScroll > 0 then
        thumbPosition = (self.scrollOffset / maxScroll) * (scrollHeight - thumbHeight)
    end
    
    love.graphics.setColor(0.5, 0.5, 0.7)
    love.graphics.rectangle("fill", scrollX, scrollY + thumbPosition, 10, thumbHeight)
end

function StatsScene:keypressed(key)
    -- Обработка закрытия через T уже в GameState
end

function StatsScene:mousepressed(x, y, button)
    if button == 1 then
        -- Проверяем клик по скроллбару
        if x >= 980 and x <= 990 and y >= 50 and y <= Display.baseHeight - 50 then
            self.isDragging = true
            self.dragStartY = y
            self.dragStartOffset = self.scrollOffset
        end
    end
end

function StatsScene:handleMouseRelease(x, y, button)
    if button == 1 then
        self.isDragging = false
    end
end

function StatsScene:handleMouseDrag(x, y, dx, dy)
    if self.isDragging then
        local totalHeight = 650 -- Примерная высота контента
        local visibleHeight = Display.baseHeight - 100
        local maxScroll = math.max(0, totalHeight - visibleHeight)
        local dragDelta = y - self.dragStartY
        
        -- Плавный скролл с чувствительностью
        local scrollDelta = (dragDelta / visibleHeight) * maxScroll * self.scrollSensitivity
        self.scrollOffset = math.max(0, math.min(maxScroll, self.dragStartOffset + scrollDelta))
    end
end

function StatsScene:handleWheel(x, y, dx, dy)
    local totalHeight = 650 -- Общая высота контента
    local visibleHeight = Display.baseHeight - 100
    local maxScroll = math.max(0, totalHeight - visibleHeight)
    
    -- Плавный скролл колесиком
    local scrollAmount = 40  -- Увеличили для лучшей чувствительности
    if dy > 0 then -- Scroll up
        self.scrollOffset = math.max(0, self.scrollOffset - scrollAmount)
    elseif dy < 0 then -- Scroll down
        self.scrollOffset = math.min(maxScroll, self.scrollOffset + scrollAmount)
    end
end

function StatsScene:mousemoved(x, y, dx, dy)
    -- Для совместимости
end