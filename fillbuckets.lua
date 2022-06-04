require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")

INPUT_CHEST = MoveDirection.UP
OUTPUT_CHEST = MoveDirection.NORTH
FULL_BUCKET = {"minecraft:water_bucket"}
EMPTY_BUCKET = {"minecraft:bucket"}
BUCKETS = {EMPTY_BUCKET[1], FULL_BUCKET[1]}

function main(t)
    print("Waiting for empty buckets..")
    while true do
        t:suck(INPUT_CHEST)
        if t:selectNext(EMPTY_BUCKET) then
            print("Filling bucket")
            turtle.placeDown()
        end
        t:dropStuffWhitelist(OUTPUT_CHEST, FULL_BUCKET)
    end
end

runTurtlePlus(nil, main)

