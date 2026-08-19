SWEP.PrintName = "AW Weapon Base"
SWEP.Slot = 0
SWEP.HoldType = "melee"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.UseHands = true

function SWEP:Initialize()
    self:SetHoldType(self.HoldType)
end

function SWEP:SendWeaponEffect(trace, entity)
    if not SERVER then return end
    net.Start("aw_weapon_effect")
    net.WriteVector(trace.HitPos)
    net.WriteVector(trace.Normal)
    net.WriteInt(trace.SurfaceProps or 0, 32)
    net.WriteInt(trace.HitBox or 0, 32)
    net.WriteEntity(IsValid(entity) and entity or Entity(-1))
    net.SendOmit(self:GetOwner())
end

function SWEP:MakeClientEffect(trace, entity)
    local effectdata = EffectData()
    effectdata:SetOrigin(trace.HitPos)
    effectdata:SetNormal(trace.Normal)
    effectdata:SetSurfaceProp(trace.SurfaceProps or 0)
    effectdata:SetHitBox(trace.HitBox or 0)
    if IsValid(entity) then effectdata:SetEntity(entity) end
    util.Effect("Impact", effectdata)
end

function SWEP:ApplyDamage(entity, amount, spec)
    if not IsValid(entity) then return end

    if entity.part_id and entity.GetAWTeam then
        local ship = world_ships and world_ships[entity:GetAWTeam()]
        local part = ship and ship.parts and ship.parts[entity.part_id]
        if part then
            if SERVER then
                part:ApplyDamage((tonumber(amount) or 0) / 5, spec or {kind = "component", penetration = 0.15}, self:GetOwner())
            end
            return
        end
    end

    if not entity:IsPlayer() then return end
    local owner = self:GetOwner()
    local damage = DamageInfo()
    damage:SetDamage(tonumber(amount) or 0)
    damage:SetAttacker(IsValid(owner) and owner or game.GetWorld())
    damage:SetInflictor(IsValid(self) and self or game.GetWorld())
    damage:SetDamageForce(IsValid(owner) and owner:GetAimVector() * 1500 or Vector())
    damage:SetDamagePosition(IsValid(owner) and owner:GetPos() or entity:GetPos())
    damage:SetDamageType(DMG_CLUB)
    entity:TakeDamageInfo(damage)
end

function SWEP:MakeTrace(range)
    local owner = self:GetOwner()
    if not IsValid(owner) then return {} end

    local trace = {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + owner:GetAimVector() * (tonumber(range) or 75),
        filter = function(ent)
            if ent == owner then return false end
            if ent:IsPlayer() then return ent:GetCurrentShip() == owner:GetCurrentShip() end
            return ent.GetAWTeam and ent:GetAWTeam() == owner:GetCurrentShip()
        end
    }
    return util.TraceLine(trace)
end

function SWEP:PrimaryAttack()
end

function SWEP:SecondaryAttack()
end
