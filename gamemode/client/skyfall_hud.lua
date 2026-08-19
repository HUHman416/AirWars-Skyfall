-- AirWars: Skyfall crew/status and Alliance mission HUD.

Skyfall = Skyfall or {}
Skyfall.SpottedShips = Skyfall.SpottedShips or {}
Skyfall.ClientMission = Skyfall.ClientMission or {active = false}

local enabled = CreateClientConVar("aw_skyfall_hud", "1", true, false, "Show the Skyfall crew/component HUD")

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

local function draw_mission(scale, accent, body)
    local mission = Skyfall.ClientMission
    if not mission or not mission.active then return end

    local width = math.min(620 * scale, ScrW() - 80 * scale)
    local x = (ScrW() - width) / 2
    local y = 26 * scale
    draw.RoundedBox(8 * scale, x, y, width, 86 * scale, Color(15, 18, 22, 225))
    draw.RoundedBox(8 * scale, x + 3 * scale, y + 3 * scale, width - 6 * scale, 4 * scale, accent)
    draw.SimpleText(mission.label or "ALLIANCE MISSION", "SkyfallMissionTitle", ScrW() / 2, y + 14 * scale, accent, TEXT_ALIGN_CENTER)
    draw.SimpleText(mission.objective or "", "SkyfallHUDBody", ScrW() / 2, y + 45 * scale, body, TEXT_ALIGN_CENTER)

    local extra = string.format("Time %d:%02d", math.floor((mission.time_left or 0) / 60), (mission.time_left or 0) % 60)
    if (mission.waves or 0) > 0 then extra = extra .. string.format("   Wave %d/%d", mission.wave or 0, mission.waves) end
    if (mission.score or 0) > 0 then extra = extra .. "   Progress " .. tostring(mission.score) end
    draw.SimpleText(extra, "SkyfallHUDBody", ScrW() / 2, y + 66 * scale, Color(190, 205, 218), TEXT_ALIGN_CENTER)
end

local function draw_boarding_notice(ply, ship, scale, accent)
    if ply:GetCurrentShip() == ply:GetAWTeam() then return end
    local captured_by = ship.skyfall and ship.skyfall.captured_by or ship.captured_by
    local captured = captured_by == ply:GetAWTeam()
    local label = captured and "COMMANDEERED AUXILIARY VESSEL" or "BOARDING ENEMY VESSEL — SABOTAGE / CAPTURE AVAILABLE"
    local width = 460 * scale
    local x = (ScrW() - width) / 2
    local y = ScrH() - 72 * scale
    draw.RoundedBox(6 * scale, x, y, width, 38 * scale, Color(24, 18, 15, 220))
    draw.SimpleText(label, "SkyfallHUDBody", ScrW() / 2, y + 19 * scale, accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "Skyfall_CrewHUD", function()
    if not enabled:GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or ply:IsSpectator() then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    local scale = Skyfall.HUDScale and Skyfall.HUDScale() or 1
    local accent = Skyfall.HUDAccent and Skyfall.HUDAccent() or Color(224, 185, 92)
    local body = Skyfall.HighContrast and Skyfall.HighContrast() and Color(255, 255, 255) or Color(235, 235, 235)
    draw_mission(scale, accent, body)

    local ship = world_ships and world_ships[ply:GetCurrentShip()]
    if not ship then return end

    local x = 24 * scale
    local y = ScrH() - 255 * scale
    local width = 305 * scale
    local height = 220 * scale
    local summary = component_summary(ship)

    draw.RoundedBox(8 * scale, x, y, width, height, Color(15, 18, 22, 215))
    draw.SimpleText("AIRWARS: SKYFALL", "SkyfallHUDTitle", x + 12 * scale, y + 10 * scale, accent, TEXT_ALIGN_LEFT)

    local title_id = ply:GetNWString("skyfall_title", "none")
    local title = Skyfall.GetTitle and Skyfall.GetTitle(title_id) or ""
    local role_line = (title ~= "" and (title .. " • ") or "") .. ply:GetSkyfallRoleData().name .. " • " .. ply:GetNWString("skyfall_ammo", "standard")
    draw.SimpleText(role_line, "SkyfallHUDBody", x + 12 * scale, y + 40 * scale, body, TEXT_ALIGN_LEFT)

    local line_y = y + 69 * scale
    local order = {"hull", "helm", "propulsion", "lift", "weapon"}
    for _, kind in ipairs(order) do
        local row = summary[kind]
        if row and row.max > 0 then
            local pct = math.Clamp(row.health / row.max, 0, 1)
            local label = COMPONENT_LABELS[kind] or kind
            local suffix = row.destroyed > 0 and ("  X" .. row.destroyed) or ""
            if row.fire > 0 then suffix = suffix .. "  FIRE:" .. row.fire end

            draw.SimpleText(string.format("%-8s %3d%%%s", label, math.floor(pct * 100), suffix), "SkyfallHUDBody", x + 12 * scale, line_y, body, TEXT_ALIGN_LEFT)
            draw.RoundedBox(2 * scale, x + 145 * scale, line_y + 4 * scale, 145 * scale, 8 * scale, Color(55, 55, 55, 230))
            draw.RoundedBox(2 * scale, x + 145 * scale, line_y + 4 * scale, 145 * scale * pct, 8 * scale, accent)
            line_y = line_y + 25 * scale
        end
    end

    local spotted = 0
    for ship_id, expires in pairs(Skyfall.SpottedShips) do
        if expires <= CurTime() then Skyfall.SpottedShips[ship_id] = nil else spotted = spotted + 1 end
    end
    if spotted > 0 then
        draw.SimpleText("Spotted targets: " .. spotted, "SkyfallHUDBody", x + 12 * scale, y + 196 * scale, Color(255, 165, 105), TEXT_ALIGN_LEFT)
    end

    draw_boarding_notice(ply, ship, scale, accent)
end)
