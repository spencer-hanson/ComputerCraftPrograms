-- Watch a block underneath and mine it, perfect for cactus collection

while true do
    print("Waiting..")
    if turtle.detectDown() then
        print("Mining..")
        turtle.digDown()
    end
    os.sleep(5)
end
