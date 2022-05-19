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
            -- TODO background funcs?
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

function turtlePlusCheckListenToCommands(turtle_plus, ignore_command_flag)
    ignore_command_flag = ignore_command_flag or false
    if ignore_command_flag then
        return
    end

    if not turtle_plus.listen_to_commands then
        while not turtle_plus.listen_to_commands do
            debugM("Turtle ignoring commands..")
            errorTrace("test")
            os.sleep(1)
        end
    end
end

-- Turn funcs
function TurtlePlus:turnLeft()
    return self:turnRelative(RelativeTurnDirection.LEFT)
end

function TurtlePlus:turnRight()
    return self:turnRelative(RelativeTurnDirection.RIGHT)
end

function TurtlePlus:turnRelative(turn_rel_dir, ignore_command_flag)
    turtlePlusCheckListenToCommands(self, ignore_command_flag)
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
            --debugM("Found current facing direction idx " .. facing_idx)
            break
        end
    end

    facing_idx = facing_idx + offset
    if facing_idx > 4 then
        facing_idx = 1
    elseif facing_idx < 1 then
        facing_idx = 4
    end
    --debugM("facing_idx " .. facing_idx .. " Now facing " .. directions[facing_idx])
    self.current_direction = directions[facing_idx]
end

function TurtlePlus:turn(turn_dir, ignore_command_flag)
    turtlePlusCheckListenToCommands(self, ignore_command_flag)
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
        --debugM("Turning " .. turn_dir)
        local turns = turn_mapping[cur_dir][turn_dir]
        for i = 1, table.getn(turns), 1 do
            if turns[i] == "left" then
                turtle.turnLeft()
            else
                turtle.turnRight()
            end
        end
    end
    self.current_direction = turn_dir
end

-- Directional funcs
function TurtlePlus:doDirectionalFunc(dir, func_args, func_up, func_down, func, do_correct, do_turn, ignore_command_flag)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 or nil will not retry)
    ignore_command_flag = ignore_command_flag or false

    turtlePlusCheckListenToCommands(self, ignore_command_flag)
    validateMoveDirection(dir)
    local previous_direction = self.current_direction

    if do_turn then
        if dir ~= MoveDirection.UP and dir ~= MoveDirection.DOWN then
            self:turn(dir)
        end
    end
    local resp = nil
    if dir == MoveDirection.UP then
        resp = func_up(unpackM(func_args))
    elseif dir == MoveDirection.DOWN then
        resp = func_down(unpackM(func_args))
    else
        resp = func(unpackM(func_args))
    end

    if do_correct then
        self:turn(previous_direction, ignore_command_flag)
    end

    return unpackM(resp)
end

-- Drop() funcs
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

function TurtlePlus:dropUp(amount, retry_sec)
    return self:drop(MoveDirection.UP, amount, false, false, retry_sec)
end

function TurtlePlus:dropDown(amount, retry_sec)
    return self:drop(MoveDirection.DOWN, amount, false, false, retry_sec)
end

