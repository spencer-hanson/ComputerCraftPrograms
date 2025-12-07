require("./libs/turtleplus")
require("./libs/movement")
require("./libs/ccutil")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH

CUBE_FORWARD = 3
CUBE_RIGHT = 3
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

    local function moveTimedOut()
        print("Quarry can't move anymore! Going home")
        t:goHome(true)
        error("Quarry cannot continue, movement obstructed")
    end

    print("Starting to quarry!")
    if not turtle.detectDown() then
        while not turtle.detectDown() do
            t:down()
        end
    end
    t:cube(dig, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, true, true, 3, moveTimedOut, 5)
    t:goHome(true)
end

function main(t)
    -- t:moveN(MoveDirection.NORTH, false, nil, nil, 3, true)
    quarry(t)
    t:finish()
end

runTurtlePlus(main)
