-- AirWars: Skyfall Alliance mode: PvE missions, virtual AI airships, and logical AI crew.

Skyfall.AIShips = Skyfall.AIShips or {}
Skyfall.Mission = Skyfall.Mission or {active = false}

local next_ai_id = -1000
local next_ai_think = 0
local next_mission_tick = 0

local MISSION_LABELS = {
    hunt = "Airship Hunt",
    fortress = "Fortress Assault",
    survival = "Survival",
    convoy = "Convoy Escort",
    salvage = "Salvage Run",
    boss = "Leviathan Hunt"
}

local function alloc_ai_id()
    while world_ships and world_ships[next_ai_id] do
        next_ai_id = next_ai_id - 1
        if next_ai_id < -30000 then next_ai_id = -1000 end
    end
    local id = next_ai_id
    next_ai_id = next_ai_id - 1
    return id
end

local function player_ship_count()
    local count = 0
    for _, ship in pairs(world_ships or {}) do
        if ship.faction == "player" then count = count + 1 end
    end
    return count
end

local function copy_vector(v)
    return Vector(v.x, v.y, v.z)
end

function Skyfall.SpawnAIShip(prefab_id, options)
    options = options or {}
    local prefab = Skyfall.Prefabs[prefab_id]
    if not prefab then return nil, "Unknown prefab " .. tostring(prefab_id) end

    local id = alloc_ai_id()
    local ship = AirWars:CreateShip(id, {
        faction = options.faction or "enemy",
        ai_controlled = true,
        position = options.position or AirWars:GetRandomPosition(4800),
        angles = options.angles or Angle()
    })
    if not ship then return nil, "Could not create AI ship" end

    ship.ai_controlled = true
    ship.ai_stationary = options.stationary == true
    ship.ai_passive = options.passive == true
    ship.ai_skill = math.Clamp(tonumber(options.skill) or 1, 0.35, 2.5)
    ship.ai_repair = math.Clamp(tonumber(options.repair) or 1, 0, 3)
    ship.ai_damage = math.Clamp(tonumber(options.damage) or 1, 0.2, 3)
    ship.ai_name = options.name or ((options.faction == "ally" and "Escort ") or "Hostile ") .. prefab.name
    ship.prefab_id = prefab_id
    ship.mission_ship = options.mission_ship == true

    local health_scale = math.Clamp(tonumber(options.health) or 1, 0.25, 6)
    for _, descriptor in ipairs(prefab.parts) do
        local index = Skyfall.ResolveBuildPartIndex(descriptor)
        local definition = index and global_config.categories[descriptor.category] and global_config.categories[descriptor.category].props[index]
        if not definition then continue end

        local part = Part:new(id)
        part.position = copy_vector(descriptor.pos)
        part.angle = Angle(descriptor.ang.p, descriptor.ang.y, descriptor.ang.r)
        part.model = definition.model
        part.aw_team = id
        part.ship_id = id
        part.entity = definition.entity
        part.info = table.Copy(definition.info or {})
        part.custom_info = table.Copy(definition.custom_info or {})
        if part.custom_info.damage then part.custom_info.damage = part.custom_info.damage * ship.ai_damage end
        part.max_health = math.max(1, (tonumber(part.info.health) or 100) * health_scale)
        part.health = part.max_health
        part.component_type = Skyfall.GetComponentType(part.entity, part.custom_info)
        local explicit_armor = tonumber(part.info.armor)
        part.armor = explicit_armor ~= nil and explicit_armor or Skyfall.DefaultArmorForPart(part)
        ship:AddPart(part)
    end

    ship:UpdateCenter()
    ship:UpdateMinMax()
    AirWars:BuildShipProps(ship)
    ship:Sync()
    Skyfall.AIShips[id] = ship
    hook.Run("Skyfall_AIShipSpawned", ship)
    return ship
end

