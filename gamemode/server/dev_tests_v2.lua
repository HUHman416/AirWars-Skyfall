-- AirWars: Skyfall developer test harness v2
-- Server-side only. State-changing commands require admin/server-console access.

local function test_authorized(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

-- Send each test line to exactly one destination. On a listen server, printing to
-- both the server console and ChatPrint caused every line to appear twice.
local function test_reply(ply, message)
    local line = "[AirWars: Skyfall Test] " .. tostring(message)
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, line)
    else
        print(line)
    end
end

local function state_name(state)
    if state == GAME_STATE_BUILDING then return "BUILDING" end
    if state == GAME_STATE_FIGHT then return "FIGHT" end
    if state == GAME_STATE_PAUSE then return "PAUSE" end
    return "UNKNOWN (" .. tostring(state) .. ")"
end

local function get_test_ship(ply, args)
    if not istable(world_ships) then return nil end

    local requested_id = tonumber(args and args[1] or nil)
    if requested_id and world_ships[requested_id] then
        return world_ships[requested_id]
    end

    if IsValid(ply) and ply.GetCurrentShip then
        local current_id = ply:GetCurrentShip()
        if world_ships[current_id] then
            return world_ships[current_id]
        end
    end

    for _, ship in pairs(world_ships) do
        return ship
    end

    return nil
end

local function remove_team_build_props(team_id)
    local removed = 0
    for _, ent in ipairs(ents.FindByClass("aw_building_prop")) do
        if IsValid(ent) and ent.GetAWTeam and ent:GetAWTeam() == team_id then
            ent:Remove()
            removed = removed + 1
        end
    end
    return removed
end

