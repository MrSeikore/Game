Display = {
    baseWidth = 1000,
    baseHeight = 700,
    scale = 1,
    offsetX = 0,
    offsetY = 0
}

function Display:initialize()
    local width, height = love.graphics.getDimensions()
    self.scale = math.min(width / self.baseWidth, height / self.baseHeight)
    self.offsetX = (width - self.baseWidth * self.scale) / 2
    self.offsetY = (height - self.baseHeight * self.scale) / 2
end

function Display:scaleX(x)
    return self.offsetX + x * self.scale
end

function Display:scaleY(y)
    return self.offsetY + y * self.scale
end

function Display:scaleWidth(width)
    return width * self.scale
end

function Display:scaleHeight(height)
    return height * self.scale
end

function Display:inverseScaleX(x)
    return (x - self.offsetX) / self.scale
end

function Display:inverseScaleY(y)
    return (y - self.offsetY) / self.scale
end

-- Inventory layout constants
Display.INVENTORY = {
    WIDTH = 300,
    PADDING = 10,
    
    EQUIPMENT = {
        x = 710, y = 30, width = 280, height = 150,
        SLOT_SIZE = 70, SLOT_MARGIN = 10
    },
    
    INVENTORY_HEADER = {
        x = 710, y = 215, width = 280, height = 50
    },
    
    INVENTORY_GRID = {
        x = 710, y = 285, width = 280, height = 200,
        CELL_SIZE = 60, COLUMNS = 4, ROWS = 4
    },
    
    BULK_DELETE = {
        x = 710, y = 540, width = 280, height = 70
    },
    
    DROP_CHANCES = {
        x = 710, y = 620, width = 280, height = 120
    }
}
