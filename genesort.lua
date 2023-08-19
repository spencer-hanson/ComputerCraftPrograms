require("./libs/turtleplus")
require("./libs/ccutil")

-- Program to combine/refine genes from Productive Bees
INPUT_CHEST = MoveDirection.UP
COMPLETED_CHEST = MoveDirection.NORTH
RECYCLE_CHEST = MoveDirection.DOWN

DO_RECYCLE_REDSTONE_DIR = "right" -- On will inhibit output, off will allow
IS_RECYCLE_EMPTY_REDSTONE_DIR = "back" -- If no signal, then chest is empty

function ensureRecycleIsEmpty()
    local has_items = redstone.getInput(IS_RECYCLE_EMPTY_REDSTONE_DIR)
    while has_items == true do
        has_items = redstone.getInput(IS_RECYCLE_EMPTY_REDSTONE_DIR)
        print("Waiting for recycling to clear..")
        sleep(2)
    end
    print("Recycle is clear, continuing")
end

function clearRecycle()
    redstone.setOutput(DO_RECYCLE_REDSTONE_DIR, true)
    ensureRecycleIsEmpty()
    redstone.setOutput(DO_RECYCLE_REDSTONE_DIR, false)
end

function main(tp)
    print("Starting up")
    redstone.setOutput(DO_RECYCLE_REDSTONE_DIR, false)
    redstone.setOutput(IS_RECYCLE_EMPTY_REDSTONE_DIR, false)
    turtle.select(1)

    print("Clearing inventory..")
    tp:dropEntireInventory(RECYCLE_CHEST, 2)
    clearRecycle()

    while true do
        print("Grabbing 1st")
        tp:suck(INPUT_CHEST, 1, nil, nil, 2)
        local done_with_current = false

        while done_with_current == false do
            print("Grabbing 2nd")
            local suck_result, suck_msg = tp:suck(INPUT_CHEST, 1)

            if suck_result ~= 1 then
                print("Input is empty, recycling")
                tp:drop(COMPLETED_CHEST)
                clearRecycle()
                done_with_current = true
            else
                print("Trying to combine")
                -- Spread out if they stack
                if tp:getSlotDetails(1).count == 2 then
                    turtle.transferTo(2,1)
                end

                local craft_res, craft_msg = turtle.craft()
                if craft_res ~= true then
                    print("Couldn't, continuing")
                    turtle.select(2)
                    tp:drop(RECYCLE_CHEST)
                    turtle.select(1)
                else
                    print("Combine successful")
                end
            end
        end
    end
end

runTurtlePlus(main)