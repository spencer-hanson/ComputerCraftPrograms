print("Starting standardization..")
print("Dropping inventory..")
for i=1,16,1 do
    while true do
        turtle.select(i)
        local suc, str = turtle.drop()
        if not suc and str == "No space for items" then
            print("Can't drop into input inventory '" .. str .. "', please fix!")
            os.sleep(2)
        else
            break
        end
    end
end

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
            inv_count = 0
            for i=1,16,1 do
                turtle.select(i)
                turtle.dropDown()
                inv_count = inv_count + turtle.getItemCount(i)
            end
            if inv_count ~= 0 then
                print("Inventory still full, retrying..")
                os.sleep(5)
            else
                break
            end
        end
    end
end
