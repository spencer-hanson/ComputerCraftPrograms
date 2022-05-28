args = { ... }
if args == nil then
    arglen = 0
end

if arglen == 0 then
    --turtle.turnRight()
    print("arglen 0")
else
    print(tostring(args[1]))
end