function love.load()
    print("Простой тест запущен!")
end

function love.update(dt)
    -- Пусто
end

function love.draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 100, 100, 200, 150)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Тест работает!", 120, 120)
end