AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetUseType(SIMPLE_USE)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCustomCollisionCheck(true)

    local profile_id = self.SkyfallWeaponProfile or self:GetNWString("skyfall_weapon_profile", "")
    local profile = Skyfall.GetWeaponProfile(profile_id)
    if not profile then
        profile_id = "gatling"
        profile = Skyfall.GetWeaponProfile(profile_id)
    end

    self.SkyfallWeaponProfile = profile_id
    self:SetNWString("skyfall_weapon_profile", profile_id)
    self.AmmoAmount = math.max(1, math.floor(profile.ammo or 1))
    self.Cooldown = math.max(0.05, tonumber(profile.cooldown) or 1)
    self.ShootingOffset = tonumber(profile.shooting_offset) or 70
    self.ShootingAngle = profile.shooting_angle or Angle()
    self:SetAmmoAmount(self.AmmoAmount)
end
