-- AirWars: Skyfall central configuration and feature flags.
--
-- Keep gameplay-facing defaults here so server owners and future systems do not
-- have to scatter magic numbers throughout the gamemode. Legacy global_config
-- remains supported; Skyfall.Config covers new/modernized systems.

Skyfall = Skyfall or {}
Skyfall.Version = "1.0.0-dev"
Skyfall.Config = Skyfall.Config or {}

Skyfall.Config.debug = Skyfall.Config.debug or {
    enabled = true,
    level = "info"
}

Skyfall.Config.performance = Skyfall.Config.performance or {
    -- Collision transfer between moving ships does not need to execute once per
    -- rendered frame. 20 Hz remains responsive while dramatically reducing work
    -- on high-refresh-rate servers/clients.
    player_ship_collision_interval = 0.05,
    fall_check_interval = 0.10,
    build_bounds_interval = 0.25,

    -- Existing ship position replication defaults to global_config's value.
    position_sync_interval = nil
}

Skyfall.Config.network = Skyfall.Config.network or {
    prop_spawn_interval = 0.10,
    team_action_interval = 0.20,
    flag_update_interval = 0.15,
    max_team_name_bytes = 64,
    max_flag_entries = 32
}

Skyfall.Config.gameplay = Skyfall.Config.gameplay or {
    respawn_delay = 3,
    boarding_transfer_distance = 2000
}

-- Feature gates let the 1.0 integration branch land systems incrementally while
-- preserving an emergency switch for server owners and regression testing.
Skyfall.Config.features = Skyfall.Config.features or {
    crew_specialties = false,
    component_engineering = false,
    fire_and_armor = false,
    blueprints = false,
    prefab_ships = false,
    pve = false,
    ai_crew = false,
    boarding = false,
    weather = false,
    tutorials = false,
    cosmetic_progression = true
}

local function split_path(path)
    if istable(path) then return path end
    local parts = {}
    for part in string.gmatch(tostring(path or ""), "[^%.]+") do
        table.insert(parts, part)
    end
    return parts
end

function Skyfall.GetConfig(path, default)
    local value = Skyfall.Config
    for _, key in ipairs(split_path(path)) do
        if not istable(value) or value[key] == nil then return default end
        value = value[key]
    end
    if value == nil then return default end
    return value
end

function Skyfall.IsFeatureEnabled(name)
    return Skyfall.GetConfig({"features", name}, false) == true
end

function Skyfall.SetFeatureEnabled(name, enabled)
    Skyfall.Config.features[name] = enabled == true
end
