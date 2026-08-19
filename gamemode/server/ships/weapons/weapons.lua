local function play_effect(angle, bullet, weapon, ship)
    if not bullet or not weapon or not ship then return end
    local info = weapon.custom_info or {}

    net.Start("aw_play_weapon_effect", false)
    net.WriteInt(tonumber(info.effect_type) or EFFECT_TYPE_CANNON, 8)
    net.WriteInt(math.floor(math.Clamp(tonumber(bullet.speed) or tonumber(info.speed) or 0, -32768, 32767)), 16)
    net.WriteInt(math.floor(math.Clamp(tonumber(bullet.gravity) or tonumber(info.gravity) or 0, -128, 127)), 8)
    net.WriteInt(bullet.id, 16)
    net.WriteInt(bullet.weapon or 0, 32)
    net.WriteInt(bullet.ship or 0, 16)
    net.WriteVector(bullet.position)
    net.WriteAngle(angle)
    net.WriteVector(ship.velocity or Vector())
    net.Broadcast()
end

function AirWars:ShipShoot(ship, weapon, offset, extra_angle, weapon_ent)
    if not istable(ship) or not istable(weapon) or weapon.destroyed or weapon.disabled then return nil end
    if not weapon.position or not weapon.angle then return nil end

    offset = tonumber(offset) or 0
    extra_angle = isangle(extra_angle) and extra_angle or Angle()

    local angle = weapon.angle + extra_angle
    local position = weapon.position - angle:Forward() * offset
    local bullet_position, bullet_angle = calculate_bullet_start(ship, position, angle)
    local bullet = add_bullet(bullet_position, bullet_angle, weapon, ship.velocity or Vector(), weapon_ent)
    if not bullet then return nil end

    play_effect(bullet_angle, bullet, weapon, ship)
    return bullet
end

local function controlled_weapon(ply)
    if not IsValid(ply) then return nil end
    local ent = ply:GetEntityUnderControl()
    if not IsValid(ent) then return nil end
    if not string.StartWith(ent:GetClass(), "aw_weapon") then return nil end
    if not isfunction(ent.Shoot) then return nil end
    return ent
end

hook.Add("PlayerButtonDown", "AW Try Shoot", function(ply, button)
    if button ~= MOUSE_LEFT then return end
    ply.shooting = true
    local weapon = controlled_weapon(ply)
    if weapon then weapon:Shoot(ply) end
end)

hook.Add("PlayerButtonUp", "AW Exit Weapon", function(ply, button)
    if button == MOUSE_LEFT then
        ply.shooting = false
        return
    end
    if button == KEY_R then
        ply.shooting = false
        ply:ExitControl()
    end
end)

-- Continuous-fire stations only inspect players who are actually holding fire;
-- this replaces the legacy weapons x players nested scan every Think.
hook.Add("Think", "Skyfall Weapon Continuous Fire", function()
    for _, ply in ipairs(player.GetAll()) do
        if not ply.shooting then continue end
        local weapon = controlled_weapon(ply)
        if weapon then weapon:Shoot(ply) end
    end
end)
