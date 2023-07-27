require("./libs/turtleplus")


function main(tp)
    while true do
        tp:digDown()
        tp:suckDown()
        tp:drop(nil, nil, nil, nil, 2)
    end
end

runTurtlePlus(main)
