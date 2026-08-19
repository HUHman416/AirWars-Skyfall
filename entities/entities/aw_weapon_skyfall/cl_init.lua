include("shared.lua")

function ENT:DrawInfo(position, angle, scale)
    if LocalPlayer():IsSpectator() then return end
    scale = scale or 0.22
    local profile = Skyfall.GetWeaponProfile(self:GetNWString("skyfall_weapon_profile", ""))
    local name = profile and profile.name or "Skyfall Weapon"
    local ammo = self:GetAmmoAmount()

    render.OverrideDepthEnable(true, true)
    render.DepthRange(0, 0)
    cam.Start3D2D(position, angle, scale)
        surface.SetDrawColor(35, 31, 25, 235)
        surface.DrawRect(0, 0, 260, 70)
        surface.SetDrawColor(130, 94, 45, 255)
        surface.DrawOutlinedRect(3, 3, 254, 64, 2)
        draw.SimpleText(name, "DermaDefaultBold", 130, 20, Color(235, 202, 125), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(ammo > 0 and ("Ammo: " .. ammo) or "RELOAD", "DermaDefaultBold", 130, 48, Color(240, 240, 240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
    render.DepthRange(0, 1)
    render.OverrideDepthEnable(false, false)
end

function ENT:Draw()
    if self:GetAWTeam() != LocalPlayer():GetCurrentShip() then return end
    local position = self:LocalToWorld(Vector(-25, -40, 25))
    local angle = self:GetAngles() - Angle(180, 180, 90)
    self:DrawInfo(position, angle)
end
