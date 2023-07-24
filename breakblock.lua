require("./libs/turtleplus")


function main(tp)
    while true do
        tp:digDown()
        tp:suckDown()
        tp:drop()
    end
end

runTurtlePlus(main)
