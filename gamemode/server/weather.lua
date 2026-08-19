-- AirWars: Skyfall Stormfront environmental simulation.

Skyfall.Weather = Skyfall.Weather or {
    type = "clear",
    wind = Vector(),
    strength = 0,
    turbulence = 0,
    fog = 0,
    visibility = 9000,
    lightning = false,
    changed_at = 0
}

local WEATHER = {
    clear = {strength = 0, turbulence = 0, fog = 0, visibility = 12000, lightning = false},
    fog = {strength = 28, turbulence = 0.08, fog = 0.82, visibility = 1900, lightning = false},
    gale = {strength = 125, turbulence = 0.48, fog = 0.18, visibility = 6500, lightning = false},
    storm = {strength = 165, turbulence = 0.78, fog = 0.56, visibility = 3200, lightning = true},
    aether = {strength = 95, turbulence = 0.62, fog = 0.34, visibility = 4700, lightning = true}
}

local next_weather_tick = 0
local next_lightning = 0

local function random_wind(strength)
    if strength <= 0 then return Vector() end
    local angle = Angle(0, math.Rand(0, 360), 0)
    return angle:Forward() * strength
end

local function payload()
    local w = Skyfall.Weather
    return {
        type = w.type,
        wind = {x = w.wind.x, y = w.wind.y, z = w.wind.z},
        strength = w.strength,
        turbulence = w.turbulence,
        fog = w.fog,
        visibility = w.visibility,
        lightning = w.lightning
    }
end

function Skyfall.SyncWeather(recipients)
    net.Start("aw_skyfall_weather")
    net.WriteTable(payload())
    if recipients then net.Send(recipients) else net.Broadcast() end
end

function Skyfall.SetWeather(weather_type)
    weather_type = string.lower(tostring(weather_type or "clear"))
    local profile = WEATHER[weather_type]
    if not profile then return false, "Unknown weather type" end

    Skyfall.Weather = {
        type = weather_type,
        wind = random_wind(profile.strength),
        strength = profile.strength,
        turbulence = profile.turbulence,
        fog = profile.fog,
        visibility = profile.visibility,
        lightning = profile.lightning,
        changed_at = CurTime()
    }
    next_lightning = CurTime() + math.Rand(5, 12)
    Skyfall.SyncWeather()
    Skyfall.Info("Weather", "Weather changed to %s", weather_type)
    hook.Run("Skyfall_WeatherChanged", Skyfall.Weather)
    return true, weather_type
end

local function weather_force(ship, dt)
    if not ship.velocity then ship.velocity = Vector() end
    local w = Skyfall.Weather
    if w.strength <= 0 then return end

    local weight = math.max(40, calculate_ship_weight(ship.id))
    local mass_factor = math.Clamp(500 / weight, 0.18, 2.5)
    ship.velocity:Add(w.wind * dt * 0.11 * mass_factor)

    if w.turbulence > 0 then
        local jitter = Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-0.45, 0.45))
        ship.velocity:Add(jitter * w.turbulence * 42 * dt * mass_factor)
        ship.angle_velocity = ship.angle_velocity or Angle()
        ship.angle_velocity:Add(Angle(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-0.5, 0.5)) * w.turbulence * dt)
    end
end

local function lightning_strike()
    local candidates = {}
    for _, ship in pairs(world_ships or {}) do
        if table.Count(ship.parts or {}) > 0 then table.insert(candidates, ship) end
    end
    if #candidates == 0 then return end

    local ship = table.Random(candidates)
    local parts = {}
    for _, part in pairs(ship.parts or {}) do table.insert(parts, part) end
    if #parts == 0 then return end
    local part = table.Random(parts)

    local severe = Skyfall.Weather.type == "aether"
    part:ApplyDamage(severe and 15 or 11, {kind = "component", penetration = 0.65, component_multiplier = 1.2, hull_multiplier = 0.8}, "lightning")
    part:AddFireStacks(severe and 3 or 2)

    net.Start("aw_skyfall_notice")
    net.WriteString("lightning")
    net.WriteString(tostring(ship.id))
    net.Broadcast()
    hook.Run("Skyfall_LightningStrike", ship, part)
end

function Skyfall.TickWeather()
    if not Skyfall.IsFeatureEnabled("weather") then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    local dt = 0.20
    local started = Skyfall.ProfileStart("weather")
    for _, ship in pairs(world_ships or {}) do weather_force(ship, dt) end

    if Skyfall.Weather.lightning and CurTime() >= next_lightning then
        lightning_strike()
        next_lightning = CurTime() + math.Rand(6, Skyfall.Weather.type == "aether" and 11 or 16)
    end
    Skyfall.ProfileEnd("weather", started)
end

hook.Add("Think", "Skyfall Stormfront", function()
    if CurTime() < next_weather_tick then return end
    next_weather_tick = CurTime() + 0.20
    Skyfall.TickWeather()
end)

hook.Add("PlayerInitialSpawn", "Skyfall_SyncWeather", function(ply)
    timer.Simple(1, function() if IsValid(ply) then Skyfall.SyncWeather(ply) end end)
end)

hook.Add("AirWars_RoundStart", "Skyfall_AutoWeather", function()
    if Skyfall.Weather.type ~= "clear" then return end
    if math.Rand(0, 1) < 0.22 then
        local options = {"fog", "gale", "storm"}
        Skyfall.SetWeather(table.Random(options))
    else
        Skyfall.SyncWeather()
    end
end)

hook.Add("AirWars_RoundEnd", "Skyfall_ClearWeatherRoundEnd", function()
    Skyfall.SetWeather("clear")
end)

concommand.Add("aw_weather", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local requested = string.lower(tostring(args[1] or ""))
    if requested == "" or requested == "list" then
        local text = "clear, fog, gale, storm, aether"
        if IsValid(ply) then ply:ChatPrint("Weather: " .. text) else print(text) end
        return
    end
    if requested == "random" then requested = table.Random({"clear", "fog", "gale", "storm", "aether"}) end
    local ok, message = Skyfall.SetWeather(requested)
    if not ok and IsValid(ply) then ply:ChatPrint(message) end
end)

Skyfall.SetFeatureEnabled("weather", true)
Skyfall.Info("Stormfront", "Wind, turbulence, fog, storm, and lightning simulation enabled")
