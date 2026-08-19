game_state = game_state or {
    time_left = global_config.build_time,
    state = GAME_STATE_BUILDING,
    skybox_id = 1
}

local function gen_state_table()
    return {
        time_left = game_state.time_left,
        state = game_state.state,
        teams = aw_teams_list,
        skybox_id = game_state.skybox_id
    }
end

function AirWars:PlayerSyncGameState(ply)
    if not IsValid(ply) then return end
    net.Start("aw_sync_game_state")
    net.WriteTable(gen_state_table())
    net.Send(ply)
end

function AirWars:SyncFlag(team)
    local flag = aw_team_flags[team] or {}
    net.Start("aw_sync_flag")
    net.WriteInt(team, 16)
    net.WriteInt(#flag, 32)
    for _, value in pairs(flag) do net.WriteInt(value, 5) end
    net.Broadcast()
end

function AirWars:PlayerSyncFlag(team, ply)
    if not IsValid(ply) then return end
    local flag = aw_team_flags[team] or {}
    net.Start("aw_sync_flag")
    net.WriteInt(team, 16)
    net.WriteInt(#flag, 32)
    for _, value in pairs(flag) do net.WriteInt(value, 5) end
    net.Send(ply)
end

function AirWars:BroadcastGameState()
    net.Start("aw_sync_game_state")
    net.WriteTable(gen_state_table())
    net.Broadcast()
end

function AirWars:TeamSyncGameState(team)
    local recipients = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:GetAWTeam() == team then table.insert(recipients, ply) end
    end
    if #recipients == 0 then return end
    net.Start("aw_sync_game_state")
    net.WriteTable(gen_state_table())
    net.Send(recipients)
end

local function clear_skyfall_round_state()
    aw_bullets = {}

    if Skyfall then
        Skyfall.Grapples = {}
        Skyfall.CaptureAttempts = {}
        Skyfall.AIShips = {}

        if Skyfall.Mission then
            Skyfall.Mission.active = false
            Skyfall.Mission.status = "idle"
            Skyfall.Mission.objective = ""
            if Skyfall.SyncMission then Skyfall.SyncMission() end
        end

        if Skyfall.SetWeather then Skyfall.SetWeather("clear") end
    end
end

function AirWars:ResetRound()
    hook.Run("Skyfall_BeforeRoundReset")

    local active_ship_ids = {}
    for id in pairs(world_ships or {}) do active_ship_ids[id] = true end

    -- One entity pass replaces the legacy ships x entities nested cleanup.
    for _, entity in ipairs(ents.FindByClass("aw*")) do
        if not IsValid(entity) or not entity.GetAWTeam then continue end
        if active_ship_ids[entity:GetAWTeam()] then entity:Remove() end
    end

    world_ships = {}
    clear_skyfall_round_state()

    game_state.state = GAME_STATE_BUILDING
    game_state.time_left = global_config.build_time
    game_state.skybox_id = 1
    AirWars:BroadcastGameState()

    net.Start("aw_round_reset")
    net.Broadcast()

    AirWars:SpawnPlayers()
    hook.Run("Skyfall_AfterRoundReset")
end
