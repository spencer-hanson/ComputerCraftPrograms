INVENTORY_SIZE = 16

-- General Lua Utility Funcs
function errorTrace(message)
    for i=2,4,1 do
        local info = debug.getinfo(i)
        local info_name = tostring(info.name)
        if info == nil or info_name == nil or info_name == "pcall" or info_name == "nil" then
            break
        else
            print("at " .. info_name .. ": " .. tostring(info.linedefined))
        end
    end

    error(message)
end

function strlist(l)
    local s = ""
    for i=1,table.getn(l),1 do
        s = s .. "," .. l[i]
    end
    return s
end
-- MoveDirection
MoveDirection = {
    NORTH = "north",
    SOUTH = "south",
    EAST = "east",
    WEST = "west",
    UP = "up",
    DOWN = "down"
}

function validateMoveDirection(dir)
    if dir == MoveDirection.NORTH or dir == MoveDirection.SOUTH or dir == MoveDirection.EAST or dir == MoveDirection.WEST or dir == MoveDirection.UP or dir == MoveDirection.DOWN then
        return
    else
        if dir == nil then
            dir = "nil"
        end
        errorTrace("Invalid MoveDirection '" .. dir .. "'")
    end
end

function MoveDirection:opposite(dir)
    validateMoveDirection(dir)
    local reverse = {
        north = "south",
        south = "north",
        east = "west",
        west = "east",
        up = "down",
        down = "up"
    }
    return reverse[dir]
end

-- TurnDirection
TurnDirection = {
    NORTH = "north",
    SOUTH = "south",
    EAST = "east",
    WEST = "west"
}

function validateTurnDirection(dir)
    if dir == TurnDirection.NORTH or dir == TurnDirection.SOUTH or dir == TurnDirection.EAST or dir == TurnDirection.WEST then
        return
    else
        if dir == nil then
            dir = "nil"
        end
        errorTrace("Invalid TurnDirection '" .. dir .. "'")
    end
end

function TurnDirection:opposite(dir)
    validateTurnDirection(dir)
    local reverse = {
        north = "south",
        south = "north",
        east = "west",
        west = "east"
    }
    return reverse[dir]
end

function TurnDirection:fromMoveDirection(dir)
    validateMoveDirection(dir)
    local map = {
        up = "none",
        down = "none",
        left = "left",
        right = "right"
    }
end

-- TurtlePlus
TurtlePlus = {
    home_drop_direction = MoveDirection.SOUTH,
    home_fuel_direction = MoveDirection.UP,
    home_refill_direction = MoveDirection.WEST,
    is_home = true,
    current_direction = TurnDirection.NORTH,
    current_forward = 0,
    current_right = 0,
    current_down = 0
}

function TurtlePlus:new(o)
    local o = o or {}
    setmetatable(o, TurtlePlus)
    self.__index = self

    o.home_drop_direction = MoveDirection.SOUTH
    o.home_fuel_direction = MoveDirection.UP
    o.home_refill_direction = MoveDirection.WEST
    o.is_home = true
    o.current_direction = TurnDirection.NORTH
    o.current_forward = 0
    o.current_right = 0
    o.current_down = 0
    return o
end

function TurtlePlus:getCurrentPositionStr()
    return "(" .. tostring(self.current_forward) .. ", " .. tostring(self.current_right) .. ", " .. tostring(self.current_down) .. ", " .. tostring(self.current_direction) .. ")"
end

function TurtlePlus:turn(turn_dir)
    validateTurnDirection(turn_dir)
    local turn_mapping = {
        -- current_position -> new position -> list of moves to get there
        north = {
            north = {},
            south = {"left", "left"},
            east = {"right"},
            west = {"left"}
        },
        south = {
            north = {"right", "right"},
            south = {},
            east = {"left"},
            west = {"right"}
        },
        east = {
            north = {"left"},
            south = {"right"},
            east = {},
            west = {"right", "right"}
        },
        west = {
            north = {"right"},
            south = {"left"},
            east = {"left", "left"},
            west = {}
        }
    }
    local cur_dir = self.current_direction
    if cur_dir == turn_dir then
        return
    else
        print("Turning " .. turn_dir)
        local turns = turn_mapping[cur_dir][turn_dir]
        for i=1,table.getn(turns),1 do
            if turns[i] == "left" then
                print("left")
                turtle.turnLeft()
            else
                print("right")
                turtle.turnRight()
            end
        end
    end
    self.current_direction = turn_dir
end

function TurtlePlus:doDirectionalFunc(dir, amount, func_up, func_down, func, do_correct, do_turn)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction

    validateMoveDirection(dir)
    local previous_direction = self.current_direction

    if do_turn then
        if dir ~= MoveDirection.UP and dir ~= MoveDirection.DOWN then
            self:turn(dir)
        end
    end

    if dir == MoveDirection.UP then
        func_up(amount)
    elseif dir == RelativeDirection.DOWN then
        func_down(amount)
    else
        func(amount)
    end

    if do_correct then
        self:turn(previous_direction)
    end
