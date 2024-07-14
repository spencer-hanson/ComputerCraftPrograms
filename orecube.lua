require("./libs/turtleplus")
require("./libs/movement")
require("./libs/ccutil")

-- Script to manage a cube of stone with a botania flower in the center that uses mana to turn the stone into ore
-- This script will mine and re-place all the stone when run
-- Setup - Top Down
--
-- [F][ ]
-- [B][T]
-- [ ][D]
-- Key
-- [F] -> chest containing the flower used, also 1 dirt
-- [B] -> Blocks to place, in the cube
-- [T] -> Turtle AND Fuel chest, where fuel is above the turtle
-- [D] -> Drops chest, directly behind the turtle


FUEL_CHEST = MoveDirection.UP
DROP_CHEST = MoveDirection.SOUTH
BLOCKS_CHEST = MoveDirection.WEST
FLOWER_CHEST = MoveDirection.WEST -- note the flower chest is 1 forward from home, has both the flower and a single dirt

CUBE_FORWARD = 11 -- cube is max range of flower
CUBE_RIGHT = 11
CUBE_DOWN = 5
DIG_HOME = true
REPLACE_FLOOR = true

--BLOCKS_NAMES = {"minecraft:stone"} -- overworld
BLOCKS_NAMES = {"minecraft:netherrack"} -- nether

FLOWER_PLACE_FORWARD = 5  -- Center of the cube
FLOWER_PLACE_RIGHT = 5
FLOWER_PLACE_DOWN = 3

--ORECHID_NAME = "botania:orechid" -- overworld
ORECHID_NAME = "botania:orechid_ignem" -- nether

DIRT_NAME = "minecraft:dirt"


function placeFunc(t)
    local past_facing_direction = t.current_direction
    while true do
        print("Placing..")
        if contains(t:getSlotDetails().name, BLOCKS_NAMES) == false then
            t:selectNext(BLOCKS_NAMES)
        end

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
                t:suckUntilStuff(BLOCKS_CHEST, BLOCKS_NAMES)
                t:goTo(forward, right, down)
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


function makeCube(t)
    t:goHome()
    t:goTo(0, 0, CUBE_DOWN-1)
    t:turn(MoveDirection.NORTH)
    t:cube(placeFunc, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, false)
end

function dig(t)
    if not t:hasEmptySlot() then
        local forward = t.current_forward
        local right = t.current_right
        local down = t.current_down
        local direction = t.current_direction

        t:goHome()
        t:dropEntireInventory(DROP_CHEST)
        t:goTo(forward, right, down)
        t:turn(direction)
    end
    turtle.digDown()
end

function deleteCube(t)
    t:goHome()
    t:cube(dig, CUBE_DOWN, CUBE_RIGHT, CUBE_FORWARD, true)
end

function putFlower(t)
    t:goHome()
    t:forward()
    while true do
        t:suckUntilFail(FLOWER_CHEST)
        if t:totalBlocksInInventory({DIRT_NAME, ORECHID_NAME}) ~= 2 then
            print("No flower and dirt found! Please place in chest! Sleeping for 5")
            os.sleep(5)
        else
            break
        end
    end

    t:goTo(FLOWER_PLACE_FORWARD, FLOWER_PLACE_RIGHT, 0)
    t:moveN("down", nil, nil, nil, FLOWER_PLACE_DOWN-1, true)
    t:digDown()
    t:selectNext({DIRT_NAME}, 1)
    turtle.placeDown()
    t:up()
    t:selectNext({ORECHID_NAME}, 1)
    turtle.placeDown()
    t:goHome()
    cleanInventory(t)
end

function removeFlower(t)
    t:goHome()
    t:goTo(FLOWER_PLACE_FORWARD, FLOWER_PLACE_RIGHT, 0)
    t:moveN("down", nil, nil, nil, FLOWER_PLACE_DOWN-1, true)
    t:digDown()
    t:goHome()
    t:forward()
    t:selectNext({DIRT_NAME}, 1)
    t:drop(FLOWER_CHEST)
    t:selectNext({ORECHID_NAME}, 1)
    t:drop(FLOWER_CHEST)
    t:goHome()
end

function cleanInventory(t)
    t:goHome()
    t:dropStuffBlacklist(DROP_CHEST, BLOCKS_NAMES)
    t:dropStuffWhitelist(BLOCKS_CHEST, BLOCKS_NAMES)
    t:dropEntireInventory(DROP_CHEST, -1)
end

function main(t)
    removeFlower(t)
    deleteCube(t)
    cleanInventory(t)
    makeCube(t)
    putFlower(t)
    t:goHome()
    t:finish()
end

runTurtlePlus(main)