local function candidate_target(ship)
    local best, best_distance
    for _, candidate in pairs(world_ships or {}) do
        if candidate == ship or not candidate.position then continue end

        local hostile = false
        if ship.faction == "enemy" then
            hostile = candidate.faction == "player" or candidate.faction == "ally"
        elseif ship.faction == "ally" then
            hostile = candidate.faction == "enemy"
        end
        if not hostile then continue end

        local distance = ship.position:DistToSqr(candidate.position)
        if not best_distance or distance < best_distance then
            best = candidate
            best_distance = distance
        end
    end
    return best, best_distance and math.sqrt(best_distance) or nil
end

local function steer_ai(ship, target)
    if ship.ai_stationary or not target then
        ship.direction.direction.x = 0
        ship.direction.direction.z = 0
        ship.direction.angle.y = 0
        return
    end

    local delta = target.position - ship.position
    local desired_yaw = delta:Angle().y + 90
    local yaw_difference = math.AngleDifference(desired_yaw, ship.angles.y)
    ship.direction.direction.x = math.abs(yaw_difference) < 110 and 1 or 0.35
    ship.direction.angle.y = math.abs(yaw_difference) < 4 and 0 or (yaw_difference > 0 and 1 or -1)

    local vertical = delta.z
    if vertical > 350 then
        ship.direction.direction.z = 1
    elseif vertical < -350 then
        ship.direction.direction.z = -1
    else
        ship.direction.direction.z = 0
    end
end

local function profile_cooldown(part)
    local id = part.custom_info and part.custom_info.skyfall_weapon_profile
    local profile = id and Skyfall.GetWeaponProfile(id)
    if profile then return tonumber(profile.cooldown) or 1 end
    if part.entity == "aw_weapon_rifle" then return 0.25 end
    if part.entity == "aw_weapon_bomb" then return 3 end
    return 1.8
end

local function fire_ai(ship, target, distance)
    if ship.ai_passive or not target or not distance or distance > 8500 then return end

    for _, weapon in pairs(ship.parts or {}) do
        if weapon.component_type ~= Skyfall.ComponentTypes.WEAPON or weapon.disabled then continue end
        if CurTime() < (weapon.ai_next_fire or 0) then continue end
        if not weapon.custom_info or not weapon.custom_info.damage then continue end

        local desired_global = (ship.position - target.position):Angle()
        local local_angle = desired_global - ship.angles
        local aim_error = math.max(0.4, 5 / ship.ai_skill)
        local_angle.p = local_angle.p + math.Rand(-aim_error, aim_error)
        local_angle.y = local_angle.y + math.Rand(-aim_error, aim_error)
        local extra = local_angle - weapon.angle

        AirWars:ShipShoot(ship, weapon, 70, extra, nil)
        weapon.ai_next_fire = CurTime() + profile_cooldown(weapon) / ship.ai_skill / math.max(0.25, Skyfall.GetPartEffectiveness(weapon))
    end
end

local function ai_engineering(ship)
    if ship.ai_repair <= 0 then return end
    if CurTime() < (ship.ai_next_repair or 0) then return end
    ship.ai_next_repair = CurTime() + math.max(0.65, 1.5 / ship.ai_repair)

    local worst, worst_fraction = nil, 2
    for _, part in pairs(ship.parts or {}) do
        if (part.fire_stacks or 0) > 0 then
            part:SetFireStacks(math.max(0, part.fire_stacks - math.max(1, math.floor(ship.ai_repair))))
            return
        end
        local fraction = Skyfall.GetPartHealthFraction(part)
        if fraction < worst_fraction then worst, worst_fraction = part, fraction end
    end

    if worst and worst_fraction < 0.96 then
        worst:AddHealth(4.5 * ship.ai_repair, "AI engineer")
        return
    end

    if table.Count(ship.destroyed_parts or {}) > 0 and CurTime() >= (ship.ai_next_rebuild or 0) then
        for part_id in pairs(ship.destroyed_parts) do
            ship.ai_next_rebuild = CurTime() + 10 / ship.ai_repair
            AirWars:RebuildPart(ship, part_id, "AI engineer")
            break
        end
    end
