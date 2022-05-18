INVENTORY_SIZE = 16
DEBUG_TURTLE = true

require("ccutil")
require("movement")

-- TurtlePlus
TurtlePlus = {
    home_drop_direction = MoveDirection.SOUTH,
    home_fuel_direction = MoveDirection.UP,
    home_refill_direction = MoveDirection.WEST,
    is_home = true,
    current_direction = TurnDirection.NORTH,
    current_forward = 0,
    current_right = 0,
    current_down = 0,
    keep_running = true,
    listen_to_commands = true -- if false will not listen to commands, on it's way to be shut down
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
    o.keep_running = true
    o.listen_to_commands = true
    return o
end

function TurtlePlus_backgroundCoroutine(turtle_plus)
    local done = false
    local key_mapping_to_func = {
        h = turtle_plus.goHomeAndTerminate
    }
    local function checkKeyPress()
        while not done do
            local event, data = os.pullEvent()
            if event == "char" then
                local val = key_mapping_to_func[data]
                if val ~= nil then
                    print("Got a valid key signal..")
                    done = false or val(turtle_plus)
                end
            end
        end
    end

    local function bgTest()
        while not done do
            --print("background test")
            --print("from bg thread" .. turtle_plus:getCurrentPositionStr())
            os.sleep(1)
            if not turtle_plus.keep_running then
                print("Ending co-routine")
                done = true
            end
        end
    end

    function backgroundFunc()
        parallel.waitForAll(
                checkKeyPress,
                bgTest
        )
    end

    return backgroundFunc
end

function TurtlePlus:getCurrentPositionStr()
    return "(" .. tostring(self.current_forward) .. ", " .. tostring(self.current_right) .. ", " .. tostring(self.current_down) .. ", " .. tostring(self.current_direction) .. ")"
end

function turtlePlusCheckListenToCommands(turtle_plus)
    if not turtle_plus.listen_to_commands then
        while not turtle_plus.listen_to_commands do
            debugM("Turtle ignoring commands..")
            os.sleep(1)
        end
    end
end

function TurtlePlus:turnRelative(turn_rel_dir)
    turtlePlusCheckListenToCommands(self)
    validateRelativeTurnDirection(turn_rel_dir)
    local directions = { "north", "east", "south", "west" }
    local offset = 0
    if turn_rel_dir == RelativeTurnDirection.LEFT then
        turtle.turnLeft()
        offset = -1
    else
        turtle.turnRight()
        offset = 1
    end

    local facing_idx = 0
    for i = 1, table.getn(directions), 1 do
        if self.current_direction == directions[i] then
            facing_idx = i
            debugM("Found current facing direction idx " .. facing_idx)
            break
        end
    end

    facing_idx = facing_idx + offset
    if facing_idx > 4 then
        facing_idx = 1
    elseif facing_idx < 1 then
        facing_idx = 4
    end
    debugM("facing_idx " .. facing_idx .. " Now facing " .. directions[facing_idx])
    self.current_direction = directions[facing_idx]
end

function TurtlePlus:turn(turn_dir, ignore_command_flag)
    if ignore_command_flag == nil then
        ignore_command_flag = false
    end
    if not ignore_command_flag then
        turtlePlusCheckListenToCommands(self)
    end

    validateTurnDirection(turn_dir)
    local turn_mapping = {
        -- current_position -> new position -> list of moves to get there
        north = {
            north = {},
            south = { "left", "left" },
            east = { "right" },
            west = { "left" }
        },
        south = {
            north = { "right", "right" },
            south = {},
            east = { "left" },
            west = { "right" }
        },
        east = {
            north = { "left" },
            south = { "right" },
            east = {},
            west = { "right", "right" }
        },
        west = {
            north = { "right" },
            south = { "left" },
            east = { "left", "left" },
            west = {}
        }
    }
    local cur_dir = self.current_direction
    if cur_dir == turn_dir then
        return
    else
        debugM("Turning " .. turn_dir)
        local turns = turn_mapping[cur_dir][turn_dir]
        for i = 1, table.getn(turns), 1 do
            if turns[i] == "left" then
                debugM("left")
                turtle.turnLeft()
            else
                debugM("right")
                turtle.turnRight()
            end
        end
    end
    self.current_direction = turn_dir
end

function TurtlePlus:doDirectionalFunc(dir, amount, func_up, func_down, func, do_correct, do_turn)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 or nil will not retry)
    if retry_sec == nil then
        retry_sec = 0
    end

    turtlePlusCheckListenToCommands(self)
    validateMoveDirection(dir)
    local previous_direction = self.current_direction

    if do_turn then
        if dir ~= MoveDirection.UP and dir ~= MoveDirection.DOWN then
            self:turn(dir)
        end
    end
    local resp = nil
    if dir == MoveDirection.UP then
        resp = func_up(amount)
    elseif dir == MoveDirection.DOWN then
        resp = func_down(amount)
    else
        resp = func(amount)
    end

    if do_correct then
        self:turn(previous_direction)
    end

    return unpack(resp)
