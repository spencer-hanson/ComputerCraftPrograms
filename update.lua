args = { ... }
if args == nil then
    arglen = 0
else
    arglen = table.getn(args)
end

SERVER_ID = 3
SERVER_MODEM_SIDE = "top"
DISK_DIRECTORY_NAME = "disk"
CLIENT_MODEM_SIDE = "left"
DONE_STR = "##done##"
UPDATE_STR = "update"

function sendFiles(sender_id)
    local files = fs.list(DISK_DIRECTORY_NAME)
    os.sleep(1)
    for i = 1, table.getn(files), 1 do
        rednet.send(sender_id, files[i])
        local filepointer = fs.open(DISK_DIRECTORY_NAME .. "/" .. files[i], "r")
        local filedata = filepointer.readAll()
        rednet.send(sender_id, filedata)
        filepointer.close()
    end
    rednet.send(sender_id, DONE_STR)
end

function waitUpdate()
    rednet.open(SERVER_MODEM_SIDE)
    while true do
        print("Waiting for update request")
        local sender_id, data, protocol = rednet.receive()
        if data == UPDATE_STR then
            print("Received update request from computer " .. sender_id .. " sending update..")
            sendFiles(sender_id)
            print("Done!")
        else
            print("Unknown data '" .. data .. "' from '" .. sender_id .. "' protocol '" .. tostring(protocol) .. "'")
        end
    end
end

function updateClient()
    rednet.open(CLIENT_MODEM_SIDE)
    rednet.send(SERVER_ID, UPDATE_STR)
    while true do
        local id, fnname, proto = rednet.receive()
        if fnname == DONE_STR then
            rednet.close(CLIENT_MODEM_SIDE)
            print("Update complete")
            return
        end

        print("Updating '" .. tostring(fnname) .. "'")
        if fs.exists(fnname) then
            fs.delete(fnname)
        end
        local fp = fs.open(fnname, "w")
        local id, content, proto = rednet.receive()

        fp.write(content)
        fp.flush()
        fp.close()
    end
end

-- Main

if arglen == 1 and args[1] == "--server" then
    print("Starting Server..")
    waitUpdate()
elseif arglen == 0 then
    print("Starting Client..")
    updateClient()
else
    error("Invalid args, usage: 'update --server' or 'update'")
end
