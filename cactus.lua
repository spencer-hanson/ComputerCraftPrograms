while true do
    print("Waiting..")
    if turtle.detectDown() then
        print("Mining..")
        turtle.digDown()
    end
    os.sleep(5)
end