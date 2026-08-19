function AirWars:SetTimeLeft(amount)
    if not istable(game_state) then return end
    game_state.time_left = math.max(0, tonumber(amount) or 0)
    AirWars:BroadcastGameState()
end

function AirWars:StartRound()
    if not istable(game_state) then return false end
    if game_state.state == GAME_STATE_FIGHT then return false end

    game_state.time_left = global_config.fight_time
    game_state.state = GAME_STATE_FIGHT
    game_state.skybox_id = math.random(1, 3)

    Skyfall.Info("Round", "Starting combat round with %d team(s)", table.Count(aw_teams_list or {}))
    AirWars:SpawnShips()
    AirWars:BroadcastGameState()
    hook.Run("AirWars_RoundStart")
    return true
end

function AirWars:TickRoundTimer()
    if not istable(game_state) then return end
    if game_state.state == GAME_STATE_PAUSE then return end

    game_state.time_left = math.max(0, (tonumber(game_state.time_left) or 0) - 1)
    if game_state.time_left > 0 then return end

    if game_state.state == GAME_STATE_BUILDING then
        if table.Count(aw_teams_list or {}) > 1 or aw_developer then
            AirWars:StartRound()
        else
            game_state.time_left = global_config.build_time
            for _, ply in ipairs(player.GetAll()) do
                ply:ChatPrint("Not enough teams to start the round")
            end
            AirWars:BroadcastGameState()
        end
        return
    end

    if game_state.state == GAME_STATE_FIGHT then
        Skyfall.Info("Round", "Fight timer expired; returning to build phase")
        AirWars:ResetRound()
        game_state.skybox_id = 1
        AirWars:BroadcastGameState()
    end
end

-- A one-second timer is both clearer and cheaper than polling CurTime from a
-- Think hook every rendered/server frame.
timer.Create("AirWars_Skyfall_RoundTimer", 1, 0, function()
    AirWars:TickRoundTimer()
end)
