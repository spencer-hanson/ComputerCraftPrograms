FUNCTION_TIMEOUT = "thisIsFunctionTimeoutUniqueValue"
-- Used when a retry function's check function times out

function unpackM(table1)
    return unpack(table1, 1, table.maxn(table1))
end

function defaultNil(val, def)
    if val == nil then
        return def
    else
        return val
    end
end

function nothing()
end

function errorTrace(message)
    print("Printing error trace")
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
    printDbg("Start wrapRetryFunc")
    if check_func == nil then
        errorTrace("Check function passed into wrapFuncInWaitAndRetryFunc is nil")
    end

    local function wrappedFunc(...)
        printDbg("Starting a waitAndRetryFunc in wrapped func")
        return waitAndRetryFunc(func, sleep_time, check_func, message, unpackM(arg))
    end
    return wrappedFunc
end

function contains(value, list)
    for i=1,table.getn(list),1 do
        if value == list[i] then
            return i
        end
    end
    return false
end

function waitAndRetryFuncTimeout(func, sleep_time, check_func, message, timeout_func, ...)
    -- ... are the args for func
    -- Retry a function 'func' until the check_func(func()) returns not nil
    -- print message each failure
    timeout_func = defaultNil(timeout_func, nothing)
    printDbg("Starting a retryfunc")
    while true do
        local func_arglen = table.getn(arg)
        local val = nil
        printDbg("Calling Func")
        if func_arglen > 0 then
            val = { func(unpackM(arg)) }
        else
            val = { func() }
        end

        printDbg("RetryFunc returned '" .. strlist(val) .."'")

        local check_func_result = check_func(unpackM(val))
        printDbg("RetryFunc check result " .. tostring(check_func_result))

        if check_func_result == FUNCTION_TIMEOUT then
	        printDbg("RetryFunc timed out")
	        return timeout_func()
        end
        if check_func_result then
            printDbg("RetryFunc success")
            return val
        else
            printDbg("RetryFunc sleeping")
            print(message)
            os.sleep(sleep_time)
        end
    end
end

function waitAndRetryFunc(func, sleep_time, check_func, message, ...)
    local function timeout_func()
        print("Function returned a timeout but none was handled!")
        return nil
    end
    printDbg("Starting a waitAndRetryFunc")
    return waitAndRetryFuncTimeout(func, sleep_time, check_func, message, timeout_func, unpackM(arg))
end

function waitAndRetry(func, sleep_time, message, ...)
    local function defaultCheckFunc(v, ...)
        if v or sleep_time == 0 then
            printDbg("WaitAndRetry check true")
            return true
        else
            printDbg("WaitAndRetry check false")
            return false
        end
    end
    printDbg("Starting a waitAndRetry")
    return waitAndRetryFunc(func, sleep_time, defaultCheckFunc, message, unpackM(arg))
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
