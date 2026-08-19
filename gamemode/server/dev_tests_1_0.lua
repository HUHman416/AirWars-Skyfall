-- AirWars: Skyfall 1.0 integration test suite.
-- Complements the v0.1 Resurrection harness with checks for every Skyfall milestone.

local function authorized(ply)
    return not IsValid(ply) or ply:IsAdmin()
end

local function reply(ply, text)
    local line = "[AirWars: Skyfall 1.0 Test] " .. tostring(text)
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, line) else print(line) end
end

local function run_integration_checks(ply)
    local pass, warn, fail = 0, 0, 0

    local function result(level, name, detail)
        if level == "PASS" then pass = pass + 1 elseif level == "WARN" then warn = warn + 1 else fail = fail + 1 end
        reply(ply, string.format("[%s] %s%s", level, name, detail and (" - " .. tostring(detail)) or ""))
    end

    local function check(name, condition, detail)
        result(condition and "PASS" or "FAIL", name, detail)
    end

    reply(ply, "=== 1.0 integration suite ===")
    check("Skyfall namespace", istable(Skyfall))
    check("Skyfall version", isstring(Skyfall.Version), Skyfall.Version)
    check("Skyfall config", istable(Skyfall.Config))
    check("server core logger", isfunction(Skyfall.Log))
    check("rate limiter", isfunction(Skyfall.AllowAction))
    check("profiler", isfunction(Skyfall.GetProfileSnapshot))

    local required_features = {
        "crew_specialties", "component_engineering", "fire_and_armor", "blueprints",
        "prefab_ships", "pve", "ai_crew", "boarding", "weather", "tutorials"
    }
    for _, name in ipairs(required_features) do
        if Skyfall.Config.features[name] == nil then
            result("FAIL", "feature flag " .. name, "missing")
        elseif Skyfall.Config.features[name] then
            result("PASS", "feature flag " .. name, "enabled")
        else
            result("WARN", "feature flag " .. name, "disabled by server configuration")
        end
    end

    local roles = {"crew", "pilot", "engineer", "gunner"}
    for _, role in ipairs(roles) do check("crew role " .. role, istable(Skyfall.Roles and Skyfall.Roles[role])) end

    local ammo_count = table.Count(Skyfall.AmmoTypes or {})
    check("ammunition families", ammo_count >= 8, ammo_count)
    for id, ammo in pairs(Skyfall.AmmoTypes or {}) do
        check("ammo " .. id .. " damage", isnumber(ammo.damage) and ammo.damage > 0, ammo.damage)
        check("ammo " .. id .. " cooldown", isnumber(ammo.cooldown) and ammo.cooldown > 0, ammo.cooldown)
    end

    local weapon_count = table.Count(Skyfall.WeaponProfiles or {})
    check("Skyfall weapon profiles", weapon_count >= 8, weapon_count)
    for id, profile in pairs(Skyfall.WeaponProfiles or {}) do
        check("weapon " .. id .. " model", isstring(profile.model) and profile.model ~= "")
        check("weapon " .. id .. " damage", isnumber(profile.damage) and profile.damage > 0, profile.damage)
        check("weapon " .. id .. " cost", isnumber(profile.cost) and profile.cost > 0, profile.cost)
    end

    check("generic weapon entity", scripted_ents.GetStored("aw_weapon_skyfall") ~= nil)
    check("Engineer Tool", weapons.GetStored("aw_engineer_tool") ~= nil)
    check("Sabotage Kit", weapons.GetStored("aw_sabotage_tool") ~= nil)

    local prefab_count = table.Count(Skyfall.Prefabs or {})
    check("prefab library", prefab_count >= 4, prefab_count)
    for id, prefab in pairs(Skyfall.Prefabs or {}) do
        local ok, resolved, cost = Skyfall.ValidateBuildDescriptors(prefab.parts)
        if ok then
            result("PASS", "prefab " .. id, string.format("%d parts / %d funds", #resolved, cost))
        else
            result("FAIL", "prefab " .. id, resolved)
        end
    end

    check("blueprint spawn API", isfunction(Skyfall.SpawnBuildDescriptors))
    check("build stats API", isfunction(Skyfall.GetBuildStats))
    check("AI ship API", isfunction(Skyfall.SpawnAIShip))
    check("mission API", isfunction(Skyfall.StartMission) and isfunction(Skyfall.EndMission))
    check("capture API", isfunction(Skyfall.CanCaptureShip) and isfunction(Skyfall.BeginCapture))
    check("grapple API", isfunction(Skyfall.AddGrapple) and isfunction(Skyfall.CutShipGrapples))
    check("weather API", isfunction(Skyfall.SetWeather) and isfunction(Skyfall.TickWeather))
    check("tutorial API", isfunction(Skyfall.SetTutorialStep))

    local extension_network = {"aw_skyfall_part_state", "aw_skyfall_spot", "aw_skyfall_mission", "aw_skyfall_weather", "aw_skyfall_notice"}
    for _, name in ipairs(extension_network) do
        check("net string " .. name, util.NetworkStringToID(name) ~= 0)
    end

    local convars = {
        "aw_skyfall_enable_pve", "aw_skyfall_enable_boarding", "aw_skyfall_enable_weather",
        "aw_skyfall_auto_weather", "aw_skyfall_enable_blueprints", "aw_skyfall_ai_difficulty"
    }
    for _, name in ipairs(convars) do check("server convar " .. name, GetConVar(name) ~= nil) end

    check("title cosmetics", table.Count(Skyfall.Titles or {}) >= 6, table.Count(Skyfall.Titles or {}))
    check("livery cosmetics", table.Count(Skyfall.Liveries or {}) >= 6, table.Count(Skyfall.Liveries or {}))

    if istable(Skyfall.Weather) then
        check("weather state", isstring(Skyfall.Weather.type), Skyfall.Weather.type)
    else
        result("FAIL", "weather state", "missing")
    end

    if Skyfall.Mission and Skyfall.Mission.active then
        result("PASS", "Alliance mission runtime", Skyfall.Mission.label or Skyfall.Mission.type)
    else
        result("WARN", "Alliance mission runtime", "no mission active; static API validated")
    end

    for id, ship in pairs(world_ships or {}) do
        check("ship " .. id .. " destroyed registry", istable(ship.destroyed_parts))
        check("ship " .. id .. " faction", isstring(ship.faction), ship.faction)
        for part_id, part in pairs(ship.parts or {}) do
            check("part " .. part_id .. " max health", isnumber(part.max_health) and part.max_health > 0, part.max_health)
            check("part " .. part_id .. " component type", isstring(part.component_type), part.component_type)
            check("part " .. part_id .. " armor", isnumber(part.armor), part.armor)
        end
    end

    reply(ply, string.format("=== 1.0 result: %d PASS / %d WARN / %d FAIL ===", pass, warn, fail))
    return fail == 0, pass, warn, fail
end

AirWars.RunSkyfall10Tests = run_integration_checks

concommand.Add("aw_test_suite", function(ply)
    if not authorized(ply) then return end
    reply(ply, "Running Resurrection smoke checks first...")
    local resurrection_ok = true
    if isfunction(AirWars.RunSkyfallSmokeTest) then
        resurrection_ok = select(1, AirWars:RunSkyfallSmokeTest(ply))
    else
        reply(ply, "[FAIL] Resurrection smoke test function missing")
        resurrection_ok = false
    end
    local integration_ok = select(1, run_integration_checks(ply))
    reply(ply, (resurrection_ok and integration_ok) and "FULL SUITE: PASS" or "FULL SUITE: FAIL — review entries above")
end)

concommand.Add("aw_test_shipwright", function(ply)
    if not authorized(ply) then return end
    for id, prefab in SortedPairs(Skyfall.Prefabs or {}) do
        local ok, resolved, cost = Skyfall.ValidateBuildDescriptors(prefab.parts)
        reply(ply, string.format("[%s] %s — %s", ok and "PASS" or "FAIL", id, ok and (#resolved .. " parts / " .. cost .. " funds") or tostring(resolved)))
    end
end)

concommand.Add("aw_test_firesteel", function(ply)
    if not authorized(ply) or not IsValid(ply) then return end
    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship then reply(ply, "[WARN] Start combat before the component mutation test") return end

    local part
    for _, candidate in pairs(ship.parts or {}) do part = candidate break end
    if not part then reply(ply, "[FAIL] No active component found") return end

    local health, fire, disabled, buff = part.health, part.fire_stacks, part.disabled, part.buff_until
    local applied = part:ApplyDamage(1, {kind = "component", penetration = 1, component_multiplier = 1}, "test")
    local damage_ok = applied > 0 and part.health < health
    part.health = health
    part.fire_stacks = fire
    part.disabled = disabled
    part.buff_until = buff
    part:SyncState()
    reply(ply, damage_ok and "[PASS] Armor/damage component path" or "[FAIL] Armor/damage component path")

    local previous_fire = part.fire_stacks or 0
    part:AddFireStacks(1)
    local fire_ok = (part.fire_stacks or 0) > previous_fire
    part:SetFireStacks(previous_fire)
    reply(ply, fire_ok and "[PASS] Fire-stack path" or "[FAIL] Fire-stack path")
end)

concommand.Add("aw_test_alliance", function(ply)
    if not authorized(ply) then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then
        reply(ply, "[WARN] Start combat before AI spawn validation")
        return
    end
    local origin = Vector(2500, 0, 1200)
    if IsValid(ply) and world_ships[ply:GetCurrentShip()] then origin = world_ships[ply:GetCurrentShip()].position + Vector(2500, 0, 0) end
    local ship, reason = Skyfall.SpawnAIShip("cutter", {faction = "enemy", passive = true, stationary = true, repair = 0, position = origin, name = "Automated Test Target"})
    if not ship then reply(ply, "[FAIL] AI spawn — " .. tostring(reason)) return end
    local ok = world_ships[ship.id] == ship and table.Count(ship.parts or {}) > 0
    reply(ply, ok and ("[PASS] AI ship spawned with " .. table.Count(ship.parts) .. " parts") or "[FAIL] AI ship registry/parts")
    AirWars:DestroyShip(ship)
end)

concommand.Add("aw_test_weather", function(ply)
    if not authorized(ply) then return end
    local original = Skyfall.Weather and Skyfall.Weather.type or "clear"
    local ok = Skyfall.SetWeather("storm")
    local state_ok = ok and Skyfall.Weather.type == "storm" and Skyfall.Weather.lightning == true and Skyfall.Weather.strength > 0
    reply(ply, state_ok and "[PASS] Stormfront state/network path" or "[FAIL] Stormfront state path")
    Skyfall.SetWeather(original)
end)

concommand.Add("aw_test_boarding", function(ply)
    if not authorized(ply) then return end
    local ships = {}
    for _, ship in pairs(world_ships or {}) do table.insert(ships, ship) end
    if #ships < 2 then
        reply(ply, "[WARN] Boarding runtime test needs two active ships; APIs are available")
        return
    end
    local grapple = Skyfall.AddGrapple(ships[1].id, ships[2].id, 1, 0.1)
    local ok = grapple and Skyfall.Grapples[grapple.id] ~= nil
    if grapple then Skyfall.RemoveGrapple(grapple.id, "integration test") end
    reply(ply, ok and "[PASS] Grapple lifecycle" or "[FAIL] Grapple lifecycle")
end)

concommand.Add("aw_test_buildship_full", function(ply)
    if not authorized(ply) or not IsValid(ply) then return end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then
        reply(ply, "Reset to BUILDING first")
        return
    end
    local ok, message = Skyfall.SpawnBuildDescriptors(ply, Skyfall.Prefabs.frigate.parts, nil, true)
    reply(ply, (ok and "[PASS] " or "[FAIL] ") .. tostring(message))
end)
