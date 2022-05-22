require("./libs/turtleplus")
require("./libs/movement")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
CUBE_FORWARD = 11
CUBE_RIGHT = 11
CUBE_DOWN = 5

TURN_DIRECTION = RelativeTurnDirection.RIGHT

function line(t, func, length)
    for i = 1, length, 1 do
        func()
        t:forward()
    end
end

function plane(t, func, width, length)
    for i = 1, width, 1 do
        line(t, func, length)
        if i ~= width then
            t:turnRelative(TURN_DIRECTION)
            func()
            t:forward()
            func()
            t:turnRelative(TURN_DIRECTION)
            TURN_DIRECTION = RelativeTurnDirection:opposite(TURN_DIRECTION)
        else
            return
        end
    end
end

function cube(t, func, height, width, length)
    for i=1,height,1 do
        plane(t, func, width, length)
        t:up()
    end
end

function main(t)
    function func()
        turtle.digDown()
    end
    cube(t, func, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD)

end

runTurtlePlus(nil, main)
