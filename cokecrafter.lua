require("turtleplus")
DROP_COUNT = 11 -- how many to drop each iteration
CRAFT_SLEEP = 500 -- how long to sleep before crafting again
CRAFT_MATERIAL_NAME = "modern_industrialization:coke"
EXCESS_CHEST_DIRECTION = MoveDirection.WEST


function craftCokeBlocks()
    local item_detail = turtle.getItemDetail()
    print("item_detail " .. strlist(item_detail) or "nil")
    local items_in_slot = 64
    if item_detail ~= nil then
        items_in_slot = item_detail.count
    end

    local items_per_slot = (items_in_slot - (items_in_slot % 9))/9

    local crafting_slots = {1,2,3,5,6,7,9,10,11}
    for i=2,9,1 do
        turtle.transferTo(crafting_slots[i], items_per_slot)
    end
    turtle.craft()
end

function dropExcessMaterials(t)
    local prev_direction = t.current_direction
    t:turn(EXCESS_CHEST_DIRECTION)
    for i=1,16,1 do
        turtle.select(i)
        local details = turtle.getItemDetail(i)
        if details ~= nil then
            if details.name == CRAFT_MATERIAL_NAME then
                t:drop(EXCESS_CHEST_DIRECTION, -1, false, false, 3)
            end
        end
    end
    t:turn(prev_direction)
end

function main(t)
    if DROP_COUNT > 64 then
        error("DROP_COUNT can't be larger than 64!")
    end

    if t:countEntireInventory() ~= 0 then
        error("Please empty turtle before starting program!")
    end

    local amount = 64
    local previously_crafted = 0

    while true do
        dropExcessMaterials(t)
        local crafted_count = 0
        if turtle.getItemCount(2) == 0 then
            crafted_count = turtle.getItemCount(1)
        else
            crafted_count = turtle.getItemCount(2)
        end

        if crafted_count + previously_crafted < DROP_COUNT then
            previously_crafted = previously_crafted + crafted_count

            amount = (DROP_COUNT - previously_crafted)*9
            if amount > 64 then
                amount = 64
            end

            turtle.select(2)
            t:dropDown()
            turtle.select(1)
            t:dropDown()
        else
            turtle.select(2)
            t:dropDown()
            turtle.select(1)
            t:dropDown()
            previously_crafted = 0
            turtle.select(1)
            amount = turtle.getItemSpace()
            print("Sleeping before next crafting..")
            os.sleep(CRAFT_SLEEP)
        end
        turtle.select(1)
        t:suck("north", amount, nil, nil, nil, 5)
        craftCokeBlocks()
    end
end

runTurtlePlus(nil, main)
