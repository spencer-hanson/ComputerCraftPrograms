require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")

-- Turtle should start with  a hoe equipped on the right (computercraft requires a diamond hoe and pick, undamaged
-- a pickaxe should be in the TOOL CHEST
-- SETUP LAYOUT - TOP DOWN
-- [B][ ][ ][ ]
-- [ ][H][ ][ ]
-- [ ][D][T][S]
-- Key
-- [ ] -> Empty space
-- [B] -> bucket chests, the water buckets are on the same level as the turtle, and the empty ones are one level up
-- [H] -> Turtle home starting position
-- [D] -> Drop off chests
-- [T] -> Tool chest, on start should contain a pickaxe
-- [S] -> Seeds chest, should contain plantable seeds

-- ---------
-- Constants
-- ---------

SEEDS_NAME = {"minecraft:wheat_seeds"}

WATER_BUCKET_FULL_DIRECTION = MoveDirection.WEST -- one forward, same level
BUCKET_EMPTY_DIRECTION = MoveDirection.WEST -- one block forward one block up
DROP_CHEST = MoveDirection.SOUTH -- directly behind home
SEEDS_CHEST = MoveDirection.SOUTH -- 2 east from home
TOOL_DIRECTION = MoveDirection.SOUTH -- one block east from home

PICKAXE_NAME = {"minecraft:diamond_pickaxe"}
HOE_NAME = {"minecraft:diamond_hoe"}
WATER_BUCKET_NAME = {"minecraft:water_bucket"}
EMPTY_BUCKET_NAME = {"minecraft:bucket"}


TOOLS = {PICKAXE_NAME[1], HOE_NAME[1]}

function pickupBucket(t)
    print("Picking up bucket")
    t:goHome()
    t:forward()
    t:suck(WATER_BUCKET_FULL_DIRECTION, 1, true, nil, 2)
end

function swapTool()
    print("Swapping tool")
    -- tool on right side
    turtle.equipRight()
end

function checkTool(t)
    print("Checking tool")
    if t:countEntireInventory().total ~= 0 then
        error("Please empty turtle before running!")
    end

    function checkForHoe()
        local name = t:getSlotDetails().name
        if string.match(name, ".+hoe.*") == nil then
            return false
        end
        return true
    end

    function checkInv(checkFunc)
        turtle.equipLeft()
        local result = checkFunc()
        turtle.equipLeft()

        turtle.equipRight()
        result = checkFunc() or result
        turtle.equipRight()

        if not result then
            error("Invalid tool setup")
        end
    end
    checkInv(checkForHoe)
    print("Tool check successfully passed")
end

function exchangeTool(t)
    print("Exchanging tool")
    t:goHome()
    t:right()

    local slots = t:getEmptySlots()
    if table.getn(slots) < 1 then
        error("Inventory full! Can't exchange tool!")
    end

    turtle.select(slots[1])
    t:suck(TOOL_DIRECTION, 1, false)
    swapTool()
    t:drop(TOOL_DIRECTION, 1, false)
    t:goHome()
end

function placeWater(t)
    print("Placing water")
    exchangeTool(t)
    pickupBucket(t)
    t:goHome()
    t:moveNum("north", 4)
    t:moveNum("east", 4)
    t:down()
    turtle.digDown()
    t:selectNext(WATER_BUCKET_NAME)
    turtle.placeDown()
    t:goHome()
    t:forward()
    t:up()
    t:dropStuffWhitelist(BUCKET_EMPTY_DIRECTION, EMPTY_BUCKET_NAME)
    t:down()
    t:goHome()
    exchangeTool(t)
end

function fillupSeeds(t)
    print("Filling up seeds")
    t:goHome()
    t:moveNum("east", 2)
    t:suckUntilFail(SEEDS_CHEST)
    t:goHome()
end

function dropoffSeeds(t)
    print("Dropping off seeds")
    t:goHome()
    t:moveNum("east", 2)
    t:dropStuffWhitelist(SEEDS_CHEST, SEEDS_NAME)
    t:goHome()
end

function tillField(t)
    print("Tilling field")
    function till()
        t:digDown()
        t:selectNext(SEEDS_NAME)
        turtle.placeDown()
    end

    t:goHome()
    t:plane(till, 9, 9, false)
end

function main(t)
    placeWater(t)
    t:dropEntireInventory(DROP_CHEST)
    fillupSeeds(t)
    tillField(t)
    dropoffSeeds(t)
    t:dropEntireInventory(DROP_CHEST)
    t:goHome()
    t:finish()
end

runTurtlePlus(main)
