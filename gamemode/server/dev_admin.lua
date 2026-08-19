-- AirWars: Skyfall general developer/admin diagnostics.

local function authorized(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function reply(ply, text)
    text = "[AirWars: Skyfall] " .. tostring(text)
    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTCONSOLE, text)
    else
        print(text)
    end
end

concommand.Add("aw_skyfall_version", function(ply)
    if not authorized(ply) then return end
    reply(ply, "Version " .. tostring(Skyfall.Version or GM.Version or "unknown"))
end)

concommand.Add("aw_skyfall_status", function(ply)
    if not authorized(ply) then return end
    local state = istable(game_state) and tostring(game_state.state) or "missing"
    local teams = istable(aw_teams_list) and table.Count(aw_teams_list) or 0
    local ships = istable(world_ships) and table.Count(world_ships) or 0
    reply(ply, string.format("state=%s timer=%s teams=%d ships=%d players=%d", state, tostring(game_state and game_state.time_left or "?"), teams, ships, #player.GetAll()))
end)

concommand.Add("aw_skyfall_features", function(ply)
    if not authorized(ply) then return end
    reply(ply, "Feature flags:")
    for name, enabled in SortedPairs(Skyfall.Config.features or {}) do
        reply(ply, string.format("  %-24s %s", name, enabled and "ON" or "OFF"))
    end
end)

concommand.Add("aw_skyfall_feature", function(ply, _, args)
    if not authorized(ply) then return end
    local name = tostring(args[1] or "")
    if name == "" or Skyfall.Config.features[name] == nil then
        reply(ply, "Usage: aw_skyfall_feature <feature> [0|1]")
        return
    end

    local value = tostring(args[2] or "")
    local enabled
    if value == "1" or value == "true" or value == "on" then
        enabled = true
    elseif value == "0" or value == "false" or value == "off" then
        enabled = false
    else
        enabled = not Skyfall.IsFeatureEnabled(name)
    end

    Skyfall.SetFeatureEnabled(name, enabled)
    reply(ply, name .. " = " .. (enabled and "ON" or "OFF"))
end)

concommand.Add("aw_skyfall_profile", function(ply)
    if not authorized(ply) then return end
    local snapshot = Skyfall.GetProfileSnapshot()
    if table.Count(snapshot) == 0 then
        reply(ply, "No profiling samples recorded yet")
        return
    end

    reply(ply, "Profiling snapshot (milliseconds):")
    for name, entry in SortedPairs(snapshot) do
        reply(ply, string.format("  %-28s calls=%d avg=%.3f max=%.3f total=%.3f", name, entry.count, entry.average * 1000, entry.max * 1000, entry.total * 1000))
    end
end)

concommand.Add("aw_skyfall_profile_reset", function(ply)
    if not authorized(ply) then return end
    Skyfall.Runtime.profile = {}
    reply(ply, "Profiling counters reset")
end)
