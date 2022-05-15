local forward = 3 -- 11
local right = 3 -- 11
local down = 4 -- 5

cur_place_slot = 1
cur_dig_slot = 1

cur_facing_direction = "forward"
cur_f = 0
cur_r = 0
cur_d = 0

function dropEntireInventory()
  for i=1,16,1 do
    turtle.select(i)
    turtle.drop()
  end
end

function reverseTurn()
    if cur_facing_direction == "right" then
      turtle.turnLeft()
    elseif cur_facing_direction == "left" then
      turtle.turnRight()
    elseif cur_facing_direction ~= "forward" then
      error("Invalid facing direction!")
    end
end

function refillAndDropoff()
  print("Refilling and Dropping off stuff")
  print("Current position (f,r,d) " .. tostring(cur_f) .. " " .. tostring(cur_r) .. " " .. tostring(cur_d))
  reverseTurn()

  for i=0,cur_d-1,1 do
    turtle.up()
  end

  turtle.turnLeft()
  for i=0,cur_r-1,1 do
    turtle.forward()
  end
  turtle.turnRight()

  for i=0,cur_f-1,1 do
    turtle.back()
  end

  turtle.turnLeft()
  turtle.turnLeft()
  dropEntireInventory()
  turtle.turnLeft()
  turtle.turnLeft()

  for i=0,cur_f-1,1 do
    turtle.forward()
  end

  turtle.turnRight()
  for i=0,cur_r-1,1 do
    turtle.forward()
  end
  turtle.turnLeft()

  for i=0,cur_d-1,1 do
    turtle.down()
  end

  turnT(cur_facing_direction, true)
end


function selectPlaceSlot()
  print("Selecting placement slot")

  if cur_place_slot > 16 then
    print("Empty, refilling!")
    refillAndDropoff()
  end

  c = turtle.getItemCount(cur_place_slot)

  if c == 0 then
    print("Placement slot empty, recursing")
    cur_place_slot = cur_place_slot + 1
    selectPlaceSlot()
  else
    turtle.select(cur_place_slot )
    print("Found placement slot")
  end
end

function checkInvEmpty()
  has_blocks = false
  for i=1,16,1 do
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
  for i=1,15,1 do
    c = turtle.getItemCount(i)
    if c == 0 then
      has_empty = true
      break
    end
  end

  if not has_empty then
    print("FULL emptying")
    refillAndDropoff()
    return
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
      cur_d = cur_d - 1
    elseif dir == "forward" then
      turtle.forward()
      cur_f = cur_f + 1
    elseif dir == "right" then
      cur_r = cur_r + 1
      turn("right")
      turtle.forward()
      correct = true
    elseif dir == "left" then
      cur_r = cur_r - 1
      turn("left")
      turtle.forward()
      correct = true
    elseif dir == "down" then
      turtle.down()
      cur_d = cur_d + 1
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

    if cur_facing_direction == dir and not force then
      return
    elseif dir ~= "forward" and cur_facing_direction ~= "forward" and not force then
      error("Invalid direction to turn " .. dir .. " not facing forward")
    end

    if dir == "left" then
      cur_facing_direction = "left"
      turtle.turnLeft()
    elseif dir == "right" then
      cur_facing_direction = "right"
      turtle.turnRight()
    elseif dir == "forward" then
      reverseTurn()
      cur_facing_direction = "forward"
    end
end

function digHoriz()
  -- start at one since we're already in slot 1
  for i=1,right-1,1 do
    dig("forward")
    digMove("right")
  end
  digMove("forward")
  turtle.turnLeft()
  for i=1,right-1,1 do
    turtle.forward()
   end
   turtle.turnRight()
  cur_f = cur_f + 1
  cur_r = 0
end



for d=0,down-1,1 do
    -- dig row
    for f=0,forward-2,1 do
        digHoriz()
    end
    -- go back to beginning
    for f=0,forward-1,1 do
        turtle.back()
    end

    if d ~= down-1 then
      cur_r = 0
      cur_f = 0
      digMove("down")
    end
end

for u=0,down-2,1 do
  move("up")
end

turtle.turnLeft()
turtle.turnLeft()
dropEntireInventory()
turtle.turnLeft()
turtle.turnLeft()


