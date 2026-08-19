-- AirWars: Skyfall boarding, sabotage support, grappling control, and vessel capture.

Skyfall.CaptureAttempts = Skyfall.CaptureAttempts or {}
local next_capture_check = 0

local function ship_component_fraction(ship, kind)
    local summary = Skyfall.GetShipComponentSummary(ship)
    local entry = summary.by_type and summary.by_type[kind]
    if not entry or entry.max_health <= 0 then return nil end
    return math.Clamp(entry.health / entry.max_health, 0, 1)
end

local function defending_crew_present(ship)
    if ship.id < 0 then return false end
    for _, defender in ipairs(player.GetAll()) do
        if defender:GetAWTeam() == ship.id and defender:Alive() and not defender:IsSpectator() and defender:GetCurrentShip() == ship.id then
            return true
        end
    end
    return false
end

function Skyfall.CanCaptureShip(ply, ship)
    if not IsValid(ply) or not istable(ship) then return false, "Invalid boarding state" end
    if ply:GetCurrentShip() ~= ship.id then return false, "You must be physically aboard the target vessel" end
    if ply:GetAWTeam() == ship.id then return false, "This is your own vessel" end
    if ship.captured_by == ply:GetAWTeam() then return false, "Your crew already controls this vessel" end
    if ship.capture_locked then return false, "This vessel has already been captured" end
    if defending_crew_present(ship) then return false, "Defending crew are still aboard" end

    local hull = ship_component_fraction(ship, Skyfall.ComponentTypes.HULL)
    if hull and hull > 0.55 then return false, "Damage the hull below 55% before capture" end

    local spawn = ship_component_fraction(ship, Skyfall.ComponentTypes.SPAWN)
    if spawn and spawn > 0 then return false, "Destroy the enemy respawn station before capture" end

    local helm = ship_component_fraction(ship, Skyfall.ComponentTypes.HELM)
    local propulsion = ship_component_fraction(ship, Skyfall.ComponentTypes.PROPULSION)
    if (helm == nil or helm > 0.20) and (propulsion == nil or propulsion > 0.25) then
        return false, "Disable the helm or cripple propulsion before capture"
    end

    return true
end

local function capture_key(ply)
    return IsValid(ply) and ply:SteamID64() or nil
end

function Skyfall.BeginCapture(ply)
    if not IsValid(ply) or not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return false, "Capture is only available during combat" end
    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    local ok, reason = Skyfall.CanCaptureShip(ply, ship)
    if not ok then return false, reason end

    local duration = ply:GetSkyfallRole() == "engineer" and 4.5 or 6
    Skyfall.CaptureAttempts[capture_key(ply)] = {
        player = ply,
        ship_id = ship.id,
        team_id = ply:GetAWTeam(),
        completes = CurTime() + duration,
        duration = duration
    }
    ply:ChatPrint(string.format("Capturing vessel... remain aboard for %.1f seconds.", duration))
    return true
end

local function complete_capture(attempt)
    local ply = attempt.player
    local ship = world_ships and world_ships[attempt.ship_id]
    if not IsValid(ply) or not ship then return false end
    local ok = Skyfall.CanCaptureShip(ply, ship)
    if not ok then return false end

    ship.captured_by = attempt.team_id
    ship.owner_team = attempt.team_id
    ship.capture_locked = true
    ship.faction = "player"
    ship.ai_controlled = false
    ship.ai_passive = true
    ship.direction = init_ship_controls()
    ship.velocity = ship.velocity or Vector()
    ship.angle_velocity = Angle()
    Skyfall.AIShips[ship.id] = nil

    if Skyfall.Mission and Skyfall.Mission.enemy_ids then
        Skyfall.Mission.enemy_ids[ship.id] = nil
    end

    ship:Sync()
    ply:ChatPrint("VESSEL CAPTURED — your crew may now operate this auxiliary ship.")
    if ply.AddPoints then ply:AddPoints(5) end
    hook.Run("Skyfall_ShipCaptured", ship, ply, attempt.team_id)
    return true
end

local function tick_captures()
    for key, attempt in pairs(Skyfall.CaptureAttempts) do
        local ply = attempt.player
        local ship = world_ships and world_ships[attempt.ship_id]
        if not IsValid(ply) or not ship or ply:GetCurrentShip() ~= attempt.ship_id or not ply:Alive() then
            if IsValid(ply) then ply:ChatPrint("Capture interrupted.") end
            Skyfall.CaptureAttempts[key] = nil
            continue
        end

        local ok, reason = Skyfall.CanCaptureShip(ply, ship)
        if not ok then
            ply:ChatPrint("Capture interrupted: " .. tostring(reason))
            Skyfall.CaptureAttempts[key] = nil
            continue
        end

        if CurTime() >= attempt.completes then
            if complete_capture(attempt) then
                Skyfall.CaptureAttempts[key] = nil
            end
        end
    end
end

hook.Add("Think", "Skyfall Capture Channels", function()
    if CurTime() < next_capture_check then return end
    next_capture_check = CurTime() + 0.25
    tick_captures()
end)

hook.Add("PlayerSpawn", "Skyfall_GiveSabotageKit", function(ply)
    timer.Simple(0, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
        if not ply:HasWeapon("aw_sabotage_tool") then ply:Give("aw_sabotage_tool") end
    end)
end)

hook.Add("PlayerDisconnected", "Skyfall_ClearCaptureAttempt", function(ply)
    Skyfall.CaptureAttempts[capture_key(ply)] = nil
end)

concommand.Add("aw_capture", function(ply)
    if not IsValid(ply) then return end
    local ok, reason = Skyfall.BeginCapture(ply)
    if not ok then ply:ChatPrint("Cannot capture: " .. tostring(reason)) end
end)

concommand.Add("aw_grapple_cut", function(ply)
    if not IsValid(ply) or not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
    local ship_id = ply:GetCurrentShip()
    local removed = Skyfall.CutShipGrapples(ship_id, ply)
    ply:ChatPrint("Cut " .. removed .. " grapple line(s).")
end)

concommand.Add("aw_boarding_status", function(ply)
    if not IsValid(ply) then return end
    local current = ply:GetCurrentShip()
    if current == ply:GetAWTeam() then
        ply:ChatPrint("You are aboard your crew's primary vessel.")
        return
    end
    local ship = world_ships and world_ships[current]
    if not ship then ply:ChatPrint("You are not aboard an active ship.") return end
    local ok, reason = Skyfall.CanCaptureShip(ply, ship)
    ply:ChatPrint("Boarded vessel " .. tostring(ship.ai_name or ship.id) .. ". Capture: " .. (ok and "READY" or tostring(reason)))
end)

Skyfall.SetFeatureEnabled("boarding", true)
Skyfall.Info("Boarding", "Grappling, sabotage, capture channels, and auxiliary ship control enabled")