end

function Skyfall.TickAIShips()
    if not Skyfall.IsFeatureEnabled("pve") or not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
    local started = Skyfall.ProfileStart("ai_ships")

    for id, ship in pairs(Skyfall.AIShips) do
        if world_ships[id] ~= ship then
            Skyfall.AIShips[id] = nil
            continue
        end
        local target, distance = candidate_target(ship)
        steer_ai(ship, target)
        fire_ai(ship, target, distance)
        ai_engineering(ship)
    end

    Skyfall.ProfileEnd("ai_ships", started)
end

local function mission_payload()
    local m = Skyfall.Mission or {}
    return {
        active = m.active == true,
        type = m.type or "",
        label = m.label or "",
        status = m.status or "",
        objective = m.objective or "",
        wave = m.wave or 0,
        waves = m.waves or 0,
        score = m.score or 0,
        time_left = m.time_left or 0
    }
end

function Skyfall.SyncMission(recipients)
    net.Start("aw_skyfall_mission")
    net.WriteTable(mission_payload())
    if recipients then net.Send(recipients) else net.Broadcast() end
end

local function mission_notice(text)
    for _, ply in ipairs(player.GetAll()) do ply:ChatPrint("[Skyfall Alliance] " .. text) end
end

local function add_enemy(ship)
    if ship then Skyfall.Mission.enemy_ids[ship.id] = true end
end

local function spawn_enemy_group(count, prefab, options)
    for i = 1, count do
        local opts = table.Copy(options or {})
        opts.faction = "enemy"
        opts.mission_ship = true
        opts.position = opts.position or Vector(math.Rand(-4500, 4500), math.Rand(-4500, 4500), math.Rand(700, 2200))
        opts.name = opts.name or (MISSION_LABELS[Skyfall.Mission.type] .. " Hostile " .. i)
        add_enemy(Skyfall.SpawnAIShip(prefab, opts))
    end
end

local function active_ids(id_table)
    local count = 0
    for id in pairs(id_table or {}) do
        if world_ships and world_ships[id] then count = count + 1 else id_table[id] = nil end
    end
    return count
end

