INVENTORY_SIZE = 16
DEBUG_TURTLE = false

require("./libs/ccutil")
require("./libs/movement")

-- TurtlePlus
TurtlePlus = {
    home_fuel_direction = MoveDirection.UP,
    home_drop_direction = MoveDirection.SOUTH,
    current_direction = TurnDirection.NORTH,
    current_forward = 0,
    current_right = 0,
    current_down = 0,
    keep_running = true,
    listen_to_commands = true, -- if false will not listen to commands, on it's way to be shut down
    force_going_home = false,  -- if true then going home should ignore things
    fuel_blacklist = {} -- list of items to NOT use as fuel
}

function printDbg(val)
    if DEBUG_TURTLE then
        print("[DEBUG] " ..val)
        os.sleep(1)
    end
end


function TurtlePlus:new(o)
    local o = o or {}
    setmetatable(o, TurtlePlus)
    self.__index = self
    o.home_fuel_direction = MoveDirection.UP
    o.home_drop_direction = MoveDirection.SOUTH
    o.current_direction = TurnDirection.NORTH
    o.current_forward = 0
    o.current_right = 0
    o.current_down = 0
    o.keep_running = true
    o.listen_to_commands = true
    o.going_home = false
    o.fuel_blacklist = {}
    return o
end

function TurtlePlus_backgroundCoroutine(turtle_plus)
    local done = false
    local key_mapping_to_func = {
        h = turtle_plus.goHomeAndTerminate,
        -- f = turtle_plus.goForceGoHomeAndTerminate
    }
    local goHome = turtle_plus.goForceGoHomeAndTerminate

    local function forceHomeChecker()
        while not done do
            local event, data = os.pullEvent()
            if event == "char" then
                if data == "f" then
                    print("Force resetting turtle..")
                    goHome(turtle_plus)
                end
            end
        end
    end

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
                bgTest,
                forceHomeChecker
        )
    end

    return backgroundFunc
end

function TurtlePlus:getCurrentPositionStr()
    return "(" .. tostring(self.current_forward) .. ", " .. tostring(self.current_right) .. ", " .. tostring(self.current_down) .. ", " .. tostring(self.current_direction) .. ")"
end

function TurtlePlus:checkFuel()
    if not self.listen_to_commands then
        return
    end

    local level = turtle.getFuelLevel()
    if level < self:numMovesFromHome() + 3 then
        print("Out of fuel! Refueling..")
        self.listen_to_commands = false
        local f = self.current_forward
        local d = self.current_down
        local r = self.current_right
        local direction = self.current_direction
        self:goHome(nil, true)

        local cur_sel = turtle.getSelectedSlot()
        while true do
            printDbg("Attempting to suck up fuel from " .. self.home_fuel_direction)
            local suckResult = self:suck(self.home_fuel_direction, -1, true, true, 5, true, true, "out of fuel, nothing found in inventory!")
            printDbg("Suck returned '" .. suckResult .. "'")

            for i = 1, INVENTORY_SIZE, 1 do
                turtle.select(i)
                local skip = false
                -- TODO untested fuel blacklist
                for _, blacklisted_name in ipairs(self.fuel_blacklist) do
                    if self:getSlotDetails(i).name == blacklisted_name then
                        printDbg("Found invalid fuel, skipping")
                        skip = true
                        break
                    end
                end
                if skip ~= true then
                    printDbg("Found valid fuel, refueling")
	                turtle.refuel()
                end
            end
            if turtle.getFuelLevel() < (f + r + d) * 2 + 5 then
                print("Not enough fuel! Insert more")
                os.sleep(3)
            else
                break
            end
        end

        turtle.select(cur_sel)
        print("Going back to work..")
        self:goTo(f, r, d, false, nil, true)
        self:turn(direction, true)
        self.listen_to_commands = true
    end
end

