-- AirWars: Skyfall persistent blueprint and prefab system.

local BLUEPRINT_VERSION = 1
local ROOT = "airwars_skyfall/blueprints"
file.CreateDir("airwars_skyfall")
file.CreateDir(ROOT)

local function build_phase()
    return istable(game_state) and game_state.state ~= GAME_STATE_FIGHT
end

local function safe_name(name)
    name = string.Trim(string.lower(tostring(name or "")))
    name = string.gsub(name, "[^%w_%- ]", "")
    name = string.gsub(name, "%s+", "_")
    return string.sub(name, 1, 32)
end

local function user_dir(ply)
    local id = IsValid(ply) and ply:SteamID64() or "server"
    local dir = ROOT .. "/" .. id
    file.CreateDir(dir)
    return dir
end

local function vec_to_table(vec)
    return {x = vec.x, y = vec.y, z = vec.z}
end

local function ang_to_table(ang)
    return {p = ang.p, y = ang.y, r = ang.r}
end

local function table_to_vec(data)
    if not istable(data) then return nil end
    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    if not x or not y or not z then return nil end
    return Vector(x, y, z)
end

local function table_to_ang(data)
    if not istable(data) then return Angle() end
    return Angle(tonumber(data.p) or 0, tonumber(data.y) or 0, tonumber(data.r) or 0)
end

local function definition(category, index)
    local cat = global_config.categories and global_config.categories[category]
    return cat and cat.props and cat.props[index] or nil
end

local function team_build_props(team_id)
    local result = {}
    for _, ent in ipairs(ents.FindByClass("aw_building_prop")) do
        if IsValid(ent) and ent.GetAWTeam and ent:GetAWTeam() == team_id then
            table.insert(result, ent)
        end
    end
    return result
end

local function clear_build(team_id)
    local removed = 0
    for _, ent in ipairs(team_build_props(team_id)) do
        ent:Remove()
        removed = removed + 1
    end
    return removed
end

local function resolve_descriptor(desc)
    if not istable(desc) then return nil end
    local category = tonumber(desc.category)
    if not category then return nil end

    local index = Skyfall.ResolveBuildPartIndex(desc)
    if not index or not definition(category, index) then return nil end

    local pos = isvector(desc.pos) and desc.pos or table_to_vec(desc.pos)
    local ang = isangle(desc.ang) and desc.ang or table_to_ang(desc.ang)
    if not pos then return nil end
    if pos:Length() > 360 then return nil end

    return {
        category = category,
        index = index,
        pos = pos,
        ang = ang,
        definition = definition(category, index)
    }
end

function Skyfall.ValidateBuildDescriptors(parts)
    if not istable(parts) or #parts == 0 then return false, "No parts" end
    if #parts > global_config.prop_limit then
        return false, "Part count exceeds server limit"
    end

    local resolved = {}
    local cost = 0
    for i, desc in ipairs(parts) do
        local item = resolve_descriptor(desc)
        if not item then return false, "Invalid part descriptor #" .. i end
        cost = cost + (tonumber(item.definition.info and item.definition.info.cost) or 0)
        if cost > global_config.max_founds then
            return false, "Blueprint exceeds ship budget"
        end
        table.insert(resolved, item)
    end
    return true, resolved, cost
end

function Skyfall.SpawnBuildDescriptors(ply, parts, origin, clear_existing)
    if not IsValid(ply) or not build_phase() then return false, "Not available during combat" end
    local ok, resolved, cost = Skyfall.ValidateBuildDescriptors(parts)
    if not ok then return false, resolved end

    local team_id = ply:GetAWTeam()
    if not aw_teams_list[team_id] then return false, "No valid team" end
    if clear_existing ~= false then clear_build(team_id) end

    origin = origin or (ply:GetPos() + ply:GetForward() * 320 + Vector(0, 0, 48))
    local spawned = 0
    for _, item in ipairs(resolved) do
        local ent = AirWars:SpawnProp(origin + item.pos, item.ang, item.category, item.index, ply, true)
        if IsValid(ent) then spawned = spawned + 1 end
    end

    return spawned == #resolved, string.format("Spawned %d/%d parts (%d funds)", spawned, #resolved, cost), spawned
end

function Skyfall.GetBuildStats(team_id)
    local stats = {parts = 0, cost = 0, weight = 0, force = 0, lift = 0, height = 0, weapons = 0}
    for _, ent in ipairs(team_build_props(team_id)) do
        stats.parts = stats.parts + 1
        stats.cost = stats.cost + (ent.info and tonumber(ent.info.cost) or 0)
        stats.weight = stats.weight + (ent.info and tonumber(ent.info.weight) or 0)
        stats.force = stats.force + (ent.custom_info and tonumber(ent.custom_info.force) or 0)
        stats.lift = stats.lift + (ent.custom_info and tonumber(ent.custom_info.lift_force) or 0)
        if ent.entity and string.StartWith(ent.entity, "aw_weapon") then stats.weapons = stats.weapons + 1 end
    end
    stats.height = math.Clamp(-stats.weight + stats.lift, 0, 1100) * 10
    return stats
end

