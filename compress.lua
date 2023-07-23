require("./libs/turtleplus")
-- Craft incoming items from an inventory above the turtle in a 3x3 crafting recipe to 'compress'
-- output below
INPUT_DIR = "north"
OUTPUT_DIR = "down"

function distributeEvenly(slots)
    -- distribute the current selected stack evenly (ish) among the given slots
    -- expects items in slot 1 will move out of slots into other slots
    local num_slots = table.getn(slots)

    local items_in_slot = turtle_plus:getSlotDetails()["count"]
    if items_in_slot < num_slots then
        print("Not enough items to craft!")
        return
    end

    local items_per_slot = (items_in_slot - (items_in_slot % num_slots)) / num_slots
    for i = 2, num_slots, 1 do
        turtle.transferTo(slots[i], items_per_slot)
    end
end

function setup3x3()
    distributeEvenly(slots)
end

function main(t)
    while true do
        local slots = { 1, 2, 3, 5, 6, 7, 9, 10, 11 }
        for i=1,table.getn(slots),1 do
            turtle.select(slots[i])
            t:suck(INPUT_DIR, 64, nil, nil, 2)
        end

        turtle.craft()
        t:dropEntireInventory(OUTPUT_DIR)
    end
end

runTurtlePlus(main)
