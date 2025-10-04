function love.load()
    print("=== ИГРА ЗАПУСКАЕТСЯ ===")
    
    -- Загрузка модулей с обработкой ошибок
    local success, err
    
    success, err = pcall(function() require('src/core/Constants') end)
    if not success then print("Ошибка Constants:", err) return end
    
    success, err = pcall(function() require('src/core/Utils') end)
    if not success then print("Ошибка Utils:", err) return end
    
    success, err = pcall(function() require('src/core/GameState') end)
    if not success then print("Ошибка GameState:", err) return end
    
    success, err = pcall(function() require('src/entities/Player') end)
    if not success then print("Ошибка Player:", err) return end
    
    success, err = pcall(function() require('src/entities/Monster') end)
    if not success then print("Ошибка Monster:", err) return end
    
    success, err = pcall(function() require('src/entities/Item') end)
    if not success then print("Ошибка Item:", err) return end
    
    success, err = pcall(function() require('src/systems/InventorySystem') end)
    if not success then print("Ошибка InventorySystem:", err) return end
    
    success, err = pcall(function() require('src/scenes/GameScene') end)
    if not success then print("Ошибка GameScene:", err) return end
    
    success, err = pcall(function() require('src/scenes/InventoryScene') end)
    if not success then print("Ошибка InventoryScene:", err) return end
    
    success, err = pcall(function() require('src/scenes/GameOverScene') end)
    if not success then print("Ошибка GameOverScene:", err) return end
    
    print("Все модули загружены успешно")
    
    -- Инициализация игры
    success, err = pcall(function() GameState:initialize() end)
    if not success then print("Ошибка инициализации:", err) return end
    
    print("=== ИГРА УСПЕШНО ЗАПУЩЕНА ===")
end

function love.update(dt)
    if GameState and GameState.update then
        local success, err = pcall(function() GameState:update(dt) end)
        if not success then print("Ошибка update:", err) end
    end
end

function love.draw()
    if GameState and GameState.draw then
        local success, err = pcall(function() GameState:draw() end)
        if not success then print("Ошибка draw:", err) end
    else
        -- Если GameState не загружен, покажем сообщение
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GameState не загружен", 400, 350)
    end
end

function love.keypressed(key)
    if GameState and GameState.keypressed then
        pcall(function() GameState:keypressed(key) end)
    end
end

function love.mousepressed(x, y, button)
    if GameState and GameState.mousepressed then
        pcall(function() GameState:mousepressed(x, y, button) end)
    end
end