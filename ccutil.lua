function debugM(msg)
    if DEBUG_TURTLE then
        print(msg)
    end
end

function errorTrace(message)
    for i = 1, 4, 1 do
        local info = debug.getinfo(i)
        if info == nil then
            print("no line")
        else
            local info_name = tostring(info.name)
            if info == nil or info_name == nil or info_name == "pcall" or info_name == "nil" then
                break
            else
                print("at " .. tostring(info_name) .. ": " .. tostring(info.linedefined))
            end
        end
    end

    error(message)
end

function wrapFuncInWaitAndRetryFunc(func, sleep_time, check_func, message)
    if check_func == nil then
        errorTrace("asdf")
    end

    local function wrappedFunc(...)
        return waitAndRetryFunc(func, sleep_time, check_func, message, unpack(arg))
    end
    return wrappedFunc
end

function waitAndRetryFunc(func, sleep_time, check_func, message, ...)
    -- ... is arg for func
    while true do
        local func_arglen = table.getn(arg)
        local val = nil

        if func_arglen > 0 then
            debugM("calling func with args '" .. strlist(arg) .. "'")
            val = { func(unpack(arg)) }
        else
            val = { func() }
        end

        debugM("Func returned " .. strlist(val))
        local check_func_result = check_func(unpack(val))
        debugM("Check func result " .. tostring(check_func_result))

        if check_func_result then
            return val
        else
            print(message)
            os.sleep(sleep_time)
        end
    end
end

function waitAndRetry(func, sleep_time, message, ...)
    local function defaultCheckFunc(v)
        if v or sleep_time == 0 then
            return true
        else
            return false
        end
    end
    return waitAndRetryFunc(func, sleep_time, defaultCheckFunc, message, unpack(arg))
end

function strlist(l)
    if l == nil then
        return "nil"
    end

    local s = ""
    for i = 1, table.getn(l), 1 do
        if l[i] == nil then
            errorTrace("Error stringifying a table")
        end
        s = s .. "," .. tostring(l[i])
    end
    return s
end
