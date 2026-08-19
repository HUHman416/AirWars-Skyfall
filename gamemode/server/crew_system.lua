-- AirWars: Skyfall multicrew role and spotting system.

function Skyfall.SetRole(ply, role)
    if not IsValid(ply) or not ply:IsPlayer() then return false end
    role = string.lower(tostring(role or "crew"))
    if not Skyfall.Roles[role] then return false end

    ply:SetNWString("skyfall_role", role)
    hook.Run("Skyfall_PlayerRoleChanged", ply, role)
    return true
end

local function role_reply(ply)
    ply:ChatPrint("Skyfall role: " .. ply:GetSkyfallRoleData().name .. " (" .. ply:GetSkyfallRole() .. ")")
end

concommand.Add("aw_role", function(ply, _, args)
    if not IsValid(ply) then return end
    local requested = string.lower(tostring(args[1] or ""))
    if requested == "" then
        role_reply(ply)
        ply:ChatPrint("Available: crew, pilot, engineer, gunner")
        return
    end

    if istable(game_state) and game_state.state == GAME_STATE_FIGHT and not aw_developer then
        ply:ChatPrint("Choose a specialty during the build phase.")
        return
    end

    if not Skyfall.SetRole(ply, requested) then
        ply:ChatPrint("Unknown role. Available: crew, pilot, engineer, gunner")
        return
    end
    role_reply(ply)
end)

hook.Add("PlayerInitialSpawn", "Skyfall_DefaultRole", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) and not Skyfall.Roles[ply:GetNWString("skyfall_role", "")] then
            Skyfall.SetRole(ply, "crew")
        end
    end)
end)

hook.Add("PlayerSpawn", "Skyfall_GiveCrewTools", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
        if not ply:HasWeapon("aw_engineer_tool") then
            ply:Give("aw_engineer_tool")
        end
    end)
end)

function Skyfall.GetShipComponentSummary(ship)
    local summary = {
        total = 0,
        destroyed = 0,
        fire = 0,
        health = 0,
        max_health = 0,
        by_type = {}
    }
    if not istable(ship) then return summary end

    for _, part in pairs(ship.parts or {}) do
        local component_type = part.component_type or Skyfall.ComponentTypes.HULL
        summary.by_type[component_type] = summary.by_type[component_type] or {count = 0, health = 0, max_health = 0, destroyed = 0}
        local entry = summary.by_type[component_type]
        local maximum = tonumber(part.max_health or (part.info and part.info.health) or 100) or 100
        local health = tonumber(part.health) or 0

        summary.total = summary.total + 1
        summary.health = summary.health + health
        summary.max_health = summary.max_health + maximum
        summary.fire = summary.fire + (part.fire_stacks or 0)
        entry.count = entry.count + 1
        entry.health = entry.health + health
        entry.max_health = entry.max_health + maximum
    end

    for _, part in pairs(ship.destroyed_parts or {}) do
        local component_type = part.component_type or Skyfall.ComponentTypes.HULL
        summary.by_type[component_type] = summary.by_type[component_type] or {count = 0, health = 0, max_health = 0, destroyed = 0}
        summary.total = summary.total + 1
        summary.destroyed = summary.destroyed + 1
        summary.max_health = summary.max_health + (tonumber(part.max_health) or 100)
        summary.by_type[component_type].count = summary.by_type[component_type].count + 1
        summary.by_type[component_type].max_health = summary.by_type[component_type].max_health + (tonumber(part.max_health) or 100)
        summary.by_type[component_type].destroyed = summary.by_type[component_type].destroyed + 1
    end

    return summary
end

local function send_spot(team_id, ship, duration)
    local recipients = get_team_members(team_id)
    if #recipients == 0 then return end

    net.Start("aw_skyfall_spot")
    net.WriteInt(ship.id, 32)
    net.WriteFloat(duration)
    net.Send(recipients)
end

concommand.Add("aw_spot", function(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
    if not Skyfall.AllowAction(ply, "spot", 1.0) then return end

    local tr = util.TraceLine({
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:GetAimVector() * 20000,
        filter = ply
    })

    local ent = tr.Entity
    if not IsValid(ent) or not ent.GetAWTeam then return end
    local target_id = ent:GetAWTeam()
    if target_id == ply:GetAWTeam() then return end
    local ship = world_ships and world_ships[target_id]
    if not ship then return end

    local duration = ply:GetSkyfallRole() == "pilot" and 15 or 8
    ship.spotted_until = CurTime() + duration
    ship.spotted_by_team = ply:GetAWTeam()
    send_spot(ply:GetAWTeam(), ship, duration)
    ply:ChatPrint("Spotted enemy ship for " .. duration .. " seconds")
end)

hook.Add("Skyfall_ComponentDestroyed", "Skyfall_CrewComponentNotice", function(ship, part)
    if not ship or not part then return end
    for _, crew in ipairs(get_team_crew(ship)) do
        crew:ChatPrint(string.upper(tostring(part.component_type or "component")) .. " DESTROYED")
    end
end)

Skyfall.SetFeatureEnabled("crew_specialties", true)
Skyfall.SetFeatureEnabled("component_engineering", true)
Skyfall.Info("Crew", "Multicrew specialties and engineering enabled")
