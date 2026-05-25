-----------------------------------------------------------------------------
-- Bot method overrides for Platinum
-- Auto-anchored via runtime TID (no dashboard input required)
-- Author: wyanido, FalinMor_
-----------------------------------------------------------------------------

local printed_tid_debug = false

-- Auto-detect Platinum save-block anchor using runtime TID
local function find_save_anchor_from_runtime_tid(runtime_anchor)
    if not runtime_anchor or runtime_anchor == 0 then
        return nil
    end

    -- 1. Read runtime TID (always valid in Platinum)
    local tid = mword(runtime_anchor + 0x8C) or 0
    if tid == 0 then
        return nil
    end

    -- 2. Extract bytes (Lua 5.1 safe)
    local b1 = tid % 256
    local b2 = math.floor(tid / 256)

    -- 3. Scan Platinum save-block window
    local start_addr = 0x0227E000
    local end_addr   = 0x02280000

    for addr = start_addr, end_addr, 2 do
        if mbyte(addr) == b1 and mbyte(addr + 1) == b2 then
            local save_anchor = addr - 0x0A

            -- 4. One-time debug sanity print
            if not printed_tid_debug then
                print_debug(string.format(
                    "[PT] Auto-anchor OK: runtime TID %d found at %08X → save_anchor %08X",
                    tid, addr, save_anchor
                ))
                print_debug(string.format("anchor = %08X", mdword(0x21C0794 + _ROM.offset)))
				printed_tid_debug = true
            end

            return save_anchor
        end
    end

    return nil
end

-------------------------------------------------------------------------------
-- Platinum battle-species scanner 
-------------------------------------------------------------------------------

local printed_species_debug_not_ready = false
local printed_species_debug_not_found = false
local printed_species_debug_found     = false

local platinum_species_addr = nil
local platinum_status_addr  = nil

local function platinum_scan_species_window()

    if platinum_species_addr then
        return platinum_species_addr, platinum_status_addr
    end

    local mon = foe and foe[1]
    if not mon or mon.species == 0 then
        if not printed_species_debug_not_ready then
            print_debug("[PT] Species scan: struct not ready yet")
            printed_species_debug_not_ready = true
        end
        return nil, nil
    end

    local target_species = mon.species
    local SCAN_START     = 0x022C5700
    local SCAN_END       = 0x022C5900
    local STATUS_OFFSET  = 0x5B9E

    for addr = SCAN_START, SCAN_END, 2 do
        if mword(addr) == target_species then
            platinum_species_addr = addr
            platinum_status_addr  = addr + STATUS_OFFSET

            if not printed_species_debug_found then
                print_debug(string.format(
                    "[PT] Species found: %d @ %08X → status @ %08X",
                    target_species, platinum_species_addr, platinum_status_addr
                ))
                printed_species_debug_found = true
            end

            return platinum_species_addr, platinum_status_addr
        end
    end

    if not printed_species_debug_not_found then
        print_debug("[PT] Species scan: not in window yet.")
        printed_species_debug_not_found = true
    end

    return nil, nil
end

-----------------------------------------------------------------------------

