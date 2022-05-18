require("movement")
require("turtleplus")

CHEST_1_LOCATION = MoveDirection.NORTH
CHEST_2_LOCATION = MoveDirection.SOUTH
DISC_DRIVE_LOCATION = MoveDirection.WEST
SONG_SLEEP_TIME = 200

args = {...}
if args == nil then
    arglen = 0
else
    arglen = table.getn(args)
end

function findDiskName()
    for _, name in ipairs(peripheral.getNames()) do
        if disk.isPresent(name) and disk.hasAudio(name) then
            return name
        end
    end
end

function musicServer()
    local current_timer = SONG_SLEEP_TIME
    local disk_name = nil
    while true do
        if disk_name == nil then
            disk_name = findDiskName()
        end

        if disk_name ~= nil and current_timer >= SONG_SLEEP_TIME then
            disk.playAudio(disk_name)
            print("Playing '" .. disk.getAudioTitle(disk_name) .. "'")
            current_timer = 0
            playing_disk = true
            os.sleep(1)
        elseif not disk.isPresent(disk_name or "none") then
            print("No disc, waiting..")
            current_timer = SONG_SLEEP_TIME
            disk_name = nil
            os.sleep(1)
        elseif current_timer < SONG_SLEEP_TIME then
            current_timer = current_timer + 1
            os.sleep(1)
        end
        os.sleep(1)
    end
end

function musicClient(t)
    while true do
        local has_item = t:suck(CHEST_1_LOCATION)
        if has_item then
            local put_disk = t:drop(DISC_DRIVE_LOCATION, 1, false, true, 0)
            print("put_disk " .. tostring(put_disk))
            os.sleep(SONG_SLEEP_TIME)
            t:suck(DISC_DRIVE_LOCATION)
            t:drop(CHEST_2_LOCATION, 1, false, true, 0)
        else
            print("No items left in chest TODO")
            local tmp = CHEST_1_LOCATION
            CHEST_1_LOCATION = CHEST_2_LOCATION
            CHEST_2_LOCATION = tmp
        end

    end
end

if arglen == 1 and args[1] == "--server" then
    print("Starting Music Disk Server..")
    musicServer()
elseif arglen == 0 then
    print("Starting Music Client..")
    runTurtlePlus(nil, musicClient)
else
    error("Invalid args, usage: 'discjockey --server' or 'discjockey'")
end
