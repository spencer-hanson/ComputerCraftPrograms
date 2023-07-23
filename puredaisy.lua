require("./libs/turtleplus")
-- This script is for converting blocks on the botania pure daisy
-- the turtle will go counter-clockwise relative to it's starting position, so keep that in mind
-- The below constants specify where the input and output chests are relative to the starting position

INPUT_CHEST = "up"
OUTPUT_CHEST = "south"


function roundFunc(placeDownBlock, t)
    placeDownBlock()
    t:move("north", false)
    placeDownBlock()
    t:move("north", false)
    placeDownBlock()
    t:move("west", false)
    placeDownBlock()
    t:move("west", false)
    placeDownBlock()
    t:move("south", false)
    placeDownBlock()
    t:move("south", false)
    placeDownBlock()
    t:move("east", false)
    placeDownBlock()
    t:move("east", false)
    placeDownBlock()
end

function main(t)
    while true do
        local amt, s = t:suck(INPUT_CHEST, 8, true, true, 5)
        print("amt " .. tostring(amt) .. " " .. tostring(s))
        roundFunc(turtle.placeDown, t)
        os.sleep(60)
        roundFunc(turtle.digDown, t)
        t:drop(OUTPUT_CHEST)
    end
end

runTurtlePlus(main)
