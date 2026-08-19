-- AirWars: Skyfall combat data: ammunition and configurable weapon families.

Skyfall = Skyfall or {}

Skyfall.AmmoTypes = Skyfall.AmmoTypes or {
    standard = {
        name = "Standard",
        damage = 1.00,
        speed = 1.00,
        splash = 1.00,
        cooldown = 1.00,
        penetration = 0.15,
        component = 1.00,
        fire = 0
    },
    greased = {
        name = "Greased",
        damage = 0.82,
        speed = 0.90,
        splash = 0.90,
        cooldown = 0.68,
        penetration = 0.08,
        component = 0.95,
        fire = 0
    },
    heavy = {
        name = "Heavy",
        damage = 1.30,
        speed = 0.88,
        splash = 1.10,
        cooldown = 1.28,
        penetration = 0.28,
        component = 1.05,
        fire = 0
    },
    incendiary = {
        name = "Incendiary",
        damage = 0.78,
        speed = 0.95,
        splash = 1.00,
        cooldown = 1.08,
        penetration = 0.05,
        component = 0.95,
        fire = 2
    },
    burst = {
        name = "Burst",
        damage = 0.90,
        speed = 0.95,
        splash = 1.55,
        cooldown = 1.15,
        penetration = 0.10,
        component = 1.00,
        fire = 0
    },
    charged = {
        name = "Charged",
        damage = 1.08,
        speed = 1.40,
        splash = 0.80,
        cooldown = 1.25,
        penetration = 0.35,
        component = 1.00,
        fire = 0
    },
    armor_piercing = {
        name = "Armor Piercing",
        damage = 1.00,
        speed = 1.12,
        splash = 0.65,
        cooldown = 1.12,
        penetration = 0.72,
        component = 0.85,
        fire = 0
    },
    shatter = {
        name = "Shatter",
        damage = 0.72,
        speed = 1.05,
        splash = 0.90,
        cooldown = 0.95,
        penetration = 0.12,
        component = 1.70,
        fire = 0
    }
}

Skyfall.WeaponProfiles = Skyfall.WeaponProfiles or {
    gatling = {
        name = "Gatling Gun",
        model = "models/aw_rifle/aw_rifle_full.mdl",
        damage = 8,
        speed = 3800,
        gravity = 0,
        splash_radius = 12,
        effect_type = EFFECT_TYPE_RIFLE,
        ammo = 18,
        cooldown = 0.12,
        weight = 28,
        health = 70,
        cost = 650,
        component_multiplier = 1.15
    },
    carronade = {
        name = "Carronade",
        model = "models/aw_cannon/aw_cannon_full.mdl",
        damage = 34,
        speed = 2100,
        gravity = 2,
        splash_radius = 70,
        effect_type = EFFECT_TYPE_CANNON,
        ammo = 4,
        cooldown = 1.10,
        weight = 55,
        health = 120,
        cost = 800,
        component_multiplier = 1.55
    },
    flak = {
        name = "Flak Cannon",
        model = "models/aw_cannon/aw_cannon_full.mdl",
        damage = 38,
        speed = 3100,
        gravity = 1,
        splash_radius = 145,
        effect_type = EFFECT_TYPE_CANNON,
        ammo = 5,
        cooldown = 1.20,
        weight = 62,
        health = 120,
        cost = 950,
        component_multiplier = 1.00
    },
    mortar = {
        name = "Sky Mortar",
        model = "models/aw_cannon/aw_cannon_full.mdl",
        damage = 88,
        speed = 1500,
        gravity = 5,
        splash_radius = 210,
        effect_type = EFFECT_TYPE_BOMB,
        ammo = 1,
        cooldown = 3.1,
        weight = 75,
        health = 130,
        cost = 1100,
        component_multiplier = 0.95
    },
    rocket = {
        name = "Rocket Battery",
        model = "models/aw_rifle/aw_rifle_full.mdl",
        damage = 50,
        speed = 2400,
        gravity = 1,
        splash_radius = 125,
        effect_type = EFFECT_TYPE_BOMB,
        ammo = 4,
        cooldown = 0.85,
        weight = 48,
        health = 90,
        cost = 1050,
        component_multiplier = 1.05,
        fire = 1
    },
    flamethrower = {
        name = "Flame Projector",
        model = "models/aw_rifle/aw_rifle_full.mdl",
        damage = 5,
        speed = 950,
        gravity = 0,
        splash_radius = 45,
        effect_type = EFFECT_TYPE_RIFLE,
        ammo = 25,
        cooldown = 0.10,
        weight = 32,
        health = 75,
        cost = 900,
        component_multiplier = 0.80,
        fire = 2,
        lifetime = 1.2
    },
    mine = {
        name = "Aerial Mine Layer",
        model = "models/aw_bomb/aw_bomb.mdl",
        damage = 115,
        speed = 250,
        gravity = 1,
        splash_radius = 260,
        effect_type = EFFECT_TYPE_BOMB,
        ammo = 1,
        cooldown = 3.5,
        weight = 50,
        health = 75,
        cost = 900,
        component_multiplier = 1.10,
        lifetime = 12
    },
    arc_cannon = {
        name = "Arc Cannon",
        model = "models/aw_cannon/aw_cannon_full.mdl",
        damage = 68,
        speed = 4400,
        gravity = 0,
        splash_radius = 55,
        effect_type = EFFECT_TYPE_CANNON,
        ammo = 2,
        cooldown = 2.2,
        weight = 58,
        health = 100,
        cost = 1250,
        component_multiplier = 1.25,
        penetration = 0.45
    }
}

