-- AirWars: Skyfall grappling system. Grapples are persistent ship links that pull
-- vessels into boarding distance and can be cut by either crew.

Skyfall.Grapples = Skyfall.Grapples or {}
local next_grapple_id = 1
local next_grapple_tick = 0

local function find_existing(a, b)
    for _, grapple in pairs(Skyfall.Grapples) do
        if (grapple.a == a and grapple.b == b) or (grapple.a == b and grapple.b == a) then
            return grapple
        end
    end
end

function Skyfall.AddGrapple(a, b, duration, strength, source_ent)
    if a == b or not world_ships[a] or not world_ships[b] then return nil end
    local existing = find_existing(a, b)
    if existing then
        existing.expires = math.max(existing.expires, CurTime() + (duration or 15))
        existing.strength = math.max(existing.strength or 1, strength or 1)
        return existing
    end

    local grapple = {
        id = next_grapple_id,
        a = a,
        b = b,
        expires = CurTime() + (duration or 15),
        strength = strength or 1,
        source_ent = source_ent
    }
    next_grapple_id = next_grapple_id + 1
    Skyfall.Grapples[grapple.id] = grapple
    hook.Run("Skyfall_GrappleAttached", grapple)
    return grapple
end

function Skyfall.RemoveGrapple(id, reason)
    local grapple = Skyfall.Grapples[id]
    if not grapple then return false end
    Skyfall.Grapples[id] = nil

    if IsValid(grapple.source_ent) then
        if grapple.source_ent.SetHookState then grapple.source_ent:SetHookState(0) end
        grapple.source_ent.hit = false
    end
    hook.Run("Skyfall_GrappleRemoved", grapple, reason)
    return true
end

function Skyfall.CutShipGrapples(ship_id, reason)
    local removed = 0
    local ids = {}
    for id, grapple in pairs(Skyfall.Grapples) do
        if grapple.a == ship_id or grapple.b == ship_id then table.insert(ids, id) end
    end
    for _, id in ipairs(ids) do
        if Skyfall.RemoveGrapple(id, reason or "cut") then removed = removed + 1 end
    end
    return removed
end

local function update_grapples()
    local now = CurTime()
    local dt = 0.05
    for id, grapple in pairs(Skyfall.Grapples) do
        if grapple.expires <= now then
            Skyfall.RemoveGrapple(id, "expired")
            continue
        end

        local a, b = world_ships[grapple.a], world_ships[grapple.b]
        if not a or not b then
            Skyfall.RemoveGrapple(id, "ship destroyed")
            continue
        end

        a.velocity = a.velocity or Vector()
        b.velocity = b.velocity or Vector()
        local delta = b.position - a.position
        local distance = delta:Length()
        if distance <= 1 then continue end

        local mass_a = math.max(1, calculate_ship_weight(a.id))
        local mass_b = math.max(1, calculate_ship_weight(b.id))
        local mass_sum = mass_a + mass_b
        local tension = math.Clamp((distance - 450) * 0.035, 0, 180) * (grapple.strength or 1)
        local direction = delta / distance

        a.velocity:Add(direction * tension * (mass_b / mass_sum) * dt * 20)
        b.velocity:Add(-direction * tension * (mass_a / mass_sum) * dt * 20)
    end
end

hook.Add("Think", "Skyfall Grappling Hook Update", function()
    if CurTime() < next_grapple_tick then return end
    next_grapple_tick = CurTime() + 0.05
    update_grapples()
end)

hook.Add("AirWars_BulletHit", "Grappling Hook Hit", function(_, bullet, ship)
    if bullet.effect_type ~= EFFECT_TYPE_HOOK then return end
    if bullet.ship == ship.id then return end

    local grapple = Skyfall.AddGrapple(bullet.ship, ship.id, 15, 1, bullet.weapon_ent)
    if not grapple then return end

    if IsValid(bullet.weapon_ent) then
        bullet.weapon_ent.hit = true
        if bullet.weapon_ent.SetHookState then bullet.weapon_ent:SetHookState(1) end
    end
end)

hook.Add("Skyfall_ShipDestroyed", "Skyfall_RemoveDestroyedShipGrapples", function(ship)
    Skyfall.CutShipGrapples(ship.id, "ship destroyed")
end)
