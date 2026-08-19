world_ships = world_ships or {}

local function add_part(self, part)
    if not istable(part) or not part.id then return false end
    self.parts[part.id] = part
    return true
end

local function sync(self)
    net.Start("aw_sync_ship")
    net.WriteTable({
        health = self.health,
        id = self.id,
        position = self.position,
        angles = self.angles,
        center = self.center,
        parts = {},
        skyfall = {
            spotted_until = self.spotted_until or 0,
            faction = self.faction or "player"
        }
    })
    net.Broadcast()
end

local function sync_to_player(self, ply)
    if not IsValid(ply) then return end
    net.Start("aw_sync_ship")
    net.WriteTable({
        health = self.health,
        id = self.id,
        position = self.position,
        angles = self.angles,
        center = self.center,
        crew_positions = get_crew(self),
        parts = {},
        skyfall = {
            spotted_until = self.spotted_until or 0,
            faction = self.faction or "player"
        }
    })
    net.Send(ply)
end

local function sync_position(self)
    net.Start("aw_sync_ship_position", true)
    net.WriteTable({
        id = self.id,
        position = {self.position.x, self.position.y, self.position.z},
        angles = self.angles
    })
    net.Broadcast()
end

function find_max_min(self)
    if not self or not istable(self.parts) or table.Count(self.parts) == 0 then
        return Vector(), Vector()
    end

    local max = Vector(-math.huge, -math.huge, -math.huge)
    local min = Vector(math.huge, math.huge, math.huge)

    for _, part in pairs(self.parts) do
        if not part.position then continue end
        max.x = math.max(max.x, part.position.x)
        max.y = math.max(max.y, part.position.y)
        max.z = math.max(max.z, part.position.z)
        min.x = math.min(min.x, part.position.x)
        min.y = math.min(min.y, part.position.y)
        min.z = math.min(min.z, part.position.z)
    end

    return max, min
end

local function find_center(self)
    if not self or table.Count(self.parts or {}) == 0 then return Vector() end
    local max, min = find_max_min(self)
    return (max + min) / 2
end

local function update_center(self)
    self.center = find_center(self)
end

local function update_max_min(self)
    local max, min = find_max_min(self)
    self.max = max
    self.min = min
end

function AirWars:DestroyShip(ship)
    if not istable(ship) then return end

    for _, ent in ipairs(ents.FindByClass("aw*")) do
        if ent.AWIsInTeam and ent:AWIsInTeam(ship.id) and not ent:IsWeapon() then
            ent:Remove()
        end
    end

    net.Start("aw_destroy_ship")
    net.WriteInt(ship.id, 32)
    net.Broadcast()

    world_ships[ship.id] = nil
    Skyfall.Info("Ship", "Destroyed ship %s", tostring(ship.id))
    hook.Run("Skyfall_ShipDestroyed", ship)
end

function AirWars:CreateShip(id, options)
    id = tonumber(id)
    if not id then return nil end
    options = options or {}

    local ship = {
        health = tonumber(options.health) or 100,
        id = id,
        position = options.position or Vector(-83, 1248, 242),
        center = Vector(),
        max = Vector(),
        min = Vector(),
        angles = options.angles or Angle(),
        direction = init_ship_controls(),
        parts = {},
        destroyed_parts = {},
        faction = options.faction or "player",
        ai_controlled = options.ai_controlled == true,
        spotted_until = 0,
        spotted_by_team = nil
    }

    ship.AddPart = add_part
    ship.Sync = sync
    ship.SyncDirection = sync_direction
    ship.UpdateCenter = update_center
    ship.UpdateMinMax = update_max_min
    ship.AssignPlayer = assign_player
    ship.SyncPosition = sync_position
    ship.SyncToPlayer = sync_to_player

    world_ships[id] = ship
    hook.Run("AirWars_ShipCreated", id)
    hook.Run("Skyfall_ShipCreated", ship)
    return ship
end

net.Receive("aw_sync_parts", function(_, ply)
    if not IsValid(ply) then return end

    local ship_id = net.ReadInt(32)
    if not Skyfall.AllowAction(ply, "sync_parts:" .. tostring(ship_id), 0.20) then return end

    local ship = world_ships[ship_id]
    if not ship then return end

    local serializable = {}
    for _, part in pairs(ship.parts or {}) do
        serializable[part.id] = part_table_simple(part)
    end

    local json = util.TableToJSON(serializable)
    if not json then return end
    local compressed = util.Compress(json)
    if not compressed then return end

    local length = #compressed
    if length > 63000 then
        ply:ChatPrint("This ship is too large to synchronize safely.")
        Skyfall.Warn("Network", "Ship %s part payload is %d bytes", tostring(ship_id), length)
        return
    end

    net.Start("aw_sync_parts")
    net.WriteInt(length, 32)
    net.WriteData(compressed, length)
    net.WriteInt(ship_id, 16)
    net.Send(ply)
end)
