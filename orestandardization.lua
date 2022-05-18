print("Starting standardization..")
while true do
    local success, reason = turtle.suck()
    if not success then
        print("Suck() failed '" .. reason .. "' retrying in 3")
        os.sleep(3)
    else
        local csuccess, creason = turtle.craft()
        if not csuccess then
            print("Craft() failed '" .. creason .. "' passing ore along")
        end
        local item_details = turtle.getItemDetail()
        print("Crafted '" .. (item_details.name or "unknown") .. "' " .. (tostring(item_details.count) or "unknown") .. "x")

        while true do
            local dsuccess, dreason = turtle.dropDown()
            if not dsuccess then
                print("DropDown() failed '" .. dreason .. "' retrying 5")
                os.sleep(5)
            else
                break
            end
        end
    end
end
