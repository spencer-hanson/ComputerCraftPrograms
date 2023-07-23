require("libs/movement")
require("libs/turtleplus")
-- Turtle to manage songs on a disk drive player
-- starts by playing all songs in chest 1 then repeats from chest 2else

CHEST_1_LOCATION = MoveDirection.NORTH
CHEST_2_LOCATION = MoveDirection.SOUTH
DISC_DRIVE_LOCATION = MoveDirection.WEST

SONG_SLEEP_TIME = 200 -- todo update for specific songs?

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

function musicClient(t)
    local drive_mapping = {
        north= "front",
        south= "back",
        east= "right",
        west= "left"
    }

    while true do
        local has_item = t:suck(CHEST_1_LOCATION)
        if has_item then
            local put_disk = t:drop(DISC_DRIVE_LOCATION, 1, false, true, 0)
            --print("put_disk " .. tostring(put_disk))

            local disk_name = nil
            if disk_name == nil then
                disk_name = findDiskName()
            end

            if disk_name ~= nil then
                local last_dir = t.current_direction
                t:turn(MoveDirection.NORTH)
                disk.playAudio(drive_mapping[DISC_DRIVE_LOCATION])
                --print("Playing '" .. disk.getAudioTitle(disk_name) .. "'")
                os.sleep(SONG_SLEEP_TIME)
                t:turn(last_dir)
            end

            t:suck(DISC_DRIVE_LOCATION)
            t:drop(CHEST_2_LOCATION, 1, false, true, 0)
        else
            local tmp = CHEST_1_LOCATION
            CHEST_1_LOCATION = CHEST_2_LOCATION
            CHEST_2_LOCATION = tmp
        end
    end
end

print("Starting Music DJ..")
runTurtlePlus(musicClient)
