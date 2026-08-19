local meta = FindMetaTable("Player")

local next_collision_check = 0
local next_fall_check = 0
local next_bounds_check = 0

function meta:AddToPropBuffer(entity)
    if self.prop_buffer then
        table.insert(self.prop_buffer, entity)
    else
        self.prop_buffer = {entity}
    end
end

function meta:ExitControl()
    local entity_under_control = self:GetEntityUnderControl()
    if IsValid(entity_under_control) then
        entity_under_control:SetController(Entity(-1))
    end
    self:SetNWEntity("aw_entity_under_control", Entity(-1))
    hook.Run("aw_player_exit_control", self, entity_under_control)
end

function meta:AWControl(entity)
    if self:IsInControl() then
        self:ExitControl()
    end
    self:SetNWEntity("aw_entity_under_control", entity)
end

function meta:GetEntityUnderControl()
    return self:GetNWEntity("aw_entity_under_control", Entity(-1))
end

function meta:AWGiveAmmo(ammo)
    if ammo == nil then ammo = true end
    self.aw_ammo = ammo
end

function meta:AWHasAmmo()
    return self.aw_ammo
end

local function check_player_ship_collisions()
    if not istable(world_ships) or table.Count(world_ships) < 2 then return end

    local started = Skyfall.ProfileStart("player_ship_collisions")
    local players = player.GetAll()
    local transfer_distance = Skyfall.GetConfig("gameplay.boarding_transfer_distance", 2000)
    local transfer_distance_sqr = transfer_distance * transfer_distance

    for _, ship in pairs(world_ships) do
        if not istable(ship) or not ship.position or not ship.angles then continue end

        local view = Matrix()
        view:Translate(global_config.world_center)
        view:Rotate(-ship.angles)
        view:Translate(-ship.position)

        for _, ply in ipairs(players) do
            if ship.id == ply:GetCurrentShip() then continue end
            if ply:IsSpectator() then continue end

            local players_ship = world_ships[ply:GetCurrentShip()]
            if not players_ship or not players_ship.position then continue end
            if players_ship.position:DistToSqr(ship.position) > transfer_distance_sqr then continue end

            local player_matrix = Matrix()
            player_matrix:Translate(players_ship.position)
            player_matrix:Rotate(players_ship.angles)
            player_matrix:Translate(ply:EyePos() - global_config.world_center)
            player_matrix:Rotate(ply:EyeAngles())
            player_matrix = view * player_matrix

            local tr = util.TraceLine({
                start = player_matrix:GetTranslation(),
                endpos = player_matrix:GetTranslation() - Vector(0, 0, 40),
                filter = function(entity)
                    return entity.GetAWTeam and entity:GetAWTeam() == ship.id
                end,
                ignoreworld = true
            })

            if IsValid(tr.Entity) and tr.Entity.part_id and tr.HitNormal.z > 0 then
                ply:SetCurrentShip(tr.Entity:GetAWTeam())
                local pos = LocalToWorld(Vector(20, 0, 0), Angle(), tr.HitPos, tr.HitNormal:Angle())
                ply:SetPos(pos)
                ply:SetEyeAngles(Angle(0, player_matrix:GetAngles().y, 0))
                ply:SetVelocity(-ply:GetVelocity())
                ply:ExitControl()
            end
        end
    end

    Skyfall.ProfileEnd("player_ship_collisions", started)
end

hook.Add("Think", "Players Check Collisions", function()
    local now = CurTime()
    if now < next_collision_check then return end
    next_collision_check = now + Skyfall.GetConfig("performance.player_ship_collision_interval", 0.05)
    check_player_ship_collisions()
end)

hook.Add("Think", "Kill after fall", function()
    local now = CurTime()
    if now < next_fall_check then return end
    next_fall_check = now + Skyfall.GetConfig("performance.fall_check_interval", 0.10)

    if not istable(game_state) or game_state.state != GAME_STATE_FIGHT then return end
    for _, ply in ipairs(player.GetAll()) do
        if ply:Alive() and ply:GetPos().z <= -1023 then
            ply:Kill()
        end
    end
end)

hook.Add("Think", "Check Bounds", function()
    local now = CurTime()
    if now < next_bounds_check then return end
    next_bounds_check = now + Skyfall.GetConfig("performance.build_bounds_interval", 0.25)

    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then return end
    for _, ply in ipairs(player.GetAll()) do
        if not ply:GetPos():WithinAABox(global_config.build_bounds.min, global_config.build_bounds.max) then
            ply:SetPos(global_config.build_bounds.player_spawn)
        end
    end
end)

hook.Add("PlayerDeath", "Remove Corpse", function(victim)
    local ragdoll = victim:GetRagdollEntity()
    if IsValid(ragdoll) then
        ragdoll:Remove()
    end
end)

hook.Add("PostPlayerDeath", "Respawn Player", function(victim)
    victim:ExitControl()
    timer.Simple(Skyfall.GetConfig("gameplay.respawn_delay", 3), function()
        if not IsValid(victim) then return end
        if not victim:Alive() then
            victim:Spawn()
        end
    end)
end)
