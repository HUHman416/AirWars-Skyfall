if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Skyfall Sabotage Kit"
SWEP.Author = "AirWars: Skyfall Contributors"
SWEP.Instructions = "Primary: damage an enemy component | Secondary: ignite/disrupt enemy machinery"
SWEP.Category = "AirWars: Skyfall"
SWEP.Spawnable = false

SWEP.Slot = 4
SWEP.HoldType = "melee"
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

local RANGE = 105

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function boarded_enemy_part(owner)
    if not IsValid(owner) then return nil end
    local current_ship = owner:GetCurrentShip()
    if current_ship == owner:GetAWTeam() then return nil end
    local ship = world_ships and world_ships[current_ship]
    if not ship then return nil end
    if ship.captured_by == owner:GetAWTeam() then return nil end

    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * RANGE,
        filter = owner
    })
    local ent = tr.Entity
    if not IsValid(ent) or not ent.part_id or not ent.GetAWTeam or ent:GetAWTeam() ~= current_ship then return nil end
    return ship.parts and ship.parts[ent.part_id], ship, ent
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.75)
    if CLIENT then return end
    local owner = self:GetOwner()
    local part = boarded_enemy_part(owner)
    if not part then return end

    part:ApplyDamage(18, {kind = "component", penetration = 0.30, component_multiplier = 1.55, hull_multiplier = 0.70}, owner)
    owner:EmitSound("physics/metal/metal_box_impact_hard2.wav", 70, 105)
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 2.25)
    if CLIENT then return end
    local owner = self:GetOwner()
    local part = boarded_enemy_part(owner)
    if not part then return end

    part:ApplyDamage(8, {kind = "component", penetration = 0.15, component_multiplier = 1.20, hull_multiplier = 0.50}, owner)
    part:AddFireStacks(2)
    part.disabled = true
    if part.SyncState then part:SyncState() end
    owner:EmitSound("ambient/energy/spark6.wav", 70, 95)
end
