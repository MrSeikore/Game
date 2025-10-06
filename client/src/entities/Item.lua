local ItemFactory = require('src/data/items/ItemFactory')

-- Старая функция для обратной совместимости
Item = {}

function Item:new(itemType, floorLevel)
    return ItemFactory:createItem(itemType, floorLevel)
end

-- Сохраняем старые методы для обратной совместимости
function Item:getColor()
    return self.color or {1, 1, 1}
end

function Item:getAffixDescription()
    local descriptions = {}
    for _, affix in ipairs(self.affixes) do
        local valueText = affix.type == "percent" and 
            string.format("%.1f%%", affix.value * 100) or tostring(affix.value)
        local description = affix.name:gsub("%%", valueText)
        table.insert(descriptions, description)
    end
    return descriptions
end

function Item:getIcon(itemType)
    if itemType == "weapon" then return "W"
    elseif itemType == "helmet" then return "H"
    elseif itemType == "armor" then return "A"
    else return "?" end
end

return Item