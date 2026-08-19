-- AirWars: Skyfall Fleet integration hooks. Kept separate so onboarding/cosmetic
-- features can wrap earlier milestone APIs without coupling those modules back to Fleet.

if isfunction(Skyfall.SpawnBuildDescriptors) and not Skyfall._fleet_spawn_wrapper then
    Skyfall._fleet_spawn_wrapper = true
    local original_spawn_descriptors = Skyfall.SpawnBuildDescriptors

    Skyfall.SpawnBuildDescriptors = function(ply, parts, origin, clear_existing)
        if not Skyfall.IsFeatureEnabled("blueprints") then
            return false, "Blueprint/prefab loading is disabled by this server"
        end
        local ok, message, count = original_spawn_descriptors(ply, parts, origin, clear_existing)
        if ok and IsValid(ply) then
            hook.Run("Skyfall_BuildTemplateLoaded", ply, parts, count)
        end
        return ok, message, count
    end
end

local function apply_ship_livery(ship, team_id)
    if not istable(ship) then return end
    local team = aw_teams_list and aw_teams_list[team_id]
    local leader = team and team.leader
    local livery = IsValid(leader) and leader:GetNWString("skyfall_livery", "brass") or "brass"
    if not Skyfall.Liveries[livery] then livery = "brass" end
    ship.livery = livery
end

hook.Add("AirWars_ShipCreated", "Skyfall_FleetLivery", function(id)
    local ship = world_ships and world_ships[id]
    if not ship then return end
    if id > 0 then
        apply_ship_livery(ship, id)
    elseif ship.faction == "enemy" then
        ship.livery = "crimson"
    elseif ship.faction == "ally" then
        ship.livery = "navy"
    else
        ship.livery = "iron"
    end
end)

hook.Add("Skyfall_ShipCaptured", "Skyfall_CapturedLivery", function(ship, ply)
    if not ship or not IsValid(ply) then return end
    ship.livery = ply:GetNWString("skyfall_livery", "brass")
    ship:Sync()
end)

hook.Add("Skyfall_AIShipSpawned", "Skyfall_GlobalAIDifficulty", function(ship)
    local setting = Skyfall.ServerSettings and Skyfall.ServerSettings.ai_difficulty
    if ship and setting then
        ship.ai_skill = math.Clamp((ship.ai_skill or 1) * setting:GetFloat(), 0.25, 3.5)
    end
end)

-- Tutorial spotting integration without making the Crew milestone depend on the
-- later Fleet tutorial system.
local next_tutorial_spot_check = 0
hook.Add("Think", "Skyfall_TutorialSpotIntegration", function()
    if CurTime() < next_tutorial_spot_check then return end
    next_tutorial_spot_check = CurTime() + 0.5

    for _, ply in ipairs(player.GetAll()) do
        if ply:GetNWInt("skyfall_tutorial_step", 0) ~= 6 then continue end
        for _, ship in pairs(world_ships or {}) do
            if ship.spotted_by_team == ply:GetAWTeam() and (ship.spotted_until or 0) > CurTime() then
                hook.Run("Skyfall_TargetSpotted", ply, ship)
                break
            end
        end
    end
end)
