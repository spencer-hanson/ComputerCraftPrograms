require("./libs/turtleplus")
require("./libs/movement")
OUTPUT_CHEST = MoveDirection.SOUTH
FUEL_CHEST = MoveDirection.UP
TUNNEL_LENGTH = 64
NUM_ROWS = 64
FIRST_TURN = RelativeTurnDirection.RIGHT

function turnAround(t)
    t:turnRelative(FIRST_TURN)
    digTwo(t)
    t:forward()
    digTwo(t)
    t:forward()
    digTwo(t)
    t:forward()
    t:turnRelative(FIRST_TURN)
    FIRST_TURN = RelativeTurnDirection:opposite(FIRST_TURN)
end

function digTwo(t)
    t:dig()
    t:digDown()
end

function forward(t)
    for i=1,TUNNEL_LENGTH,1 do
        digTwo(t)
        t:forward()
    end
end

function main(t)
    for i=1,NUM_ROWS,1 do
        forward(t)
        turnAround(t)
    end
    t:goHome(true)
    t:finish()
end

turtle_plus = TurtlePlus:new()
turtle_plus.home_drop_direction = OUTPUT_CHEST
turtle_plus.home_fuel_direction = FUEL_CHEST

runTurtlePlus(turtle_plus, main)
