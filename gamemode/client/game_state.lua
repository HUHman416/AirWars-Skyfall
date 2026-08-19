game_state = game_state or {
    time_left = 999,
    state = 0,
    team_name = "",
    skybox_id = 1,
    teams = {}
}

net.Receive("aw_sync_game_state", function()
    local previous_skybox = game_state.skybox_id
    local incoming = net.ReadTable()
    if not istable(incoming) then return end
    game_state = incoming
    game_state.teams = game_state.teams or {}
    if game_state.skybox_id ~= previous_skybox and isfunction(spawn_clouds) then spawn_clouds() end
end)

net.Receive("aw_round_reset", function()
    world_ships = {}
    if Skyfall then
        Skyfall.SpottedShips = {}
        Skyfall.ClientMission = {active = false}
    end
end)

net.Receive("aw_player_sync_data", function()
    local data = net.ReadTable()
    if IsValid(LocalPlayer()) then LocalPlayer().player_data = istable(data) and data or {} end
end)

function game_state_get_time_left()
    return game_state.time_left or 0
end

function game_state_get_state()
    return game_state.state or GAME_STATE_BUILDING
end
