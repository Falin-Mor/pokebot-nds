-----------------------------------------------------------------------------
-- General bot methods for all games
-- Author: wyanido, storyzealot, Zyrne
-- Homepage: https://github.com/wyanido/pokebot-nds
-----------------------------------------------------------------------------
pointers = pointers or {}

---------------------------------------------------------
-- UNIVERSAL FISHING MODULE (Gen 4 + Gen 5)
---------------------------------------------------------

pointers.fishing = pointers.fishing or {}

-- Gen 4
pointers.fishing.D  = { fishing_exclamation_popup = 0x02291E57 }
pointers.fishing.P  = { fishing_exclamation_popup = 0x02291E1F }
pointers.fishing.PL = { fishing_exclamation_popup = 0x022A1AAF }

pointers.fishing.HG = { fishing_exclamation_popup = 0x021DEA33 }
pointers.fishing.SS = { fishing_exclamation_popup = 0x021DEA33 } 

-- Gen 5
pointers.fishing.B  = { fishing_exclamation_popup = 0x02259857 }
pointers.fishing.W  = { fishing_exclamation_popup = 0x02259877 }

pointers.fishing.B2 = { fishing_exclamation_popup = 0x0224738F }
pointers.fishing.W2 = { fishing_exclamation_popup = 0x022473CF }

---------------------------------------------------------
-- SAFE POINTER RESOLUTION
---------------------------------------------------------

local GAME = _ROM.version
local fish_ptr = pointers.fishing[GAME]

if not fish_ptr then
    fish_ptr = { fishing_exclamation_popup = 0x0211184C } -- fallback
    pointers.fishing[GAME] = fish_ptr
end

---------------------------------------------------------
-- COUNTERS
---------------------------------------------------------

bite_count = bite_count or 0
miss_count = miss_count or 0

local function print_bite_status()
    print("Bites: " .. bite_count .. " | Misses: " .. miss_count)
end

local function count_bite()
    bite_count = bite_count + 1
    print_bite_status()
end

local function count_miss()
    miss_count = miss_count + 1
    print_bite_status()
end

---------------------------------------------------------
-- RAW FLAG READ
---------------------------------------------------------

local function fishing_flag()
    return mbyte(fish_ptr.fishing_exclamation_popup)
end

---------------------------------------------------------
-- UNIVERSAL BITE DETECTOR
---------------------------------------------------------

local function fishing_bite_detected(v)

    -- SS: simple state, bite = 1
    if GAME == "SS" or GAME == "HG" then
        return v == 1
    end

    -- Black & White: bite = 2
    if GAME == "B" or GAME == "W" then
        return v == 2
    end

    -- Black 2 / White 2: bite = 2
    if GAME == "B2" or GAME == "W2" then
        return v == 2
    end

    -- Diamond / Pearl / Platinum: bite = 4
    if GAME == "D" or GAME == "P" or GAME == "PL" then
        return v == 4
    end

    return false
end

---------------------------------------------------------
-- MAIN FISHING MODE (FRAMEADVANCE DETECTOR)
---------------------------------------------------------

function mode_fishing()
    local TIMEOUT_FRAMES = 300

    if game_state.in_battle then
        process_wild_encounter()
        return
    end

    -- Cast rod
    press_button("Y")
    wait_frames(60)

    local frames = 0
    local bite = false

    -- High‑frequency detection loop
    while frames < TIMEOUT_FRAMES do
        local v = fishing_flag()

        if fishing_bite_detected(v) then
            press_button("A")
            bite = true
            break
        end

        frames = frames + 1
        emu.frameadvance()
    end

    if bite then
        local wait_frames_count = 0
        while not game_state.in_battle and wait_frames_count < 180 do
            progress_text()
            wait_frames_count = wait_frames_count + 1
        end

        if game_state.in_battle then
            count_bite()
            process_wild_encounter()
            wait_frames(90)
        else
            count_miss()
        end
    else
        print("Not even a nibble or got away...")
        count_miss()
        press_sequence(30, "A", 20)
    end
