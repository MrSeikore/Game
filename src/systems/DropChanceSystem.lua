DropChanceSystem = {
    visible = true,
    displayTime = 0,
    showForSeconds = 5
}

function DropChanceSystem:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DropChanceSystem:update(dt)
    -- Optional: Add timer logic if you want the display to disappear after some time
    if self.displayTime > 0 then
        self.displayTime = self.displayTime - dt
        if self.displayTime <= 0 then
            self.visible = false
        end
    end
end

function DropChanceSystem:draw()
    if not self.visible then return end
    
    local currentFloor = GameState:getCurrentFloor()
    local chances = self:getDropChances(currentFloor)
    
    -- Background
    love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
    love.graphics.rectangle("fill", 10, 10, 200, 140)
    love.graphics.setColor(0.3, 0.3, 0.4)
    love.graphics.rectangle("line", 10, 10, 200, 140)
    
    -- Title
    love.graphics.setColor(1, 1, 0)
    love.graphics.print("DROP CHANCES (F" .. currentFloor .. "):", 15, 15)
    
    -- Chances list
    local yOffset = 35
    local rarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary"}
    
    for _, rarity in ipairs(rarities) do
        if chances[rarity] and chances[rarity] > 0 then
            local color = self:getRarityColor(rarity)
            love.graphics.setColor(color)
            love.graphics.print(rarity .. ": " .. string.format("%.1f%%", chances[rarity] * 100), 15, 15 + yOffset)
            yOffset = yOffset + 20
        end
    end
end

function DropChanceSystem:getDropChances(floorLevel)
    -- Бесконечная прогрессия шансов
    local chances = {
        Common = math.max(0.05, 0.7 - (floorLevel * 0.05)),
        Uncommon = math.min(0.4, 0.25 + (floorLevel * 0.03)),
        Rare = math.min(0.3, 0.05 + (floorLevel * 0.02)),
        Epic = math.min(0.25, 0.0 + (floorLevel * 0.015)),
        Legendary = math.min(0.2, 0.0 + (floorLevel * 0.01))
    }
    
    -- Нормализуем шансы
    local total = chances.Common + chances.Uncommon + chances.Rare + chances.Epic + chances.Legendary
    chances.Common = chances.Common / total
    chances.Uncommon = chances.Uncommon / total
    chances.Rare = chances.Rare / total
    chances.Epic = chances.Epic / total
    chances.Legendary = chances.Legendary / total
    
    return chances
end

function DropChanceSystem:getRarityColor(rarity)
    if rarity == "Common" then return {0.8, 0.8, 0.8}
    elseif rarity == "Uncommon" then return {0, 1, 0}
    elseif rarity == "Rare" then return {0, 0, 1}
    elseif rarity == "Epic" then return {0.6, 0, 0.8}
    elseif rarity == "Legendary" then return {1, 0.65, 0}
    else return {1, 1, 1} end
end

function DropChanceSystem:show()
    self.visible = true
    self.displayTime = self.showForSeconds
end

function DropChanceSystem:hide()
    self.visible = false
    self.displayTime = 0
end

function DropChanceSystem:toggle()
    self.visible = not self.visible
    if self.visible then
        self.displayTime = self.showForSeconds
    else
        self.displayTime = 0
    end
end

-- Optional event handler
function DropChanceSystem:onMonsterKilled(data)
    -- You could update drop chances based on monster kills if needed
    print("Monster killed - updating drop chances if needed")
end