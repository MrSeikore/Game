local json = {}

function json.encode(data)
    local function serialize(val)
        if type(val) == "string" then
            return '"' .. val:gsub('"', '\\"') .. '"'
        elseif type(val) == "number" or type(val) == "boolean" then
            return tostring(val)
        elseif type(val) == "table" then
            local parts = {}
            for k, v in pairs(val) do
                if type(k) == "string" then
                    table.insert(parts, '"' .. k .. '":' .. serialize(v))
                end
            end
            return "{" .. table.concat(parts, ",") .. "}"
        else
            return "null"
        end
    end
    
    return serialize(data)
end

function json.decode(str)
    -- Простой парсинг для тестирования
    local data = {}
    str = str:gsub("^{", ""):gsub("}$", "")
    for pair in str:gmatch('"[^"]-"[%s]*:[%s]*[^,]+') do
        local key, value = pair:match('"([^"]+)"[%s]*:[%s]*(.+)')
        if key and value then
            -- Убираем кавычки из строковых значений
            if value:match('^".*"$') then
                value = value:sub(2, -2)
            end
            data[key] = value
        end
    end
    return data
end

return json