function turtlePlusCheckListenToCommands(turtle_plus, do_commands_anyways)
    do_commands_anyways = defaultNil(do_commands_anyways, false)
    local function stall()
        while not turtle_plus.listen_to_commands do
            print("Turtle ignoring commands..")
            os.sleep(1)
        end
    end

    if do_commands_anyways ~= false then
        if turtle_plus.force_going_home then
	        if type(do_commands_anyways) == "table" and do_commands_anyways["force"] then
	            return -- we have been told to ignore but we will continue during a forced go home
	        else
	            stall() -- force going home overrides our ignore flag
	        end
        else
            return -- not force going home, and we can ignore commands
        end
    else
        if not turtle_plus.listen_to_commands then
            stall() -- not allowed to do commands, no pass from the flag
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

function TurtlePlus:turnRelative(turn_rel_dir, do_commands_anyways)
    turtlePlusCheckListenToCommands(self, do_commands_anyways)
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
            --print("Found current facing direction idx " .. facing_idx)
            break
        end
    end

    facing_idx = facing_idx + offset
    if facing_idx > 4 then
        facing_idx = 1
    elseif facing_idx < 1 then
        facing_idx = 4
    end
    --print("facing_idx " .. facing_idx .. " Now facing " .. directions[facing_idx])
    self.current_direction = directions[facing_idx]
end

function TurtlePlus:turn(turn_dir, do_commands_anyways)
    turtlePlusCheckListenToCommands(self, do_commands_anyways)
    printDbg("turn(" .. tostring(turn_dir) .. ", " .. tostring(do_commands_anyways) .. ")")

    if turn_dir == RelativeTurnDirection.LEFT or turn_dir == RelativeTurnDirection.RIGHT then
        return self:turnRelative(turn_dir, do_commands_anyways)
    end

    if turn_dir == MoveDirection.UP or turn_dir == MoveDirection.DOWN then
        return
    end

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
        --print("Turning " .. turn_dir)suck
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
function TurtlePlus:doDirectionalFunc(dir, func_args, func_up, func_down, func, do_correct, do_turn, do_commands_anyways)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if < 0 or nil will not retry)
    do_commands_anyways = defaultNil(do_commands_anyways, false)

    turtlePlusCheckListenToCommands(self, do_commands_anyways)
    validateMoveDirection(dir)
    printDbg("doDirectionalFunc(" .. tostring(dir) .. ", " .. tostring(func_args) .. ", " .. tostring(func_up) .. ", " .. tostring(func_down) .. ", " .. tostring(func).. ", " ..tostring(func).. ", " ..tostring(do_correct).. ", " ..tostring(do_turn)..", " ..tostring(do_commands_anyways) .. ")")
    local previous_direction = self.current_direction

    if do_turn then
        if dir ~= MoveDirection.UP and dir ~= MoveDirection.DOWN then
            printDbg("Turning " ..tostring(dir))
            self:turn(dir, do_commands_anyways)
        end
    else
        printDbg("Not Turning")
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
        self:turn(previous_direction, do_commands_anyways)
    end

    return unpackM(resp)
end

-- Drop() funcs
function TurtlePlus:dropStuffFunc(direction, func)
    validateMoveDirection(direction)
    -- Drop stuff according to func(item_name) -> true(drop) else (dont drop)
    local currently_selected_slot = turtle.getSelectedSlot()
    local stuff_slots = self:getNonEmptySlots()

    for i = 1, table.getn(stuff_slots), 1 do
        local slot = stuff_slots[i]
        local info = self:getSlotDetails(slot)
        if func(info.name) then
            turtle.select(slot)
            self:drop(direction, -1, false, true, -1)
        end
    end
    turtle.select(currently_selected_slot)
end

function TurtlePlus:dropStuffWhitelist(direction, whitelisted_stuff_names)
    validateMoveDirection(direction)
    -- Drop only whitelisted stuff
    local function nameMatches(name)
        for i = 1, table.getn(whitelisted_stuff_names), 1 do
            if whitelisted_stuff_names[i] == name then
                return true
            end
        end
        return false
    end
    return self:dropStuffFunc(direction, nameMatches)