local function begin_objective()
    local m = Skyfall.Mission
    local player_scale = math.max(1, #player.GetAll())

    if m.type == "hunt" then
        m.objective = "Destroy the hostile airship squadron."
        spawn_enemy_group(math.Clamp(math.ceil(player_scale / 2), 1, 4), player_scale >= 5 and "frigate" or "cutter", {skill = 0.9 + player_scale * 0.04, repair = 0.7})
    elseif m.type == "fortress" then
        m.objective = "Destroy the fortified sky platform."
        local fortress = Skyfall.SpawnAIShip("dreadnought", {faction = "enemy", stationary = true, mission_ship = true, position = Vector(0, 3600, 1400), health = 1.65, damage = 1.05, skill = 0.95, repair = 1.1, name = "Aerial Bastion"})
        add_enemy(fortress)
    elseif m.type == "survival" then
        m.wave = 1
        m.waves = 4
        m.objective = "Survive four escalating hostile waves."
        spawn_enemy_group(1, "cutter", {skill = 0.8, repair = 0.5})
    elseif m.type == "convoy" then
        m.objective = "Escort the allied frigate to the extraction corridor."
        local convoy = Skyfall.SpawnAIShip("frigate", {faction = "ally", passive = true, mission_ship = true, position = Vector(-5000, 0, 1000), health = 1.35, repair = 1.1, name = "Merchant Escort"})
        if convoy then
            m.convoy_id = convoy.id
            m.convoy_goal = Vector(5000, 0, 1000)
        end
        spawn_enemy_group(math.Clamp(math.ceil(player_scale / 2), 1, 3), "cutter", {skill = 0.85, repair = 0.5})
    elseif m.type == "salvage" then
        m.objective = "Approach and recover three drifting wrecks."
        m.salvage_ids = {}
        m.salvage_target = 3
        m.salvage_count = 0
        for i = 1, 3 do
            local salvage = Skyfall.SpawnAIShip("cutter", {faction = "salvage", passive = true, stationary = true, mission_ship = true, position = Vector(-2600 + i * 1800, (i % 2 == 0) and 2200 or -2200, 900 + i * 200), health = 0.6, repair = 0, name = "Drifting Wreck " .. i})
            if salvage then m.salvage_ids[salvage.id] = true end
        end
        spawn_enemy_group(1, "cutter", {skill = 0.8, repair = 0.4})
    elseif m.type == "boss" then
        m.objective = "Destroy the Leviathan-class flagship."
        local boss = Skyfall.SpawnAIShip("dreadnought", {faction = "enemy", mission_ship = true, position = Vector(0, 4200, 1600), health = 2.5 + player_scale * 0.12, damage = 1.2, skill = 1.15, repair = 1.5, name = "LEVIATHAN"})
        add_enemy(boss)
    end

    Skyfall.SyncMission()
    mission_notice(m.objective)
end

function Skyfall.StartMission(mission_type)
    mission_type = string.lower(tostring(mission_type or "hunt"))
    if not MISSION_LABELS[mission_type] then return false, "Unknown mission type" end
    if Skyfall.Mission.active then return false, "A mission is already active" end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then return false, "Start missions during the build phase" end

    local has_build = #ents.FindByClass("aw_building_prop") > 0
    if not has_build then return false, "Build or load at least one player ship first" end

    Skyfall.Mission = {
        active = true,
        type = mission_type,
        label = MISSION_LABELS[mission_type],
        status = "active",
        objective = "Preparing mission...",
        started_at = CurTime(),
        time_left = mission_type == "convoy" and 300 or (mission_type == "survival" and 420 or 600),
        score = 0,
        enemy_ids = {},
        salvage_ids = {}
    }

    AirWars:StartRound()
    timer.Simple(0.75, function()
        if Skyfall.Mission.active then begin_objective() end
    end)
    Skyfall.SyncMission()
    return true, "Started " .. MISSION_LABELS[mission_type]
end

local function cleanup_mission_ships()
    local ids = {}
    for id, ship in pairs(world_ships or {}) do
        if ship.mission_ship then table.insert(ids, id) end
    end
    for _, id in ipairs(ids) do
        local ship = world_ships[id]
        if ship then AirWars:DestroyShip(ship) end
    end
end

function Skyfall.EndMission(success, reason, skip_reset)
    if not Skyfall.Mission.active then return end
    local label = Skyfall.Mission.label or "Mission"
    Skyfall.Mission.active = false
    Skyfall.Mission.status = success and "victory" or "failed"
    Skyfall.Mission.objective = reason or (success and "Mission complete." or "Mission failed.")
    Skyfall.SyncMission()

    mission_notice(label .. (success and " complete! " or " failed. ") .. tostring(reason or ""))
    if success then
        for _, ply in ipairs(player.GetAll()) do
            if ply.AddPoints then ply:AddPoints(15) end
        end
    end

    cleanup_mission_ships()
    if not skip_reset then
        timer.Simple(4, function()
            if istable(game_state) and game_state.state == GAME_STATE_FIGHT then AirWars:ResetRound() end
        end)
    end
end

local function convoy_tick(m)
    local convoy = world_ships and world_ships[m.convoy_id]
    if not convoy then Skyfall.EndMission(false, "The convoy was destroyed.") return end
    if not m.convoy_goal then return end

    local delta = m.convoy_goal - convoy.position
    if delta:Length() < 500 then
        Skyfall.EndMission(true, "The convoy reached the extraction corridor.")
        return
    end

    local ghost_target = {position = m.convoy_goal}
    steer_ai(convoy, ghost_target)
    if active_ids(m.enemy_ids) == 0 then
        spawn_enemy_group(1, "cutter", {skill = 0.9 + (300 - m.time_left) / 1000, repair = 0.5})
    end
end

local function salvage_tick(m)
    local recovered
    for id in pairs(m.salvage_ids or {}) do
        local salvage = world_ships and world_ships[id]
        if not salvage then
            m.salvage_ids[id] = nil
            continue
        end
        for _, player_ship in pairs(world_ships or {}) do
            if player_ship.faction == "player" and player_ship.position and player_ship.position:DistToSqr(salvage.position) <= (800 * 800) then
                m.salvage_ids[id] = nil
                m.salvage_count = (m.salvage_count or 0) + 1
                m.score = (m.score or 0) + 1
                AirWars:DestroyShip(salvage)
                recovered = true
                mission_notice(string.format("Salvage recovered (%d/%d)", m.salvage_count, m.salvage_target))
                break
            end
        end
    end
    if recovered then Skyfall.SyncMission() end
    if (m.salvage_count or 0) >= (m.salvage_target or 3) then
        Skyfall.EndMission(true, "All salvage secured.")
    elseif active_ids(m.enemy_ids) == 0 then
        spawn_enemy_group(1, "cutter", {skill = 0.85, repair = 0.4})
    end
end

function Skyfall.TickMission()
    local m = Skyfall.Mission
    if not m.active then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    m.time_left = math.max(0, (m.time_left or 0) - 1)
    if m.time_left <= 0 then Skyfall.EndMission(false, "Time expired.") return end

    local enemies = active_ids(m.enemy_ids)
    if m.type == "hunt" or m.type == "fortress" or m.type == "boss" then
        if enemies == 0 then Skyfall.EndMission(true, "All mission targets destroyed.") return end
    elseif m.type == "survival" then
        if enemies == 0 then
            if (m.wave or 1) >= (m.waves or 4) then
                Skyfall.EndMission(true, "All hostile waves defeated.")
                return
            end
            m.wave = (m.wave or 1) + 1
            spawn_enemy_group(math.min(4, m.wave), m.wave >= 3 and "frigate" or "cutter", {skill = 0.75 + m.wave * 0.12, repair = 0.4 + m.wave * 0.2, health = 0.9 + m.wave * 0.1})
            mission_notice("Wave " .. m.wave .. " incoming!")
        end
    elseif m.type == "convoy" then
        convoy_tick(m)
    elseif m.type == "salvage" then
        salvage_tick(m)
    end

    Skyfall.SyncMission()
end

hook.Add("Skyfall_ShipDestroyed", "Skyfall_AllianceDestroyedShip", function(ship)
    Skyfall.AIShips[ship.id] = nil
    local m = Skyfall.Mission
    if not m.active then return end
    if m.enemy_ids then m.enemy_ids[ship.id] = nil end
    if m.convoy_id == ship.id then
        timer.Simple(0, function() if Skyfall.Mission.active then Skyfall.EndMission(false, "The convoy was destroyed.") end end)
    end
end)

hook.Add("Think", "Skyfall Alliance AI", function()
    local now = CurTime()
    if now >= next_ai_think then
        next_ai_think = now + 0.20
        Skyfall.TickAIShips()
    end
    if now >= next_mission_tick then
        next_mission_tick = now + 1
        Skyfall.TickMission()
    end
end)

concommand.Add("aw_pve_start", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local mission_type = tostring(args[1] or "hunt")
    local ok, message = Skyfall.StartMission(mission_type)
    if IsValid(ply) then ply:ChatPrint(message) else print("[Skyfall Alliance] " .. message) end
end)

concommand.Add("aw_pve_stop", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    Skyfall.EndMission(false, "Mission aborted by administrator.")
end)

concommand.Add("aw_pve_list", function(ply)
    local text = "hunt, fortress, survival, convoy, salvage, boss"
    if IsValid(ply) then ply:ChatPrint("Alliance missions: " .. text) else print(text) end
end)

Skyfall.SetFeatureEnabled("pve", true)
Skyfall.SetFeatureEnabled("ai_crew", true)
Skyfall.Info("Alliance", "PvE missions, AI airships, and logical AI crew enabled")
