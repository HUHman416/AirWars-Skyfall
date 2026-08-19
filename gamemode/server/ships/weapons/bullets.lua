aw_bullets = aw_bullets or {}

local next_bullet_id = 1
local next_collision_check = 0

local function allocate_bullet_id()
    local id = next_bullet_id
    next_bullet_id = next_bullet_id + 1
    if next_bullet_id > 32760 then next_bullet_id = 1 end
    return id
end

function calculate_bullet_start(ship, position, angle)
    local view = Matrix()
    view:Translate(ship.position)
    view:Rotate(ship.angles)

    local matrix = Matrix()
    matrix:Translate(position - ship.center)
    matrix:Rotate(angle)
    matrix = view * matrix

    return matrix:GetTranslation(), matrix:GetAngles()
end

function add_bullet(position, direction, weapon, velocity, weapon_ent)
    if not istable(weapon) or not istable(weapon.custom_info) then return nil end

    local info = weapon.custom_info
    local ammo_name = IsValid(weapon_ent) and weapon_ent:GetNWString("skyfall_ammo_type", "standard") or "standard"
    local ammo = Skyfall.GetAmmoType(ammo_name)

    local bullet = {
        position = position,
        previous_position = position,
        direction = direction,
        speed = math.max(0, (tonumber(info.speed) or 0) * (ammo.speed or 1)),
        damage = math.max(0, (tonumber(info.damage) or 0) * (ammo.damage or 1)),
        weapon = weapon.id,
        weapon_ent = weapon_ent,
        ship = weapon.aw_team or weapon.ship_id,
        gravity = tonumber(info.gravity) or 0,
        velocity = velocity or Vector(),
        fall_velocity = Vector(),
        life_time = CurTime() + math.max(0.2, tonumber(info.lifetime) or 6),
        effect_type = tonumber(info.effect_type) or EFFECT_TYPE_CANNON,
        splash_radius = math.max(1, (tonumber(info.splash_radius) or 1) * (ammo.splash or 1)),
        penetration = math.Clamp(math.max(tonumber(info.penetration) or 0, tonumber(ammo.penetration) or 0), 0, 1),
        component_multiplier = math.max(0, (tonumber(info.component_multiplier) or 1) * (tonumber(ammo.component) or 1)),
        hull_multiplier = tonumber(info.hull_multiplier) or 1,
        fire = math.max(0, (tonumber(info.fire) or 0) + (tonumber(ammo.fire) or 0)),
        ammo_type = ammo_name,
        armed_at = CurTime() + 0.08,
        id = allocate_bullet_id()
    }

    table.insert(aw_bullets, bullet)
    return bullet
end

local function find_close_parts(position, ship, radius)
    local list = {}
    local radius_sqr = radius * radius
    for _, part in pairs(ship.parts or {}) do
        if part.position and part.position:DistToSqr(position) <= radius_sqr then
            table.insert(list, part)
        end
    end
    return list
end

local function send_hit(bullet, ship_id, position)
    net.Start("aw_bullet_hit")
    net.WriteInt(bullet.id, 16)
    net.WriteInt(bullet.effect_type, 8)
    net.WriteInt(ship_id, 16)
    net.WriteVector(position or bullet.position)
    net.Broadcast()
end

local function ship_collision_radius(ship)
    local max = ship.max or Vector()
    local min = ship.min or Vector()
    return math.max(500, (max - min):Length() * 0.65 + 250)
end

local function damage_part(part, bullet, fraction)
    if not part or part.destroyed then return end
    fraction = math.Clamp(tonumber(fraction) or 1, 0, 1)
    if fraction <= 0 then return end

    local spec = {
        kind = part.component_type == Skyfall.ComponentTypes.HULL and "hull" or "component",
        penetration = bullet.penetration,
        component_multiplier = bullet.component_multiplier,
        hull_multiplier = bullet.hull_multiplier
    }
    part:ApplyDamage(bullet.damage * fraction, spec, bullet.weapon_ent)

    if bullet.fire > 0 then
        part:AddFireStacks(bullet.fire * math.max(0.25, fraction))
    end
end