function AirWars:RunSkyfallSmokeTest(ply)
    local passed = 0
    local warnings = 0
    local failed = 0

    local function result(level, name, detail)
        if level == "PASS" then
            passed = passed + 1
        elseif level == "WARN" then
            warnings = warnings + 1
        else
            failed = failed + 1
        end

        local suffix = detail ~= nil and (" - " .. tostring(detail)) or ""
        test_reply(ply, "[" .. level .. "] " .. name .. suffix)
    end

    local function check(name, condition, detail)
        if condition then
            result("PASS", name, detail)
        else
            result("FAIL", name, detail)
        end
    end

    test_reply(ply, "=== v0.1 Resurrection smoke test ===")

    check("AirWars table", istable(AirWars))
    check("global_config table", istable(global_config))
    check("game_state table", istable(game_state))
    check("team registry", istable(aw_teams_list))
    check("ship registry", istable(world_ships))

    local required_functions = {
        "SetTimeLeft",
        "StartRound",
        "ResetRound",
        "BroadcastGameState",
        "CreateShip",
        "SpawnShips",
        "SpawnPlayers",
        "SpawnProp"
    }

    for _, name in ipairs(required_functions) do
        check("AirWars:" .. name, istable(AirWars) and isfunction(AirWars[name]))
    end

    if istable(global_config) then
        check("build time", isnumber(global_config.build_time) and global_config.build_time > 0, global_config.build_time)
        check("fight time", isnumber(global_config.fight_time) and global_config.fight_time > 0, global_config.fight_time)
        check("position sync rate", isnumber(global_config.position_sync_rate) and global_config.position_sync_rate > 0, global_config.position_sync_rate)
        check("build bounds", istable(global_config.build_bounds) and global_config.build_bounds.min ~= nil and global_config.build_bounds.max ~= nil)
    end

    if istable(game_state) then
        local valid_state = game_state.state == GAME_STATE_BUILDING or game_state.state == GAME_STATE_FIGHT or game_state.state == GAME_STATE_PAUSE
        check("round state", valid_state, state_name(game_state.state))
        check("round timer", isnumber(game_state.time_left) and game_state.time_left >= 0, game_state.time_left)
    end

    local required_entities = {
        "aw_building_prop",
        "aw_ship_controller",
        "aw_engine",
        "aw_sail",
        "aw_player_spawn",
        "aw_ammunition_storage",
        "aw_weapon_cannon",
        "aw_weapon_rifle",
        "aw_weapon_hook",
        "aw_weapon_bomb"
    }

    for _, class in ipairs(required_entities) do
        check("entity " .. class, scripted_ents.GetStored(class) ~= nil)
    end

    local required_weapons = {
        "aw_tool_remover",
        "aw_tool_pusher",
        "aw_tool_stacker",
        "aw_melee",
        "aw_hands"
    }

    for _, class in ipairs(required_weapons) do
        check("SWEP " .. class, weapons.GetStored(class) ~= nil)
    end

    local required_network_strings = {
        "aw_sync_game_state",
        "aw_round_reset",
        "aw_sync_ship",
        "aw_sync_ship_position",
        "aw_destroy_ship"
    }

    for _, name in ipairs(required_network_strings) do
        check("net string " .. name, util.NetworkStringToID(name) ~= 0)
    end

    local team_count = istable(aw_teams_list) and table.Count(aw_teams_list) or 0
    if team_count == 0 then
        result("WARN", "teams", "No teams exist yet; join the server before gameplay testing")
    else
        result("PASS", "teams", team_count .. " registered")
        for id, team_data in pairs(aw_teams_list) do
            if not istable(team_data) then
                result("FAIL", "team " .. tostring(id), "team entry is not a table")
            else
                check("team " .. tostring(id) .. " members", istable(team_data.members))
                if not IsValid(team_data.leader) then
                    result("WARN", "team " .. tostring(id) .. " leader", "leader is not currently valid")
                end
            end
        end
    end

    for _, ply_test in ipairs(player.GetAll()) do
        if not ply_test.GetAWTeam then
            result("FAIL", "player " .. ply_test:Nick(), "GetAWTeam is unavailable")
        else
            local team_id = ply_test:GetAWTeam()
            if ply_test:IsSpectator() then
                result("PASS", "player " .. ply_test:Nick(), "spectator")
            elseif not istable(aw_teams_list) or not aw_teams_list[team_id] then
                result("FAIL", "player " .. ply_test:Nick(), "missing team " .. tostring(team_id))
            else
                result("PASS", "player " .. ply_test:Nick(), "team " .. tostring(team_id))
            end
        end
    end

    local ship_count = istable(world_ships) and table.Count(world_ships) or 0
    if ship_count == 0 then
        result("WARN", "ships", "No active ships; normal during the build phase")
    else
        result("PASS", "ships", ship_count .. " active")
        for id, ship in pairs(world_ships) do
            if not istable(ship) then
                result("FAIL", "ship " .. tostring(id), "ship entry is not a table")
            else
                check("ship " .. tostring(id) .. " id", ship.id == id, ship.id)
                check("ship " .. tostring(id) .. " parts", istable(ship.parts))
                check("ship " .. tostring(id) .. " controls", istable(ship.direction))
                check("ship " .. tostring(id) .. " SyncPosition", isfunction(ship.SyncPosition))
                check("ship " .. tostring(id) .. " SyncToPlayer", isfunction(ship.SyncToPlayer))
            end
        end
    end

    if istable(game_state) and game_state.state == GAME_STATE_FIGHT then
        local controllers = #ents.FindByClass("aw_ship_controller")
        local spawns = #ents.FindByClass("aw_player_spawn")
        if controllers > 0 then
            result("PASS", "fight controllers", controllers)
        else
            result("WARN", "fight controllers", "none found")
        end
        if spawns > 0 then
            result("PASS", "fight player spawns", spawns)
        else
            result("WARN", "fight player spawns", "none found")
        end
    end

    test_reply(ply, "=== Result: " .. passed .. " PASS / " .. warnings .. " WARN / " .. failed .. " FAIL ===")
    if failed == 0 then
        test_reply(ply, "Automated checks passed. Manual physics/gameplay checks may still be required.")
    end

    return failed == 0, passed, warnings, failed
end

