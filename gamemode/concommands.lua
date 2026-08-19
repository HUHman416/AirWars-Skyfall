concommand.Add("set_time", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    AirWars:SetTimeLeft(tonumber(args[1]) or 0)
end)

-- AirWars: Skyfall developer tooling.
include("server/dev_admin.lua")
include("server/dev_tests_v2.lua")
