args = { ... }
if args == nil then
    arglen = 0
else
    arglen = table.getn(args)
end

SERVER_ID = 3

if peripheral.find("modem") == nil then
    error("No modem found! Cannot update!")
end
DISK_DIRECTORY_NAME = "disk"
DONE_STR = "##done##"
UPDATE_STR = "update"

function sendFile(sender_id, remote_path, local_path)
    rednet.send(sender_id, remote_path)
    local filepointer = fs.open(local_path, "r")
    local filedata = filepointer.readAll()
    rednet.send(sender_id, filedata)
    filepointer.close()
end

function sendData(sender_id, remote_path, local_path)
    local attrs = fs.attributes(local_path)
    if attrs.isDir == false then
        sendFile(sender_id, remote_path, local_path)
    else
        local files = fs.list(local_path)
        for i = 1, table.getn(files), 1 do
            local local_file_path = local_path .. "/" .. files[i]
            local remote_file_path = remote_path .. "/" .. files[i]

            if attrs.isDir then
                sendData(sender_id, remote_file_path, local_file_path)
            else
                sendFile(sender_id, remote_file_path, local_file_path)
            end
        end
    end
end

function sendFiles(sender_id)
    local files = fs.list(DISK_DIRECTORY_NAME)
    os.sleep(1)
    for i = 1, table.getn(files), 1 do
        sendData(sender_id, files[i], DISK_DIRECTORY_NAME .. "/" .. files[i])
    end
    rednet.send(sender_id, DONE_STR)
end

function waitUpdate()
    peripheral.find("modem", rednet.open)
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
    peripheral.find("modem", rednet.open)
    rednet.send(SERVER_ID, UPDATE_STR)
    while true do
        local id, fnname, proto = rednet.receive()
        if fnname == DONE_STR then
            rednet.close()
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
    print("Starting Update Server..")
    waitUpdate()
elseif arglen == 0 then
    print("Starting Update Client..")
    updateClient()
else
    error("Invalid args, usage: 'update --server' or 'update'")
end