function Skyfall.GetAmmoType(name)
    name = string.lower(tostring(name or "standard"))
    return Skyfall.AmmoTypes[name] or Skyfall.AmmoTypes.standard, Skyfall.AmmoTypes[name] and name or "standard"
end

function Skyfall.GetWeaponProfile(name)
    return Skyfall.WeaponProfiles[string.lower(tostring(name or ""))]
end

function Skyfall.DefaultArmorForPart(part)
    if not istable(part) then return 0 end
    if part.component_type ~= Skyfall.ComponentTypes.HULL then return 0.12 end
    local model = string.lower(tostring(part.model or ""))
    if string.find(model, "metal", 1, true) or string.find(model, "blastdoor", 1, true) then return 0.32 end
    if string.find(model, "wood", 1, true) then return 0.08 end
    if string.find(model, "glass", 1, true) or string.find(model, "window", 1, true) then return 0.03 end
    if string.find(model, "plastic", 1, true) then return 0.12 end
    return 0.16
end

local function register_weapon_build_entries()
    if not global_config or not global_config.categories or not global_config.categories[CATEGORY_WEAPONS] then return end
    local list = global_config.categories[CATEGORY_WEAPONS].props
    if not istable(list) then return end

    local present = {}
    for _, entry in ipairs(list) do
        if entry.custom_info and entry.custom_info.skyfall_weapon_profile then
            present[entry.custom_info.skyfall_weapon_profile] = true
        end
    end

    for id, profile in SortedPairs(Skyfall.WeaponProfiles) do
        if present[id] then continue end
        table.insert(list, {
            name = profile.name,
            model = profile.model,
            entity = "aw_weapon_skyfall",
            info = {
                weight = profile.weight,
                health = profile.health,
                cost = profile.cost,
                armor = 0.12
            },
            custom_info = {
                damage = profile.damage,
                speed = profile.speed,
                gravity = profile.gravity,
                splash_radius = profile.splash_radius,
                effect_type = profile.effect_type,
                skyfall_weapon_profile = id,
                component_multiplier = profile.component_multiplier,
                fire = profile.fire or 0,
                penetration = profile.penetration or 0,
                lifetime = profile.lifetime or 6
            },
            category = CATEGORY_WEAPONS
        })
    end
end

register_weapon_build_entries()
