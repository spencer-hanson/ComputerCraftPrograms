require("./libs/turtleplus")
require("./libs/movement")
require("./libs/ccutil")


FUEL_CHEST = MoveDirection.WEST
SAPLINGS_CHEST = MoveDirection.SOUTH
OUTPUT_CHEST = MoveDirection.DOWN

SAPLING_NAME = "minecraft:birch_sapling"
FUEL_NAMES = {"minecraft:charcoal"}
KEEP_IN_INVENTORY = {"minecraft:charcoal", SAPLING_NAME}


function clearInventory(t)
    print("Clearing inventory..")
    t:goHome()
    t:dropStuffBlacklist(OUTPUT_CHEST, KEEP_IN_INVENTORY)
    t:dropStuffWhitelist(SAPLINGS_CHEST, {SAPLING_NAME})
end

function getAndPlaceSapling(t)
    print("Getting and placing sapling")
    t:goHome()
    local found_sapling = t:selectNext({SAPLING_NAME}, 1)
    if found_sapling ~= true then
	    t:suckUntilStuff(SAPLINGS_CHEST, {SAPLING_NAME})
    end
    t:turn(MoveDirection.NORTH)
    t:selectNext({SAPLING_NAME}, 1)
    turtle.place()
end

function waitForTreeGrowth(t)
    print("Waiting for tree growth..")
    t:goHome()
    local found_block = false
    while found_block ~= true do
        t:up()
	    if turtle.detect() == true then
	        found_block = true
        else
            print("No tree found, waiting 5 seconds..")
            t:down()
            os.sleep(5)
        end
    end
    t:goHome()
end

function chopTree(t)
    print("Chopping tree")
    t:goHome()
    local done = false
    while done ~= true do
	    if turtle.detect() ~= true and turtle.detectUp() ~= true then
	        done = true
        else
            t:digUp()
            t:dig()
            t:up()
        end
    end
    t:goHome()
end

function pickupDrops(t)
    print("Sucking up items..")
    for i=0, 6, 1 do
	    t:suckUp()
	    t:suck()
	    os.sleep(1)
    end
end

function main(t)
    t.home_fuel_direction = FUEL_CHEST
    t.home_drop_direction = OUTPUT_CHEST
    while true do
        clearInventory(t)
        getAndPlaceSapling(t)
        waitForTreeGrowth(t)
        chopTree(t)
        pickupDrops(t)
    end
end

runTurtlePlus(main)


-- TODO test f button home thingy
-- TODO test refueling blacklist turtle_plus.lua#120
-- TODO Fix initial no fuel issue catch 22