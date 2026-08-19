local next_position_update = 0

function init_ship_controls()
    return {
        direction = Vector(),
        angle = Angle(),
        controller_angle = Angle()
    }
end

local function component_efficiency(ship, component_type)
    if not istable(ship) then return 0 end
    local count = 0
    local total = 0

    for _, part in pairs(ship.parts or {}) do
        if part.component_type == component_type then
            count = count + 1
            total = total + Skyfall.GetPartEffectiveness(part)
        end
    end
    for _, part in pairs(ship.destroyed_parts or {}) do
        if part.component_type == component_type then
            count = count + 1
        end
    end

    if count == 0 then return 1 end
    return math.Clamp(total / count, 0, 1.35)
end

hook.Add("KeyPress", "Ship Controls PBD", function(ply, key)
    local controller = ply:GetEntityUnderControl()
    if not IsValid(controller) or controller:GetClass() != "aw_ship_controller" then return end

    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship or not ship.direction then return end

    ship.active_pilot = ply
    ship.direction.controller_angle = ply.controller_angle or Angle()
    if key == IN_FORWARD then ship.direction.direction.x = 1 end
    if key == IN_BACK then ship.direction.direction.x = -1 end
    if key == IN_MOVELEFT then ship.direction.angle.y = 1 end
    if key == IN_MOVERIGHT then ship.direction.angle.y = -1 end
    if key == IN_JUMP then ship.direction.direction.z = 1 end
    if key == IN_SPEED then ship.direction.direction.z = -1 end
end)

hook.Add("KeyRelease", "Ship Controls PBU", function(ply, key)
    local controller = ply:GetEntityUnderControl()
    if not IsValid(controller) or controller:GetClass() != "aw_ship_controller" then return end

    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship or not ship.direction then return end

    ship.direction.controller_angle = ply.controller_angle or Angle()
    if key == IN_FORWARD or key == IN_BACK then ship.direction.direction.x = 0 end
    if key == IN_MOVELEFT or key == IN_MOVERIGHT then ship.direction.angle.y = 0 end
    if key == IN_SPEED or key == IN_JUMP then ship.direction.direction.z = 0 end

    if key == IN_RELOAD and ply:IsInControl() then
        ply:ExitControl()
    end
end)

hook.Add("Think", "Update Ships Position", function()
    local now = CurTime()
    local interval = Skyfall.GetConfig("performance.position_sync_interval", nil) or global_config.position_sync_rate
    if next_position_update > now then return end
    next_position_update = now + math.max(0.02, tonumber(interval) or 0.1)

    for _, ship in pairs(world_ships or {}) do
        if ship.disable_position_sync or not ship.SyncPosition then continue end
        ship:SyncPosition()
    end
end)

hook.Add("Think", "Update Ships Controls", function()
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    local started = Skyfall.ProfileStart("ship_controls")
    local frame_scale = math.Clamp(FrameTime() * 60, 0, 4)
    local damping_factor = math.pow(0.99, frame_scale)

    for _, ship in pairs(world_ships or {}) do
        if ship.disable_position_sync or not ship.direction then continue end

        ship.velocity = ship.velocity or Vector()
        ship.angle_velocity = ship.angle_velocity or Angle()
        ship.speed = ship.velocity:Length()
        ship.rotation_speed = math.abs(ship.angle_velocity.x) + math.abs(ship.angle_velocity.y) + math.abs(ship.angle_velocity.z)

        local pilot_multiplier = 1
        if IsValid(ship.active_pilot) then
            pilot_multiplier = ship.active_pilot:GetSkyfallRoleMultiplier("handling_multiplier", 1)
        end
        local helm_efficiency = component_efficiency(ship, Skyfall.ComponentTypes.HELM)
        local propulsion_efficiency = fight_calculate_efficiency(ship.id)
        local max_height = calculate_height(ship.id)

        local forward = (ship.angles + ship.direction.controller_angle + Angle(0, 90)):Forward()
        local input_vector = -ship.direction.direction.x * forward + Vector(0, 0, ship.direction.direction.z)
        local turn_input = ship.direction.angle

        ship.velocity:Add(input_vector * 2 * propulsion_efficiency * pilot_multiplier * frame_scale)
        ship.velocity = ship.velocity * damping_factor

        ship.angle_velocity = ship.angle_velocity + (turn_input / 4 * propulsion_efficiency * helm_efficiency * pilot_multiplier * frame_scale)
        ship.angle_velocity = ship.angle_velocity * damping_factor

        if ship.position.z > max_height then
            ship.velocity.z = math.min(ship.velocity.z, -200)
        end

        ship.angles:Add(ship.angle_velocity * FrameTime())
        ship.position:Add(ship.velocity * FrameTime())
    end

    Skyfall.ProfileEnd("ship_controls", started)
end)

hook.Add("aw_player_exit_control", "Reset ship velocity", function(ply, controller)
    if not IsValid(controller) or controller:GetClass() != "aw_ship_controller" then return end
    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship or not ship.direction then return end
    ship.direction.direction = Vector()
    ship.direction.angle = Angle()
    if ship.active_pilot == ply then ship.active_pilot = nil end
end)
