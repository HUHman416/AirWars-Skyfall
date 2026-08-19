-- AirWars: Skyfall accessibility and presentation preferences.

Skyfall = Skyfall or {}

local hud_scale = CreateClientConVar("aw_skyfall_hud_scale", "1.0", true, false, "Scale Skyfall-specific HUD elements", 0.75, 1.50)
local high_contrast = CreateClientConVar("aw_skyfall_high_contrast", "0", true, false, "Use higher-contrast Skyfall HUD colors")
local reduced_motion = CreateClientConVar("aw_skyfall_reduced_motion", "0", true, false, "Reduce optional Skyfall camera/screen motion effects")
local text_alerts = CreateClientConVar("aw_skyfall_text_alerts", "1", true, false, "Show text equivalents for Skyfall audio/environment alerts")

function Skyfall.HUDScale()
    return math.Clamp(hud_scale:GetFloat(), 0.75, 1.50)
end

function Skyfall.HighContrast()
    return high_contrast:GetBool()
end

function Skyfall.ReducedMotion()
    return reduced_motion:GetBool()
end

function Skyfall.TextAlerts()
    return text_alerts:GetBool()
end

function Skyfall.HUDAccent()
    return Skyfall.HighContrast() and Color(255, 230, 90) or Color(224, 185, 92)
end

function Skyfall.RebuildHUDFonts()
    local scale = Skyfall.HUDScale()
    surface.CreateFont("SkyfallHUDTitle", {font = "Trebuchet24", size = math.Round(22 * scale), weight = 800})
    surface.CreateFont("SkyfallHUDBody", {font = "Trebuchet18", size = math.Round(16 * scale), weight = 600})
    surface.CreateFont("SkyfallMissionTitle", {font = "Trebuchet24", size = math.Round(24 * scale), weight = 900})
end

Skyfall.RebuildHUDFonts()
cvars.AddChangeCallback("aw_skyfall_hud_scale", function() timer.Simple(0, Skyfall.RebuildHUDFonts) end, "Skyfall_RebuildHUDFonts")

concommand.Add("aw_accessibility", function()
    chat.AddText(Skyfall.HUDAccent(), "[Skyfall Accessibility] ", color_white,
        string.format("HUD scale %.2f | high contrast %s | reduced motion %s | text alerts %s",
            Skyfall.HUDScale(), Skyfall.HighContrast() and "ON" or "OFF", Skyfall.ReducedMotion() and "ON" or "OFF", Skyfall.TextAlerts() and "ON" or "OFF"))
end)
