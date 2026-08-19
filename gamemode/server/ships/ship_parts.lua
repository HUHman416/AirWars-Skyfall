Part = Part or {}

local function max_health(part)
    return math.max(1, tonumber(part.max_health or (part.info and part.info.health) or 100) or 100)
end

function part_table_simple(part)
    return {
        model = part.model,
        position = part.position,
        angle = part.angle,
        id = part.id,
        health = part.health,
        max_health = max_health(part),
        ship_id = part.ship_id,
        info = part.info,
        entity = part.entity,
        component_type = part.component_type,
        fire_stacks = part.fire_stacks or 0,
        disabled = part.disabled == true,
        buff_until = part.buff_until or 0,
        armor = part.armor or 0
    }
end

local function find_part_entity(part)
    for _, ent in ipairs(ents.FindByClass("aw*")) do
        if ent.part_id ~= part.id then continue end
        if not ent.GetAWTeam or ent:GetAWTeam() ~= part.ship_id then continue end
        return ent
    end
end

local function sync_health(part)
    net.Start("aw_sync_part_health")
    net.WriteInt(part.id, 32)
    net.WriteInt(part.ship_id, 16)
    net.WriteInt(math.floor(math.Clamp(part.health or 0, 0, 32767)), 16)
    net.Broadcast()
end

local function sync_state(part)
    net.Start("aw_skyfall_part_state")
    net.WriteInt(part.ship_id, 32)
    net.WriteInt(part.id, 32)
    net.WriteString(part.component_type or Skyfall.ComponentTypes.HULL)
    net.WriteFloat(tonumber(part.health) or 0)
    net.WriteFloat(max_health(part))
    net.WriteUInt(math.Clamp(math.floor(part.fire_stacks or 0), 0, 255), 8)
    net.WriteBool(part.disabled == true)
    net.WriteFloat(math.max(0, (part.buff_until or 0) - CurTime()))
    net.WriteFloat(tonumber(part.armor) or 0)
    net.Broadcast()
end

local function destroy_part(part, reason)
    local ship = world_ships and world_ships[part.ship_id]
    if not ship or not ship.parts[part.id] then return end

    part.health = 0
    part.destroyed = true
    part.disabled = true
    ship.destroyed_parts = ship.destroyed_parts or {}
    ship.destroyed_parts[part.id] = part
    ship.parts[part.id] = nil

    local ent = find_part_entity(part)
    if IsValid(ent) then ent:Remove() end

    ship:UpdateMinMax()
    sync_health(part)
    sync_state(part)

    hook.Run("aw_part_destroyed", ship, part, reason)
    hook.Run("Skyfall_ComponentDestroyed", ship, part, reason)
end

local function add_health(part, amount, source)
    if part.destroyed then return false end
    amount = tonumber(amount) or 0
    if amount == 0 then return false end

    local previous = tonumber(part.health) or 0
    part.health = math.Clamp(previous + amount, 0, max_health(part))

    if part.health <= 0 then
        destroy_part(part, source)
        return true
    end

    if part.health > max_health(part) * 0.20 then
        part.disabled = false
    end

    sync_health(part)
    sync_state(part)
    hook.Run("Skyfall_ComponentHealthChanged", world_ships[part.ship_id], part, previous, part.health, source)
    return true
end

local function apply_damage(part, amount, damage_type, attacker)
    if part.destroyed then return 0 end
    amount = math.max(0, tonumber(amount) or 0)
    if amount <= 0 then return 0 end

    local multiplier = 1
    if damage_type == "component" then multiplier = 1.25 end
    if damage_type == "hull" and part.component_type ~= Skyfall.ComponentTypes.HULL then multiplier = 0.85 end

    local applied = amount * multiplier
    part:AddHealth(-applied, attacker or damage_type)
    return applied
end

local function set_fire_stacks(part, stacks)
    part.fire_stacks = math.Clamp(math.floor(tonumber(stacks) or 0), 0, 20)
    sync_state(part)
end

local function add_fire_stacks(part, stacks)
    part:SetFireStacks((part.fire_stacks or 0) + (tonumber(stacks) or 0))
end

local function apply_buff(part, duration, multiplier)
    part.buff_until = math.max(part.buff_until or 0, CurTime() + math.max(0, tonumber(duration) or 0))
    part.buff_multiplier = math.Clamp(tonumber(multiplier) or 1.10, 1, 1.35)
    sync_state(part)
end

local function get_effectiveness(part)
    return Skyfall.GetPartEffectiveness(part)
end

function Part:new(ship_id)
    local id
    repeat
        id = math.random(1, 999999)
    until not (world_ships[ship_id] and ((world_ships[ship_id].parts and world_ships[ship_id].parts[id]) or (world_ships[ship_id].destroyed_parts and world_ships[ship_id].destroyed_parts[id])))

    local part = {
        health = 100,
        max_health = 100,
        collisions = {},
        position = Vector(),
        angle = Angle(),
        model = "models/props_phx/construct/metal_plate1.mdl",
        info = {},
        id = id,
        ship_id = ship_id,
        component_type = Skyfall.ComponentTypes.HULL,
        fire_stacks = 0,
        disabled = false,
        destroyed = false,
        armor = 0,
        buff_until = 0,
        buff_multiplier = 1.10
    }

    part.AddHealth = add_health
    part.ApplyDamage = apply_damage
    part.SetFireStacks = set_fire_stacks
    part.AddFireStacks = add_fire_stacks
    part.ApplyBuff = apply_buff
    part.GetEffectiveness = get_effectiveness
    part.SyncState = sync_state
    part.CheckHit = check_hit

    return part
end

function AirWars:RebuildPart(ship, part_id, engineer)
    if not istable(ship) or not istable(ship.destroyed_parts) then return false end
    local part = ship.destroyed_parts[part_id]
    if not part then return false end

    part.destroyed = false
    part.disabled = false
    part.fire_stacks = 0
    part.health = math.max(1, max_health(part) * 0.35)
    ship.destroyed_parts[part_id] = nil
    ship.parts[part_id] = part

    if isfunction(AirWars.BuildShipPart) then
        AirWars:BuildShipPart(ship, part)
    end

    ship:UpdateMinMax()
    ship:Sync()
    part:SyncState()
    hook.Run("Skyfall_ComponentRebuilt", ship, part, engineer)
    return true
end