end

function TurtlePlus:drop(dir, amount, do_correct, do_turn)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction

    -- if amount == -1 drop all
    if amount == -1 then
        local item = turtle.getItemDetail()
        if item == nil then
            return
        end
        amount = item.count
    end
    self:doDirectionalFunc(dir, amount, turtle.dropUp, turtle.dropDown, turtle.drop, do_correct, do_turn)
end

function TurtlePlus:suck(dir, amount, do_correct, do_turn)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction

    -- if amount == -1 suck all
    if amount == -1 then
        amount = 64
    end
    self:doDirectionalFunc(dir, amount, turtle.suckUp, turtle.suckDown, turtle.suck, do_correct, do_turn)
end

function TurtlePlus:dropEntireInventory(dir)
    validateMoveDirection(dir)
    for i = 1, INVENTORY_SIZE, 1 do
        turtle.select(i)
        self:drop(dir, -1, false, false)
    end
end

function TurtlePlus:move(dir, do_correct)
    -- do_correct correct the turn
    validateMoveDirection(dir)

    if dir == MoveDirection.NORTH then
        self.current_forward = self.current_forward + 1
    elseif dir == MoveDirection.EAST then
        self.current_right = self.current_right + 1
    elseif dir == MoveDirection.SOUTH then
        self.current_forward = self.current_forward - 1
    elseif dir == MoveDirection.WEST then
        self.current_right = self.current_right - 1
    elseif dir == MoveDirection.UP then
        self.current_down = self.current_down - 1
    elseif dir == MoveDirection.DOWN then
        self.current_down = self.current_down + 1
    end

    if dir == MoveDirection.UP then
        turtle.up()
        return
    elseif dir == MoveDirection.DOWN then
        turtle.down()
        return
    end

    local function shiftOrder(order, num_shifts)
        new_order = {}
        order_len = table.getn(order)
        for i=0,order_len-1,1 do
            local val = (i + num_shifts) % order_len
            new_order[val+1] = order[i+1]
        end
        return new_order
    end

    -- north 0 shifts
    -- north,east,south,west
    -- north,east,south,west

    -- south 2 shifts right
    -- CURRENT  south,west,north,east
    -- ABSOLUTE north,east,south,west

    -- east 1 shifts right
    -- east,south,west,north

    -- west 3 shift right
    -- west,north,east,south

    local orig_order = {"north", "east", "south", "west"}
    local order_idxs = { -- index values of the above array
        north = 1,
        east = 2,
        south = 3,
        west = 4
    }
    local shift_mapping = { -- how many shifts each direction needs
        north = 0,
        west = 3,
        south = 2,
        east = 1
    }

    local directional_shift = shift_mapping[self.current_direction]
    local shifted_order = shiftOrder(orig_order, directional_shift)


    local shifted_idx = order_idxs[dir]
    local new_direction = shifted_order[shifted_idx]

    print("Shifted " .. strlist(shifted_order))
    --print(self.current_direction .. " -" .. shifted_idx .. "> " .. tostring(new_direction))
    print("Dir " .. dir .. " newdir " .. new_direction)

    if new_direction == MoveDirection.WEST then
        turtle.turnLeft()
        turtle.forward()
        if do_correct then
            turtle.turnRight()
        else
            self.current_direction = dir
        end

    elseif new_direction == MoveDirection.EAST then
        turtle.turnRight()
        turtle.forward()
        if do_correct then
            turtle.turnLeft()
        else
            self.current_direction = dir
        end
    elseif new_direction == MoveDirection.NORTH then
        turtle.forward()
    elseif new_direction == MoveDirection.SOUTH then
        turtle.back()
    end
end

function TurtlePlus:goHome()
    self:turn(MoveDirection.NORTH)
    for i=1,self.current_down,1 do
        turtle.up()
    end

    turtle.turnLeft()
    for i=1,self.current_right,1 do
        turtle.forward()
    end
    turtle.turnRight()

    for i=1,self.current_forward,1 do
        turtle.back()
    end
    self.current_forward = 0
    self.current_right = 0
    self.current_down = 0
end

function TurtlePlus:goTo(forward, right, down)

end



t = TurtlePlus:new()
-- Turn directionality test
--dirs = {"north","east","south","west"}
--for i=1,4,1 do
--    t:turn(dirs[i])
--    for j=1,4,1 do
--        print("moving " .. dirs[j])
--        t:move(dirs[j], false)
--        os.sleep(2)
--    end
--end


t:move("north", false)
t:move("east", false)
t:move("north", false)
t:move("east", false)
t:move("down", false)
t:move("down", false)
t:move("down", false)

t:goHome()

--t:turn("north")
--t:turn("east")
--os.sleep(2)
--print(t:getCurrentPositionStr())
--t:move("north")

--t:move("west")
--t:move("south")
--t:turn("north")