function TurtlePlus:dropLeft(amount, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
    self:drop(MoveDirection.left(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dropRight(amount, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
    self:drop(MoveDirection.right(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:drop(dir, amount, do_correct, do_turn, retry_sec)
    turtlePlusCheckListenToCommands(self)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 will not retry)
    -- if amount == -1 drop all
    dir = dir or MoveDirection.NORTH
    do_correct = do_correct or true
    do_turn = do_turn or true
    retry_sec = retry_sec or 0

    local dropped_count = 0
    if amount == -1 or amount == nil then
        local item = turtle.getItemDetail()
        if item == nil then
            return
        end
        amount = item.count
    end

    local function dropCheckFunc(item_count, ...)
        --debugM("Checking " .. tostring(item_count) .. " - " .. strlist(arg))
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

    return self:doDirectionalFunc(dir, {amount}, up, down, f, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dropEntireInventory(dir, retry_sec)
    turtlePlusCheckListenToCommands(self)
    validateMoveDirection(dir)
    for i = 1, INVENTORY_SIZE, 1 do
        turtle.select(i)
        self:drop(dir, -1, false, false, retry_sec)
    end
end

-- Suck() funcs
function wrapSuckFunc(turtle_plus, suckFunc)
    function newSuckFunc(amount)
        local beforeAmt = turtle_plus:countEntireInventory()
        local result, reason = suckFunc(amount)
        if not result then
            return result, reason
        else
            local afterAmt = turtle_plus:countEntireInventory()
            return afterAmt - beforeAmt
        end
    end
    return newSuckFunc
end

function TurtlePlus:suckUp(amount, retry_sec)
    return self:suck(MoveDirection.UP, amount, false, false, retry_sec)
end

function TurtlePlus:suckDown(amount, retry_sec)
    return self:suck(MoveDirection.DOWN, amount, false, false, retry_sec)
end

function TurtlePlus:suckLeft(amount, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
   return self:suck(MoveDirection.left(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:suckRight(amount, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
    return self:suck(MoveDirection.right(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:suck(dir, amount, do_correct, do_turn, retry_sec, ignore_command_flag)
    ignore_command_flag = ignore_command_flag or false
    turtlePlusCheckListenToCommands(self, ignore_command_flag)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 will not retry)

    -- if amount == -1 or nil suck all
    dir = dir or MoveDirection.NORTH
    do_correct = do_correct or true
    do_turn = do_turn or true
    retry_sec = retry_sec or 0

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

        if suck_all and item_count > 1 then
            return true
        elseif item_count == amount then
            print("Suck amount failure, ActualSucked " .. tostring(item_count) .. " != AmountToSuck " .. amount)
            return false
        else
            return true
        end
    end

    local up = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suckUp), retry_sec, suckCheckFunc, "SuckUp() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))
    local f = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suck), retry_sec, suckCheckFunc, "Suck() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))
    local down = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suckDown), retry_sec, suckCheckFunc, "SuckDown() failed, insufficient amount or none, retrying in " .. tostring(retry_sec))

    return self:doDirectionalFunc(dir, {amount}, up, down, f, do_correct, do_turn, retry_sec, ignore_command_flag)
end

-- Dig() funcs
function TurtlePlus:digUp(tool_side, retry_sec)
    return self:dig(MoveDirection.UP, tool_side, false, false, retry_sec)
end

function TurtlePlus:digDown(tool_side, retry_sec)
    return self:dig(MoveDirection.DOWN, tool_side, false, false, retry_sec)
end

function TurtlePlus:digLeft(tool_side, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
    return self:dig(MoveDirection.left(self.current_direction), tool_side, do_correct, do_turn, retry_sec)
end

function TurtlePlus:digRight(tool_side, do_correct, do_turn, retry_sec)
    do_correct = do_correct or true
    do_turn = do_turn or true
    return self:dig(MoveDirection.right(self.current_direction), tool_side, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dig(dir, tool_side, do_correct, do_turn, retry_sec)
    validateMoveDirection(dir)
    turtlePlusCheckListenToCommands(self)

    dir = dir or MoveDirection.NORTH
    do_correct = do_correct or true
    do_turn = do_turn or true
    retry_sec = retry_sec or 0

    local f = waitAndRetry(turtle.dig, retry_sec, "Dig() returned false, retrying in " .. tostring(retry_sec))
    local up = waitAndRetry(turtle.digUp, retry_sec, "DigUp() returned false, retrying in " .. tostring(retry_sec))
    local down = waitAndRetry(turtle.digDown, retry_sec, "DigDown() returned false, retrying in " .. tostring(retry_sec))
    return self:doDirectionalFunc(dir, {tool_side}, up, down, f, do_correct, do_turn, retry_sec)
end

-- Move() funcs
function TurtlePlus:forward()
    return self:move(self.current_direction, false, nil)
end

function TurtlePlus:back()
    return self:move(MoveDirection.opposite(self.current_direction), false, nil)
end

function TurtlePlus:up()
    return self:move(MoveDirection.UP, false, nil)
end

function TurtlePlus:down()
    return self:move(MoveDirection.DOWN, false, nil)
end

function TurtlePlus:right(do_correct)
    do_correct = do_correct or true
    return self:move(MoveDirection.right(self.current_direction), do_correct, nil)
end

function TurtlePlus:left(do_correct)
    do_correct = do_correct or true
    return self:move(MoveDirection.left(self.current_direction), do_correct, nil)
end
function TurtlePlus:moveN(dir, do_correct, retry_sec, ignore_command_flag, num_moves)
    print("Calling moveN with " .. tostring(dir) .. ", " .. tostring(dir) .. ", " .. tostring(retry_sec) .. ", " .. tostring(ignore_command_flag) .. ", " .. tostring(num_moves))
    --os.sleep(3)
    num_moves = num_moves or 1
    ignore_command_flag = ignore_command_flag or false
    for i=1,num_moves,1 do
        self:move(dir, do_correct, retry_sec, ignore_command_flag)
    end
end

function TurtlePlus:checkFuel()
    if not self.listen_to_commands then
        return
    end

    local level = turtle.getFuelLevel()
    if level < self:numMovesFromHome() + 3 then
        print("Refueling..")
        self.listen_to_commands = false
        local f = self.current_forward
        local d = self.current_down
        local r = self.current_right
        local direction = self.current_direction
        self:goHome(true)


        local cur_sel = turtle.getSelectedSlot()
        while true do
            self:suck(self.home_fuel_direction, -1, true, true, 5, true)
            for i=1,INVENTORY_SIZE,1 do
                turtle.select(i)
                turtle.refuel()
            end
            if turtle.getFuelLevel() < (f + r + d)*2 + 5 then
                print("Not enough fuel! Insert more")
                os.sleep(3)
            else
                break
            end
        end

        turtle.select(cur_sel)
        print("Going back to work..")
        self:goTo(f, r, d, false, true)
        self:turn(direction, true)
        self.listen_to_commands = true
    end
end

function wrapMoveFunc(turtle_plus, move_func)
    function wrappedFunc()
        turtle_plus:checkFuel()
        return move_func()
    end
    return wrappedFunc
end

function TurtlePlus:move(dir, do_correct, retry_sec, ignore_command_flag)
    print("Calling move with " .. tostring(dir) .. ", " .. tostring(dir) .. ", " .. tostring(retry_sec) .. ", " .. tostring(ignore_command_flag))
    --os.sleep(3)
    self:checkFuel()
    ignore_command_flag = ignore_command_flag or false
    turtlePlusCheckListenToCommands(self, ignore_command_flag)
    -- do_correct correct the turn
    validateMoveDirection(dir)
    do_correct = do_correct or true
    retry_sec = retry_sec or 5

    if dir == MoveDirection.UP then
        waitAndRetry(wrapMoveFunc(self, turtle.up), 5, "Moving up failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        self.current_down = self.current_down - 1
        return
    elseif dir == MoveDirection.DOWN then
        waitAndRetry(wrapMoveFunc(self, turtle.down), 5, "Moving down failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        self.current_down = self.current_down + 1
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

    --debugM("Shifted " .. strlist(shifted_order))
    --debugM(self.current_direction .. " -" .. shifted_idx .. "> " .. tostring(new_direction))
    --debugM("Dir " .. dir .. " newdir " .. new_direction)

    --local movement_success = false


    if new_direction == MoveDirection.WEST then
        turtle.turnLeft()
        waitAndRetry(wrapMoveFunc(self, turtle.forward), retry_sec, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnRight()
        else
            self.current_direction = dir
        end

    elseif new_direction == MoveDirection.EAST then
        turtle.turnRight()
        waitAndRetry(wrapMoveFunc(self, turtle.forward), retry_sec, "Moving east failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnLeft()
        else
            self.current_direction = dir
        end
    elseif new_direction == MoveDirection.NORTH then
        waitAndRetry(wrapMoveFunc(self, turtle.forward), retry_sec, "Moving north failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
    elseif new_direction == MoveDirection.SOUTH then
        waitAndRetry(wrapMoveFunc(self, turtle.back), retry_sec, "Moving south failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
    end

    if dir == MoveDirection.NORTH then
        self.current_forward = self.current_forward + 1
    elseif dir == MoveDirection.EAST then
        self.current_right = self.current_right + 1
    elseif dir == MoveDirection.SOUTH then
        self.current_forward = self.current_forward - 1
    elseif dir == MoveDirection.WEST then
        self.current_right = self.current_right - 1
    end
end

-- Extra funcs

function TurtlePlus:goHomeAndTerminate()
    self.listen_to_commands = false
    print("Sending terminate..")
    os.sleep(2)
    print("Forcing go home")
    self:goHome(true)
    error("Turtle forcibly reset by user")
end

function TurtlePlus:goHome(ignore_command_flag)
    debugM("Going home")
    turtlePlusCheckListenToCommands(self, ignore_command_flag)

    self:turn(MoveDirection.NORTH, ignore_command_flag)
    self:moveN(MoveDirection.UP, false, nil, ignore_command_flag, self.current_down)

    self:turnRelative(RelativeTurnDirection.LEFT, ignore_command_flag)
    self:moveN(self.current_direction, false, nil, ignore_command_flag, self.current_right)

    self:turnRelative(RelativeTurnDirection.RIGHT, ignore_command_flag)
    self:moveN(MoveDirection.SOUTH, false, nil, ignore_command_flag, self.current_forward)

    self.current_forward = 0
    self.current_right = 0
    self.current_down = 0
end

function TurtlePlus:goTo(forward, right, down, do_correct, ignore_command_flag)
    ignore_command_flag = ignore_command_flag or false
    turtlePlusCheckListenToCommands(self, ignore_command_flag)
    local old_dir = self.current_direction
    self:moveN(MoveDirection.NORTH, false, nil, ignore_command_flag, forward)
    self:moveN(MoveDirection.EAST, false, nil, ignore_command_flag, right)
    self:moveN(MoveDirection.DOWN, false, nil, ignore_command_flag, down)

    if do_correct then
        self:turn(old_dir, ignore_command_flag)
    end
end

function TurtlePlus:dropOffInventoryAtHome(dir)
    dir = dir or self.home_drop_direction

    turtlePlusCheckListenToCommands(self)
    local f = self.current_forward
    local r = self.current_right
    local d = self.current_down
    self:goHome()
    self:dropEntireInventory(self.home_drop_direction, 5)
    self:goTo(f, r, d)
end

function TurtlePlus:countEntireInventory()
    local prev_selected_slot = turtle.getSelectedSlot()
    local total = 0
    for i=1,INVENTORY_SIZE,1 do
        total = total + turtle.getItemCount(i)
    end
    turtle.select(prev_selected_slot)
    return total
end

function TurtlePlus:numMovesFromHome()
   return self.current_right + self.current_forward + self.current_down
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
