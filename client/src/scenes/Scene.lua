Scene = {}

function Scene:new(name)
    local o = {
        name = name
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Scene:onEnter() end
function Scene:onExit() end
function Scene:update(dt) end
function Scene:draw() end
function Scene:keypressed(key) end
function Scene:mousepressed(x, y, button) end
function Scene:mousemoved(x, y, dx, dy) end