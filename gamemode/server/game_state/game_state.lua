if !game_state then
	game_state = {
		time_left = global_config.build_time,
		state = GAME_STATE_BUILDING,
		skybox_id = 1
	}
end

local function gen_state_table()
	return {
		time_left = game_state.time_left,
		state = game_state.state,
		teams = aw_teams_list,
		skybox_id = game_state.skybox_id
	}
end

function AirWars:PlayerSyncGameState(player)
	local state = gen_state_table()
	net.Start("aw_sync_game_state")
	net.WriteTable(state)
	net.Send(player)
end

function AirWars:SyncFlag(team)
	net.Start("aw_sync_flag")
	net.WriteInt(team, 16)
	net.WriteInt(#(aw_team_flags[team] or {}), 32)
	for _, v in pairs(aw_team_flags[team] or {}) do
		net.WriteInt(v, 5)
	end
	net.Broadcast()
end

function AirWars:PlayerSyncFlag(team, player)
	net.Start("aw_sync_flag")
	net.WriteInt(team, 16)
	net.WriteInt(#(aw_team_flags[team] or {}), 32)
	for _, v in pairs(aw_team_flags[team] or {}) do
		net.WriteInt(v, 5)
	end
	net.Send(player)
end

function AirWars:BroadcastGameState()
	local state = gen_state_table()
	net.Start("aw_sync_game_state")
	net.WriteTable(state)
	net.Broadcast()
end

function AirWars:TeamSyncGameState(team)
	local state = gen_state_table()
	local players = {}
	for _, v in pairs(player.GetAll()) do
		if v:GetAWTeam() != team then continue end
		table.insert(players, v)
	end
	if #players < 1 then return end
	net.Start("aw_sync_game_state")
	net.WriteTable(state)
	net.Send(players)
end

function AirWars:ResetRound()
	for _, ship in pairs(world_ships or {}) do
		AirWars:TeamSyncGameState(ship.id)
		for _, entity in pairs(ents.FindByClass("aw*")) do
			if !IsValid(entity) or entity.AWIsInTeam == nil then continue end
			if entity:AWIsInTeam(ship.id) then
				entity:Remove()
			end
		end
	end

	world_ships = {}
	game_state.state = GAME_STATE_BUILDING
	game_state.time_left = global_config.build_time
	game_state.skybox_id = 1
	AirWars:BroadcastGameState()

	net.Start("aw_round_reset")
	net.Broadcast()

	AirWars:SpawnPlayers()
end
