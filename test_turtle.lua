require("./libs/turtleplus")

function main(t)
    -- Turn directionality test
    --local dirs = {"north","east","south","west"}
    --for i=1,4,1 do
    --    t:turn(dirs[i])
    --    for j=1,4,1 do
    --        print("moving " .. dirs[j])
    --        t:move(dirs[j], false)
    --    end
    --end
    --t:turn(RelativeTurnDirection.NORTH)

    --t:goTo(2, 0, 0)
    --while true do
    --    t:turnRelative(RelativeTurnDirection.LEFT)
    --end

    -- drop test
    --t:drop("north", 1, false, false, 5)
    --t:drop("north", 1, false, false)

    -- dropEntireInventory test
    --t:dropOffInventoryAtHome()

    -- suck test TODO
    --suck(dir, amount, do_correct, do_turn, retry_sec)

    -- Refuel test
    --t:moveN(t.current_direction, nil, nil, nil, 10)
    --t:goHome()
    --debugM("main done")
    --print("Fuel level left " .. turtle.getFuelLevel())
    --t:finish()

    -- TODO 'd' key to drop everything offset -> getWaitingFunc() for all hotkeys and descriptions

end

runTurtlePlus(nil, main)
