require("./libs/movement")
require("./libs/turtleplus")
require("./libs/ccutil")
INPUT_CHEST = MoveDirection.NORTH
OUTPUT_CHEST = MoveDirection.EAST

FLUIX_SEED = "ae2:fluix_crystal_seed"
FLUIX_CRYSTAL = "ae2:fluix_crystal"

TIMEOUT_TIME = 70

function main(t)
    while true do
        t:suckUntilFail(INPUT_CHEST)
        t:turn(MoveDirection.NORTH)
        local count = t:totalBlocksInInventory({FLUIX_SEED})
        if count ~= 0 then
            print("Converting " .. count .. " seeds")
            t:dropStuffWhitelist(MoveDirection.DOWN, {FLUIX_SEED})
            t:turn(MoveDirection.NORTH)
            os.sleep(TIMEOUT_TIME)
            t:suckUntilFail(MoveDirection.DOWN)
            local crystal_count = t:totalBlocksInInventory({FLUIX_CRYSTAL})
            print("Converted " .. crystal_count .. " crystals!")
            t:dropStuffWhitelist(OUTPUT_CHEST, {FLUIX_CRYSTAL})
            t:turn(MoveDirection.NORTH)
        end
        os.sleep(5)
    end
end

runTurtlePlus(nil, main)