end

--- Returns the index of the first non-fainted Pokémon in the party
function get_lead_mon_index()
	update_party()

    for i = 1, 6 do
        local mon = party[i]
        if mon and mon.currentHP and mon.currentHP > 0 then
            return i
        end
    end

    return 1 -- fallback to slot 1
end

--- Finds and uses the best available options to safely weaken the foe
function subdue_pokemon()
    -- Ensure target has no recoil moves before attempting to weaken it
    local recoil_moves = {"Brave Bird", "Double-Edge", "Flare Blitz", "Head Charge", "Head Smash", "Self-Destruct",
                            "Take Down", "Volt Tackle", "Wild Charge", "Wood Hammer"}
    local recoil_slot = 0

    for _, v in ipairs(recoil_moves) do
        recoil_slot = pokemon.get_move_slot(foe[1], v)

        if recoil_slot ~= 0 then
            print_warn("The target has a recoil move. False Swipe won't be used.")
            break
        end
    end

    if recoil_slot == 0 then
        -- Check whether the lead actually has False Swipe
        local false_swipe_slot = pokemon.get_move_slot(party[get_lead_mon_index()], "False Swipe")

        if false_swipe_slot == 0 then
            print_warn("The lead Pokemon can't use False Swipe.")
        else
            use_move(false_swipe_slot)
        end
    end
    
    -- Status moves in order of usefulness
    local status_moves = {"Spore", "Sleep Powder", "Lovely Kiss", "Dark Void", "Hypnosis", "Sing", "Grass Whistle",
                            "Thunder Wave", "Glare", "Stun Spore"}
    local status_slot = 0

    for i = 1, #foe[1].type, 1 do
        if foe[1].type[i] == "Ground" then
            print_debug("Foe is Ground-type. Thunder Wave can't be used.")
            table.remove(status_moves, 8) -- Remove Thunder Wave from viable options if target is Ground type
            break
        end
    end

    -- Remove Grass type status moves if target has Sap Sipper
    if foe[1].ability == "Sap Sipper" then
        local grass_moves = {"Spore", "Sleep Powder", "Grass Whistle", "Stun Spore"}

        for i, k in ipairs(grass_moves) do
            for i2, k2 in pairs(status_moves) do
                if k == k2 then
                    table.remove(status_moves, i2)
                    break
                end
            end
        end
    end

    for _, v in ipairs(status_moves) do
        status_slot = pokemon.get_move_slot(party[get_lead_mon_index()], v)

        if status_slot ~= 0 then
            break
        end
    end

    if status_slot > 0 then
        -- Bot will blindly use the status move once and hope it lands
        use_move(status_slot)
    else
        print_warn("The lead Pokemon has no usable status moves.")
    end
end

function should_fight_foe()
    local annoying_moves = {
        "Disable", "Torment", "Imprison", "Encore", "Taunt", "Attract",
        "Protect", "Detect", "Substitute", "Confuse Ray", "Hypnosis",
        "Sleep Powder", "Spore", "Yawn", "Swagger", "Thunder Wave",
        "Will-O-Wisp", "Leech Seed", "Mean Look", "Block",
        "Destiny Bond", "Bide"
    }

	for _, move in ipairs(annoying_moves) do
		if pokemon.get_move_slot(foe[1], move) ~= 0 then
			
			if config.battle_non_targets then
				print_debug("Foe knows an annoying move: " .. move .. ". Running.")
			end
			
			return false
		end
	end

    return true
end

