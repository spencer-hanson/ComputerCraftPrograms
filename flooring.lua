require("./libs/turtleplus")
require("./libs/movement")

FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
PLANE_FORWARD = 37
PLANE_RIGHT = 10
DIG_HOME = true
REPLACE_FLOOR = true
BLOCKS_NAMES = {"minecraft:dirt"}
--"byg:mahogany_planks"

function planeFunc(t)
    local past_facing_direction = t.current_direction
    t:dig()
    while true do
        print("Placing..")
        local success, reason = turtle.placeDown() -- todo placing api
        if success then
            t:turn(past_facing_direction)
            return
        elseif reason == "No items to place" then
            if t:totalBlocksInInventory(BLOCKS_NAMES) == 0 then
                local forward = t.current_forward
                local right = t.current_right
                local down = t.current_down
                t:goHome(DIG_HOME)

                local s, r = t:drop(DROP_CHEST, nil, false, true, 5)
                while s do
                    s, r = t:suck(BLOCKS_CHEST, nil, false, true, 5)
                end
                if t:totalBlocksInInventory(BLOCKS_NAMES) == 0 then
                    t:suck(BLOCKS_CHEST, 1, false, true, 5)
                    t:suck(BLOCKS_CHEST, nil, false, true, 5)
                end
                t:goTo(forward, right, down, nil, DIG_HOME)
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
    t:plane(planeFunc, PLANE_RIGHT, PLANE_FORWARD)
end

runTurtlePlus(nil, main)
