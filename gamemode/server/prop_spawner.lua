function count_team_props(team)
    local count = 0
    for _, ent in ipairs(ents.FindByClass("aw_building_prop")) do
        if ent.GetAWTeam and ent:GetAWTeam() == team then
            count = count + 1
        end
    end
    return count
end

local function get_prop_definition(category, index)
    if not isnumber(category) or not isnumber(index) then return nil end
    local category_data = global_config.categories and global_config.categories[category]
    if not istable(category_data) or not istable(category_data.props) then return nil end
    if not Skyfall.ValidateIndex(category_data.props, index) then return nil end
    return category_data.props[index]
end

function AirWars:SpawnProp(position, angle, category, index, player, stacker)
    if not IsValid(player) or not player:IsPlayer() then return nil end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then return nil end

    local prop = get_prop_definition(category, index)
    if not prop or not istable(prop.info) or not prop.model then
        Skyfall.Warn("Build", "Rejected invalid prop request category=%s index=%s from %s", tostring(category), tostring(index), player:Nick())
        return nil
    end

    local team_id = player:GetAWTeam()
    if not aw_teams_list or not aw_teams_list[team_id] then return nil end
    if not can_afford(team_id, tonumber(prop.info.cost) or 0) then return nil end
    if count_team_props(team_id) >= global_config.prop_limit then return nil end

    local ent = ents.Create("aw_building_prop")
    if not IsValid(ent) then
        Skyfall.Error("Build", "Failed to create aw_building_prop")
        return nil
    end

    ent:SetModel(prop.model)
    local pos = isvector(position) and position or player:GetPos()
    if not stacker then
        pos = pos - Vector(0, 0, ent:OBBMins().z)
    end
    ent:SetPos(pos)
    ent:SetAngles(isangle(angle) and angle or Angle())

    ent.owner = player
    ent.info = prop.info
    ent.entity = prop.entity
    ent.custom_info = prop.custom_info
    ent:SetAWTeam(team_id)
    ent:SetCategory(category)
    ent:SetProp(index)

    ent:Spawn()
    ent:Activate()

    AirWars:TeamSyncGameState(team_id)

    undo.Create("AirWars build prop")
        undo.AddEntity(ent)
        undo.SetPlayer(player)
    undo.Finish()

    return ent
end

local function spawn_prop(player, category_index, index)
    if not IsValid(player) or not player:Alive() then return end

    local trace_data = {
        start = player:GetShootPos(),
        endpos = player:GetShootPos() + (player:GetAimVector() * 2048),
        filter = function(ent)
            if ent == player then return false end
            return ent.GetAWTeam and ent:GetAWTeam() == player:GetAWTeam()
        end
    }

    local trace = util.TraceLine(trace_data)
    AirWars:SpawnProp(trace.HitPos, Angle(), category_index, index, player)
end

net.Receive("aw_spawn_prop", function(_, player)
    if not Skyfall.AllowAction(player, "spawn_prop", Skyfall.GetConfig("network.prop_spawn_interval", 0.10)) then return end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then return end

    local category_index = net.ReadInt(8)
    local prop_index = net.ReadInt(8)
    if not get_prop_definition(category_index, prop_index) then
        Skyfall.Warn("Network", "Invalid aw_spawn_prop payload from %s (%s/%s)", IsValid(player) and player:Nick() or "unknown", tostring(category_index), tostring(prop_index))
        return
    end

    spawn_prop(player, category_index, prop_index)
end)