end

function wrapDropFunc(dropFunc)
    function newDropFunc(amount)
        local beforeAmt = turtle.getItemCount(turtle.getSelectedSlot())

        local result, reason = dropFunc(amount)
        if not result then
            return result, reason
        else
            local afterAmt = turtle.getItemCount(turtle.getSelectedSlot())
            return beforeAmt - afterAmt
        end
    end
    return newDropFunc
end

function TurtlePlus:drop(dir, amount, do_correct, do_turn, retry_sec)
    turtlePlusCheckListenToCommands(self)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 will not retry)

    -- if amount == -1 drop all
    if dir == nil then
        dir = MoveDirection.NORTH
    end

    if do_correct == nil then
        do_correct = false
    end

    if do_turn == nil then
        do_turn = true
    end

    if retry_sec == nil then
        retry_sec = 0
    end


    local dropped_count = 0
    if amount == -1 or amount == nil then
        local item = turtle.getItemDetail()
        if item == nil then
            return
        end
        amount = item.count
    end

    local function dropCheckFunc(item_count, ...)
        debugM("Checking " .. tostring(item_count) .. " - " .. strlist(arg))
        if item_count == false then
            return false
        elseif item_count == true then
            return true
        end

        dropped_count = dropped_count + item_count
        if retry_sec == 0 then
            return true
        end

        if dropped_count ~= amount then
            print("Dropped amount failure, ActualDropped " .. tostring(dropped_count) .. " != AmountToDrop " .. amount)
            return false
        else
            return true
        end
    end

    local up = wrapFuncInWaitAndRetryFunc(wrapDropFunc(turtle.dropUp), retry_sec, dropCheckFunc, "DropUp() failed, nothing dropped, retrying in " .. tostring(retry_sec))
    local f = wrapFuncInWaitAndRetryFunc(wrapDropFunc(turtle.drop), retry_sec, dropCheckFunc, "Drop() failed, nothing dropped, retrying in " .. tostring(retry_sec))
    local down = wrapFuncInWaitAndRetryFunc(wrapDropFunc(turtle.dropDown), retry_sec, dropCheckFunc, "DropDown() failed, nothing dropped, retrying in " .. tostring(retry_sec))

    return self:doDirectionalFunc(dir, amount, up, down, f, do_correct, do_turn, retry_sec)
end

function wrapSuckFunc(suckFunc)
    function newSuckFunc(amount)
        print("Suck " .. amount)
        --error("TODO") -- TODO if you suck() while current slot is full, will put in empty slot, leading to incorrect
        -- count of number of things sucked up
        local beforeAmt = turtle.getItemCount(turtle.getSelectedSlot())
        local result, reason = suckFunc(amount)
        if not result then
            return result, reason
        else
            local afterAmt = turtle.getItemCount(turtle.getSelectedSlot())
            return afterAmt - beforeAmt
        end
    end
    return newSuckFunc
end

