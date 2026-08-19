local function build_props_for_team(team_id)
    local result = {}
    for _, ent in ipairs(ents.FindByClass("aw_building_prop")) do
        if ent.GetAWTeam and ent:GetAWTeam() == team_id then
            table.insert(result, ent)
        end
    end
    return result
end

function build_calculate_ship_cost(team_id)
    local cost = 0
    for _, ent in ipairs(build_props_for_team(team_id)) do
        if ent.info then cost = cost + (tonumber(ent.info.cost) or 0) end
    end
    return cost
end

function build_calculate_ship_weight(team_id)
    local weight = 0
    for _, ent in ipairs(build_props_for_team(team_id)) do
        if ent.info then weight = weight + (tonumber(ent.info.weight) or 0) end
    end
    if CLIENT and IsValid(LocalPlayer()) and LocalPlayer().GetAWTeam then
        weight = weight + #get_team_members(LocalPlayer():GetAWTeam()) * 40
    end
    return weight
end

function build_calculate_ship_force(team_id)
    local force = 0
    for _, ent in ipairs(build_props_for_team(team_id)) do
        if ent.custom_info and ent.custom_info.force then
            force = force + (tonumber(ent.custom_info.force) or 0)
        end
    end
    return force
end

function build_calculate_ship_lift_force(team_id)
    local force = 0
    for _, ent in ipairs(build_props_for_team(team_id)) do
        if ent.custom_info and ent.custom_info.lift_force then
            force = force + (tonumber(ent.custom_info.lift_force) or 0)
        end
    end
    return force
end

function fight_calculate_ship_weight(ship)
    if not istable(ship) then return 0 end
    local weight = 1
    for _, part in pairs(ship.parts or {}) do
        if part.info then weight = weight + (tonumber(part.info.weight) or 0) end
    end
    weight = weight + #get_crew(ship) * 40
    return weight
end

function fight_calculate_ship_force(ship)
    if not istable(ship) then return 0 end
    local force = 1
    for _, part in pairs(ship.parts or {}) do
        if part.custom_info and part.custom_info.force then
            force = force + (tonumber(part.custom_info.force) or 0) * Skyfall.GetPartEffectiveness(part)
        end
    end
    return force
end

function fight_calculate_ship_lift_force(ship)
    if not istable(ship) then return 0 end
    local force = 1
    for _, part in pairs(ship.parts or {}) do
        if part.custom_info and part.custom_info.lift_force then
            force = force + (tonumber(part.custom_info.lift_force) or 0) * Skyfall.GetPartEffectiveness(part)
        end
    end
    return force
end

function fight_calculate_efficiency(ship_id)
    local ship = world_ships and world_ships[ship_id]
    if not ship then return 0 end
    local weight = math.max(1, fight_calculate_ship_weight(ship))
    return math.Clamp(fight_calculate_ship_force(ship) / weight, 0, 3)
end

function calculate_ship_weight(ship_id)
    if ship_id == nil then return 0 end
    if istable(game_state) and game_state.state == GAME_STATE_FIGHT then
        return fight_calculate_ship_weight(world_ships and world_ships[ship_id])
    end
    return build_calculate_ship_weight(ship_id)
end

function calculate_ship_force(ship_id)
    if ship_id == nil then return 0 end
    if istable(game_state) and game_state.state == GAME_STATE_FIGHT then
        return fight_calculate_ship_force(world_ships and world_ships[ship_id])
    end
    return build_calculate_ship_force(ship_id)
end

function calculate_ship_lift_force(ship_id)
    if ship_id == nil then return 0 end
    if istable(game_state) and game_state.state == GAME_STATE_FIGHT then
        return fight_calculate_ship_lift_force(world_ships and world_ships[ship_id])
    end
    return build_calculate_ship_lift_force(ship_id)
end

function calculate_height(ship_id)
    if ship_id == nil then return 0 end
    local height = -calculate_ship_weight(ship_id) + calculate_ship_lift_force(ship_id)
    return math.Clamp(height, 0, 1100) * 10
end

function can_afford(ship_id, amount)
    if ship_id == nil then return false end
    local cost = build_calculate_ship_cost(ship_id)
    return (cost + (tonumber(amount) or 0)) <= global_config.max_founds
end
