-- AirWars: Skyfall Stormfront client presentation.

Skyfall.ClientWeather = Skyfall.ClientWeather or {
    type = "clear",
    wind = Vector(),
    strength = 0,
    turbulence = 0,
    fog = 0,
    visibility = 12000,
    lightning = false
}

local weather_fx = CreateClientConVar("aw_skyfall_weather_fx", "1", true, false, "Enable Skyfall fog/weather presentation")

net.Receive("aw_skyfall_weather", function()
    local data = net.ReadTable() or {}
    local wind = data.wind or {}
    Skyfall.ClientWeather = {
        type = tostring(data.type or "clear"),
        wind = Vector(tonumber(wind.x) or 0, tonumber(wind.y) or 0, tonumber(wind.z) or 0),
        strength = tonumber(data.strength) or 0,
        turbulence = tonumber(data.turbulence) or 0,
        fog = tonumber(data.fog) or 0,
        visibility = tonumber(data.visibility) or 12000,
        lightning = data.lightning == true
    }
end)

net.Receive("aw_skyfall_notice", function()
    local kind = net.ReadString()
    local detail = net.ReadString()
    if kind == "lightning" then
        surface.PlaySound("ambient/energy/weld2.wav")
        chat.AddText(Color(230, 195, 110), "[Skyfall] ", Color(230, 230, 230), "Lightning struck ship " .. detail .. "!")
    end
end)

local function fog_color(weather_type)
    if weather_type == "aether" then return 85, 95, 112 end
    if weather_type == "storm" then return 92, 99, 105 end
    if weather_type == "fog" then return 155, 158, 150 end
    return 170, 180, 185
end

local function apply_fog(scale)
    if not weather_fx:GetBool() then return end
    local w = Skyfall.ClientWeather
    if not w or (w.fog or 0) <= 0 then return end

    local r, g, b = fog_color(w.type)
    local visibility = math.max(500, (w.visibility or 5000) * (scale or 1))
    render.FogMode(MATERIAL_FOG_LINEAR)
    render.FogStart(visibility * 0.12)
    render.FogEnd(visibility)
    render.FogMaxDensity(math.Clamp(w.fog or 0, 0, 0.95))
    render.FogColor(r, g, b)
    return true
end

hook.Add("SetupWorldFog", "Skyfall_WorldFog", function()
    return apply_fog(1)
end)

hook.Add("SetupSkyboxFog", "Skyfall_SkyboxFog", function(scale)
    return apply_fog(scale or 1)
end)

hook.Add("HUDPaint", "Skyfall_WeatherIndicator", function()
    if not weather_fx:GetBool() then return end
    local w = Skyfall.ClientWeather
    if not w or w.type == "clear" then return end

    local text = string.upper(w.type) .. string.format("  Wind %.0f", w.strength or 0)
    draw.RoundedBox(5, ScrW() - 210, 22, 188, 34, Color(15, 18, 22, 195))
    draw.SimpleText(text, "DermaDefaultBold", ScrW() - 116, 39, Color(224, 195, 122), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)
