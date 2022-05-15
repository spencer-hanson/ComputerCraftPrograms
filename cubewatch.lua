DIG_FORWARD = 3 -- 11
DIG_RIGHT = 3 -- 11
DIG_DOWN = 3 -- 5

-- Relative to the starting position of the turtle, where are the chests for dropping, refueling and placing
HOME_DROP_LOCATION = "south"  -- TODO import movement utility funcs and change to consts
HOME_FUEL_LOCATION = "up"
HOME_PLACE_LOCATION = "west"


-- Start Movement utility functions and classes



-- End Movement utility functions and classes



function returnToHome()
    reverseTurn()

    for i = 0, CURRENT_DOWN_MOVEMENT - 1, 1 do
        turtle.up()
    end

    turtle.turnLeft()
    for i = 0, CURRENT_RIGHT_MOVEMENT - 1, 1 do
        turtle.forward()
    end
    turtle.turnRight()

    for i = 0, CURRENT_FORWARD_MOVEMENT - 1, 1 do
        turtle.back()
    end
end

function returnToWork()
    for i = 0, CURRENT_FORWARD_MOVEMENT - 1, 1 do
        turtle.forward()
    end

    turtle.turnRight()
    for i = 0, CURRENT_RIGHT_MOVEMENT - 1, 1 do
        turtle.forward()
    end
    turtle.turnLeft()

    for i = 0, CURRENT_DOWN_MOVEMENT - 1, 1 do
        turtle.down()
    end

    turnT(CURRENT_FACING_DIRECTION, true)
end

function dropOffInventoryAtHome()
    print("Dropping off stuff")
    print("Current position (forward, right, down) " .. getCurrentPositionStr())

    returnToHome()

    dropEntireInventory(loc)

    returnToWork()

end

function pickupFuelAtHome()
    print("Going home to refuel")
    print("Current position (forward, right, down) " .. getCurrentPositionStr())

    returnToHome()

    turtle.turnLeft()
    turtle.turnLeft()

    dropEntireInventory()

    turtle.turnLeft()
    turtle.turnLeft()

    returnToWork()

end

function selectPlaceSlot()
    print("Selecting placement slot")

    if CURRENT_PLACEMENT_SLOT > 16 then
        print("Empty, refilling!")
        refillAndDropoff()
    end

    count = turtle.getItemCount(CURRENT_PLACEMENT_SLOT)

    if count == 0 then
        print("Placement slot empty, recursing")
        CURRENT_PLACEMENT_SLOT = CURRENT_PLACEMENT_SLOT + 1
        selectPlaceSlot()
    else
        turtle.select(CURRENT_PLACEMENT_SLOT)
        print("Found placement slot")
    end
end

function checkInvEmpty()
    has_blocks = false
    for i = 1, 16, 1 do
        c = turtle.getItemCount(i)
        if c ~= 0 then
            has_blocks = true
            break
        end
    end
    if not has_blocks then
        print("Out of blocks, refilling")
        refillAndDropoff()
        return
    end
end

function checkInvFull()
    has_empty = false
    for i = 1, 16, 1 do
        c = turtle.getItemCount(i)
        if c == 0 then
            has_empty = true
            break
        end
    end

    if not has_empty then
        print("Inventory Full, emptying")
        dropOffInventoryAtHome()
        return
    end
end

function checkFuel()
    fuel = turtle.getFuelLevel()
    if fuel * 2 < CURRENT_FORWARD_MOVEMENT + CURRENT_RIGHT_MOVEMENT + CURRENT_DOWN_MOVEMENT then
        print("Low on fuel, refueling")
        refillAndDropoff()
    end
end

function move(dir)
    moveT(dir, true)
end

function moveT(dir, do_correct)
    print("MoveT " .. dir .. " " .. tostring(do_correct))
    checkInvFull()
    correct = false

    if dir == "up" then
        turtle.up()
        CURRENT_DOWN_MOVEMENT = CURRENT_DOWN_MOVEMENT - 1
    elseif dir == "forward" then
        turtle.forward()
        CURRENT_FORWARD_MOVEMENT = CURRENT_FORWARD_MOVEMENT + 1
    elseif dir == "right" then
        CURRENT_RIGHT_MOVEMENT = CURRENT_RIGHT_MOVEMENT + 1
        turn("right")
        turtle.forward()
        correct = true
    elseif dir == "left" then
        CURRENT_RIGHT_MOVEMENT = CURRENT_RIGHT_MOVEMENT - 1
        turn("left")
        turtle.forward()
        correct = true
    elseif dir == "down" then
        turtle.down()
        CURRENT_DOWN_MOVEMENT = CURRENT_DOWN_MOVEMENT + 1
    else
        error("invalid direction to move")
    end

    if correct and do_correct then
        turn("forward")
    end
end

function dig(dir)
    digT(dir, true)
end

function digT(dir, do_correct)
    print("DigT " .. dir .. " " .. tostring(do_correct))

    checkInvFull()
    correct = false

    if dir == "up" then
        turtle.digUp()
    elseif dir == "forward" then
        turtle.dig()
    elseif dir == "down" then
        turtle.digDown()
    elseif dir == "left" then
        turn("left")
        turtle.dig()
        correct = true
    elseif dir == "right" then
        turn("right")
        turtle.dig()
        correct = true
    else
        error("invalid direction to dig")
    end
    if correct and do_correct then
        turn("forward")
    end
end

function digMove(dir)
    print("DigMove " .. dir)
    checkInvFull()
    digT(dir, false)
    moveT(dir, false)
    turn("forward")
end

function turn(dir)
    turnT(dir, false)
end

function turnT(dir, force)
    print("TurnT " .. dir .. " " .. tostring(force))

    if CURRENT_FACING_DIRECTION == dir and not force then
        return
    elseif dir ~= "forward" and CURRENT_FACING_DIRECTION ~= "forward" and not force then
        error("Invalid direction to turn " .. dir .. " not facing forward")
    end

    if dir == "left" then
        CURRENT_FACING_DIRECTION = "left"
        turtle.turnLeft()
    elseif dir == "right" then
        CURRENT_FACING_DIRECTION = "right"
        turtle.turnRight()
    elseif dir == "forward" then
        reverseTurn()
        CURRENT_FACING_DIRECTION = "forward"
    end
end

function digHoriz()
    -- start at one since we're already in slot 1
    for i = 1, DIG_RIGHT - 1, 1 do
        dig("forward")
        digMove("right")
    end
    digMove("forward")
    turtle.turnLeft()
    for i = 1, DIG_RIGHT - 1, 1 do
        turtle.forward()
    end
    turtle.turnRight()
    CURRENT_FORWARD_MOVEMENT = CURRENT_FORWARD_MOVEMENT + 1
    CURRENT_RIGHT_MOVEMENT = 0
end

for d = 0, DIG_DOWN - 1, 1 do
    -- dig row
    for f = 0, DIG_FORWARD - 2, 1 do
        digHoriz()
    end
    -- go back to beginning
    for f = 0, DIG_FORWARD - 1, 1 do
        turtle.back()
    end

    if d ~= DIG_DOWN - 1 then
        CURRENT_RIGHT_MOVEMENT = 0
        CURRENT_FORWARD_MOVEMENT = 0
        digMove("down")
    end
end

for u = 0, DIG_DOWN - 2, 1 do
    move("up")
end

turtle.turnLeft()
turtle.turnLeft()
dropEntireInventory()
turtle.turnLeft()
turtle.turnLeft()


