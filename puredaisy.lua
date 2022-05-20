require("turtleplus")
INPUT_CHEST = "up"
OUTPUT_CHEST = "south"

function doMove(t, dir)
    t:move(dir, false)
end

function roundFunc(func, t)
    func()
    doMove(t, "north")
    func()
    doMove(t, "north")
    func()
    doMove(t, "west")
    func()
    doMove(t, "west")
    func()
    doMove(t, "south")
    func()
    doMove(t, "south")
    func()
    doMove(t, "east")
    func()
    doMove(t, "east")
    func()
end

function main(t)
    while true do
        local amt, s = t:suck(INPUT_CHEST, 8, true, true, 5)
        print("amt " .. tostring(amt) .. " " .. tostring(s))
        roundFunc(turtle.placeDown, t)
        os.sleep(60)
        roundFunc(turtle.digDown, t)
        t:drop(OUTPUT_CHEST)
    end
end

runTurtlePlus(nil, main)
