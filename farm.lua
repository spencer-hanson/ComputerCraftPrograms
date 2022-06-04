require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")

WATER_BUCKET_FULL_DIRECTION = MoveDirection.WEST
BUCKET_EMPTY_DIRECTION = MoveDirection.WEST
DROP_CHEST = MoveDirection.SOUTH
SEEDS_CHEST = MoveDirection.SOUTH

TOOL_DIRECTION = MoveDirection.SOUTH

PICKAXE_NAME = {"minecraft:diamond_pickaxe"}
HOE_NAME = {"minecraft:diamond_hoe"}
WATER_BUCKET_NAME = {"minecraft:water_bucket"}
EMPTY_BUCKET_NAME = {"minecraft:bucket"}
SEEDS_NAME = {"minecraft:wheat_seeds"}

TOOLS = {PICKAXE_NAME[1], HOE_NAME[1]}

function pickupBucket(t)
    t:goHome()
    t:forward()
    t:suck(WATER_BUCKET_FULL_DIRECTION, 1, true, nil, 2)
end

function swapTool()
    -- tool on right side
    turtle.equipRight()
end

function checkTool(t)
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
    t:goHome()
    t:moveNum("east", 2)
    t:suckUntilFail(SEEDS_CHEST)
    t:goHome()
end

function dropoffSeeds(t)
    t:goHome()
    t:moveNum("east", 2)
    t:dropStuffWhitelist(SEEDS_CHEST, SEEDS_NAME)
    t:goHome()
end

function tillField(t)
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

runTurtlePlus(nil, main)
