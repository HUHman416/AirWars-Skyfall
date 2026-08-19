-- AirWars: Skyfall multicrew definitions shared between client and server.

Skyfall = Skyfall or {}

Skyfall.Roles = Skyfall.Roles or {
    crew = {
        name = "Crew",
        description = "General-purpose aircrew with no specialization bonuses.",
        repair_multiplier = 1.0,
        handling_multiplier = 1.0,
        reload_multiplier = 1.0
    },
    pilot = {
        name = "Pilot",
        description = "Improved helm response and target spotting.",
        repair_multiplier = 0.9,
        handling_multiplier = 1.12,
        reload_multiplier = 1.0
    },
    engineer = {
        name = "Engineer",
        description = "Faster repairs, rebuilds, fire suppression, and component buffs.",
        repair_multiplier = 1.5,
        handling_multiplier = 1.0,
        reload_multiplier = 0.95
    },
    gunner = {
        name = "Gunner",
        description = "Improved reload handling and ammunition specialization.",
        repair_multiplier = 0.9,
        handling_multiplier = 1.0,
        reload_multiplier = 1.18
    }
}

Skyfall.ComponentTypes = Skyfall.ComponentTypes or {
    HULL = "hull",
    HELM = "helm",
    PROPULSION = "propulsion",
    LIFT = "lift",
    WEAPON = "weapon",
    AMMO = "ammo",
    SPAWN = "spawn",
    UTILITY = "utility"
}

local player_meta = FindMetaTable("Player")

function player_meta:GetSkyfallRole()
    local role = self:GetNWString("skyfall_role", "crew")
    if not Skyfall.Roles[role] then return "crew" end
    return role
end

function player_meta:GetSkyfallRoleData()
    return Skyfall.Roles[self:GetSkyfallRole()] or Skyfall.Roles.crew
end

function player_meta:GetSkyfallRoleMultiplier(key, default)
    local data = self:GetSkyfallRoleData()
    local value = tonumber(data and data[key])
    return value or default or 1
end

function Skyfall.GetComponentType(entity_class, custom_info)
    entity_class = tostring(entity_class or "")
    custom_info = custom_info or {}

    if entity_class == "aw_ship_controller" then return Skyfall.ComponentTypes.HELM end
    if string.StartWith(entity_class, "aw_weapon_") then return Skyfall.ComponentTypes.WEAPON end
    if entity_class == "aw_ammunition_storage" then return Skyfall.ComponentTypes.AMMO end
    if entity_class == "aw_player_spawn" then return Skyfall.ComponentTypes.SPAWN end
    if custom_info.force then return Skyfall.ComponentTypes.PROPULSION end
    if custom_info.lift_force then return Skyfall.ComponentTypes.LIFT end
    if entity_class == "aw_speaker" or entity_class == "aw_flag" then return Skyfall.ComponentTypes.UTILITY end
    return Skyfall.ComponentTypes.HULL
end

function Skyfall.GetPartHealthFraction(part)
    if not istable(part) then return 0 end
    local maximum = math.max(1, tonumber(part.max_health or (part.info and part.info.health) or 100) or 100)
    return math.Clamp((tonumber(part.health) or 0) / maximum, 0, 1)
end

function Skyfall.GetPartEffectiveness(part)
    if not istable(part) or part.destroyed then return 0 end
    local health = Skyfall.GetPartHealthFraction(part)
    local minimum = 0.20
    local effectiveness = minimum + (1 - minimum) * health
    if part.disabled then effectiveness = effectiveness * 0.35 end
    if (part.buff_until or 0) > CurTime() then
        effectiveness = effectiveness * (part.buff_multiplier or 1.10)
    end
    return math.Clamp(effectiveness, 0, 1.35)
end
