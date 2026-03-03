-----------------------------------------------------------------------------
-- Main Pokebot NDS script
-- Author: wyanido
-- Homepage: https://github.com/wyanido/pokebot-nds
--
-- Responsible for loading the files appropriate to the current state,
-- including emulator, game, language, and configuration.
-----------------------------------------------------------------------------

package.cpath = package.cpath .. ";.\\lua\\modules\\?.dll"
dofile("lua\\detect_emu.lua")

print("PokeBot NDS v1.2c by wyanido, Zyrne")
print("https://github.com/wyanido/pokebot-nds")
print("Running " .. _VERSION .. " on " .. _EMU)
print("")

-- Clear values that might linger after restarting the script
game_state = nil
config = nil
foe = nil
party = {}

-- Load core data and modules
dofile("lua\\data\\misc.lua")
pokemon = require("lua\\modules\\pokemon")
dofile("lua\\modules\\input.lua")
dofile("lua\\detect_game.lua")
dofile("lua\\modules\\dashboard.lua")
dofile("lua\\helpers.lua")

-----------------------------------------------------------------------------
-- MODE LOADING
-----------------------------------------------------------------------------
-- config.mode is set by detect_game.lua based on config.json
-- Example values: "manual", "static", "gift", "fishing", etc.

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
    -- Apply inputs accumulated this frame
    joypad.set(input)

    -- Update game state (battle flags, overworld state, etc.)
    process_frame()

    -- Clear inputs that were not held
    clear_unheld_inputs()

    -- Run the selected mode
    mode_function()
end