concommand.Add("aw_test_help", function(ply)
    if not test_authorized(ply) then return end
    test_reply(ply, "Commands:")
    test_reply(ply, "  aw_test_all                 - non-destructive automated smoke test")
    test_reply(ply, "  aw_test_status              - print current round/team/ship status")
    test_reply(ply, "  aw_test_buildship           - replace your build with a standard test ship")
    test_reply(ply, "  aw_test_ship [team id]      - validate one active ship")
    test_reply(ply, "  aw_test_devmode [0|1]       - toggle solo developer mode")
    test_reply(ply, "  aw_test_time <seconds>      - set the current round timer")
    test_reply(ply, "  aw_test_startfight          - immediately begin combat")
    test_reply(ply, "  aw_test_reset               - immediately reset to build phase")
    test_reply(ply, "  aw_test_respawn             - respawn the issuing player")
    test_reply(ply, "  aw_test_roundtrip           - DESTRUCTIVE build -> fight -> reset test")
end)

concommand.Add("aw_test_all", function(ply)
    if not test_authorized(ply) then return end
    AirWars:RunSkyfallSmokeTest(ply)
end)

concommand.Add("aw_test_status", function(ply)
    if not test_authorized(ply) then return end
    local state = istable(game_state) and state_name(game_state.state) or "MISSING"
    local time_left = istable(game_state) and game_state.time_left or "?"
    local teams = istable(aw_teams_list) and table.Count(aw_teams_list) or 0
    local ships = istable(world_ships) and table.Count(world_ships) or 0
    local build_props = #ents.FindByClass("aw_building_prop")
    test_reply(ply, "State=" .. state .. " | Time=" .. tostring(time_left) .. " | Teams=" .. teams .. " | Ships=" .. ships .. " | BuildProps=" .. build_props .. " | DevMode=" .. tostring(aw_developer == true))
end)

concommand.Add("aw_test_buildship", function(ply)
    if not test_authorized(ply) or not IsValid(ply) then return end
    if not istable(game_state) then
        test_reply(ply, "game_state is unavailable")
        return
    end
    if game_state.state == GAME_STATE_FIGHT then
        test_reply(ply, "Reset to BUILDING before creating a test ship")
        return
    end
    if not isfunction(AirWars.SpawnProp) then
        test_reply(ply, "AirWars:SpawnProp is unavailable")
        return
    end

    local team_id = ply:GetAWTeam()
    if not team_id or not aw_teams_list[team_id] then
        test_reply(ply, "Your AirWars team is unavailable")
        return
    end

    local removed = remove_team_build_props(team_id)
    local origin = ply:GetPos() + ply:GetForward() * 320 + Vector(0, 0, 48)
    local spawned = 0
    local target_parts = 15

    local function add(offset, category, index, angle)
        local ent = AirWars:SpawnProp(origin + offset, angle or Angle(), category, index, ply, true)
        if IsValid(ent) then spawned = spawned + 1 end
        return ent
    end

    -- Six large plates form a proper walkable 3x2 deck rather than the original
    -- single tiny plate. The remaining nine parts exercise every legacy system.
    local deck_offsets = {
        Vector(-96, -48, 0), Vector(0, -48, 0), Vector(96, -48, 0),
        Vector(-96,  48, 0), Vector(0,  48, 0), Vector(96,  48, 0)
    }
    for _, offset in ipairs(deck_offsets) do
        add(offset, CATEGORY_PROPS, 3)
    end

    add(Vector(-45, -25, 24), CATEGORY_SPECIALS, 1) -- steering wheel
    add(Vector(-115, 0, 65), CATEGORY_SPECIALS, 2)  -- sail
    add(Vector(0, 0, 205), CATEGORY_SPECIALS, 4)    -- large balloon
    add(Vector(-35, 50, 24), CATEGORY_SPECIALS, 5)  -- player spawn
    add(Vector(45, 50, 24), CATEGORY_SPECIALS, 6)   -- ammunition storage

    add(Vector(105, -60, 28), CATEGORY_WEAPONS, 1)  -- cannon
    add(Vector(105, -20, 28), CATEGORY_WEAPONS, 2)  -- rifle
    add(Vector(105,  25, 28), CATEGORY_WEAPONS, 3)  -- grappling hook
    add(Vector(-105, 60, 28), CATEGORY_WEAPONS, 4)  -- bomb

    test_reply(ply, "Test ship created: " .. spawned .. "/" .. target_parts .. " parts spawned; removed " .. removed .. " previous build parts")
    if spawned < target_parts then
        test_reply(ply, "[WARN] Some parts failed to spawn. Run aw_test_all and check funds/entity errors.")
    else
        test_reply(ply, "Walkable deck created. Next: aw_test_startfight")
    end
end)