--- Continuously tries to catch the foe until the battle ends, or there are no valid Poke Balls left
function catch_pokemon()
    local function get_preferred_ball(balls)
		local priority = config.pokeball_priority
		if not priority or #priority == 0 then
			priority = { "Ultra Ball", "Great Ball", "Poke Ball" }
			print_debug("Poké Ball priority empty — falling back to default priority list")
		end
        -- Compare with override ruleset first
        if config.pokeball_override then
            for ball, _ in pairs(config.pokeball_override) do
                if pokemon.matches_ruleset(foe[1], config.pokeball_override[ball]) then
                    local index = balls[string.lower(ball)]

                    if index then
                        print_debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
                        return index
                    end
                end
            end
        end

        -- If no override rules were matched, default to priority
        if config.pokeball_priority then
            for _, ball in ipairs(config.pokeball_priority) do
                local index = balls[string.lower(ball)]

                if index then
                    print_debug("Bot will use " .. ball .. " from slot " .. ((index - 1) % 6) .. ", page " .. math.floor(index / 6))
                    return index
                end
            end
        end

        return -1
    end

	local COORDS = {
		[1] = {x = 60,  y = 35},
		[2] = {x = 180, y = 35},
		[3] = {x = 60,  y = 80},
		[4] = {x = 180, y = 80},
		[5] = {x = 60,  y = 130},
		[6] = {x = 180, y = 130},
	}

	local function get_button(index)
		local button = (index - 1) % 6 + 1

		-- Gen 5 uses 0-based slot indexing
		if GAME == "B" or GAME == "W" or GAME == "B2" or GAME == "W2" then
			button = button - 1
			if button == 0 then button = 6 end
		end

		return button
	end

	local function use_ball(index)
		local page = math.floor((index - 1) / 6)
		local current_page = mbyte(pointers.battle_bag_page)

		while current_page ~= page do
			if current_page < page then
				touch_screen_at(58, 180)
				current_page = current_page + 1
			else
				touch_screen_at(17, 180)
				current_page = current_page - 1
			end
			wait_frames(30)
		end

		local button = get_button(index)
		local x = COORDS[button].x
		local y = COORDS[button].y

		touch_screen_at(x, y)
		wait_frames(30)
		touch_screen_at(108, 176)
	end

    if config.subdue_target then 
        subdue_pokemon()
    end

    while game_state.in_battle do
        local balls = get_usable_balls()
        local ball_index = get_preferred_ball(balls)
        
        if ball_index == -1 then
            abort("No valid Poke Balls to catch the target with")
        end

        while mbyte(pointers.battle_menu_state) ~= 1 do
            press_sequence("B", 8)
        end

        wait_frames(20)

        touch_screen_at(38, 174)
        wait_frames(90)

        touch_screen_at(192, 36)
        wait_frames(90)

        use_ball(ball_index)

        -- Wait until catch failed or battle ended
        while mbyte(pointers.battle_menu_state) ~= 1 and game_state.in_battle do
            press_sequence("B", 8)
            touch_screen_at(0, 0) -- Skip Pokedex entry screen in HGSS without pressing A to avoid accidental menu inputs 
        end
    end

    print("Skipping through all post-battle dialogue... (This may take a few seconds)")

    for i = 0, 59, 1 do
        press_sequence("B", 10)
    end

    if config.save_game_after_catch then
        save_game()
    end
end

--- Logs the current wild foes and decides the next actions to take
function process_wild_encounter()
    clear_all_inputs()
    wait_frames(30)

    -- Check all foes in case of a double battle
    local is_target = false
    local foe_item = false
    local foe_name = foe[1].name

    for i, mon in ipairs(foe) do
        is_target = pokemon.log_encounter(mon) or is_target

        if mon.heldItem ~= "none" then
            foe_item = true
        end
    end

    if is_target then
        print("Wild " .. foe_name .. " is a target!")

        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end
        else
            abort("Stopping script for manual catch")
        end
    else
        while game_state.in_battle and foe do
            if #foe == 2 then
                print("Won't battle two targets at once. Fleeing!")
                flee_battle()
            else
				
				if not should_fight_foe() then
					flee_battle()
					return
				end
				
                -- Thief wild items (previously do_thief)
                local lead = get_lead_mon_index()
                local thief_slot = pokemon.get_move_slot(party[lead], "Thief")

                if config.thief_wild_items and foe_item and thief_slot ~= 0 then
                    print(foe_name .. " has a held item. Using Thief and fleeing...")

                    while get_battle_state() ~= "Menu" do
                        press_sequence("B", 5)
                    end

                    use_move(thief_slot)
                    flee_battle()
                elseif config.battle_non_targets then
                    print(foe_name .. " was not a target. Battling...")

                    while game_state.in_battle do
                        battle_foe()
                    end
                else
                    print(foe_name .. " was not a target. Fleeing!")
                    flee_battle()
                end
            end
        end
    end

    if config.pickup then
        do_pickup()
    end
