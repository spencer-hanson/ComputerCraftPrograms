require("./libs/turtleplus")
require("./libs/movement")
require("./libs/ccutil")
-- Script to feed the Spectrolus flower from botania all the colors of wool in the correct order
-- Setup - Top down view
-- [C][C][C][C]
-- [T][ ][ ][ ]
-- [F][ ][ ][ ]
-- Key
-- [C] -> stack of 4 chests
-- [T] -> turtle starting position, facing the chests
-- [F] -> Spectrolus flower
--
-- Note: Each chest should contain only one type of wool, it DOES NOT matter where they go, only that they are unique

-- ---------
-- Constants
-- ---------
-- 0 for Gaia mana spreader with potency lens
-- somewhere between 0.05-0.3 ish for Gaia mana spreader w/o potency lens
-- somewhere between 0.9-1.5 for elven mana spreader with potency lens

SLEEP_BETWEEN_DROPS = 0
COLOR_PREFIX = "minecraft:"
COLOR_SUFFIX = "_wool"
function formatColor(colr)
    return COLOR_PREFIX .. colr .. COLOR_SUFFIX
end
COLOR_ORDER = {
    "white",
    "orange",
    "magenta",
    "light_blue",
    "yellow",
    "lime",
    "pink",
    "gray",
    "light_gray",
    "cyan",
    "purple",
    "blue",
    "brown",
    "green",
    "red",
    "black"
}

COLOR_MAP = {
    -- Map of Color - [coordinate list, slot]
}

function checkInventory(tp)

    for i=1,16,1 do
        local item_name = tp:getSlotDetails(i).name
        local found = false
        for _, wool_name in ipairs(COLOR_ORDER) do
            if formatColor(wool_name) == item_name then
                found = true
            end
        end
        if found == false then
            print("Invalid item '" .. item_name .."' isn't a minecraft wool in the order list!")
            error("unknown item in inventory")
        end
    end
end

function grabWool(tp, colr)
    map_val = COLOR_MAP[colr][1]
    slot = COLOR_MAP[colr][2]
    rows = map_val[1]
    cols = map_val[2]
    print("Color '"..colr.."' is at "..rows..","..cols .. " and in slot " ..slot)
    tp:moveN(MoveDirection.EAST, nil, nil, nil, cols - 1)
    tp:moveN(MoveDirection.UP, nil, nil, nil, rows - 1)
    local amount = 64 - tp:getSlotDetails().count -- get enough to have a full stack
    tp:suck(nil, 2, nil, nil, 2) -- retry every 2 seconds to make sure we got at least 2 wool
    tp:suck(nil, math.max(amount - 2, 0)) -- Grab more if there is any, up to a stack
end

function searchForWool(tp, row, col)
    tp:suck(nil, 2, nil, nil, 2) -- pick up at least 2, retry_sec is 2
    tp:suck(nil, 62) -- try to fill up the stack, but don't wait for it

    item_name = turtle.getItemDetail().name
    print("'"..row..","..col.."' - '" ..item_name)
    local selected_slot = turtle.getSelectedSlot()

    COLOR_MAP[item_name] = {{row, col}, selected_slot}

    if selected_slot ~= 16 then
        turtle.select(selected_slot + 1)
    end
end

function mapChestsToColors(tp)
    turtle.select(1)
    local cur_row_dir = MoveDirection.UP
    for column = 1,4,1 do
        local abs_row = 1
        local abs_row_change = 1 -- change is positive 1
        if cur_row_dir == MoveDirection.DOWN then
            abs_row = 4
            abs_row_change = -1
        end

        for _ = 1,3,1 do
            searchForWool(tp, abs_row, column)
            tp:move(cur_row_dir)
            abs_row = abs_row + abs_row_change
        end

        searchForWool(tp, abs_row, column)
        if column ~= 4 then
            tp:right()
        end
        cur_row_dir = MoveDirection:opposite(cur_row_dir)
    end
    tp:goHome()
end

function mapInventory(tp)
    for i=0, 15, 1 do
        local row = math.fmod(i, 4)
        local col = math.floor(i / 4)
        -- the number of times the slot goes into 4 (i/4) is the column,
        -- and if the column is even (fmod(..,2)) then we start from 4 instead of 1 and count down
        if math.fmod(col,2) ~= 0 then
            row = 3 - row
        end

        -- 1 index'd (not 0 indexed)
        row = row + 1
        col = col + 1

        turtle.select(i+1)
        item_name = tp:getSlotDetails().name
        print("Mapping '"..item_name.."' to '"..row..","..col)
        COLOR_MAP[item_name] = {{row, col}, i+1}
    end
end

function deliverWool(tp)
    while true do
        print("Completed cycle, continuing")
        for _, colr in ipairs(COLOR_ORDER) do
            local wool_name = formatColor(colr)
            color_data = COLOR_MAP[wool_name]
            turtle.select(color_data[2]) -- slot where the wool color is
            slot_data = tp:getSlotDetails()
            if slot_data.count <= 1 then
                -- out of that color of wool, need to go get more
                tp:turn(MoveDirection.NORTH)
                grabWool(tp, wool_name)
                tp:goHome()
            end
            os.sleep(SLEEP_BETWEEN_DROPS) -- sleep since the flower produces too much mana, dont want to waste
            tp:drop(MoveDirection.SOUTH, 1, false)
        end
    end
end

function main(tp)
    if tp:isInventoryEmpty() then
        mapChestsToColors(tp)
        deliverWool(tp)
    else
        print("Assuming inventory is colormap, terminate and clear inventory if this is not the case")
        os.sleep(2)
        checkInventory(tp)
        mapInventory(tp)
        deliverWool(tp)
        --grabWool(tp, formatColor("magenta"))
        --tp:goHome()
        --grabWool(tp, formatColor("light_gray"))
        --tp:goHome()
        --grabWool(tp, formatColor("red"))
        --tp:goHome()
        --grabWool(tp, formatColor("green"))
        --tp:goHome()
        --grabWool(tp, formatColor("purple"))
        --tp:goHome()
    end
    tp:finish()
end

runTurtlePlus(main)
