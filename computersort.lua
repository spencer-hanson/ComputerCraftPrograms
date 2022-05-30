require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")


turtle_plus = TurtlePlus:new()
CURRENT_CONFIG = "DEFAULT"

CONFIG = {
    DEFAULT={
        PASSTHROUGH_CHEST=MoveDirection.DOWN,
        INPUT_CHEST=MoveDirection.NORTH,
        PROCESS_CHEST=MoveDirection.UP
    }
} -- todo config stuff
PASSTHROUGH_CHEST = CONFIG[CURRENT_CONFIG]["PASSTHROUGH_CHEST"]
INPUT_CHEST = CONFIG[CURRENT_CONFIG]["INPUT_CHEST"]
PROCESS_CHEST = CONFIG[CURRENT_CONFIG]["PROCESS_CHEST"]


function PASSTHROUGH()
    turtle_plus:drop(PASSTHROUGH_CHEST, -1, nil, nil, 3)
end

function PROCESS()
    local csuccess, creason = turtle.craft()
    if not csuccess then
        print("Craft() failed '" .. creason .. "' passing ore along")
    end

    PASSTHROUGH()
    --turtle_plus:drop(PROCESS_CHEST, -1, nil, nil, 3)
end

function INPUT_STUFF()
    turtle_plus:suck(INPUT_CHEST, -1, nil, nil, nil, nil, false)
end

RULES = {
    "modern_industrialization:deepslate_.+",
    "minecraft:deepslate_.+",
    "excavated_variants:.+",
    "ae2:deepslate_.+",
    "gobber2:gobber2_ore_deepslate"
}

function suck()
    INPUT_STUFF()
end

function sortItemName(name, slot)
    turtle.select(slot)
    for i=1,table.getn(RULES),1 do
        pat = RULES[i]
        if string.match(name, pat) ~= nil then
            print(name .. "#sort")
            PROCESS()
            return
        end
    end
    print(name .. "#pass")
    PASSTHROUGH()
end

function sort(slot)
    slot = defaultNil(slot, 1)
    local data = turtle_plus:getSlotDetails(slot)
    if data["name"] ~= "none" and data["count"] > 0 then
        sortItemName(data["name"], slot)
    end
end

function main()
    for i=1,INVENTORY_SIZE,1 do
        sort(i)
    end

    turtle.select(1)
    while true do
        suck()
        sort()
    end

    --parallel.waitForAll(
    --        suckThread,
    --        sortThread
    --)
end

main()
