require("./libs/turtleplus")
require("./libs/movement")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
CUBE_FORWARD = 28
CUBE_RIGHT = 28
CUBE_DOWN = 2

TURN_DIRECTION = RelativeTurnDirection.RIGHT

function line(t, func, length)
    for i = 1, length-1, 1 do
        func()
        t:forward(true)
    end
end

function plane(t, func, width, length)
    for i = 1, width, 1 do
        line(t, func, length)
        if i ~= width then
            t:turnRelative(TURN_DIRECTION)
            func()
            t:forward(true)
            t:turnRelative(TURN_DIRECTION)
            TURN_DIRECTION = RelativeTurnDirection:opposite(TURN_DIRECTION)
        else
            return
        end
    end
end

function cube(t, func, height, width, length, go_down)
    for i=1,height,1 do
        plane(t, func, width, length)
        func()
        if go_down then
            t:down(true)
        else
            t:up(true)
        end

        t:turn(MoveDirection:opposite(t.current_direction))
    end
end

function main(t)
    function dig()
        turtle.digDown()
    end

    function place()
        while true do
            local success, reason = turtle.placeDown()
            if success then
                return
            else
                print("place failed retrying in 2 " .. tostring(reason))
                os.sleep(2)
            end
        end
    end

    cube(t, dig, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, true)
    t:up() -- need because we're placing underneath
    plane(t, place, CUBE_RIGHT, CUBE_FORWARD)
    place() -- need because last block in plane isn't placed

    print("Finished, going home")
    t:goHome()
    t:finish()
end

runTurtlePlus(nil, main)
