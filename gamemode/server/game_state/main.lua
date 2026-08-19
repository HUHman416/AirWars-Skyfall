include("game_state.lua")
include("teams.lua")
include("timer.lua")

local next_winner_check = 0

local function finish_pvp_round(winners)
    AirWars:ResetRound()

    for _, ply in ipairs(player.GetAll()) do
        if ply.AddPoints then ply:AddPoints(2) end
        ply:ChatPrint("You got 2 points for playing")
    end

    for _, team_members in pairs(winners) do
        for _, winner in ipairs(team_members) do
            if winner.AddPoints then winner:AddPoints(10) end
            winner:ChatPrint("Your crew won the round! +10 points")
        end
    end

    hook.Run("AirWars_RoundEnd", winners)
end

hook.Add("Think", "Check Winners", function()
    if CurTime() < next_winner_check then return end
    next_winner_check = CurTime() + 0.5

    if aw_developer then return end
    if Skyfall and Skyfall.Mission and Skyfall.Mission.active then return end
    if not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end

    local winners = {}
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsSpectator() then continue end
        local team_id = ply:GetAWTeam()
        winners[team_id] = winners[team_id] or {}
        table.insert(winners[team_id], ply)
    end

    if table.Count(winners) <= 1 then
        finish_pvp_round(winners)
    end
end)