concommand.Add("aw_blueprint_save", function(ply, _, args)
    if not IsValid(ply) or not build_phase() then return end
    local name = safe_name(table.concat(args, " "))
    if name == "" then ply:ChatPrint("Usage: aw_blueprint_save <name>") return end

    local props = team_build_props(ply:GetAWTeam())
    if #props == 0 then ply:ChatPrint("Build a ship before saving a blueprint.") return end

    local center = Vector()
    for _, ent in ipairs(props) do center = center + ent:GetPos() end
    center = center / #props

    local parts = {}
    for _, ent in ipairs(props) do
        local category, index = ent:GetCategory(), ent:GetProp()
        if not definition(category, index) then continue end
        table.insert(parts, {
            category = category,
            index = index,
            pos = vec_to_table(ent:GetPos() - center),
            ang = ang_to_table(ent:GetAngles())
        })
    end

    local blueprint = {
        schema = BLUEPRINT_VERSION,
        name = name,
        created = os.time(),
        skyfall_version = Skyfall.Version,
        parts = parts
    }

    local ok, reason = Skyfall.ValidateBuildDescriptors(parts)
    if not ok then ply:ChatPrint("Blueprint validation failed: " .. tostring(reason)) return end

    file.Write(user_dir(ply) .. "/" .. name .. ".json", util.TableToJSON(blueprint, true))
    ply:ChatPrint("Saved blueprint '" .. name .. "' with " .. #parts .. " parts.")
end)

concommand.Add("aw_blueprint_load", function(ply, _, args)
    if not IsValid(ply) or not build_phase() then return end
    local name = safe_name(table.concat(args, " "))
    if name == "" then ply:ChatPrint("Usage: aw_blueprint_load <name>") return end

    local path = user_dir(ply) .. "/" .. name .. ".json"
    if not file.Exists(path, "DATA") then ply:ChatPrint("Blueprint not found: " .. name) return end
    local blueprint = util.JSONToTable(file.Read(path, "DATA") or "")
    if not blueprint or tonumber(blueprint.schema) ~= BLUEPRINT_VERSION then
        ply:ChatPrint("Blueprint is invalid or uses an unsupported schema.")
        return
    end

    local ok, message = Skyfall.SpawnBuildDescriptors(ply, blueprint.parts, nil, true)
    ply:ChatPrint((ok and "Loaded " or "Failed to load ") .. name .. ": " .. tostring(message))
end)

concommand.Add("aw_blueprint_list", function(ply)
    if not IsValid(ply) then return end
    local files = file.Find(user_dir(ply) .. "/*.json", "DATA")
    if #files == 0 then ply:ChatPrint("No saved Skyfall blueprints.") return end
    for _, filename in ipairs(files) do
        ply:ChatPrint("- " .. string.StripExtension(filename))
    end
end)

concommand.Add("aw_blueprint_delete", function(ply, _, args)
    if not IsValid(ply) then return end
    local name = safe_name(table.concat(args, " "))
    if name == "" then return end
    local path = user_dir(ply) .. "/" .. name .. ".json"
    if file.Exists(path, "DATA") then
        file.Delete(path)
        ply:ChatPrint("Deleted blueprint '" .. name .. "'.")
    end
end)

concommand.Add("aw_prefab", function(ply, _, args)
    if not IsValid(ply) or not build_phase() then return end
    local id = string.lower(tostring(args[1] or ""))
    if id == "" or id == "list" then
        ply:ChatPrint("Skyfall prefab ships:")
        for key, prefab in SortedPairs(Skyfall.Prefabs or {}) do
            ply:ChatPrint(string.format("- %s: %s (crew %s)", key, prefab.name, prefab.recommended_crew or "?"))
        end
        return
    end

    local prefab = Skyfall.Prefabs[id]
    if not prefab then ply:ChatPrint("Unknown prefab. Use aw_prefab list") return end
    local ok, message = Skyfall.SpawnBuildDescriptors(ply, prefab.parts, nil, true)
    ply:ChatPrint((ok and "Loaded " or "Failed to load ") .. prefab.name .. ": " .. tostring(message))
end)

concommand.Add("aw_shipstats", function(ply)
    if not IsValid(ply) then return end
    if build_phase() then
        local s = Skyfall.GetBuildStats(ply:GetAWTeam())
        ply:PrintMessage(HUD_PRINTCONSOLE, string.format("[Skyfall Shipwright] parts=%d cost=%d/%d weight=%.1f propulsion=%.1f lift=%.1f ceiling=%.0f weapons=%d", s.parts, s.cost, global_config.max_founds, s.weight, s.force, s.lift, s.height, s.weapons))
        return
    end

    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship then return end
    local summary = Skyfall.GetShipComponentSummary(ship)
    ply:PrintMessage(HUD_PRINTCONSOLE, string.format("[Skyfall Shipwright] active=%d destroyed=%d health=%.0f/%.0f weight=%.1f propulsion=%.1f lift=%.1f", table.Count(ship.parts or {}), table.Count(ship.destroyed_parts or {}), summary.health, summary.max_health, fight_calculate_ship_weight(ship), fight_calculate_ship_force(ship), fight_calculate_ship_lift_force(ship)))
end)

Skyfall.SetFeatureEnabled("blueprints", true)
Skyfall.SetFeatureEnabled("prefab_ships", true)
Skyfall.Info("Shipwright", "Blueprint persistence and prefab ship library enabled")
