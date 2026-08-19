-- AirWars: Skyfall crew/status and Alliance mission HUD.

Skyfall = Skyfall or {}
Skyfall.SpottedShips = Skyfall.SpottedShips or {}
Skyfall.ClientMission = Skyfall.ClientMission or {active = false}

local enabled = CreateClientConVar("aw_skyfall_hud", "1", true, false, "Show the Skyfall crew/component HUD")

surface.CreateFont("SkyfallHUDTitle", {font = "Trebuchet24", size = 22, weight = 800})
surface.CreateFont("SkyfallHUDBody", {font = "Trebuchet18", size = 16, weight = 600})
surface.CreateFont("SkyfallMissionTitle", {font = "Trebuchet24", size = 24, weight = 900})

local COMPONENT_LABELS = {
    hull = "Hull",
    helm = "Helm",
    propulsion = "Engines",
    lift = "Lift",
    weapon = "Weapons",
    ammo = "Ammo",
    spawn = "Spawn",
    utility = "Utility"
}

local function component_summary(ship)
    local result = {}
    for _, part in pairs(ship.parts or {}) do
        local kind = part.component_type or "hull"
        result[kind] = result[kind] or {health = 0, max = 0, fire = 0, destroyed = 0}
        local row = result[kind]
        row.health = row.health + (tonumber(part.health) or 0)
        row.max = row.max + (tonumber(part.max_health or (part.info and part.info.health) or 100) or 100)
        row.fire = row.fire + (tonumber(part.fire_stacks) or 0)
    end
    for _, part in pairs(ship.destroyed_parts or {}) do
        local kind = part.component_type or "hull"
        result[kind] = result[kind] or {health = 0, max = 0, fire = 0, destroyed = 0}
        result[kind].max = result[kind].max + (tonumber(part.max_health) or 100)
        result[kind].destroyed = result[kind].destroyed + 1
    end
    return result
end

net.Receive("aw_skyfall_spot", function()
    local ship_id = net.ReadInt(32)
    local duration = net.ReadFloat()
    Skyfall.SpottedShips[ship_id] = CurTime() + math.max(0, duration)
end)

net.Receive("aw_skyfall_mission", function()
    Skyfall.ClientMission = net.ReadTable() or {active = false}
end)

local function draw_mission()
    local mission = Skyfall.ClientMission
    if not mission or not mission.active then return end

    local width = math.min(620, ScrW() - 80)
    local x = (ScrW() - width) / 2
    local y = 26
    draw.RoundedBox(8, x, y, width, 86, Color(15, 18, 22, 218))
    draw.RoundedBox(8, x + 3, y + 3, width - 6, 4, Color(205, 165, 75, 235))
    draw.SimpleText(mission.label or "ALLIANCE MISSION", "SkyfallMissionTitle", ScrW() / 2, y + 14, Color(232, 195, 104), TEXT_ALIGN_CENTER)
    draw.SimpleText(mission.objective or "", "SkyfallHUDBody", ScrW() / 2, y + 45, Color(235, 235, 235), TEXT_ALIGN_CENTER)

    local extra = string.format("Time %d:%02d", math.floor((mission.time_left or 0) / 60), (mission.time_left or 0) % 60)
    if (mission.waves or 0) > 0 then extra = extra .. string.format("   Wave %d/%d", mission.wave or 0, mission.waves) end
    if (mission.score or 0) > 0 then extra = extra .. "   Progress " .. tostring(mission.score) end
    draw.SimpleText(extra, "SkyfallHUDBody", ScrW() / 2, y + 66, Color(180, 198, 210), TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "Skyfall_CrewHUD", function()
    if not enabled:GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:IsSpectator() then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    draw_mission()

    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship then return end

    local x = 24
    local y = ScrH() - 245
    local width = 260
    local summary = component_summary(ship)

    draw.RoundedBox(8, x, y, width, 210, Color(15, 18, 22, 205))
    draw.SimpleText("AIRWARS: SKYFALL", "SkyfallHUDTitle", x + 12, y + 10, Color(224, 185, 92), TEXT_ALIGN_LEFT)
    draw.SimpleText("Role: " .. ply:GetSkyfallRoleData().name .. "  Ammo: " .. ply:GetNWString("skyfall_ammo", "standard"), "SkyfallHUDBody", x + 12, y + 38, Color(235, 235, 235), TEXT_ALIGN_LEFT)

    local line_y = y + 65
    local order = {"hull", "helm", "propulsion", "lift", "weapon"}
    for _, kind in ipairs(order) do
        local row = summary[kind]
        if row and row.max > 0 then
            local pct = math.Clamp(row.health / row.max, 0, 1)
            local label = COMPONENT_LABELS[kind] or kind
            local suffix = row.destroyed > 0 and ("  X" .. row.destroyed) or ""
            if row.fire > 0 then suffix = suffix .. "  FIRE:" .. row.fire end

            draw.SimpleText(string.format("%-8s %3d%%%s", label, math.floor(pct * 100), suffix), "SkyfallHUDBody", x + 12, line_y, Color(220, 220, 220), TEXT_ALIGN_LEFT)
            draw.RoundedBox(2, x + 120, line_y + 4, 120, 8, Color(55, 55, 55, 220))
            draw.RoundedBox(2, x + 120, line_y + 4, 120 * pct, 8, Color(205, 165, 75, 235))
            line_y = line_y + 24
        end
    end

    local spotted = 0
    for ship_id, expires in pairs(Skyfall.SpottedShips) do
        if expires <= CurTime() then
            Skyfall.SpottedShips[ship_id] = nil
        else
            spotted = spotted + 1
        end
    end
    if spotted > 0 then
        draw.SimpleText("Spotted targets: " .. spotted, "SkyfallHUDBody", x + 12, y + 188, Color(255, 150, 100), TEXT_ALIGN_LEFT)
    end
end)
