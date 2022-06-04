require("./libs/turtleplus")
require("./libs/ccutil")
require("./libs/movement")

INPUT_CHEST = MoveDirection.UP
RECYCLE_CHEST = MoveDirection.NORTH
OUTPUT_CHEST = MoveDirection.DOWN

RULES = {
    -- Techreborn 2x2 recipes
    { "techreborn:redstone_small_dust", "2x2" },
    { "techreborn:platinum_small_dust", "2x2" },
    { "techreborn:platinum_small_dust", "2x2" },
    { "techreborn:yellow_garnet_small_dust", "2x2" },
    { "techreborn:emerald_small_dust", "2x2" },
    { "techreborn:red_garnet_small_dust", "2x2" },
    { "techreborn:sulfur_small_dust", "2x2" },
    { "techreborn:sapphire_small_dust", "2x2" },
    { "techreborn:glowstone_small_dust", "2x2" },
    { "techreborn:peridot_small_dust", "2x2" },
    { "techreborn:ruby_small_dust", "2x2" },
    { "techreborn:.+_small_dust", "2x2" },


    -- Techreborn 3x3 recipes
    { "techreborn:silver_nugget", "3x3" },
    { "techreborn:nickel_nugget", "3x3" },
    { "techreborn:lead_nugget", "3x3" },
    { "techreborn:tin_nugget", "3x3" },
    { "techreborn:.+_nugget", "3x3" },

    -- Minecraft 3x3
    { "minecraft:gold_nugget", "3x3"},
    { "minecraft:iron_nugget", "3x3"},

    -- Modern Industrialization 3x3
    { "modern_industrialization:.+_tiny_dust", "3x3"}
}


function generateRuleList()
    local item_names = {}
    local count = 1

    for rule_idx = 1, table.getn(RULES), 1 do
        item_names[count] = RULES[rule_idx][1]
        count = count + 1
    end
    return item_names
end

RULE_ITEM_NAME_LIST = generateRuleList()

function setup2x2()
    local slots = { 1, 2, 5, 6 }
    distributeEvenly(slots)
end

function setup3x3()
    local slots = { 1, 2, 3, 5, 6, 7, 9, 10, 11 }
    distributeEvenly(slots)
end

CRAFTING_PATTERNS = {
    { "2x2", setup2x2 },
    { "3x3", setup3x3 }
}

turtle_plus = TurtlePlus:new()

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

function lookupCraftingRecipe(recipe)
    for craft_idx = 1, table.getn(CRAFTING_PATTERNS), 1 do
        local pattern = CRAFTING_PATTERNS[craft_idx]
        local name = pattern[1]
        local func = pattern[2]
        if name == recipe then
            return func
        end
    end
    return nil
end

function lookupRecipeForCurrentSlot()
    local data = turtle_plus:getSlotDetails()
    local error_str = "no match for any known recipes"

    for rule_idx = 1, table.getn(RULES), 1 do
        local rule = RULES[rule_idx]
        local item_name = rule[1]
        if string.match(data["name"], item_name) ~= nil then
            local item_crafting_pattern = rule[2]
            print(item_name .. " matched pattern " .. item_crafting_pattern)
            local pat_f = lookupCraftingRecipe(item_crafting_pattern)
            if pat_f ~= nil then
                return pat_f
            else
                error_str = "Matched item, invalid crafting recipe name '" .. item_crafting_pattern .. "'"
                break
            end
        end
    end

    print("Error with Item " .. data["name"] .. "'" .. error_str .. "'")
    turtle_plus:dropEntireInventory(RECYCLE_CHEST)
    --os.sleep(5)
    return nil
end

function recycleAndOutput()
    turtle_plus:dropStuffWhitelist(RECYCLE_CHEST, RULE_ITEM_NAME_LIST)
    turtle_plus:dropEntireInventory(OUTPUT_CHEST)
end

function main(t)
    turtle.select(1)
    recycleAndOutput()

    while true do
        turtle_plus:suck(INPUT_CHEST)
        local pat_func = lookupRecipeForCurrentSlot()
        if pat_func ~= nil then
            pat_func()

            local csuccess, creason = turtle.craft()
            if not csuccess then
                print("Error crafting " .. tostring(creason))
                turtle_plus:dropEntireInventory(RECYCLE_CHEST)
            else
                print("Crafting success")
            end
        end
        recycleAndOutput()
    end
end

runTurtlePlus(turtle_plus, main)
