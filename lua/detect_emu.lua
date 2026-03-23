-----------------------------------------------------------------------------
-- Emulator detection and setup (DeSmuME-only)
-----------------------------------------------------------------------------

function print_debug(message)
    if config.debug then
        print("- " .. message)
    end
end

function print_warn(message)
    print("# " .. message .. " #")
end

-- Always DeSmuME now
_EMU = "DeSmuME"

-- Memory readers
mbyte  = memory.readbyte
mword  = memory.readwordunsigned
mdword = memory.readdwordunsigned

-- Check ROM loaded
local game_is_loaded = emu.emulating()
if not game_is_loaded then
    error("Please load a ROM before enabling the script!")
end

-- Soft reset (DeSmuME)
function soft_reset()
    emu.reset()
    randomise_reset()
end

-- Universal pseudo-hard reset
function hard_reset()
    print("Performing pseudo-hard reset...")
    wait_frames(math.random(300, 800))
    soft_reset()
    wait_frames(60)
end

-- Lua 5.1 compatibility
require("lua\\compatability\\utf8")
require("lua\\compatability\\table")
