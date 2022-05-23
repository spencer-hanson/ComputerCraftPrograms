require("./libs/ccutil")

-- MoveDirection
MoveDirection = {
    NORTH = "north",
    SOUTH = "south",
    EAST = "east",
    WEST = "west",
    UP = "up",
    DOWN = "down"
}

function validateMoveDirection(dir)
    if dir == MoveDirection.NORTH or dir == MoveDirection.SOUTH or dir == MoveDirection.EAST or dir == MoveDirection.WEST or dir == MoveDirection.UP or dir == MoveDirection.DOWN then
        return
    else
        if dir == nil then
            dir = "nil"
        end
        errorTrace("Invalid MoveDirection '" .. dir .. "'")
    end
end

function MoveDirection:opposite(dir)
    validateMoveDirection(dir)
    local reverse = {
        north = "south",
        south = "north",
        east = "west",
        west = "east",
        up = "down",
        down = "up"
    }
    return reverse[dir]
end

function MoveDirection:left(dir)
    local left = {
        north = "west",
        south = "east",
        east = "north",
        west = "south",
        up = "up",
        down = "down"
    }
    return left[dir]
end

function MoveDirection:right(dir)
    return MoveDirection:opposite(MoveDirection:left(dir))
end

-- RelativeTurnDirection
RelativeTurnDirection = {
    LEFT = "left",
    RIGHT = "right"
}

function validateRelativeTurnDirection(dir)
    if dir == RelativeTurnDirection.LEFT or dir == RelativeTurnDirection.RIGHT then
        return
    else
        if dir == nil then
            dir = "nil"
        end
        errorTrace("Invalid RelativeTurnDirection '" .. dir .. "'")
    end
end

function RelativeTurnDirection:opposite(dir)
    validateRelativeTurnDirection(dir)
    if dir == RelativeTurnDirection.LEFT then
        return RelativeTurnDirection.RIGHT
    else
        return RelativeTurnDirection.LEFT
    end
end

-- TurnDirection
TurnDirection = {
    NORTH = "north",
    SOUTH = "south",
    EAST = "east",
    WEST = "west"
}

function validateTurnDirection(dir)
    if dir == TurnDirection.NORTH or dir == TurnDirection.SOUTH or dir == TurnDirection.EAST or dir == TurnDirection.WEST then
        return
    else
        if dir == nil then
            dir = "nil"
        end
        errorTrace("Invalid TurnDirection '" .. dir .. "'")
    end
end

function TurnDirection:opposite(dir)
    validateTurnDirection(dir)
    local reverse = {
        north = "south",
        south = "north",
        east = "west",
        west = "east"
    }
    return reverse[dir]
end

function TurnDirection:fromMoveDirection(dir)
    validateMoveDirection(dir)
    local map = {
        up = "none",
        down = "none",
        left = "left",
        right = "right"
    }
end
