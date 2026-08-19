-- AirWars: Skyfall ready-to-build ship templates.
-- Positions are relative to the prefab origin and intentionally stay within the
-- legacy AirWars build-radius rules.

Skyfall = Skyfall or {}
Skyfall.Prefabs = Skyfall.Prefabs or {}

local function p(category, index, x, y, z, yaw)
    return {category = category, index = index, pos = Vector(x, y, z), ang = Angle(0, yaw or 0, 0)}
end

local function w(profile, x, y, z, yaw)
    return {category = CATEGORY_WEAPONS, profile = profile, pos = Vector(x, y, z), ang = Angle(0, yaw or 0, 0)}
end

Skyfall.Prefabs.cutter = {
    name = "Cutter",
    description = "Compact 2-3 crew patrol ship with cannon, gatling, and grapple.",
    recommended_crew = "2-3",
    parts = {
        p(CATEGORY_PROPS, 3, -64, 0, 0), p(CATEGORY_PROPS, 3, 64, 0, 0),
        p(CATEGORY_SPECIALS, 1, -45, 0, 28),
        p(CATEGORY_SPECIALS, 2, -110, 0, 70),
        p(CATEGORY_SPECIALS, 4, 0, 0, 205),
        p(CATEGORY_SPECIALS, 5, -25, 55, 28),
        p(CATEGORY_SPECIALS, 6, 35, 55, 28),
        p(CATEGORY_WEAPONS, 1, 105, -45, 30),
        w("gatling", 105, 45, 30),
        p(CATEGORY_WEAPONS, 3, -105, 55, 30)
    }
}

Skyfall.Prefabs.frigate = {
    name = "Frigate",
    description = "Balanced 3-5 crew combat ship with broad weapon coverage.",
    recommended_crew = "3-5",
    parts = {
        p(CATEGORY_PROPS, 3, -96, -48, 0), p(CATEGORY_PROPS, 3, 0, -48, 0), p(CATEGORY_PROPS, 3, 96, -48, 0),
        p(CATEGORY_PROPS, 3, -96, 48, 0), p(CATEGORY_PROPS, 3, 0, 48, 0), p(CATEGORY_PROPS, 3, 96, 48, 0),
        p(CATEGORY_SPECIALS, 1, -65, 0, 28),
        p(CATEGORY_SPECIALS, 2, -135, -45, 75), p(CATEGORY_SPECIALS, 2, -135, 45, 75),
        p(CATEGORY_SPECIALS, 4, -20, 0, 215),
        p(CATEGORY_SPECIALS, 5, -40, 55, 28),
        p(CATEGORY_SPECIALS, 6, 35, 55, 28),
        p(CATEGORY_WEAPONS, 1, 120, -65, 30),
        w("carronade", 120, 0, 30),
        w("gatling", 120, 65, 30),
        p(CATEGORY_WEAPONS, 3, -120, 70, 30),
        w("rocket", -15, -75, 32)
    }
}

Skyfall.Prefabs.cruiser = {
    name = "Cruiser",
    description = "Heavy 5-7 crew warship built around layered firepower and redundancy.",
    recommended_crew = "5-7",
    parts = {
        p(CATEGORY_PROPS, 3, -144, -48, 0), p(CATEGORY_PROPS, 3, -48, -48, 0), p(CATEGORY_PROPS, 3, 48, -48, 0), p(CATEGORY_PROPS, 3, 144, -48, 0),
        p(CATEGORY_PROPS, 3, -144, 48, 0), p(CATEGORY_PROPS, 3, -48, 48, 0), p(CATEGORY_PROPS, 3, 48, 48, 0), p(CATEGORY_PROPS, 3, 144, 48, 0),
        p(CATEGORY_SPECIALS, 1, -95, 0, 28),
        p(CATEGORY_SPECIALS, 2, -160, -55, 75), p(CATEGORY_SPECIALS, 2, -160, 55, 75),
        p(CATEGORY_SPECIALS, 4, -55, 0, 220), p(CATEGORY_SPECIALS, 3, 80, 0, 180),
        p(CATEGORY_SPECIALS, 5, -55, 55, 28),
        p(CATEGORY_SPECIALS, 6, 25, 55, 28), p(CATEGORY_SPECIALS, 6, 80, 55, 28),
        p(CATEGORY_WEAPONS, 1, 155, -65, 30),
        w("flak", 155, 0, 30),
        w("gatling", 155, 65, 30),
        w("rocket", 30, -78, 30),
        w("carronade", -55, -78, 30),
        p(CATEGORY_WEAPONS, 3, -155, 70, 30),
        w("mortar", -140, -55, 30)
    }
}

Skyfall.Prefabs.dreadnought = {
    name = "Dreadnought",
    description = "Expensive 7+ crew flagship; large gun deck, redundant lift, and experimental weapons.",
    recommended_crew = "7+",
    parts = {
        p(CATEGORY_PROPS, 3, -144, -96, 0), p(CATEGORY_PROPS, 3, -48, -96, 0), p(CATEGORY_PROPS, 3, 48, -96, 0), p(CATEGORY_PROPS, 3, 144, -96, 0),
        p(CATEGORY_PROPS, 3, -144, 0, 0), p(CATEGORY_PROPS, 3, -48, 0, 0), p(CATEGORY_PROPS, 3, 48, 0, 0), p(CATEGORY_PROPS, 3, 144, 0, 0),
        p(CATEGORY_PROPS, 3, -144, 96, 0), p(CATEGORY_PROPS, 3, -48, 96, 0), p(CATEGORY_PROPS, 3, 48, 96, 0), p(CATEGORY_PROPS, 3, 144, 96, 0),
        p(CATEGORY_SPECIALS, 1, -105, 0, 28),
        p(CATEGORY_SPECIALS, 2, -170, -70, 80), p(CATEGORY_SPECIALS, 2, -170, 70, 80), p(CATEGORY_SPECIALS, 2, 20, 0, 80),
        p(CATEGORY_SPECIALS, 4, -75, -25, 230), p(CATEGORY_SPECIALS, 4, 80, 25, 230),
        p(CATEGORY_SPECIALS, 5, -75, 75, 28),
        p(CATEGORY_SPECIALS, 6, 0, 75, 28), p(CATEGORY_SPECIALS, 6, 75, 75, 28),
        w("arc_cannon", 170, -80, 32), w("flak", 170, 0, 32), w("arc_cannon", 170, 80, 32),
        w("gatling", 60, -105, 32), w("gatling", 60, 105, 32),
        w("rocket", -35, -105, 32), w("rocket", -35, 105, 32),
        w("mortar", -145, -70, 32), w("mine", -145, 70, 32),
        p(CATEGORY_WEAPONS, 3, -180, 0, 32)
    }
}

function Skyfall.ResolveBuildPartIndex(descriptor)
    if not descriptor or not global_config or not global_config.categories then return nil end
    local category = global_config.categories[descriptor.category]
    if not category or not category.props then return nil end

    if descriptor.profile then
        for index, entry in ipairs(category.props) do
            if entry.custom_info and entry.custom_info.skyfall_weapon_profile == descriptor.profile then
                return index
            end
        end
        return nil
    end

    local index = tonumber(descriptor.index)
    if index and category.props[index] then return index end
    return nil
end