end

--- Collects held items from Pickup Pokemon if enough have accumulated
function do_pickup()
    local item_count = 0

    for i, mon in ipairs(party) do
        if mon.ability == "Pickup" and mon.heldItem ~= "none" then
            item_count = item_count + 1
        end
    end

    if item_count >= tonumber(config.pickup_threshold) then
        wait_frames(100)
		open_menu("Pokemon")

        for _, mon in ipairs(party) do
            if mon.ability == "Pickup" and mon.heldItem ~= "none" then
                press_sequence("A", 8, "Up", 8, "Up", 8, "A", 22, "Down", 8, "A")
                wait_frames(90)
                press_button("B")
            end

            press_sequence("Right", 5)
        end
        
        press_sequence(30, "B", 120, "B", 60, "B", 60)
    else
        print_debug(item_count .. " Pickup items in party. Collecting at " .. config.pickup_threshold)
    end
end

--- Saves the game
function save_game()
    print("Saving game...")
    
    open_menu("Save")
    press_sequence("A", 90, "A", 900)
    press_sequence("B", 60, "B", 10)
end

-- Selects a move on the FIGHT menu
-- @param id The move index in the moveset
function use_move(id)
    wait_frames(30)
    touch_screen_at(128, 90)
    wait_frames(30)

    local x = 80 * ((id - 1) % 2 + 1)
    local y = 50 * (math.floor((id - 1) / 2) + 1)
    touch_screen_at(x, y)
    wait_frames(60)
end

local function stop_advancing()
    return (not game_state.in_battle) or (get_battle_state() == "Menu")
end

local function advance_battle_ui()
    while not stop_advancing() do

        -- Mash B
        for i = 1, 40 do
            press_button("B")
            wait_frames(6)
            if stop_advancing() then return end
        end

        -- Wait for level-up screen
        for i = 1, 320 do
            wait_frames(1)
            if stop_advancing() then return end
        end		
		
        -- Tap top screen
        for i = 1, 10 do
            touch_screen_at(130, 5)
            wait_frames(20)
            if stop_advancing() then return end
        end
		
		print("Please wait... New Move may be detected.")
		
		-- Tap top screen
        for i = 1, 10 do
            touch_screen_at(130, 5)
            wait_frames(20)
            if stop_advancing() then return end
        end
		
        -- Final taps
		if GAME == "B" or GAME == "W" or GAME == "B2" or GAME == "W2" then
			touch_screen_at(130, 100)
		else
			touch_screen_at(130, 130)
		end

        wait_frames(60)
  
		for i = 1, 8 do
            touch_screen_at(130, 70)
            wait_frames(40)
			if stop_advancing() then return end
        end
    end
end

function battle_foe()
    -- Wait for the Fight menu
	advance_battle_ui()

    -- Pick the best move
    local best_move = pokemon.find_best_attacking_move(party[get_lead_mon_index()], foe[1])

    if best_move.power > 0 then
        debug_print_pp()
        print_debug("Best move is " .. best_move.name .. " (Avg Power: " .. best_move.power .. ")")
        use_move(best_move.index)
    else
        print("Lead Pokemon has no valid moves left to battle! Fleeing...")
        flee_battle()
        return
    end

    -- Wait for Fight menu to disappear (move selected)
    while get_battle_state() == "Menu" do
        if not game_state.in_battle then return end
        wait_frames(1)
    end

    -- Tap through everything
    advance_battle_ui()
