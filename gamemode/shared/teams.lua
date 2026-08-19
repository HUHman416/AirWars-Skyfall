local entity_meta = FindMetaTable("Entity")
local player_meta = FindMetaTable("Player")

function get_team_members(team_id)
	local result = {}
	for _, v in pairs(player.GetAll()) do
		if v:GetAWTeam() == team_id then
			table.insert(result, v)
		end
	end
	return result
end

function entity_meta:AWIsInTeam(team)
	if !self.GetAWTeam then return false end
	return self:GetAWTeam() == team
end

function player_meta:GetAWTeamName()
	local teams = CLIENT and game_state and game_state.teams or aw_teams_list
	local team = teams and teams[self:GetAWTeam()]
	if !team then return self:Name() end
	return team.name or self:Name()
end

function player_meta:IsLeader()
	local teams = CLIENT and game_state and game_state.teams or aw_teams_list
	local team = teams and teams[self:GetAWTeam()]
	if !team then return false end
	return team.leader == self
end

hook.Add("PhysgunPickup", "Crew Props Pickup", function(player, entity)
	if !IsValid(entity) or entity:IsPlayer() or !entity.GetAWTeam then return false end
	return player:AWIsInTeam(entity:GetAWTeam())
end)

hook.Add("PlayerFootstep", "disable_footstep_sound", function(player)
	if CLIENT then
		return player:GetAWTeam() != LocalPlayer():GetAWTeam()
	end
end)
