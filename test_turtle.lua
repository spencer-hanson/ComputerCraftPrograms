require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")
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
    --t:up()
    -- test directions while digging
    --t:down(true)
    --t:back(true)
    --t:left(true)
    --t:forward(true)
    --t:forward(true)
    --t:right(true)
    --t:goHome(true)

    --t:goTo(8, 8, 8, nil, true)
    --t.current_forward = 8
    --t.current_right = 8
    --t.current_down = 8
    --t:goHome(true)

    --local forward = t.current_forward
    --local right = t.current_right
    --local down = t.current_down
    --
    --t:goHome()
    --t:drop(MoveDirection.SOUTH, nil, false, true, 5)
    --t:suck(MoveDirection.WEST, 1, false, true, 5)
    --t:goTo(forward, right, down)
    --print("Done")

    -- drop stuff
    --t:dropStuffWhitelist(MoveDirection.WEST, {"minecraft:dirt"})
    --t:dropStuffBlacklist(MoveDirection.WEST, {"minecraft:dirt"})
    --t:turn(MoveDirection.NORTH)
    --print("start")
    --turtle.select(1)
    --t:selectNext({"minecraft:dirt", "minecraft:charcoal"})
    --print("Dropping first found")
    --t:drop(MoveDirection.WEST)
    --
    --t:selectNext({"minecraft:dirt", "minecraft:charcoal"})
    --print("dropping second found")
    --t:drop(MoveDirection.WEST)
    --
    --print("drop third found")
    --t:selectNext({"minecraft:dirt", "minecraft:charcoal"})
    --t:drop(MoveDirection.WEST)
    --
    --t:turn(MoveDirection.NORTH)




    t:finish()
end

runTurtlePlus(nil, main)
