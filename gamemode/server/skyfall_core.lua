-- AirWars: Skyfall server foundation helpers.

Skyfall = Skyfall or {}
Skyfall.Runtime = Skyfall.Runtime or {}
Skyfall.Runtime.rate_limits = Skyfall.Runtime.rate_limits or {}
Skyfall.Runtime.profile = Skyfall.Runtime.profile or {}

local LEVELS = {
    debug = 1,
    info = 2,
    warn = 3,
    error = 4
}

local function configured_level()
    local name = string.lower(tostring(Skyfall.GetConfig("debug.level", "info")))
    return LEVELS[name] or LEVELS.info
end

function Skyfall.Log(level, scope, message, ...)
    if not Skyfall.GetConfig("debug.enabled", true) then return end

    level = string.lower(tostring(level or "info"))
    local level_value = LEVELS[level] or LEVELS.info
    if level_value < configured_level() then return end

    local formatted = tostring(message or "")
    local args = {...}
    if #args > 0 then
        local ok, result = pcall(string.format, formatted, unpack(args))
        if ok then formatted = result end
    end

    local prefix = "[AirWars: Skyfall][" .. string.upper(level) .. "]"
    if scope and scope ~= "" then
        prefix = prefix .. "[" .. tostring(scope) .. "]"
    end

    MsgC(Color(215, 170, 80), prefix .. " ", color_white, formatted .. "\n")
end

function Skyfall.Debug(scope, message, ...)
    Skyfall.Log("debug", scope, message, ...)
end

function Skyfall.Info(scope, message, ...)
    Skyfall.Log("info", scope, message, ...)
end

function Skyfall.Warn(scope, message, ...)
    Skyfall.Log("warn", scope, message, ...)
end

function Skyfall.Error(scope, message, ...)
    Skyfall.Log("error", scope, message, ...)
end

local function player_key(ply)
    if not IsValid(ply) then return "server" end
    local steam_id = ply:SteamID64()
    if steam_id and steam_id ~= "0" then return steam_id end
    return "entity:" .. ply:EntIndex()
end

-- Simple per-player/per-action cooldown. This is intentionally conservative:
-- it prevents accidental or malicious net-message spam without changing normal
-- UI responsiveness.
function Skyfall.AllowAction(ply, action, interval)
    if not IsValid(ply) then return true end

    interval = tonumber(interval) or 0
    if interval <= 0 then return true end

    local key = player_key(ply)
    Skyfall.Runtime.rate_limits[key] = Skyfall.Runtime.rate_limits[key] or {}
    local bucket = Skyfall.Runtime.rate_limits[key]
    local now = CurTime()
    local next_allowed = bucket[action] or 0

    if now < next_allowed then
        return false
    end

    bucket[action] = now + interval
    return true
end

function Skyfall.ValidateIndex(tbl, index)
    return istable(tbl) and isnumber(index) and index >= 1 and index <= #tbl and tbl[index] ~= nil
end

function Skyfall.ValidatePlayerEntity(ent)
    return IsValid(ent) and ent:IsPlayer()
end

function Skyfall.ProfileStart(name)
    if not SysTime then return nil end
    return SysTime()
end

function Skyfall.ProfileEnd(name, started)
    if not started or not SysTime then return 0 end
    local elapsed = SysTime() - started
    local profile = Skyfall.Runtime.profile
    profile[name] = profile[name] or {count = 0, total = 0, max = 0}
    local entry = profile[name]
    entry.count = entry.count + 1
    entry.total = entry.total + elapsed
    entry.max = math.max(entry.max, elapsed)
    return elapsed
end

function Skyfall.GetProfileSnapshot()
    local result = {}
    for name, entry in pairs(Skyfall.Runtime.profile) do
        result[name] = {
            count = entry.count,
            total = entry.total,
            max = entry.max,
            average = entry.count > 0 and (entry.total / entry.count) or 0
        }
    end
    return result
end

hook.Add("PlayerDisconnected", "Skyfall_ClearRateLimits", function(ply)
    Skyfall.Runtime.rate_limits[player_key(ply)] = nil
end)

Skyfall.Info("Foundation", "Skyfall server core initialized (%s)", Skyfall.Version or "dev")
