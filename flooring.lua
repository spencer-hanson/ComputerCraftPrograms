require("./libs/turtleplus")
require("./libs/movement")

-- Fill out a floor with a block/seeds/something placeable

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
PLANE_FORWARD = 33
PLANE_RIGHT = 33
DIG_HOME = true
REPLACE_FLOOR = true
BLOCKS_NAMES = {"minecraft:sweet_berries"}
--"byg:mahogany_planks"

function refill(t)
    if t:totalBlocksInInventory(BLOCKS_NAMES) == 0 then
        local forward = t.current_forward
        local right = t.current_right
        local down = t.current_down

        t:goHome()
        t:dropStuffBlacklist(DROP_CHEST, BLOCKS_NAMES)
        -- EDITED for compressed dirt
        --t:suck(BLOCKS_CHEST)
        --turtle.craft()
        --
        t:suckUntilStuff(BLOCKS_CHEST, BLOCKS_NAMES)
        t:goTo(forward, right, down)
    end
end
function placeFunc(t)
    local past_facing_direction = t.current_direction
    while true do
        print("Placing..")
        if contains(t:getSlotDetails().name, BLOCKS_NAMES) == false then
            if not t:selectNext(BLOCKS_NAMES) then
                refill(t)
            end
        end

        local success, reason = turtle.placeDown() -- todo placing api
        if success then
            t:turn(past_facing_direction)
            return
        elseif reason == "No items to place" then
            refill(t)
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
    --refill(t)
    --t:turn("north")
    --os.sleep(15)
    t:moveNum("down", 29)
    t:plane(placeFunc, PLANE_RIGHT, PLANE_FORWARD)
    --t:goTo(16, 16, 30)
    t:goHome()
    t:finish()
end

runTurtlePlus(main)
