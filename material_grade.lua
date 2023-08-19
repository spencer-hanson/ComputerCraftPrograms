require("./libs/turtleplus")
require("./libs/ccutil")

-- Program to craft Blazing Dust from Silent Gear
OUTPUT_CHEST = MoveDirection.NORTH
HAMMER_CHEST = MoveDirection.EAST
GLOWSTONE_CHEST = MoveDirection.WEST
GOLD_CHEST = MoveDirection.UP
BLAZE_CHEST = MoveDirection.DOWN

HAMMER_NAME = "silentgear:hammer"
GLOWSTONE_NAME = "minecraft:glowstone_dust"
BLAZE_POWDER_NAME = "silentgear:blaze_gold_dust"
BLAZE_INGOT_NAME = "silentgear:blaze_gold_ingot"

function tryCraft(tp)
    local res = turtle.craft()
    if res ~= true then
        errorTrace("Can't craft, error!")
    end
end
function main(tp)
    turtle.select(1)

    if tp:isInventoryEmpty() ~= true then
        print("Inventory must be empty to start program!")
        tp:finish()
    else
        print("Starting Material Grading")
        while true do
            tp:suck(BLAZE_CHEST, 64, true, true, 2)
            turtle.transferTo(2, 16)
            turtle.transferTo(3, 16)
            turtle.transferTo(5, 16)
            turtle.transferTo(6, 16)
            tp:suck(GOLD_CHEST, 16, true, true, 2)
            tryCraft(tp)

            tp:suck(HAMMER_CHEST, 1, true, true, 2)
            tryCraft(tp)
            tp:selectNext({BLAZE_INGOT_NAME})
            local selected = tp:getSlotDetails()
            if selected.name == BLAZE_INGOT_NAME then
                tp:selectNext({BLAZE_POWDER_NAME}, 1)
                tp:suck(HAMMER_CHEST, 1, true, true, 2) -- get a new hammer
                tp:selectNext({BLAZE_POWDER_NAME}, 1)
                tp:drop(HAMMER_CHEST) -- drop already crafted blaze powder
                tryCraft(tp)
                tp:selectNext({BLAZE_POWDER_NAME})
                tp:suck(HAMMER_CHEST)  -- grab back the blaze powder
            end

            local found = tp:selectNext({HAMMER_NAME})
            if found then
                tp:drop(HAMMER_CHEST, 1, true, true)
            end
            print("Dropping hammer, now glowstone")
            tp:suck(GLOWSTONE_CHEST, 32, true, true, 2)
            tp:selectNext({GLOWSTONE_NAME}, 1)
            turtle.transferTo(2, 16)
            turtle.transferTo(5, 16)

            tryCraft(tp)
            tp:drop(OUTPUT_CHEST, -1, true, true, 2)
            turtle.select(1)
        end
    end
end

runTurtlePlus(main)