end

--- Manages the party between battles to make sure the bot can proceed with its task
function check_party_status()
    local function is_healthy(mon)
        local pp = 0

        for i, move in ipairs(mon.moves) do
            if move.power ~= nil then
                pp = pp + mon.pp[i]
            end
        end

        return mon.currentHP > mon.maxHP / 4 and pp > 0 and not mon.isEgg
    end

    if #party == 0 or game_state.in_battle then -- Don't check party status if bot was started during a battle
        return nil
    end

    if not is_healthy(party[get_lead_mon_index()]) then
        if not config.cycle_lead_pokemon then
            abort("Lead Pokemon is not suitable to battle, and the config disallows replacing it")
        end
    
        print("Lead Pokemon is not suitable to battle. Replacing...")

        local replacement

        for i, ally in ipairs(party) do
            if is_healthy(ally) then
                replacement = i
                break
            end
        end

        if not replacement then
            abort("No suitable Pokemon left to battle")
        end

        print("Next replacement is " .. party[replacement].name .. " (Slot " .. replacement .. ")")
        wait_frames(100)
		open_menu("Pokemon")
        
        -- Highlight lead
        local i = 1
        while i ~= get_lead_mon_index() do
            press_sequence("Right", 5)
            i = i + 1
        end

        -- Switch
        press_sequence("A", 30, "Up", 8, "Up", 8, "Up", 8, "A", 30)
        
        -- Highlight replacement
        local i = 1
        while i ~= replacement do
            press_sequence("Right", 5)
            i = i + 1
        end

        press_sequence("A", 30, "B", 120, "B", 120, "B", 30) -- Exit out of menu
    end

    if config.thief_wild_items then
        -- Check leading Pokemon for held items
        local lead = get_lead_mon_index()

        if party[lead].heldItem ~= "none" and pokemon.get_move_slot(party[lead], "Thief") ~= 0 then
            print("Thief Pokemon already holds an item. Removing...")
            clear_all_inputs()

            open_menu("Pokemon")
            
            local i = 1
            while i ~= lead do
                press_sequence("Right", 5)
                i = i + 1
            end
            
            -- Take item
            press_sequence("A", 8, "Up", 8, "Up", 8, "A", 22, "Down", 8, "A")
            wait_frames(90)
            press_button("B")
            
            press_sequence(30, "B", 120, "B", 60) -- Exit out of menu
        end
    end
end

--- Moves the bot toward a position on the map
-- @param target Target position (x, z)
-- @param on_move Function called each frame while moving
function move_to(target, on_move)
    if target.x then
        target.x = target.x + 0.5

        while game_state.trainer_x < target.x - 0.5 do
            hold_button("Right")
            if on_move then on_move() end
        end
        
        while game_state.trainer_x > target.x + 0.5 do
            hold_button("Left")
            if on_move then on_move() end
        end
    end

    if target.z then
        target.z = target.z + 0.5
        
        while game_state.trainer_z < target.z - 0.5 do
            hold_button("Down")
            if on_move then on_move() end
        end
        
        while game_state.trainer_z > target.z + 0.5 do
            hold_button("Up")
            if on_move then on_move() end
        end
    end
end

-- Same as above essentially, but won't gradually move the player off course
function move_to_fixed(target)
    while game_state.trainer_x < target.x do
        hold_button("Right")
    end

    while game_state.trainer_x > target.x do
        hold_button("Left")
    end

    while game_state.trainer_z < target.z do
        hold_button("Down")
    end

    while game_state.trainer_z > target.z do
        hold_button("Up")
    end
end

