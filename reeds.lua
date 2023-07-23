require("./libs/turtleplus")

-- Script to watch reeds grow
FORWARD = 3
RIGHT = 2
SLEEP_TIME = 5


function main(t)
    while true do
        print("Waiting..")
        if turtle.detect() then
            print("Mining..")
            turtle.dig()
            t:moveN(t.current_direction, nil, nil, nil, FORWARD, true)
            t:turnRight()
            t:dig()
            t:moveN(t.current_direction, nil, nil, nil, RIGHT-1, true)
            t:turnRight()
            t:dig()
            t:moveN(t.current_direction, nil, nil, nil, FORWARD, true)
            t:turnRight()
            t:dig()
            t:moveN(t.current_direction, nil, nil, nil, RIGHT-1, true)
            t:turn("north")
        end
        os.sleep(SLEEP_TIME)
    end
end

runTurtlePlus(main)
