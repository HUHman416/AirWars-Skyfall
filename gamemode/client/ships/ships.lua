world_ships = world_ships or {}

net.Receive("aw_sync_ship", function()
    local incoming = net.ReadTable()
    if not istable(incoming) or not incoming.id then return end

    local previous = world_ships[incoming.id]
    if previous then
        incoming.future_position = previous.future_position
        incoming.future_angles = previous.future_angles
        incoming.destroyed_parts = previous.destroyed_parts or incoming.destroyed_parts
    end
    incoming.parts = incoming.parts or {}
    incoming.destroyed_parts = incoming.destroyed_parts or {}
    world_ships[incoming.id] = incoming

    net.Start("aw_sync_parts")
    net.WriteInt(incoming.id, 32)
    net.SendToServer()
end)

net.Receive("aw_destroy_ship", function()
    local id = net.ReadInt(32)
    local ship = world_ships[id]
    if ship and ship.position and local_ship then
        sound.Play("ambient/explosions/explode_8.wav", calculate_position_raw(ship.position))
    end
    world_ships[id] = nil
end)

net.Receive("aw_sync_direction", function()
    local direction = net.ReadTable()
    local id = net.ReadInt(32)
    if world_ships[id] then world_ships[id].direction = direction end
end)

net.Receive("aw_sync_ship_position", function()
    local info = net.ReadTable()
    if not istable(info) or not info.id or not istable(info.position) then return end
    local ship = world_ships[info.id]
    if not ship then return end
    ship.future_position = Vector(tonumber(info.position[1]) or 0, tonumber(info.position[2]) or 0, tonumber(info.position[3]) or 0)
    ship.future_angles = info.angles or ship.angles
end)

hook.Add("Think", "lerp ship positions", function()
    local lerp_amount = math.Clamp(FrameTime() * 5, 0, 1)
    for _, ship in pairs(world_ships) do
        if not ship.future_position or not ship.future_angles or not ship.position or not ship.angles then continue end
        local previous = ship.position
        ship.position = LerpVector(lerp_amount, ship.position, ship.future_position)
        ship.angles = LerpAngle(lerp_amount, ship.angles, ship.future_angles)
        ship.speed = previous:Distance(ship.position)
    end
end)
