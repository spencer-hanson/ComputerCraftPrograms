require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")
-- Sort items into different inventories, given a config
-- Sorting all armor, tools and weapons out from a given input

CURRENT_CONFIG = "DEFAULT"

CONFIG = {
    DEFAULT={
        PASSTHROUGH_CHEST=MoveDirection.EAST,
        INPUT_CHEST=MoveDirection.NORTH,
        TRASH_CHEST=MoveDirection.UP,
        COMPUTER_CHEST=MoveDirection.DOWN
    }
} -- todo config stuff

PASSTHROUGH_CHEST = CONFIG[CURRENT_CONFIG]["PASSTHROUGH_CHEST"]
INPUT_CHEST = CONFIG[CURRENT_CONFIG]["INPUT_CHEST"]
COMPUTER_CHEST = CONFIG[CURRENT_CONFIG]["COMPUTER_CHEST"]
TRASH_CHEST = CONFIG[CURRENT_CONFIG]["TRASH_CHEST"]

EQUIPMENT_NAMES = {
    "sword",
    "pickaxe",
    "axe",
    "boots",
    "leggings",
    "chestplate",
    "helmet",
    "bow",
    "crossbow",
    "shield"
}

function match_equipment_with_prefix(prefix, value)
    if value:sub(1, #prefix) == prefix then
        for _, equipment in ipairs(EQUIPMENT_NAMES) do
            if value:sub(-#equipment) == equipment then
                return true
            end
        end
        return false
    else
        return false
    end
end

function passthrough_match(value)
    return match_equipment_with_prefix("minecraft", value)
end

function trash_match(value)
    if value:sub(1, #"minecraft") == "minecraft" then
        return false
    end

    return match_equipment_with_prefix("", value)
end

function computer_match(value)
    return true
end

RULE_CHECK_ORDER = {
    "passthrough",
    "trash",
    "computer"
}

function passthrough(tp)
    print("Passes through")
    tp:drop(PASSTHROUGH_CHEST, -1, nil, nil, 3)
end

function trash(tp)
    -- pass to other chest
    print("goes to trash")
    tp:drop(TRASH_CHEST, -1, nil, nil, 3)
end

function computer(tp)
    print("goes to computer")
    tp:drop(COMPUTER_CHEST, -1, nil, nil, 3)
end

RULES = {
    ["passthrough"] = {passthrough_match, passthrough},
    ["trash"] = {trash_match, trash},
    ["computer"] = {computer_match, computer}
}



function sortItemName(tp, name, slot)
    turtle.select(slot)
    for i=1,table.getn(RULE_CHECK_ORDER),1 do
        rule = RULE_CHECK_ORDER[i]
        if RULES[rule][1](name) then
            RULES[rule][2](tp)
            return
        end
    end
end

function sort(tp, slot)
    slot = defaultNil(slot, 1)
    local data = tp:getSlotDetails(slot)
    if data["name"] ~= "none" and data["count"] > 0 then
        sortItemName(tp, data["name"], slot)
    end
end

function main(tp)
    for i = 1, INVENTORY_SIZE,1 do
        sort(tp, i)
    end

    turtle.select(1)
    while true do
        tp:suck(INPUT_CHEST, -1, nil, nil, nil, nil, false)
        sort(tp, nil)
    end
end

runTurtlePlus(main)