function TurtlePlus:suck(dir, amount, do_correct, do_turn, retry_sec)
    turtlePlusCheckListenToCommands(self)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 will not retry)

    -- if amount == -1 or nil suck all
    if dir == nil then
        dir = MoveDirection.NORTH
    end

    if do_correct == nil then
        do_correct = false
    end

    if do_turn == nil then
        do_turn = true
    end

    if retry_sec == nil then
        retry_sec = 0
    end

    local suck_all = false
    if amount == -1 or amount == nil then
        suck_all = true
        amount = 64
    end

    local function suckCheckFunc(item_count, message)
        if retry_sec == 0 then
            return true
        end

        if item_count == false then
            return false
        end

        if retry_sec == 0 then
            return true
        end

        if suck_all and item_count > 1 then
            return true
        elseif item_count == amount then
            print("Suck amount failure, ActualSucked " .. tostring(item_count) .. " != AmountToSuck " .. amount)
            return false
        else
            return true
        end
    end

    local up = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(turtle.suckUp), retry_sec, suckCheckFunc, "SuckUp() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))
    local f = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(turtle.suck), retry_sec, suckCheckFunc, "Suck() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))
    local down = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(turtle.suckDown), retry_sec, suckCheckFunc, "SuckDown() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))

    return self:doDirectionalFunc(dir, amount, up, down, f, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dropEntireInventory(dir, retry_sec)
    turtlePlusCheckListenToCommands(self)
    validateMoveDirection(dir)
    for i = 1, INVENTORY_SIZE, 1 do
        turtle.select(i)
        self:drop(dir, -1, false, false, retry_sec)
    end
end

function TurtlePlus:move(dir, do_correct)
    turtlePlusCheckListenToCommands(self)
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
        waitAndRetry(turtle.up, 5, "Moving up failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        return
    elseif dir == MoveDirection.DOWN then
        waitAndRetry(turtle.down, 5, "Moving down failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        return
    end

    local function shiftOrder(order, num_shifts)
        new_order = {}
        order_len = table.getn(order)
        for i = 0, order_len - 1, 1 do
            local val = (i + num_shifts) % order_len
            new_order[val + 1] = order[i + 1]
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

    local orig_order = { "north", "east", "south", "west" }
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

    debugM("Shifted " .. strlist(shifted_order))
    debugM(self.current_direction .. " -" .. shifted_idx .. "> " .. tostring(new_direction))
    debugM("Dir " .. dir .. " newdir " .. new_direction)

    --local movement_success = false


    if new_direction == MoveDirection.WEST then
        turtle.turnLeft()
        waitAndRetry(turtle.forward, 5, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnRight()
        else
            self.current_direction = dir
        end

    elseif new_direction == MoveDirection.EAST then
        turtle.turnRight()
        waitAndRetry(turtle.forward, 5, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnLeft()
        else
            self.current_direction = dir
        end
    elseif new_direction == MoveDirection.NORTH then
        waitAndRetry(turtle.forward, 5, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
    elseif new_direction == MoveDirection.SOUTH then
        waitAndRetry(turtle.back, 5, "Moving backwards failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
    end


end

function TurtlePlus:goHomeAndTerminate()
    self.listen_to_commands = false
    print("Sending terminate..")
    os.sleep(2)
    print("Forcing go home")
    self:goHome(true)
    error("Turtle forcibly reset by user")
end

function TurtlePlus:goHome(ignore_command_flag)
    if not ignore_command_flag then
        turtlePlusCheckListenToCommands(self)
    end

    self:turn(MoveDirection.NORTH, ignore_command_flag)

    for i = 1, self.current_down, 1 do
        if ignore_command_flag then
            turtle.up()
        else
            self:move(MoveDirection.UP, false)
        end
    end

    if ignore_command_flag then
        turtle.turnLeft()
    else
        self:turnRelative(RelativeTurnDirection.LEFT)
    end

    for i = 1, self.current_right, 1 do
        if ignore_command_flag then
            turtle.forward()
        else
            self:move(MoveDirection.FORWARD, false)
        end
    end

    if ignore_command_flag then
        turtle.turnRight()
    else
        self:turnRelative(RelativeTurnDirection.RIGHT)
    end

    for i = 1, self.current_forward, 1 do
        if ignore_command_flag then
            turtle.back()
        else
            self:move(RelativeTurnDirection.SOUTH, false)
        end
    end

    self.current_forward = 0
    self.current_right = 0
    self.current_down = 0
end

function TurtlePlus:goTo(forward, right, down, do_correct)
    turtlePlusCheckListenToCommands(self)
    local old_dir = self.current_direction
    for i = 1, forward, 1 do
        self:move(MoveDirection.NORTH, false)
    end
    for i = 1, right, 1 do
        self:move(MoveDirection.EAST, false)
    end
    for i = 1, down, 1 do
        self:move(MoveDirection.DOWN, false)
    end

    if do_correct then
        self:turn(old_dir)
    end

end

function TurtlePlus:dropOffInventoryAtHome()
    turtlePlusCheckListenToCommands(self)
    f = self.current_forward
    r = self.current_right
    d = self.current_down
    self:goHome()
    self:dropEntireInventory(self.home_drop_direction, 5)
    self:goTo(f, r, d)
end

function TurtlePlus:pickupFuelAtHome()
    turtlePlusCheckListenToCommands(self)
    f = self.current_forward
    r = self.current_right
    d = self.current_down
    self:goHome()
    -- TODO
    error("todo")
    self:goTo(f, r, d, false)
end

function TurtlePlus:moveAndFunc(dir, do_correct, moveFunc)
    turtlePlusCheckListenToCommands(self)
    self:move(dir, do_correct)
    moveFunc()
end

function TurtlePlus:finish()
    self.keep_running = false
end

function runTurtlePlus(turtle_plus, main_func)
    debugM("Starting turtle..")
    if turtle_plus == nil then
        turtle_plus = TurtlePlus:new()
    end

    function mainFunc()
        return main_func(turtle_plus)
    end

    parallel.waitForAll(
            TurtlePlus_backgroundCoroutine(turtle_plus),
            mainFunc
    )
    debugM("All routines finished, stopping")
end