--- General script for receiving and checking multiple gift Pokemon types
function mode_gift()
    if not game_state.in_game then
        print("Waiting to reach overworld...")

        while not game_state.in_game do
            progress_text()
        end
    end

    local og_party_count = #party
    while #party == og_party_count do
        progress_text()
    end

    local mon = party[#party]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        abort(mon.name .. " is a target!")
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end

--- Resets until the encountered overworld Pokemon is a target
function mode_static_encounters()
    while not game_state.in_battle do
        if game_state.map_name == "Dreamyard" then
            hold_button("Right")
        elseif game_state.map_name == "Spear Pillar" then
            hold_button("Up")
        end

        progress_text()
    end

    local mon = foe[1]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end

            abort("Target " .. mon.name .. " was caught!")
        else
            abort(mon.name .. " is a target!")
        end
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end

--- Presses the RUN button until the battle is over
function flee_battle()
    while game_state.in_battle do
        touch_screen_at(125, 175)
        wait_frames(5)
    end

    print("Got away safely!")
end

--- Progress text with imperfect inputs to increase the randomness of frames hit
function progress_text()
    hold_button("A")
    wait_frames(math.random(5, 20))
    release_button("A")
    wait_frames(5)
end

function progress_text_B()
    hold_button("B")
    wait_frames(math.random(5, 20))
    release_button("B")
    wait_frames(5)
end
---------------------------------------------------------------
-- Clean Bot State Machine
---------------------------------------------------------------

bot = bot or {
    phase = "walk_left",
    timer = 0,
	retry = 0,
    WALK_FRAMES   = 90,
    CUTSCENE_WAIT = 40,
}
bot.seen = bot.seen or {}

function mode_hgss_roamers()
---------------------------------------------------------------
-- Roamer Reader 
---------------------------------------------------------------
local hunt_raikou = config.hunt_raikou
local hunt_entei  = config.hunt_entei

local bit = bit or require("bit")

local function read_u32(a)
    local b1 = memory.readbyte(a)
    local b2 = memory.readbyte(a+1)
    local b3 = memory.readbyte(a+2)
    local b4 = memory.readbyte(a+3)
    return b1 + bit.lshift(b2,8) + bit.lshift(b3,16) + bit.lshift(b4,24)
end

local function read_u16(a)
    local b1 = memory.readbyte(a)
    local b2 = memory.readbyte(a+1)
    return b1 + bit.lshift(b2,8)
end

local function find_roamer_header()
    local START = 0x02280000
    local END   = 0x02283000

    for addr = START, END, 4 do
        local hp1 = read_u32(addr)
        local hp2 = read_u32(addr + 0x14)

        if hp1 == 65576 and hp2 == 65576 then
            local header = addr - 0x20

            if header % 4 == 0 then
                return header
            end
        end
    end

    return nil
end


local function read_roamer(core)
    local loc  = read_u32(core)
    local iv32 = read_u32(core + 4)
    local pid  = read_u32(core + 8)
    return loc, iv32, pid
end

local function is_shiny(pid, tid, sid)
    local low  = bit.band(pid, 0xFFFF)
    local high = bit.rshift(pid, 16)
    return bit.bxor(low, high, tid, sid) < 8
end

local tid_sid = mdword(pointers.trainer_id)
local TID = bit.band(tid_sid, 0xFFFF)
local SID = bit.rshift(tid_sid, 16)

local function valid_roamer(iv32, pid)
    return (iv32 ~= 0 and iv32 ~= 0xFFFFFFFF and pid ~= 0 and pid ~= 0xFFFFFFFF)
end

---------------------------------------------------------------
-- Phase: Walk Left
---------------------------------------------------------------

local function phase_walk_left()
    bot.timer = bot.timer + 1
    hold_button("Left")

    if bot.timer >= bot.WALK_FRAMES then
        release_button("Left")
        bot.phase = "wait_cutscene"
        bot.timer = 0
        print("Waiting for roamers to populate...")
    end
end

---------------------------------------------------------------
-- Phase: Wait for Cutscene (timing‑based)
---------------------------------------------------------------

local function phase_wait_cutscene()
    bot.timer = bot.timer + 1
    progress_text()

    if bot.timer >= bot.CUTSCENE_WAIT then
        bot.phase = "check_roamers"
        bot.timer = 0
        print("Checking roamers...")
    end
end

---------------------------------------------------------------
-- Phase: Check Roamers
---------------------------------------------------------------

local function phase_check_roamers()
local header = find_roamer_header()

	if not header then
		if bot.retry == 0 then
			bot.retry = 1			
			print("No roamer header yet, retrying once...")			
			bot.phase = "walk_left"
			bot.timer = 0
			return
		else
			print("Still no header. Stopping script.")
			abort("Roamer header not found")   -- clean script exit
		end
	end

	bot.retry = 0

    local raikou = header + 0x10
    local entei  = header + 0x24

    local _, r_iv32, r_pid = read_roamer(raikou)
    local _, e_iv32, e_pid = read_roamer(entei)
	
	local function calc_sv(pid)
		local low  = bit.band(pid, 0xFFFF)
		local high = bit.rshift(pid, 16)
		return bit.bxor(low, high, TID, SID)
	end

	local r_sv = calc_sv(r_pid)
	local e_sv = calc_sv(e_pid)

	local key = string.format("%08X_%08X", r_pid, e_pid)

	-- Dupe detection across entire session since last hard reset
	if bot.seen[key] then
		print("Duplicate PID pair detected! Performing hard reset to break seed path...")
		bot.seen = {}   -- clear history
		hard_reset()
		bot.phase = "walk_left"
		bot.timer = 0
		return
	end

		-- Mark this PID pair as seen
	bot.seen[key] = true
		
local function print_roamer(name, sv, shiny)
    print(string.format(
        "%-8s | %-12s | %-12s",
        name,
        string.format("SV: %5d", sv),
        string.format("Shiny: %-5s", tostring(shiny))
    ))
end

if hunt_raikou then
    print_roamer("Raikou", r_sv, r_sv < 8)
end

if hunt_entei then
    print_roamer("Entei",  e_sv, e_sv < 8)
end

if not hunt_raikou and not hunt_entei then
    abort("Both roamer toggles are OFF — nothing to hunt.")
end

local r_shiny = hunt_raikou and is_shiny(r_pid, TID, SID)
local e_shiny = hunt_entei  and is_shiny(e_pid, TID, SID)

if r_shiny or e_shiny then
    print("✨ SHINY FOUND ✨")
    abort("Ending Script")
end

    bot.phase = "reset"
    bot.timer = 0
end

---------------------------------------------------------------
-- Phase: Reset + long wait + progress_text()
---------------------------------------------------------------

    local function phase_reset()
        wait_frames(math.random(0, 45)) -- jitter to break seed loops

        print("Soft resetting...")
        soft_reset()

        wait_frames(300)

        for i = 1, 40 do
            progress_text()
        end

        print("Starting cutscene...")
        bot.phase = "walk_left"
        bot.timer = 0
    end
    ---------------------------------------------------------------
    -- Dispatcher (one tick per frame)
    ---------------------------------------------------------------
    if bot.phase == "walk_left" then
        phase_walk_left()
    elseif bot.phase == "wait_cutscene" then
        phase_wait_cutscene()
    elseif bot.phase == "check_roamers" then
        phase_check_roamers()
    elseif bot.phase == "reset" then
        phase_reset()
    end
end

function mode_rock_smash()

    press_button("A")
    wait_frames(5)
	
	for i = 1, 60 do   
        press_button("A")
        wait_frames(1)
    end
	
    local TIMEOUT = 420
    wait_frames(TIMEOUT)

    if not game_state.in_battle then
        print("Not a battle. Resetting...")
        soft_reset()
        wait_frames(300)
        return
    end

    local mon = foe[1]
    local is_target = pokemon.log_encounter(mon)

    if is_target then
        if config.auto_catch then
            while game_state.in_battle do
                catch_pokemon()
            end
            abort("Target " .. mon.name .. " was caught!")
        else
            abort(mon.name .. " is a target!")
        end
    else
        print(mon.name .. " was not a target, resetting...")
        soft_reset()
    end
end
