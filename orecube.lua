require("./libs/turtleplus")
require("./libs/movement")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
CUBE_FORWARD = 11
CUBE_RIGHT = 11
CUBE_DOWN = 5
DIG_HOME = true
REPLACE_FLOOR = true

BLOCKS_NAMES = {"minecraft:stone"}
ORECHID_NAME_SLOT_16 = "botania:orechid"
DIRT_NAME_SLOT_15 = "minecraft:dirt"


function placeFunc(t)
    local past_facing_direction = t.current_direction
    while true do
        print("Placing..")
        t:selectNext(BLOCKS_NAMES)
        local success, reason = turtle.placeDown() -- todo placing api
        if success then
            t:turn(past_facing_direction)
            return
        elseif reason == "No items to place" then
            if t:totalBlocksInInventory(BLOCKS_NAMES) == 0 then
                local forward = t.current_forward
                local right = t.current_right
                local down = t.current_down
                t:goHome()

                t:dropStuffBlacklist(DROP_CHEST, BLOCKS_NAMES)
                t:suckUntilStuff(BLOCKS_CHEST, BLOCKS_NAMES, 64)
                t:goTo(forward, right, down)
            else
                t:selectNext(BLOCK_NAMES)
            end
        elseif reason == "Cannot place block here" then
            if REPLACE_FLOOR then
                t:digDown()
            else
                t:turn(past_facing_direction)
                return
            end
        else
            print("Cannot place, reason: " .. tostring(reason))
            os.sleep(1)
        end
    end
end


function main(t)
    function dig(tt)
        turtle.digDown()
    end

    t:cube(dig, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, true)
    t:goTo(0, 0, CUBE_DOWN-1)

    t:cube(placeFunc, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, false)
    print("Finished, going home")
    t:goHome()
    t:dropStuffBlacklist(DROP_CHEST, BLOCKS_NAMES)
    t:finish()
end

runTurtlePlus(nil, main)