function update_pointers()
    -------------------------------------------------------------------------
    -- Runtime anchor (same as DP/HGSS logic)
    -------------------------------------------------------------------------
    local anchor     = mdword(0x21C0794 + _ROM.offset)
    local foe_anchor = mdword(anchor + 0x217A8)
    -------------------------------------------------------------------------
    -- Battle species/status scan (Platinum-only)
    -------------------------------------------------------------------------
	local species_addr, status_addr = platinum_scan_species_window()

	local hp_addr  = nil
	local max_addr = nil

	if species_addr then
		hp_addr  = species_addr + 0x4C
		max_addr = species_addr + 0x50
	end
    -------------------------------------------------------------------------
    -- Auto-detect save-block anchor using runtime TID
    -------------------------------------------------------------------------
    local tid_anchor = find_save_anchor_from_runtime_tid(anchor) or 0

    -------------------------------------------------------------------------
    -- Pointer table (Platinum)
    -------------------------------------------------------------------------
    pointers = {
        start_value = 0x2101008, -- 0 until save has been loaded

        ---------------------------------------------------------------------
        -- Runtime anchor-based pointers (Platinum)
        ---------------------------------------------------------------------
        party_count = anchor + 0xB0,
        party_data  = anchor + 0xB4,

        foe_count   = foe_anchor - 0x2D5C,
        current_foe = foe_anchor - 0x2D58,
		foe_species = species_addr,
		foe_status  = status_addr,
		currentHP   = hp_addr,
		maxHP       = max_addr,
		
		map_header  = anchor + 0x1294,
        menu_option = 0x21C4C86 + _ROM.offset,

        trainer_x   = 0x21C5CE4 + _ROM.offset,
        trainer_y   = 0x21C5CE8 + _ROM.offset,
        trainer_z   = 0x21C5CEC + _ROM.offset,
        facing      = anchor + 0x238A4,

        bike_gear   = anchor + 0x1320,
        bike        = anchor + 0x1324,

        daycare_egg = anchor + 0x1840,

        selected_starter = anchor + 0x41850,
        starters_ready   = anchor + 0x418D4,

        battle_menu_state  = anchor + 0x44878,
        battle_menu_state2 = anchor + 0xED6A6,
		battle_bag_page = anchor + 0xC47E,
		
        battle_indicator       = 0x021D18F2 + _ROM.offset,
        fishing_bite_indicator = 0x021CF636 + _ROM.offset,

        trainer_name = anchor + 0x7C,
        trainer_id   = anchor + 0x8C,

        roamer = mdword(anchor + 0x28364),

        ---------------------------------------------------------------------
        -- Platinum save-block pockets (auto-anchored)
        -- Each slot: [id16][qty16]
        ---------------------------------------------------------------------

        -- Items
        items_pocket          = tid_anchor + 0x5C2,
        items_pocket_qty      = tid_anchor + 0x5C4,

        -- Key Items
        key_items_pocket      = tid_anchor + 0x67E,
        key_items_pocket_qty  = tid_anchor + 0x680,

        -- TMs/HMs
        tms_hms_pocket        = tid_anchor + 0x91E,
        tms_hms_pocket_qty    = tid_anchor + 0x920,

        -- Mail
        mail_pocket           = tid_anchor + 0xAAE,
        mail_pocket_qty       = tid_anchor + 0xAB0,

        -- Medicine
        medicine_pocket       = tid_anchor + 0xADE,
        medicine_pocket_qty   = tid_anchor + 0xAE0,

        -- Berries
        berries_pocket        = tid_anchor + 0xB7E,
        berries_pocket_qty    = tid_anchor + 0xB80,

        -- Poké Balls
        poke_balls_pocket     = tid_anchor + 0xC7E,
        poke_balls_pocket_qty = tid_anchor + 0xC80,

        -- Battle Items
        battle_items_pocket      = tid_anchor + 0xCBA,
        battle_items_pocket_qty  = tid_anchor + 0xCBC,
    }
end

-- Platinum battle state reader
local function pl_battle_menu_state()
    return mbyte(pointers.battle_menu_state)
end

function get_battle_state()
    local s = pl_battle_menu_state()

    if s == 0 then
        return "Busy"        -- text, animations, HP bar, move execution
    elseif s == 1 then
        return "Menu"        -- FIGHT root menu (ready)
    elseif s == 4 then
        return "MoveSelect"
    elseif s == 8 then
        return "Bag"
    elseif s == 10 then
        return "Pokemon"
    elseif s == 14 then
        return "Run"         -- also appears during move execution
    else
        return "Unknown"
    end
end

function foe_has_status()
    return mbyte(pointers.foe_status) ~= 0
end

