clientside_models = clientside_models or {}
aw_parts_ents = aw_parts_ents or {}

function try_load_model(model)
    if clientside_models[model] then return clientside_models[model] end
    clientside_models[model] = ClientsideModel(model)
    if IsValid(clientside_models[model]) then
        clientside_models[model]:SetNoDraw(true)
    end
    return clientside_models[model]
end

net.Receive("aw_sync_parts", function()
    local msg_length = net.ReadInt(32)
    if msg_length <= 0 or msg_length > 63000 then return end

    local compressed = net.ReadData(msg_length)
    local ship_id = net.ReadInt(16)
    local ship = world_ships and world_ships[ship_id]
    if not ship then return end

    local json = util.Decompress(compressed)
    if not json then return end
    local parts = util.JSONToTable(json)
    if not parts then return end

    ship.parts = parts
    ship.destroyed_parts = ship.destroyed_parts or {}
end)

net.Receive("aw_sync_part_health", function()
    local part_id = net.ReadInt(32)
    local ship_id = net.ReadInt(16)
    local health = net.ReadInt(16)

    local ship = world_ships and world_ships[ship_id]
    if not ship then return end
    ship.parts = ship.parts or {}
    ship.destroyed_parts = ship.destroyed_parts or {}

    local part = ship.parts[part_id] or ship.destroyed_parts[part_id]
    if not part then return end

    local damage = (part.health or health) - health
    part.health = health

    if health <= 0 and ship.parts[part_id] then
        part.destroyed = true
        part.disabled = true
        ship.destroyed_parts[part_id] = part
        ship.parts[part_id] = nil
        hook.Run("aw_part_destroyed", ship, part, damage)
        hook.Run("Skyfall_ComponentDestroyedClient", ship, part, damage)
    end
end)

net.Receive("aw_skyfall_part_state", function()
    local ship_id = net.ReadInt(32)
    local part_id = net.ReadInt(32)
    local component_type = net.ReadString()
    local health = net.ReadFloat()
    local max_health = net.ReadFloat()
    local fire_stacks = net.ReadUInt(8)
    local disabled = net.ReadBool()
    local buff_remaining = net.ReadFloat()
    local armor = net.ReadFloat()

    local ship = world_ships and world_ships[ship_id]
    if not ship then return end
    ship.parts = ship.parts or {}
    ship.destroyed_parts = ship.destroyed_parts or {}

    local part = ship.parts[part_id] or ship.destroyed_parts[part_id]
    if not part then return end

    part.component_type = component_type
    part.health = health
    part.max_health = max_health
    part.fire_stacks = fire_stacks
    part.disabled = disabled
    part.buff_until = CurTime() + math.max(0, buff_remaining)
    part.armor = armor
end)
