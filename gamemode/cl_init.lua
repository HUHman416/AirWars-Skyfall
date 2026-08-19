GM.Version = "1.0.0-dev"
GM.Name = "AirWars: Skyfall"
GM.Author = "The HellBox & AirWars: Skyfall Contributors"

include("enums.lua")
include("config.lua")
include("point_shop_config.lua")
include("shared/main.lua")
include("client/main.lua")

aw_load_pointshop_models()

function GM:OnPlayerChat(player, text, team_chat, _)
    if team_chat and player:GetAWTeam() != LocalPlayer():GetAWTeam() then
        return true
    end
    if team_chat then
        chat.AddText(Color(100, 100, 255), "[TEAM] ", player:Name(), Color(250, 250, 250), ": ", text)
        return true
    end
end

function GM:OnUndo()
    surface.PlaySound("buttons/button15.wav")
end
