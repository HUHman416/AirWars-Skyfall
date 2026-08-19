-- AirWars: Skyfall Fire & Steel systems: ammunition choice and component fires.

local function list_ammo(ply)
    local names = {}
    for id, data in SortedPairs(Skyfall.AmmoTypes or {}) do
        table.insert(names, id .. " (" .. tostring(data.name or id) .. ")")
    end
    ply:ChatPrint("Ammunition: " .. table.concat(names, ", "))
end

concommand.Add("aw_ammo", function(ply, _, args)
    if not IsValid(ply) then return end
    local requested = string.lower(tostring(args[1] or ""))
    if requested == "" then
        ply:ChatPrint("Selected ammunition: " .. ply:GetNWString("skyfall_ammo", "standard"))
        list_ammo(ply)
        return
    end

    if not Skyfall.AmmoTypes[requested] then
        ply:ChatPrint("Unknown ammunition type: " .. requested)
        list_ammo(ply)
        return
    end

    ply:SetNWString("skyfall_ammo", requested)
    ply:ChatPrint("Selected " .. Skyfall.AmmoTypes[requested].name .. " ammunition. It will be loaded the next time you reload a ship weapon.")
end)

hook.Add("PlayerInitialSpawn", "Skyfall_DefaultAmmo", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) and ply:GetNWString("skyfall_ammo", "") == "" then
            ply:SetNWString("skyfall_ammo", "standard")
        end
    end)
end)

local function nearby_parts(ship, source, radius)
    local result = {}
    if not source.position then return result end
    local radius_sqr = radius * radius
    for _, part in pairs(ship.parts or {}) do
        if part == source or part.destroyed or not part.position then continue end
        if part.position:DistToSqr(source.position) <= radius_sqr then
            table.insert(result, part)
        end
    end
    return result
end

function Skyfall.TickComponentFires()
    if not Skyfall.IsFeatureEnabled("fire_and_armor") then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    local started = Skyfall.ProfileStart("component_fire")
    for _, ship in pairs(world_ships or {}) do
        local burning = {}
        for _, part in pairs(ship.parts or {}) do
            if (part.fire_stacks or 0) > 0 then table.insert(burning, part) end
        end

        for _, part in ipairs(burning) do
            if not part.destroyed then
                local stacks = math.Clamp(part.fire_stacks or 0, 0, 20)
                local damage = 0.75 + stacks * 0.85
                part:ApplyDamage(damage, {kind = "fire", penetration = 1, component_multiplier = 1, hull_multiplier = 1}, "fire")

                local spread_chance = math.Clamp(0.015 * stacks, 0, 0.22)
                for _, neighbor in ipairs(nearby_parts(ship, part, 130)) do
                    if math.Rand(0, 1) < spread_chance then neighbor:AddFireStacks(1) end
                end

                if stacks <= 2 and math.Rand(0, 1) < 0.12 then
                    part:SetFireStacks(stacks - 1)
                end
            end
        end
    end
    Skyfall.ProfileEnd("component_fire", started)
end

timer.Create("AirWars_Skyfall_FireTick", 1, 0, Skyfall.TickComponentFires)

-- Hull plates form the structural health pool. Once no hull health remains the
-- entire virtual ship is considered broken apart, which gives both PvP and PvE a
-- deterministic destruction condition instead of relying on every entity being gone.
hook.Add("Skyfall_ComponentDestroyed", "Skyfall_StructuralDestruction", function(ship)
    if not istable(ship) or not world_ships or world_ships[ship.id] ~= ship then return end
    local summary = Skyfall.GetShipComponentSummary(ship)
    local hull = summary.by_type and summary.by_type[Skyfall.ComponentTypes.HULL]
    if hull and hull.max_health > 0 and hull.health <= 0 then
        timer.Simple(0, function()
            if world_ships and world_ships[ship.id] == ship then
                AirWars:DestroyShip(ship)
            end
        end)
    end
end)

concommand.Add("aw_fire_status", function(ply)
    if not IsValid(ply) then return end
    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship then return end

    local burning = 0
    local stacks = 0
    for _, part in pairs(ship.parts or {}) do
        if (part.fire_stacks or 0) > 0 then
            burning = burning + 1
            stacks = stacks + part.fire_stacks
        end
    end
    ply:ChatPrint(string.format("Fire status: %d burning component(s), %d total stack(s)", burning, stacks))
end)

Skyfall.SetFeatureEnabled("fire_and_armor", true)
Skyfall.Info("Combat", "Fire, armor, penetration, and specialized ammunition enabled")
