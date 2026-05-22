-----------------------------------------------------------------------------
-- Main Pokebot NDS script
-- Authors: wyanido, FalinMor_
-- Homepage: https://github.com/Falin-Mor/pokebot-nds
--
-- Responsible for loading the files appropriate to the current state,
-- including emulator, game, language, and configuration.
-----------------------------------------------------------------------------

package.cpath = package.cpath .. ";.\\lua\\modules\\?.dll"
dofile("lua\\detect_emu.lua")

print("PokeBot NDS v1.2c by wyanido, FalinMor_")
print("https://github.com/Falin-Mor/pokebot-nds")
print("Running " .. _VERSION .. " on " .. _EMU)
print("This is a Work-In-Progress and may have issues.")
print("Feel free to join the discord! https://discord.gg/g52tXE7Hyc")
print("")

game_state = nil
config = nil
foe = nil
party = {}

dofile("lua\\data\\misc.lua")
pokemon = require("lua\\modules\\pokemon")
dofile("lua\\modules\\input.lua")
dofile("lua\\modules\\dashboard.lua")
dofile("lua\\helpers.lua")

-----------------------------------------------------------------------------
-- MODE LOADING
-----------------------------------------------------------------------------
local mode_function = _G["mode_" .. config.mode]

if not mode_function then
    abort("Function for mode '" .. config.mode .. "' does not exist. It may not be compatible with this game.")
end

print("---------------------------")
print("Bot mode set to " .. config.mode)

-----------------------------------------------------------------------------
-- MAIN LOOP
-----------------------------------------------------------------------------
while true do
    joypad.set(input)
    process_frame()
    clear_unheld_inputs()
    mode_function()
end
