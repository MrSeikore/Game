local debugLog = {}
local debugScrollOffset = 0
local maxDebugLines = 15

function love.load()
    -- Переопределяем print для отображения в игре
    local originalPrint = print
    print = function(...)
        originalPrint(...)
        local message = table.concat({...}, " ")
        table.insert(debugLog, message)
        if #debugLog > 50 then  -- Храним больше логов
            table.remove(debugLog, 1)
        end
    end
    
    print("=== RPG GAME ===")
    
    -- Load core modules first (без зависимостей)
    require('src/core/Constants')
    require('src/core/Utils')
    require('src/core/Display')
    require('src/core/GameState')  -- Базовая структура
    
    -- Load base scene class
    require('src/scenes/Scene')
    
    -- Load data modules
    require('src/data/Affixes')
    
    -- Load entities
    require('src/entities/Player')
    require('src/entities/Monster')
    require('src/entities/Item')
    
    -- Load systems and scenes
    require('src/systems/DropChanceSystem')
    require('src/systems/SaveSystem')
    require('src/scenes/GameScene')
    require('src/scenes/InventoryScene')
    require('src/scenes/StatsScene')
    
    -- Initialize display first
    Display:initialize()
    
    -- Initialize base game state
    GameState:initialize()
    
    -- Теперь инициализируем все системы
    require('src/core/GameInitializer')
    GameInitializer:initializeAll()
    
    print("Game fully loaded")
    print("Controls: T - Toggle Stats, R - Respawn")
    print("Debug: Mouse wheel to scroll logs")
end

function love.update(dt)
    GameState:update(dt)
end

function love.draw()
    -- Apply scaling
    love.graphics.push()
    love.graphics.translate(Display.offsetX, Display.offsetY)
    love.graphics.scale(Display.scale, Display.scale)
    
    GameState:draw()
    
    -- Отрисовываем логи поверх всего с скроллингом
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 5, 5, 600, 280)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("DEBUG LOGS (Scroll with mouse wheel):", 10, 10)
    
    local startIndex = math.max(1, #debugLog - maxDebugLines - debugScrollOffset + 1)
    local endIndex = math.min(#debugLog, startIndex + maxDebugLines - 1)
    
    for i = startIndex, endIndex do
        local logIndex = i
        local displayIndex = i - startIndex + 1
        love.graphics.print(debugLog[logIndex], 10, 30 + (displayIndex-1) * 16)
    end
    
    -- Показываем индикатор скролла
    if #debugLog > maxDebugLines then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Scroll: " .. debugScrollOffset .. "/" .. (#debugLog - maxDebugLines), 10, 265)
    end
    
    love.graphics.pop()
end

function love.wheelmoved(x, y)
    -- Скроллинг логов отладки (только если мышка над логами)
    local mouseX, mouseY = love.mouse.getPosition()
    if mouseX >= 5 and mouseX <= 605 and mouseY >= 5 and mouseY <= 285 then
        if y ~= 0 then
            local maxScroll = math.max(0, #debugLog - maxDebugLines)
            debugScrollOffset = math.max(0, math.min(maxScroll, debugScrollOffset - y * 3))
            return
        end
    end
    
    -- Обработка колесика для инвентаря и статистики
    if y ~= 0 then
        local baseX = Display:inverseScaleX(mouseX)
        local baseY = Display:inverseScaleY(mouseY)
        
        -- Обработка колесика для статистики (только если открыта и мышка в правой области)
        if GameState.showStats and baseX >= 700 then
            if GameState.scenes.stats then
                GameState.scenes.stats:handleWheel(baseX, baseY, x, y)
            end
        -- Обработка колесика для инвентаря (только если мышка в правой области)
        elseif baseX >= 700 and GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
            GameState.scenes.inventory.inventorySystem:handleWheel(baseX, baseY, x, y)
        end
    end
end

-- Остальные функции оставляем без изменений...
function love.keypressed(key)
    GameState:keypressed(key)
end

function love.mousepressed(x, y, button)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    if button == 1 then
        GameState:mousepressed(baseX, baseY, button)
    end
end

function love.mousereleased(x, y, button)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    -- Обработка отпускания мыши для статистики
    if GameState.showStats and GameState.scenes.stats then
        GameState.scenes.stats:handleMouseRelease(baseX, baseY, button)
    end
    
    -- Обработка отпускания мыши для инвентаря
    if GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
        GameState.scenes.inventory.inventorySystem:handleMouseRelease(baseX, baseY, button)
    end
end

function love.mousemoved(x, y, dx, dy)
    local baseX = Display:inverseScaleX(x)
    local baseY = Display:inverseScaleY(y)
    
    -- Обработка drag для статистики
    if GameState.showStats and GameState.scenes.stats then
        GameState.scenes.stats:handleMouseDrag(baseX, baseY, dx, dy)
    end
    
    -- Обработка drag для инвентаря
    if love.mouse.isDown(1) and GameState.scenes.inventory and GameState.scenes.inventory.inventorySystem then
        GameState.scenes.inventory.inventorySystem:handleMouseDrag(baseX, baseY, dx, dy)
    end
    
    GameState:mousemoved(baseX, baseY, dx, dy)
end

function love.resize(width, height)
    Display:initialize()
end