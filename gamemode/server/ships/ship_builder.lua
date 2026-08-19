function AirWars:BuildShipPart(ship, part)
    if not istable(ship) or not istable(part) then return nil end

    local ent = ents.Create(part.entity or "aw_part")
    if not IsValid(ent) then
        Skyfall.Error("Ship", "Failed to create entity %s for part %s", tostring(part.entity or "aw_part"), tostring(part.id))
        return nil
    end

    ent:SetPos(part.position + global_config.world_center - ship.center)
    ent:SetModel(part.model)
    ent:SetAngles(part.angle)
    ent.part_id = part.id
    ent:SetAWTeam(part.aw_team or ship.id)
    ent:Spawn()
    ent:Activate()
    ent.ship_collision = true
    if ent.SetPartID then ent:SetPartID(part.id) end

    local model_bounds_max, model_bounds_min, center = ent:OBBMaxs(), ent:OBBMins(), ent:OBBCenter()
    part.collision_bounds = {model_bounds_max, model_bounds_min, center}
    part.combat_position = ent:GetPos()

    if part.SyncState then part:SyncState() end
    return ent
end

function AirWars:BuildShipProps(ship)
    for _, part in pairs(ship.parts or {}) do
        AirWars:BuildShipPart(ship, part)
    end
end

local function setup_part(entity, ship)
    if not IsValid(entity) or not istable(entity.info) then return nil end

    local part = Part:new(ship.id)
    part.position = entity:GetPos()
    part.angle = entity:GetAngles()
    part.model = entity:GetModel()
    part.aw_team = ship.id
    part.ship_id = ship.id
    part.entity = entity.entity
    part.custom_info = entity.custom_info or {}
    part.info = entity.info or {}
    part.max_health = math.max(1, tonumber(part.info.health) or 100)
    part.health = part.max_health
    part.component_type = Skyfall.GetComponentType(part.entity, part.custom_info)
    part.armor = tonumber(part.info.armor) or 0

    ship:AddPart(part)
    return part
end

local function create_player_ships()
    for _, ply in ipairs(player.GetAll()) do
        local team_id = ply:GetAWTeam()
        if not world_ships[team_id] then
            AirWars:CreateShip(team_id)
        end
    end
end

function AirWars:SpawnPlayers()
    for _, ply in ipairs(player.GetAll()) do
        ply.prop_buffer = {}
        ply.lives = 3
        ply:Spawn()
    end
end

function AirWars:GetRandomPosition(radius)
    radius = tonumber(radius) or 5000
    for _ = 1, 64 do
        local position = Vector(math.Rand(-radius, radius), math.Rand(-radius, radius), math.Rand(0, radius))
        local valid = true
        for _, ship in pairs(world_ships or {}) do
            if ship.position and ship.position:DistToSqr(position) < (2000 * 2000) then
                valid = false
                break
            end
        end
        if valid then return position end
    end
    return Vector(math.Rand(-radius, radius), math.Rand(-radius, radius), math.Rand(0, radius))
end

function AirWars:GenShipsPosition(ship)
    for _ = 1, 64 do
        local position = Vector(math.Rand(-5000, 5000), math.Rand(-5000, 5000), calculate_height(ship.id))
        local valid = true
        for _, other in pairs(world_ships or {}) do
            if other ~= ship and other.position and other.position:DistToSqr(position) < (2000 * 2000) then
                valid = false
                break
            end
        end
        if valid then return position end
    end
    Skyfall.Warn("Ship", "Could not find fully separated spawn for ship %s after 64 attempts", tostring(ship.id))
    return Vector(math.Rand(-5000, 5000), math.Rand(-5000, 5000), calculate_height(ship.id))
end

function AirWars:SpawnShips()
    create_player_ships()

    local building_props = ents.FindByClass("aw_building_prop")
    for _, ship in pairs(world_ships) do
        if ship.ai_controlled then continue end

        local blocked = find_blocked_entities(ship.id)
        local blocked_lookup = {}
        for _, ent in ipairs(blocked) do blocked_lookup[ent] = true end

        for _, entity in ipairs(building_props) do
            if not IsValid(entity) or blocked_lookup[entity] then continue end
            if entity.AWIsInTeam and entity:AWIsInTeam(ship.id) then
                setup_part(entity, ship)
                entity:Remove()
            end
        end

        ship:UpdateCenter()
        ship:UpdateMinMax()
        AirWars:BuildShipProps(ship)
        ship.position = AirWars:GenShipsPosition(ship)
        ship:Sync()
        AirWars:TeamSyncGameState(ship.id)
    end

    AirWars:SpawnPlayers()
    AirWars:SpawnIslands()
    hook.Run("AirWars_ShipsSpawned")
    hook.Run("Skyfall_ShipsSpawned")
end
