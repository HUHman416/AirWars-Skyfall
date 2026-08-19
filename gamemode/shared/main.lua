include("skyfall_config.lua")
include("skyfall_crew.lua")
include("skyfall_combat.lua")
include("skyfall_prefabs.lua")
include("player.lua")
include("props_collision.lua")
include("teams.lua")
include("entity.lua")
include("noclip.lua")
include("crew.lua")
include("founds.lua")
include("tool_base.lua")
include("math.lua")

aw_flag_colors = {
    Color(255, 255, 255),
    Color(26, 26, 44),
    Color(93, 39, 93),
    Color(177, 62, 83),
    Color(239, 125, 87),
    Color(255, 205, 117),
    Color(167, 240, 112),
    Color(56, 183, 100),
    Color(37, 113, 121),
    Color(41, 53, 111),
    Color(59, 93, 201),
    Color(65, 166, 246),
    Color(115, 239, 247),
    Color(148, 176, 194),
    Color(86, 108, 134),
}

hook.Add("Move", "FreezePlayer", function(player, move_data)
    if player:IsInControl() then
        if move_data:KeyDown(IN_JUMP) then return true end
        move_data:SetMaxSpeed(0)
        return false
    end
end)

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

local function get_team_build_props(team)
    local props = {}
    for _, ent in ipairs(ents.FindByClass("aw_building_prop")) do
        if ent.GetAWTeam and ent:GetAWTeam() == team then
            table.insert(props, ent)
        end
    end
    return props
end

local function find_close_entities(team, props)
    props = props or get_team_build_props(team)
    local result = {}
    local found = {}

    for i = 1, #props do
        local a = props[i]
        local radius = a.custom_info and a.custom_info.intersection_radius
        if not radius then continue end

        for j = i + 1, #props do
            local b = props[j]
            if b.entity != a.entity then continue end
            if not b.custom_info or not b.custom_info.intersection_radius then continue end
            if b:GetPos():DistToSqr(a:GetPos()) >= (radius * radius) then continue end

            if not found[a] then
                found[a] = true
                table.insert(result, a)
            end
            if not found[b] then
                found[b] = true
                table.insert(result, b)
            end
        end
    end

    return result
end

function find_blocked_entities(team)
    local props = get_team_build_props(team)
    if #props == 0 then return {} end

    local center = Vector()
    for _, ent in ipairs(props) do
        center = center + ent:GetPos()
    end
    center = center / #props

    local result = {}
    local found = {}
    for _, ent in ipairs(props) do
        if ent:GetPos():DistToSqr(center) > (300 * 300) then
            found[ent] = true
            table.insert(result, ent)
        end
    end

    for _, ent in ipairs(find_close_entities(team, props)) do
        if not found[ent] then
            found[ent] = true
            table.insert(result, ent)
        end
    end

    return result
end
