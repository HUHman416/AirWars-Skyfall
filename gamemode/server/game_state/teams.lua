local player_meta = FindMetaTable("Player")

aw_team_requests = aw_team_requests or {}
aw_teams_list = aw_teams_list or {}
aw_team_flags = aw_team_flags or {}

function aw_remove_team(id)
    aw_teams_list[id] = nil
    aw_team_flags[id] = nil
end

function aw_add_to_team(id, member)
    local team = aw_teams_list[id]
    if not team or not IsValid(member) then return false end
    if table.HasValue(team.members, member) then return true end
    table.insert(team.members, member)
    return true
end

function aw_leave_from_team(member)
    if not IsValid(member) then return end
    local team_id = member:GetAWTeam()
    local team = aw_teams_list[team_id]
    if not team then return end

    table.RemoveByValue(team.members, member)
    if #team.members < 1 then
        aw_remove_team(team_id)
        return
    end

    if member == team.leader then
        team.leader = team.members[1]
    end
end

function player_meta:SetLeader(is_leader)
    self:SetNWBool("aw_leader", is_leader ~= false)
end

function player_meta:CreateAWTeam(team_id)
    team_id = tonumber(team_id)
    if not team_id then return false end

    aw_leave_from_team(self)
    self:SetAWTeam(team_id)
    aw_teams_list[team_id] = {
        name = self:Name(),
        members = {self},
        leader = self,
        id = team_id
    }
    AirWars:BroadcastGameState()
    hook.Run("AirWars_TeamCreated", self, team_id)
    return true
end

function player_meta:JoinAWTeam(team_id)
    local team = aw_teams_list[team_id]
    if not team then return false end

    aw_leave_from_team(self)
    self:SetAWTeam(team_id)
    aw_add_to_team(team_id, self)
    AirWars:BroadcastGameState()
    hook.Run("AirWars_PlayerJoinedTeam", self, team_id)
    return true
end

-- UTF-8 safe character truncation for team names.
local function str_left(str, max_chars)
    str = tostring(str or "")
    max_chars = math.max(0, tonumber(max_chars) or 0)
    local result = ""
    local count = 0
    for char in string.gmatch(str, ".[\128-\191]*") do
        if count >= max_chars then break end
        result = result .. char
        count = count + 1
    end
    return string.Trim(result)
end

local function can_change_teams(ply)
    return IsValid(ply) and istable(game_state) and game_state.state ~= GAME_STATE_FIGHT
end

net.Receive("aw_send_team_request", function(_, applicant)
    if not can_change_teams(applicant) then return end
    if not Skyfall.AllowAction(applicant, "team_request", Skyfall.GetConfig("network.team_action_interval", 0.20)) then return end

    local id = net.ReadInt(32)
    local team = aw_teams_list[id]
    if not team or not IsValid(team.leader) then return end
    if applicant:GetAWTeam() == id then return end

    if (applicant.invite_cooldown or 0) > CurTime() then
        applicant:ChatPrint("Wait before sending another crew request")
        return
    end
    applicant.invite_cooldown = CurTime() + 5

    -- Keep the legacy signed 8-bit request protocol inside its safe range.
    if #aw_team_requests >= 120 then
        aw_team_requests = {}
    end

    local index = table.insert(aw_team_requests, {team.leader, applicant, CurTime() + 30})
    net.Start("aw_team_request")
    net.WriteEntity(applicant)
    net.WriteInt(index, 8)
    net.Send(team.leader)
end)

net.Receive("aw_change_team_name", function(_, ply)
    if not can_change_teams(ply) then return end
    if not Skyfall.AllowAction(ply, "team_name", Skyfall.GetConfig("network.team_action_interval", 0.20)) then return end

    local name = net.ReadString()
    if #name > Skyfall.GetConfig("network.max_team_name_bytes", 64) then return end
    if not ply:IsLeader() then return end

    local team = aw_teams_list[ply:GetAWTeam()]
    if not team then return end
    local cleaned = str_left(name, 15)
    if cleaned == "" then cleaned = ply:Name() end
    team.name = cleaned
    AirWars:BroadcastGameState()
end)

net.Receive("aw_team_kick_player", function(_, ply)
    if not can_change_teams(ply) then return end
    if not Skyfall.AllowAction(ply, "team_kick", Skyfall.GetConfig("network.team_action_interval", 0.20)) then return end

    local target = net.ReadEntity()
    if not Skyfall.ValidatePlayerEntity(target) then return end

    local team_id = ply:GetAWTeam()
    if target:GetAWTeam() ~= team_id then return end
    if target ~= ply and not ply:IsLeader() then return end

    target:CreateAWTeam(AirWars:GenerateTeamId())
    AirWars:BroadcastGameState()
end)

net.Receive("aw_update_flag", function(_, ply)
    if not IsValid(ply) then return end
    if not Skyfall.AllowAction(ply, "flag_update", Skyfall.GetConfig("network.flag_update_interval", 0.15)) then return end

    local requested_len = math.max(0, net.ReadInt(32))
    local max_entries = Skyfall.GetConfig("network.max_flag_entries", 32)
    local read_len = math.min(requested_len, max_entries)
    local data = {}

    for _ = 1, read_len do
        local _, bits_left = net.BytesLeft()
        if bits_left <= 0 then break end
        table.insert(data, math.Clamp(net.ReadInt(5), 0, 31))
    end

    local team_id = ply:GetAWTeam()
    if not aw_teams_list[team_id] then return end
    aw_team_flags[team_id] = data
    AirWars:SyncFlag(team_id)
end)

net.Receive("aw_accept_team_request", function(_, ply)
    if not can_change_teams(ply) then return end
    if not Skyfall.AllowAction(ply, "team_accept", Skyfall.GetConfig("network.team_action_interval", 0.20)) then return end

    local request_id = net.ReadInt(8)
    local request = aw_team_requests[request_id]
    if not request then return end

    local leader = request[1]
    local target = request[2]
    local expires = request[3] or 0

    -- Authorize before consuming the request so forged packets cannot delete
    -- somebody else's invitation.
    if leader ~= ply then return end
    if not IsValid(target) or not IsValid(leader) then
        aw_team_requests[request_id] = nil
        return
    end
    if expires > 0 and CurTime() > expires then
        aw_team_requests[request_id] = nil
        return
    end

    local team_id = leader:GetAWTeam()
    if not aw_teams_list[team_id] then return end

    aw_team_requests[request_id] = nil
    target:JoinAWTeam(team_id)
end)

hook.Add("PlayerInitialSpawn", "Sync Flags", function(ply)
    timer.Simple(3, function()
        if not IsValid(ply) then return end
        for id in pairs(aw_teams_list) do
            AirWars:PlayerSyncFlag(id, ply)
        end
    end)
end)