end

function TurtlePlus:dropStuffBlacklist(direction, blacklisted_stuff_names)
    validateMoveDirection(direction)
    -- Drop everything but blacklisted stuff
    local function nameDoesntMatch(name)
        for i = 1, table.getn(blacklisted_stuff_names), 1 do
            if blacklisted_stuff_names[i] == name then
                return false
            end
        end
        return true
    end
    return self:dropStuffFunc(direction, nameDoesntMatch)
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

function TurtlePlus:dropUp(amount, retry_sec)
    return self:drop(MoveDirection.UP, amount, false, false, retry_sec)
end

function TurtlePlus:dropDown(amount, retry_sec)
    return self:drop(MoveDirection.DOWN, amount, false, false, retry_sec)
end

function TurtlePlus:dropLeft(amount, do_correct, do_turn, retry_sec)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    self:drop(MoveDirection.left(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dropRight(amount, do_correct, do_turn, retry_sec)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    self:drop(MoveDirection.right(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:drop(dir, amount, do_correct, do_turn, retry_sec)
    turtlePlusCheckListenToCommands(self)
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if <= 0 will not retry)
    -- if amount == -1 drop all
    amount = defaultNil(amount, -1)
    dir = defaultNil(dir, MoveDirection.NORTH)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    retry_sec = defaultNil(retry_sec, 0)

    local dropped_count = 0
    if amount == -1 or amount == nil then
        local item = turtle.getItemDetail()
        if item == nil then
            return
        end
        amount = item.count
    end

    local function dropCheckFunc(item_count, ...)
        --print("Checking " .. tostring(item_count) .. " - " .. strlist(arg))
        if retry_sec <= 0 then
            return true
        end

        if item_count == false then
            return false
        elseif item_count == true then
            return true
        end

        dropped_count = dropped_count + item_count

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

    return self:doDirectionalFunc(dir, { amount }, up, down, f, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dropEntireInventory(dir, retry_sec)
    turtlePlusCheckListenToCommands(self)
    validateMoveDirection(dir)
    retry_sec = defaultNil(retry_sec, 5)
    local last_slot = turtle.getSelectedSlot()

    self:turn(dir)
    local stuff_slots = self:getNonEmptySlots()
    for i = 1, table.getn(stuff_slots), 1 do
        turtle.select(stuff_slots[i])
        self:drop(dir, -1, false, false, retry_sec)
    end
    turtle.select(last_slot)
end

-- Suck() funcs
function TurtlePlus:suckUntilStuff(direction, specific_blocks, num)
    -- suck until inventory gets greater than or equal to the number of specific blocks
    -- set to -1 for any nonzero amount
    num = defaultNil(num, -1)
    local total_found = 0
    local found_blocks = self:totalBlocksInInventory(specific_blocks)
    while true do
        print("Attempting to refill stuff " .. direction .. "..")
        self:suckUntilFail(direction)
        found_blocks = self:totalBlocksInInventory(specific_blocks)
        total_found = total_found + found_blocks
        if found_blocks > 0 and num < 0 then
            return
        elseif total_found >= num then
            return
        else
            os.sleep(2)
        end
    end
end

function TurtlePlus:suckUntilFail(direction)
    direction = defaultNil(direction, self.current_direction)
    validateMoveDirection(direction)
    -- fail reasons
    -- No items to take
    -- No space for items
    while true do
        local success, reason = self:suck(direction, -1, false, true, -1)
        if not success then
            return reason
        end
    end
end

function wrapSuckFunc(turtle_plus, suckFunc, count_sucked, total_amount)
    current_sucked = 0

    function newSuckFunc(amount)
        if not count_sucked then
            return suckFunc(amount)
        end

        local beforeAmt = turtle_plus:countEntireInventory().total
        local result, reason = suckFunc(total_amount - current_sucked)
        if not result then
            return result, reason
        else
            local afterAmt = turtle_plus:countEntireInventory().total
            current_sucked = current_sucked + afterAmt - beforeAmt
            return current_sucked
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
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    return self:suck(MoveDirection:left(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:suckRight(amount, do_correct, do_turn, retry_sec)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    return self:suck(MoveDirection:right(self.current_direction), amount, do_correct, do_turn, retry_sec)
end

function TurtlePlus:suck(dir, amount, do_correct, do_turn, retry_sec, do_commands_anyways, count_sucked, failure_message)
    do_commands_anyways = defaultNil(do_commands_anyways, false)
    -- if amount == -1 or nil suck all
    dir = defaultNil(dir, MoveDirection.NORTH)
    count_sucked = defaultNil(count_sucked, true)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    retry_sec = defaultNil(retry_sec, 0)
    failure_message = defaultNil(failure_message, "insufficient amount or none, retrying in " .. tostring(retry_sec))

    turtlePlusCheckListenToCommands(self, do_commands_anyways)
    printDbg("suck(" .. tostring(dir) .. ", " .. tostring(amount) .. ", " .. tostring(do_correct) .. ", " .. tostring(do_turn) .. ", " .. tostring(retry_sec) .. ", " .. tostring(do_commands_anyways) .. ", " .. tostring(count_sucked) .. ")")
    -- do_correct - correct back to north
    -- do_turn -  turn back to the original direction
    -- retry_sec how long to wait between tries (if <= 0 will not retry)

    local suck_all = false
    if amount == -1 or amount == nil then
        suck_all = true
        amount = 64
    end

    local function suckCheckFunc(item_count, _)
        if retry_sec <= 0 then
            printDbg("suckCheckFunc -r> True")
            return true
        end

        if item_count == false then
            printDbg("suckCheckFunc -i> False")
            return false
        end

        if suck_all and item_count >= 1 then
            printDbg("suckCheckFunc -i> True")
            return true
        elseif item_count ~= amount then
            print("Suck amount failure, ActualSucked " .. tostring(item_count) .. " != AmountToSuck " .. amount)
            printDbg("suckCheckFunc -ia> False")
            return false
        else
            printDbg("suckCheckFunc -ia> True")
            return true
        end
    end

    local up = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suckUp, count_sucked, amount), retry_sec, suckCheckFunc, "SuckUp() failed, " .. failure_message)
    local f = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suck, count_sucked, amount), retry_sec, suckCheckFunc, "Suck() failed, " .. failure_message)
    local down = wrapFuncInWaitAndRetryFunc(wrapSuckFunc(self, turtle.suckDown, count_sucked, amount), retry_sec, suckCheckFunc, "SuckDown() " .. failure_message)

    return self:doDirectionalFunc(dir, { amount }, up, down, f, do_correct, do_turn, do_commands_anyways)
end

-- Dig() funcs
function TurtlePlus:digUp(tool_side, retry_sec)
    return self:dig(MoveDirection.UP, tool_side, false, false, retry_sec)
end

function TurtlePlus:digDown(tool_side, retry_sec)
    return self:dig(MoveDirection.DOWN, tool_side, false, false, retry_sec)
end

function TurtlePlus:digLeft(tool_side, do_correct, do_turn, retry_sec)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    return self:dig(MoveDirection:left(self.current_direction), tool_side, do_correct, do_turn, retry_sec)
end

function TurtlePlus:digRight(tool_side, do_correct, do_turn, retry_sec)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    return self:dig(MoveDirection:right(self.current_direction), tool_side, do_correct, do_turn, retry_sec)
end

function TurtlePlus:dig(dir, tool_side, do_correct, do_turn, retry_sec, do_commands_anyways)
    dir = defaultNil(dir, self.current_direction)

    validateMoveDirection(dir)
    turtlePlusCheckListenToCommands(self, do_commands_anyways)

    dir = defaultNil(dir, MoveDirection.NORTH)
    do_correct = defaultNil(do_correct, true)
    do_turn = defaultNil(do_turn, true)
    retry_sec = defaultNil(retry_sec, 0)
    printDbg("dig(" .. tostring(dir) .. ", " .. tostring(tool_side) .. ", " .. tostring(do_correct) .. ", " .. tostring(do_turn) .. ", " .. tostring(retry_sec) .. ", " .. tostring(do_commands_anyways) .. ")")
    local function digCheckFunc(result, ...)
        return true -- todo use detect() to determine if the block in front was broken?
        --return result
    end

    local f = wrapFuncInWaitAndRetryFunc(turtle.dig, retry_sec, digCheckFunc, "Dig() returned false, retrying in " .. tostring(retry_sec))
    local up = wrapFuncInWaitAndRetryFunc(turtle.digUp, retry_sec, digCheckFunc, "DigUp() returned false, retrying in " .. tostring(retry_sec))
    local down = wrapFuncInWaitAndRetryFunc(turtle.digDown, retry_sec, digCheckFunc, "DigDown() returned false, retrying in " .. tostring(retry_sec))

    return self:doDirectionalFunc(dir, { tool_side }, up, down, f, do_correct, do_turn, do_commands_anyways)
end

-- Move() funcs
function TurtlePlus:forward(do_dig)
    return self:move(self.current_direction, false, nil, nil, do_dig)
end

function TurtlePlus:back(do_dig)
    return self:move(MoveDirection:opposite(self.current_direction), false, nil, nil, do_dig)
end

function TurtlePlus:up(do_dig)
    return self:move(MoveDirection.UP, false, nil, nil, do_dig)
end

function TurtlePlus:down(do_dig)
    return self:move(MoveDirection.DOWN, false, nil, nil, do_dig)
end

function TurtlePlus:right(do_dig, do_correct)
    do_correct = defaultNil(do_correct, true)
    return self:move(MoveDirection:right(self.current_direction), do_correct, nil, nil, do_dig)
end

function TurtlePlus:left(do_dig, do_correct)
    do_correct = defaultNil(do_correct, true)
    return self:move(MoveDirection:left(self.current_direction), do_correct, nil, nil, do_dig)
end

function TurtlePlus:moveNum(dir, num)
    return self:moveN(dir, false, nil, nil, num, nil)
end

function TurtlePlus:moveN(dir, do_correct, retry_sec, do_commands_anyways, num_moves, do_dig)
    local old_dir = self.current_direction
    do_correct = defaultNil(do_correct, true)
    num_moves = defaultNil(num_moves, 1)
    do_commands_anyways = defaultNil(do_commands_anyways, false)
    printDbg("moveN(" .. tostring(dir) .. ", " .. tostring(do_correct) .. ", " .. tostring(retry_sec) .. ", " .. tostring(do_commands_anyways) .. ", " .. tostring(num_moves) .. ", " .. tostring(do_dig) .. ")")

    if num_moves < 0 then
        num_moves = num_moves * -1
        dir = MoveDirection:opposite(dir)
        if do_dig then
            self:turn(dir, do_commands_anyways)
        end
    end

    for i = 1, num_moves, 1 do
        self:move(dir, false, retry_sec, do_commands_anyways, do_dig)
    end
    if do_correct then
	    self:turn(old_dir, do_commands_anyways)
    end
end

function wrapMoveFunc(turtle_plus, move_func, do_commands_anyways)
    function wrappedFunc()
        turtlePlusCheckListenToCommands(turtle_plus, do_commands_anyways)
        turtle_plus:checkFuel()
        return move_func()
    end
    return wrappedFunc
end

function TurtlePlus:move(dir, do_correct, retry_sec, do_commands_anyways, do_dig)
    do_dig = defaultNil(do_dig, false)
    self:checkFuel()
    do_commands_anyways = defaultNil(do_commands_anyways, false)
    turtlePlusCheckListenToCommands(self, do_commands_anyways)
    -- do_correct correct the turn, ie go back to the orientation you were before the movement
    validateMoveDirection(dir)
    do_correct = defaultNil(do_correct, true)
    retry_sec = defaultNil(retry_sec, 5)
    printDbg("move(" .. tostring(dir) .. ", " .. tostring(do_correct) .. ", " .. tostring(retry_sec) .. ", " .. tostring(do_commands_anyways) .. ", " .. tostring(do_dig))

    if dir == MoveDirection.UP then
        if do_dig then
            self:dig(MoveDirection.UP, nil, nil, nil, 0, do_commands_anyways)
        end

        waitAndRetry(wrapMoveFunc(self, turtle.up, do_commands_anyways), 5, "Moving up failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        self.current_down = self.current_down - 1
        return
    elseif dir == MoveDirection.DOWN then
        if do_dig then
            self:dig(MoveDirection.DOWN, nil, nil, nil, 0, do_commands_anyways)
        end
        waitAndRetry(wrapMoveFunc(self, turtle.down, do_commands_anyways), 5, "Moving down failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
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

    --print("Shifted " .. strlist(shifted_order))
    --print(self.current_direction .. " -" .. shifted_idx .. "> " .. tostring(new_direction))
    --print("Dir " .. dir .. " newdir " .. new_direction)

    local function wrapCheckDigMove(tp, move_func, dig_direction, should_dig, ignore_cmd_flg)
        local function wrapped()
            local move_success, msg = move_func()
            printDbg("wrapCheckDigMove '" .. tostring(move_success) .. "' msg '" .. tostring(msg) .."'")
            if move_success then
                return true, nil
            end
            if should_dig then
                printDbg("Need to dig to move")
                tp:dig(dig_direction, nil, nil, nil, 0, ignore_cmd_flg)
            end
            printDbg("Going to retry movement")
            return wrapMoveFunc(tp, move_func, ignore_cmd_flg)()
        end
        return wrapped
    end

    if new_direction == MoveDirection.WEST then
        turtle.turnLeft()
        dig_move_func = wrapCheckDigMove(self, turtle.forward, self.current_direction, do_dig, do_commands_anyways)
        waitAndRetry(dig_move_func, retry_sec, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnRight()
        else
            self.current_direction = dir
        end

    elseif new_direction == MoveDirection.EAST then
        turtle.turnRight()
        dig_move_func = wrapCheckDigMove(self, turtle.forward, self.current_direction, do_dig, do_commands_anyways)
        waitAndRetry(dig_move_func, retry_sec, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
        if do_correct then
            turtle.turnLeft()
        else
            self.current_direction = dir
        end
    elseif new_direction == MoveDirection.NORTH then
        dig_move_func = wrapCheckDigMove(self, turtle.forward, self.current_direction, do_dig, do_commands_anyways)
        waitAndRetry(dig_move_func, retry_sec, "Moving forward failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
    elseif new_direction == MoveDirection.SOUTH then
        printDbg("Moving south")
        dig_move_func = wrapCheckDigMove(self, turtle.back, MoveDirection:opposite(self.current_direction), do_dig, do_commands_anyways)
        waitAndRetry(dig_move_func, retry_sec, "Moving back failed! Waiting 5 seconds and retrying.. (press 'h' to go home and terminate)")
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

function TurtlePlus:goForceGoHomeAndTerminate()
    self:goHomeAndTerminate(true, true)
end

function TurtlePlus:goHomeAndTerminate(do_dig, force_go_home)
    do_dig = defaultNil(do_dig, false)
    force_go_home = defaultNil(force_go_home, false)

    local ignore_cmd_flag = true

    if force_go_home then
	    self.force_going_home = true
	    ignore_cmd_flag = {}
	    ignore_cmd_flag["force"] = true
    end

    self.listen_to_commands = false
    print("Sending terminate..")
    os.sleep(2)
    print("Forcing go home")
    self:goHome(do_dig, ignore_cmd_flag)
    error("Turtle forcibly reset by user")
end

function TurtlePlus:goHome(do_dig, do_commands_anyways)
    print("Going home")
    do_dig = defaultNil(do_dig, false)

    turtlePlusCheckListenToCommands(self, do_commands_anyways)

    printDbg("Going home UP")
    self:turn(MoveDirection.NORTH, do_commands_anyways)
    self:moveN(MoveDirection.UP, false, nil, do_commands_anyways, self.current_down, do_dig)

    printDbg("Going home LEFT")
    self:turnRelative(RelativeTurnDirection.LEFT, do_commands_anyways)
    self:moveN(self.current_direction, false, nil, do_commands_anyways, self.current_right, do_dig)

    printDbg("Going home RIGHT")
    self:turnRelative(RelativeTurnDirection.RIGHT, do_commands_anyways)
    self:moveN(MoveDirection.SOUTH, false, nil, do_commands_anyways, self.current_forward, do_dig)

    self.current_forward = 0
    self.current_right = 0
    self.current_down = 0

    printDbg("Resetting orientation")
    self:turn(MoveDirection.NORTH, do_commands_anyways)
end

function TurtlePlus:goTo(forward, right, down, do_correct, do_dig, do_commands_anyways)
    do_dig = defaultNil(do_dig, false)
    do_commands_anyways = defaultNil(do_commands_anyways, false)
    turtlePlusCheckListenToCommands(self, do_commands_anyways)
    local old_dir = self.current_direction

    self:moveN(MoveDirection.NORTH, false, nil, do_commands_anyways, forward - self.current_forward, do_dig)
    self:moveN(MoveDirection.EAST, false, nil, do_commands_anyways, right - self.current_right, do_dig)
    self:moveN(MoveDirection.DOWN, false, nil, do_commands_anyways, down - self.current_down, do_dig)

    if do_correct then
        self:turn(old_dir, do_commands_anyways)
    end
end

function TurtlePlus:dropOffInventoryAtHome(do_dig)
    dir = self.home_drop_direction

    turtlePlusCheckListenToCommands(self)
    local f = self.current_forward
    local r = self.current_right
    local d = self.current_down
    cur_dir = self.current_direction
    self:goHome(do_dig)
    self:dropEntireInventory(dir, 5)
    self:goTo(f, r, d, nil, do_dig)
    self:turn(cur_dir)
end

function TurtlePlus:totalBlocksInInventory(specific_blocks)
    if specific_blocks == nil then
        return 0
    end
    local inv_count = self:countEntireInventory(specific_blocks)
    local total = 0
    for i = 1, table.getn(specific_blocks), 1 do
        total = total + inv_count[specific_blocks[i]]
    end
    return total
end

function TurtlePlus:getSlotDetails(slot)
    slot = defaultNil(slot, turtle.getSelectedSlot())
    local data = turtle.getItemDetail(slot)
    if data ~= nil then
        return data
    else
        return { name = "none", count = 0 }
    end
end

function TurtlePlus:countSlot(name, slot)
    return self:countSelectedSlot(name, slot)
end

function TurtlePlus:countSelectedSlot(name, slot)
    slot = defaultNil(slot, turtle.getSelectedSlot())

    local data = turtle.getItemDetail(slot)
    if data == nil then
        return 0
    end
    if name ~= nil then
        if data.name == name then
            return data.count
        else
            return 0
        end
    end
    return data.count
end

function TurtlePlus:selectNext(specific_blocks, start_from)

    if specific_blocks == nil then
        error("Cannot selectNext(nil)!")
    end

    local selected = turtle.getSelectedSlot()
    if selected >= INVENTORY_SIZE then
        selected = 1 -- loop back around
    end
    start_from = defaultNil(start_from, selected)

    for i = start_from, INVENTORY_SIZE, 1 do
        for j = 1, table.getn(specific_blocks), 1 do
            local count = 0
            if specific_blocks ~= nil then
                count = self:countSlot(specific_blocks[j], i)
            else
                count = self:countSlot(nil, i)
            end
            if count > 0 then
                turtle.select(i)
                return true
            end
        end
    end
    return false
end

function TurtlePlus:getNonEmptySlots()
    local slots = {}
    local count = 1

    for i=1,INVENTORY_SIZE,1 do
        local info = self:getSlotDetails(i)
        if info.count ~= 0 then
            slots[count] = i
            count = count + 1
        end
    end
    return slots
end

function TurtlePlus:isInventoryFull()
    local slots = self:getEmptySlots()
    if #slots == 0 then
        return true
    else
        return false
    end
end

function TurtlePlus:isInventoryEmpty()
    local slots = self:getNonEmptySlots()
    if #slots == 0 then -- if the number of 'non empty slots' (slots filled) is 0, inventory is empty
        return true
    else
        return false
    end
end

function TurtlePlus:getEmptySlots()
    local slots = {}
    local count = 1

    for i=1,INVENTORY_SIZE,1 do
        local info = self:getSlotDetails(i)
        if info.count == 0 then
            slots[count] = i
            count = count + 1
        end
    end
    return slots
end

function TurtlePlus:hasEmptySlot()
    for i=1,INVENTORY_SIZE,1 do
        if self:getSlotDetails(i).name == "none" then
            return true
        end
    end
    return false
end

function TurtlePlus:countEntireInventory(specific_blocks)
    local total = 0
    local totals = {}

    for i = 1, INVENTORY_SIZE, 1 do
        total = total + turtle.getItemCount(i)
        if specific_blocks ~= nil then
            for j = 1, table.getn(specific_blocks), 1 do
                local key = specific_blocks[j]
                if totals[key] == nil then
                    totals[key] = self:countSelectedSlot(key, i)
                else
                    totals[key] = totals[key] + self:countSelectedSlot(key, i)
                end
            end
        end
    end
    totals["total"] = total
    return totals
end

function TurtlePlus:numMovesFromHome()
    return self.current_right + self.current_forward + self.current_down
end

function TurtlePlus:finish()
    self:turn(MoveDirection.NORTH)
    self.keep_running = false
end

-- Misc building funcs

function TurtlePlus:cube(func, height, width, length, go_down, do_dig)
    do_dig = defaultNil(do_dig, true)
    local plane_turn_dir = RelativeTurnDirection.RIGHT
    for i = 0, height-1, 1 do
        self:plane(func, width, length, do_dig, plane_turn_dir)
        func(self)
        if go_down then
            self:down(do_dig)
        else
            self:up(do_dig)
        end
        if width % 2 == 0 then -- need to tell plane to turn the other way if we have an even width
            plane_turn_dir = RelativeTurnDirection:opposite(plane_turn_dir)
        end

        self:turn(MoveDirection:opposite(self.current_direction))
    end
end

function TurtlePlus:line(func, length, do_dig)
    do_dig = defaultNil(do_dig, true)
    for i = 1, length - 1, 1 do
        func(self)
        self:forward(do_dig)
    end
end

function TurtlePlus:plane(func, width, length, do_dig, start_turn_direction)
    do_dig = defaultNil(do_dig, true)
    local turn_direction = defaultNil(start_turn_direction, RelativeTurnDirection.RIGHT)

    for i = 1, width, 1 do
        self:line(func, length, do_dig)
        if i ~= width then
            self:turnRelative(turn_direction)
            func(self)
            self:forward(do_dig)
            self:turnRelative(turn_direction)
            turn_direction = RelativeTurnDirection:opposite(turn_direction)
        else
            return
        end
    end
    func(self) -- last block
end


-- Helper func to run turtle plus with a coroutine, not needed though
function runTurtlePlus(main_func, turtle_plus)
    print("Starting turtle..")
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
    print("All routines finished, stopping")
end
