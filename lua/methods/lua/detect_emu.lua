-----------------------------------------------------------------------------
-- Emulator + Game Detection (DeSmuME‑only, English‑only)
-- Authors: wyanido, storyzealot, FalinMor_
-----------------------------------------------------------------------------

local SUPPORTED_GAMES = {
    D  = { gen = 4 },
    P  = { gen = 4 },
    PL = { gen = 4 },
    HG = { gen = 4 },
    SS = { gen = 4 },
    B  = { gen = 5 },
    W  = { gen = 5 },
    B2 = { gen = 5 },
    W2 = { gen = 5 }
}

if bizstring ~= nil then
    error("\nUnsupported Emulator Detected.\n\n" ..
          "BizHawk is no longer supported.\n" ..
          "Please run this bot on **DeSmuME 0.9.11+**.\n")
end

_EMU = "DeSmuME"

mbyte  = memory.readbyte
mword  = memory.readwordunsigned
mdword = memory.readdwordunsigned

if not emu.emulating() then
    error("Please load a ROM before enabling the script!")
end

function print_debug(message)
    if config.debug then
        print("- " .. message)
    end
end

function print_warn(message)
    print("# " .. message .. " #")
end

function soft_reset()
    emu.reset()
    randomise_reset()
end

function hard_reset()
    print_debug("Performing pseudo-hard reset...")
    wait_frames(3)
    save_game()
    soft_reset()
    wait_frames(60)
end

-----------------------------------------------------------------------------
-- Lua 5.1 Compatibility
-----------------------------------------------------------------------------

require("lua\\compatability\\utf8")
require("lua\\compatability\\table")

-----------------------------------------------------------------------------
-- ROM + Language Detection
-----------------------------------------------------------------------------

local function get_game_code()
    local addr = 0x23FFE08
    local b1 = mbyte(addr)
    local b2 = mbyte(addr + 1)

    if b2 == 0 then
        return utf8.char(b1)
    else
        return utf8.char(b1, b2)
    end
end

local function get_language_code()
    local lang = mbyte(0x023FFE0F)

    -- Gen 4 EN = 0x45, Gen 5 EN = 0x4F
    if lang == 0x45 or lang == 0x4F then
        return "EN"
    end

    return nil
end

function identify_game()
    local game = get_game_code()
    local lang = get_language_code()

    if not game or not SUPPORTED_GAMES[game] then
        error("\nUnsupported ROM detected.\n\n" ..
              "Game code: " .. tostring(game) .. "\n" ..
              "This bot only supports English versions of:\n" ..
              "D, P, PL, HG, SS, B, W, B2, W2\n")
    end

    if not lang then
        error("\nUnsupported language detected.\n\n" ..
              "Currently only supports English ROMs.\n" ..
              "Please load an English version of the game.\n")
    end

    print("Detected Game: " .. game .. " (EN)")

    local rom = SUPPORTED_GAMES[game]
    rom.version = game
    rom.offset = 0 

    return rom
end

_ROM = identify_game()

-----------------------------------------------------------------------------
-- BOT MODES INITIALISATION
-----------------------------------------------------------------------------
dofile("lua\\methods\\global.lua")

if _ROM.gen == 4 then
    dofile("lua\\methods\\gen_iv.lua")
    _MON_BYTE_LENGTH = 236 -- Gen 4 has 16 extra trailing bytes of ball seals data
    
    if _ROM.version == "HG" or _ROM.version == "SS" then
        dofile("lua\\data\\maps\\hgss.lua")
        dofile("lua\\methods\\hgss.lua")
    else
        dofile("lua\\data\\maps\\gen_iv.lua")
        
        if _ROM.version == "PL" then
            dofile("lua\\methods\\pt.lua")
        end
    end
else
    dofile("lua\\methods\\gen_v.lua")
    dofile("lua\\data\\maps\\gen_v.lua")
    _MON_BYTE_LENGTH = 220

    if _ROM.version == "B2" or _ROM.version == "W2" then
        dofile("lua\\methods\\b2w2.lua")
    end
end