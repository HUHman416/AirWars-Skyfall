if SERVER then AddCSLuaFile() end

SWEP.PrintName = "Skyfall Engineer Tool"
SWEP.Author = "AirWars: Skyfall Contributors"
SWEP.Instructions = "Primary: repair component | Secondary: suppress fire/buff, or rebuild nearby destroyed component"
SWEP.Category = "AirWars: Skyfall"
SWEP.Spawnable = false
SWEP.AdminOnly = false

SWEP.Slot = 4
SWEP.HoldType = "melee"
SWEP.ViewModelFOV = 62
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

local RANGE = 120

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

local function trace_component(owner)
    if not IsValid(owner) then return nil, nil end
    local tr = util.TraceLine({
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * RANGE,
        filter = owner
    })

    local ent = tr.Entity
    if not IsValid(ent) or not ent.part_id or not ent.GetAWTeam then return nil, tr end
    if ent:GetAWTeam() ~= owner:GetCurrentShip() then return nil, tr end

    local ship = world_ships and world_ships[ent:GetAWTeam()]
    if not ship then return nil, tr end
    return ship.parts and ship.parts[ent.part_id] or nil, tr
end

local function find_nearby_destroyed(owner)
    if not IsValid(owner) then return nil, nil end
    local ship = world_ships and world_ships[owner:GetCurrentShip()]
    if not ship or not istable(ship.destroyed_parts) then return nil, nil end

    local nearest
    local nearest_distance = RANGE * RANGE
    for _, part in pairs(ship.destroyed_parts) do
        local pos = part.combat_position
        if not isvector(pos) then continue end
        local dist = owner:GetPos():DistToSqr(pos)
        if dist <= nearest_distance then
            nearest_distance = dist
            nearest = part
        end
    end
    return ship, nearest
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + 0.65)
    if CLIENT then return end

    local owner = self:GetOwner()
    local part = trace_component(owner)
    if not part then return end

    local multiplier = owner:GetSkyfallRoleMultiplier("repair_multiplier", 1)
    local amount = 10 * multiplier
    if part:AddHealth(amount, owner) then
        owner:EmitSound("ambient/materials/metal_stress2.wav", 65, 115)
    end
end

function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire(CurTime() + 1.0)
    if CLIENT then return end

    local owner = self:GetOwner()
    local part = trace_component(owner)
    if part then
        local role_mult = owner:GetSkyfallRoleMultiplier("repair_multiplier", 1)
        if (part.fire_stacks or 0) > 0 then
            part:SetFireStacks(math.max(0, (part.fire_stacks or 0) - math.ceil(2 * role_mult)))
            owner:EmitSound("ambient/gas/steam2.wav", 65, 110)
            return
        end

        part:ApplyBuff(6 + (4 * role_mult), 1.05 + (0.05 * math.min(role_mult, 1.5)))
        owner:EmitSound("buttons/button17.wav", 60, 115)
        return
    end

    local ship, destroyed = find_nearby_destroyed(owner)
    if ship and destroyed and AirWars:RebuildPart(ship, destroyed.id, owner) then
        owner:EmitSound("ambient/materials/metal_stress4.wav", 70, 105)
        owner:ChatPrint("Rebuilt " .. tostring(destroyed.component_type or "component") .. " at 35% health")
    end
end
