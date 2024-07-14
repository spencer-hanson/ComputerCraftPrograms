require("./libs/turtleplus")
require("./libs/movement")
require("./libs/ccutil")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH

CUBE_FORWARD = 32
CUBE_RIGHT = 32
CUBE_DOWN = 300


function dig(t)
    if not t:hasEmptySlot() then
        local forward = t.current_forward
        local right = t.current_right
        local down = t.current_down
        local direction = t.current_direction

        t:goHome(true)
        t:dropEntireInventory(DROP_CHEST)
        t:goTo(forward, right, down)
        t:turn(direction)
    end
    turtle.digDown()
end


function quarry(t)
    print("Starting to quarry!")
    if not turtle.detectDown() then
        while not turtle.detectDown() do
            t:down()
        end
    end

    t:cube(dig, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, true, true)
    t:goHome(true)
end

function main(t)
    quarry(t)
    t:finish()
end

runTurtlePlus(main)
