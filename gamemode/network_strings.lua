-- AirWars: Skyfall network string registry.
-- Keep this file declarative: validation/rate limiting belongs in receivers.

local NETWORK_STRINGS = {
    -- Legacy AirWars protocol
    "aw_spawn_prop",
    "aw_sync_parts",
    "aw_sync_ship",
    "aw_round_reset",
    "aw_assign_ship",
    "aw_sync_direction",
    "aw_sync_ship_position",
    "aw_send_team_request",
    "aw_play_weapon_effect",
    "aw_sync_part_health",
    "aw_sync_game_state",
    "aw_change_team_name",
    "aw_team_request",
    "aw_accept_team_request",
    "aw_team_kick_player",
    "aw_destroy_ship",
    "aw_bullet_hit",
    "aw_weapon_effect",
    "aw_effect",
    "aw_player_sync_data",
    "aw_update_flag",
    "aw_sync_flag",
    "aw_pointshop_wear",
    "aw_player_sync_wearables",

    -- Skyfall extension protocol
    "aw_skyfall_part_state",
    "aw_skyfall_spot",
    "aw_skyfall_mission",
    "aw_skyfall_weather",
    "aw_skyfall_notice"
}

for _, name in ipairs(NETWORK_STRINGS) do
    util.AddNetworkString(name)
end

Skyfall.NetworkStrings = NETWORK_STRINGS
