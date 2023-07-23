-- -------------------------
-- USAGE AND EXAMPLES
-- -------------------------
-- This script is for a one-way sync of files between a server and client
-- Server usage: 'update --server <server root directory>
-- Client usage: 'update <server computer id>
--
-- To use this script, you need 2 computers with attached modems
-- Computer 1, which we will call the 'server' we have a directory of scripts we would like to
-- copy over to computer 2, called the 'client'
--
-- On the server we run 'update --server myfolder/' where 'myfolder' is the folder of files
-- (Note: If you use a floppy and it's mounted on 'disk/' then use that)
-- The server will start, and give you a computer Invalid
--
-- On the client computer run 'update <server id>' where <server id> is the id of the server computer
-- for example, if on the server you run the lua line 'os.getComputerID()' and get 2
-- then on your client run 'update 2' to connect to that computer and update


-- ---------
-- Constants
-- ---------
-- Note that if any of these strings match any content in a file being transferred, things will break
DONE_STR = "##done##"  -- Sent at the end of a file's data
READY_STR = "##ready##" -- Sent to the client to specify the server is ready to send data
UPDATE_STR = "##update##" -- Sent to the server to ask for an update

-- -----------
-- Server Code
-- -----------

function serverWaitForRequest(root_dir)
    peripheral.find("modem", rednet.open)
    while true do
        print("Server waiting for update request..")
        local sender_id, data, protocol = rednet.receive()
        if data == UPDATE_STR then
            print("Received update request from computer " .. sender_id .. " sending ack and update..")
            rednet.send(sender_id, READY_STR)
            sendFiles(sender_id, root_dir)
            print("Done!")
        else
            print("Unknown data '" .. tostring(data) .. "' from '" .. sender_id .. "' protocol '" .. tostring(protocol) .. "'")
        end
    end
end

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

function sendFiles(sender_id, root_dir)
    local files = fs.list(root_dir)
    os.sleep(1)
    for i = 1, table.getn(files), 1 do
        sendData(sender_id, files[i], root_dir .. "/" .. files[i])
    end
    rednet.send(sender_id, DONE_STR)
end

-- ------------
-- Client Code
-- ------------
function updateClient(server_id)
    peripheral.find("modem", rednet.open)
    print("Attempting to connect to server..")
    rednet.send(server_id, UPDATE_STR)
    -- TODO check if messages are coming from update server?
    local id, data, proto = rednet.receive(nil, 5)
    if data == nil then
        print("Timed out contacting server! Shutting down..")
        return
    else
        if data == READY_STR then
            clientReady()
        else
            print("Got unexpected response '" .. data .. "' Shutting down..")
            return
        end
    end

end

function clientReady()
    print("Starting to receive data")
    while true do
        id, data, proto = rednet.receive(nil, 5)
        if data == nil then
            print("Error receiving data, timed out! Shutting down..")
            return
        elseif data == DONE_STR then
            rednet.close()
            print("Update complete")
            return
        end

        print("Updating '" .. tostring(data) .. "'")
        if fs.exists(data) then
            if fs.isReadOnly(data) then
                print("Server requested an update of a read-only entry '" ..data.."' on client! Delete the entry clientside or reconfigure server root!")
                error("read-only cannot be modified")
            end
            fs.delete(data)
        end
        local fp = fs.open(data, "w")
        id, data, proto = rednet.receive()

        fp.write(data)
        fp.flush()
        fp.close()
    end
end
-- ----
-- Main
-- ----

args = { ... }
if args == nil then
    arglen = 0
else
    arglen = table.getn(args)
end


if peripheral.find("modem") == nil then
    error("To run update, we need a modem to communicate with other computers!")
end

if arglen == 2 and args[1] == "--server" then
    root_dir = args[2]
    if fs.exists(root_dir) then
        print("Starting Update Server on Computer " .. os.getComputerID())
        print("Root directory " .. root_dir)
        serverWaitForRequest(root_dir)
    else
       print("Could not find root directory '" .. root_dir .."' Shutting down...")
    end
elseif arglen == 1 then
    if args[1] == "--server" then
        print("Invalid syntax for server!")
        error("invalid args")
    end
    server_id = tonumber(args[1])
    print("Starting update client, attempting to contact server id " .. server_id)
    if server_id == nil then
        print("Cannot start client")
        print("Server ID '" .. server_id .. "'   is not a valid value!")
    else
        updateClient(server_id)
    end
else
    print("\n Invalid args given, usage: 'update --server <absolute root directory>' or 'update <update server id>' \n")
    error("Incorrect run syntax")
end
print("Exited")