local function process_hit(ship, bullet, trace)
    local entity = trace.Entity
    if not IsValid(entity) then return false end

    if entity.part_id then
        local hit_part = ship.parts and ship.parts[entity.part_id]
        if hit_part then
            local splash = math.max(1, bullet.splash_radius)
            local nearby = find_close_parts(hit_part.position, ship, splash)
            if #nearby == 0 then
                damage_part(hit_part, bullet, 1)
            else
                for _, part in ipairs(nearby) do
                    local distance = hit_part.position:Distance(part.position)
                    local fraction = math.Clamp(1 - (distance / splash), 0.10, 1)
                    damage_part(part, bullet, fraction)
                end
            end
        end
    end

    if entity:IsPlayer() then
        local damage = DamageInfo()
        damage:SetDamage(bullet.damage * 2.25)
        damage:SetDamageType(DMG_BLAST)
        damage:SetDamagePosition(trace.HitPos)
        damage:SetAttacker(IsValid(bullet.weapon_ent) and bullet.weapon_ent or game.GetWorld())
        damage:SetInflictor(IsValid(bullet.weapon_ent) and bullet.weapon_ent or game.GetWorld())
        entity:TakeDamageInfo(damage)
    end

    send_hit(bullet, ship.id, trace.HitPos)
    hook.Run("AirWars_BulletHit", entity, bullet, ship)
    hook.Run("Skyfall_ProjectileHit", entity, bullet, ship, trace)
    return true
end

local function check_bullets_collision()
    if #aw_bullets == 0 then return end
    local started = Skyfall.ProfileStart("bullet_collisions")

    for index = #aw_bullets, 1, -1 do
        local bullet = aw_bullets[index]
        local removed = false

        for _, ship in pairs(world_ships or {}) do
            if removed then break end
            if not ship.position or not ship.angles then continue end
            if ship.id == bullet.ship and CurTime() < bullet.armed_at then continue end

            local radius = ship_collision_radius(ship)
            if ship.position:DistToSqr(bullet.position) > radius * radius then continue end

            local view = Matrix()
            view:Translate(global_config.world_center)
            view:Rotate(-ship.angles)
            view:Translate(-ship.position)

            local bullet_matrix = Matrix()
            bullet_matrix:Translate(bullet.position)
            bullet_matrix:Rotate(bullet.direction)
            bullet_matrix = view * bullet_matrix

            local travel_distance = math.max(80, bullet.previous_position:Distance(bullet.position) + 40)
            local trace = util.TraceLine({
                start = bullet_matrix:GetTranslation(),
                endpos = bullet_matrix:GetTranslation() - bullet_matrix:GetAngles():Forward() * travel_distance,
                filter = function(entity)
                    if not IsValid(entity) then return false end
                    if entity.part_id == bullet.weapon then return false end
                    if entity:IsPlayer() then return entity:GetCurrentShip() == ship.id end
                    return entity.GetAWTeam and entity:GetAWTeam() == ship.id
                end,
                ignoreworld = true
            })

            if IsValid(trace.Entity) and process_hit(ship, bullet, trace) then
                table.remove(aw_bullets, index)
                removed = true
            end
        end
    end

    Skyfall.ProfileEnd("bullet_collisions", started)
end

hook.Add("Think", "Move Bullets", function()
    if #aw_bullets == 0 then return end
    local dt = math.Clamp(FrameTime(), 0, 0.1)

    for index = #aw_bullets, 1, -1 do
        local bullet = aw_bullets[index]
        bullet.previous_position = Vector(bullet.position.x, bullet.position.y, bullet.position.z)
        bullet.fall_velocity:Add(Vector(0, 0, bullet.gravity * 140) * dt)
        local forward_velocity = bullet.direction:Forward() * bullet.speed + bullet.velocity
        bullet.position:Add(-forward_velocity * dt)
        bullet.position:Add(-bullet.fall_velocity * dt)

        if CurTime() > bullet.life_time then
            table.remove(aw_bullets, index)
        end
    end
end)

hook.Add("Think", "Check bullets collisions", function()
    if CurTime() < next_collision_check then return end
    next_collision_check = CurTime() + 0.02
    check_bullets_collision()
end)
