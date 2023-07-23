require("./libs/turtleplus")
require("./libs/movement")
-- Dig a series of tunnels like in a diamond strip mine (2x1xTUNNEL_LENGTH) with a 2 block gap between tunnels

OUTPUT_CHEST = MoveDirection.SOUTH
FUEL_CHEST = MoveDirection.UP
TUNNEL_LENGTH = 64
NUM_ROWS = 21  -- will be x3 in actualy size, might not want to go too high, if turtle gets out of loaded chunk will terminate program
FIRST_TURN = RelativeTurnDirection.RIGHT

function turnAround(t)
    print("Turning around")
    t:turnRelative(FIRST_TURN)
    digTwo(t)
    t:forward(true)
    digTwo(t)
    t:forward(true)
    digTwo(t)
    t:forward(true)
    t:turnRelative(FIRST_TURN)
    FIRST_TURN = RelativeTurnDirection:opposite(FIRST_TURN)
end

function digTwo(t)
    if t:isInventoryFull() then
        t:dropOffInventoryAtHome(OUTPUT_CHEST, true)
    end
    t:dig()
    t:digDown()
end

function forward(t)
    for i=1,TUNNEL_LENGTH,1 do
        digTwo(t)
        t:forward(true)
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

runTurtlePlus(main, turtle_plus)
