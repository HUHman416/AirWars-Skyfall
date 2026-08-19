AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local function get_station_part(ent)
    if not IsValid(ent) or not ent.GetAWTeam then return nil, nil end
    local ship = world_ships and world_ships[ent:GetAWTeam()]
    if not ship or not ship.parts then return ship, nil end
    return ship, ship.parts[ent.part_id]
end

local function selected_ammo(ply)
    if not IsValid(ply) then return "standard" end
    local _, name = Skyfall.GetAmmoType(ply:GetNWString("skyfall_ammo", "standard"))
    return name
end

function ENT:Use(activator)
    if not IsValid(activator) or not activator:IsPlayer() or activator:IsSpectator() then return end

    local ship, part = get_station_part(self)
    if not ship or not part or part.destroyed or part.disabled then
        activator:ChatPrint("This weapon is disabled and needs repair.")
        return
    end

    if IsValid(self:GetController()) and self:GetController() ~= activator then
        activator:ChatPrint("Weapon station already occupied.")
        return
    end

    if self:GetAmmoAmount() < 1 then
        self:Reload(activator)
        return
    end

    activator:AWControl(self)
end

function ENT:Reload(ply)
    local ammo_type = "standard"
    if IsValid(ply) then
        if not ply:AWHasAmmo() then
            ply:ChatPrint("You need ammunition from an ammo storage first.")
            return false
        end
        ammo_type = selected_ammo(ply)
        ply:AWGiveAmmo(false)
    end

    self:SetNWString("skyfall_ammo_type", ammo_type)
    self:SetAmmoAmount(math.max(1, tonumber(self.AmmoAmount) or 1))
    hook.Run("Skyfall_WeaponReloaded", self, ply, ammo_type)
    return true
end

function ENT:Shoot(ply)
    if CurTime() < (self.cooldown or 0) then return end

    local ship, part = get_station_part(self)
    if not ship or not part or part.destroyed or part.disabled then
        if IsValid(ply) then ply:ExitControl() end
        return
    end

    if self:GetAmmoAmount() < 1 then
        if IsValid(ply) then ply:ExitControl() end
        return
    end

    local ammo_type = self:GetNWString("skyfall_ammo_type", "standard")
    local ammo = Skyfall.GetAmmoType(ammo_type)
    self.SkyfallAmmoType = ammo_type

    AirWars:ShipShoot(ship, part, self.ShootingOffset, self.ShootingAngle, self)
    self:SetAmmoAmount(math.Clamp(self:GetAmmoAmount() - 1, 0, math.max(1, self.AmmoAmount or 1)))

    local role_multiplier = IsValid(ply) and ply:GetSkyfallRoleMultiplier("reload_multiplier", 1) or 1
    local effectiveness = math.max(0.20, Skyfall.GetPartEffectiveness(part))
    local base_cooldown = math.max(0.05, tonumber(self.Cooldown) or 1)
    self.cooldown = CurTime() + (base_cooldown * (ammo.cooldown or 1) / role_multiplier / effectiveness)

    self:OnShoot(part)
    hook.Run("Skyfall_WeaponFired", self, ply, part, ammo_type)

    if self:GetAmmoAmount() < 1 and IsValid(ply) then
        ply:ExitControl()
    end
end

function ENT:OnShoot()
end

function ENT:OnHit()
end

function ENT:OnRemove()
    if IsValid(self:GetController()) then
        self:GetController():ExitControl()
    end
end