concommand.Add("aw_test_ship", function(ply, cmd, args)
    if not test_authorized(ply) then return end
    local ship = get_test_ship(ply, args)
    if not ship then
        test_reply(ply, "No active ship found. Start combat first or provide an active team id.")
        return
    end

    test_reply(ply, "Ship " .. tostring(ship.id) .. ": parts=" .. tostring(istable(ship.parts) and table.Count(ship.parts) or 0) .. ", health=" .. tostring(ship.health) .. ", position=" .. tostring(ship.position) .. ", angles=" .. tostring(ship.angles))
    test_reply(ply, "Controls=" .. tostring(istable(ship.direction)) .. " | SyncPosition=" .. tostring(isfunction(ship.SyncPosition)) .. " | SyncToPlayer=" .. tostring(isfunction(ship.SyncToPlayer)))
end)

concommand.Add("aw_test_devmode", function(ply, cmd, args)
    if not test_authorized(ply) then return end
    local value = string.lower(tostring(args[1] or ""))
    if value == "1" or value == "true" or value == "on" then
        aw_developer = true
    elseif value == "0" or value == "false" or value == "off" then
        aw_developer = false
    else
        aw_developer = not aw_developer
    end
    test_reply(ply, "Developer mode: " .. (aw_developer and "ON" or "OFF"))
end)

concommand.Add("aw_test_time", function(ply, cmd, args)
    if not test_authorized(ply) then return end
    local seconds = tonumber(args[1])
    if not seconds then
        test_reply(ply, "Usage: aw_test_time <seconds>")
        return
    end
    seconds = math.max(0, math.floor(seconds))
    AirWars:SetTimeLeft(seconds)
    test_reply(ply, "Round timer set to " .. seconds .. " seconds")
end)

concommand.Add("aw_test_startfight", function(ply)
    if not test_authorized(ply) then return end
    if not isfunction(AirWars.StartRound) then
        test_reply(ply, "StartRound is unavailable")
        return
    end

    if not istable(aw_teams_list) or table.Count(aw_teams_list) <= 1 then
        aw_developer = true
        test_reply(ply, "Solo/one-team test detected; developer mode enabled to prevent instant victory reset")
    end

    AirWars:StartRound()
    test_reply(ply, "Combat phase forced")
end)

concommand.Add("aw_test_reset", function(ply)
    if not test_authorized(ply) then return end
    if not isfunction(AirWars.ResetRound) then
        test_reply(ply, "ResetRound is unavailable")
        return
    end
    AirWars:ResetRound()
    test_reply(ply, "Round reset to build phase")
end)

concommand.Add("aw_test_respawn", function(ply)
    if not test_authorized(ply) or not IsValid(ply) then return end
    ply:Spawn()
    test_reply(ply, "Player respawned")
end)

concommand.Add("aw_test_roundtrip", function(ply)
    if not test_authorized(ply) then return end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then
        test_reply(ply, "Roundtrip must start from BUILDING/PAUSE state")
        return
    end
    if #ents.FindByClass("aw_building_prop") == 0 then
        test_reply(ply, "Roundtrip requires build props. Run aw_test_buildship first.")
        return
    end

    aw_developer = true
    test_reply(ply, "Starting DESTRUCTIVE roundtrip test: build -> combat -> validation -> reset")
    AirWars:StartRound()

    timer.Simple(1, function()
        if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then
            test_reply(ply, "[FAIL] Roundtrip did not enter FIGHT state")
            return
        end

        test_reply(ply, "[PASS] Entered FIGHT state with " .. tostring(istable(world_ships) and table.Count(world_ships) or 0) .. " ship(s)")
        AirWars:RunSkyfallSmokeTest(ply)

        timer.Simple(1, function()
            AirWars:ResetRound()
            if istable(game_state) and game_state.state == GAME_STATE_BUILDING then
                test_reply(ply, "[PASS] Returned to BUILDING state")
            else
                test_reply(ply, "[FAIL] Round reset did not return to BUILDING state")
            end
        end)
    end)
end)
