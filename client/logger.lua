local Logger = {}
Logger.__index = Logger

function Logger.new(name)
    local self = setmetatable({}, Logger)
    self.name = name or "LOG"
    return self
end

function Logger:log(message)
    local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
    print(timestamp .. " " .. self.name .. ": " .. message)
end

return Logger