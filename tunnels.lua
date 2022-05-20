require("turtleplus")
OUTPUT_CHEST = "SOUTH"
FUEL_CHEST = "NORTH"
TUNNEL_LENGTH = 32

function digTwo(t)
    t:dig()
    t:digDown()
end

function forward(t)
    for i=1,TUNNEL_LENGTH,1 do
        digTwo()
        t:forward()
    end
end

function main(t)
     forward(t)
    t:turnRight()
    digTwo(t)
    t:forward()
    digTwo(t)
    t:forward()
    digTwo(t)
    t:forward()
    t:turnRight()
    forward(t)
    t:finish()
end
turtle_plus = TurtlePlus:new()
turtle_plus.home_drop_direction = OUTPUT_CHEST
turtle_plus.home_fuel_direction = FUEL_CHEST

runTurtlePlus(turtle_plus, main)
