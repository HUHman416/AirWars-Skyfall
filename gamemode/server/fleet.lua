-- AirWars: Skyfall Fleet milestone: onboarding, server settings, and cosmetic identity.

local flags = bit.bor(FCVAR_ARCHIVE, FCVAR_NOTIFY)
local cv_pve = CreateConVar("aw_skyfall_enable_pve", "1", flags, "Enable Skyfall Alliance PvE systems", 0, 1)
local cv_boarding = CreateConVar("aw_skyfall_enable_boarding", "1", flags, "Enable Skyfall boarding/capture systems", 0, 1)
local cv_weather = CreateConVar("aw_skyfall_enable_weather", "1", flags, "Enable Skyfall environmental weather physics", 0, 1)
local cv_auto_weather = CreateConVar("aw_skyfall_auto_weather", "1", flags, "Allow rounds to select weather automatically", 0, 1)
local cv_blueprints = CreateConVar("aw_skyfall_enable_blueprints", "1", flags, "Enable persistent player blueprints", 0, 1)
local cv_ai_difficulty = CreateConVar("aw_skyfall_ai_difficulty", "1.0", flags, "Global Alliance AI skill multiplier", 0.5, 2.0)

Skyfall.ServerSettings = {
    pve = cv_pve,
    boarding = cv_boarding,
    weather = cv_weather,
    auto_weather = cv_auto_weather,
    blueprints = cv_blueprints,
    ai_difficulty = cv_ai_difficulty
}

local function apply_feature_settings()
    Skyfall.SetFeatureEnabled("pve", cv_pve:GetBool())
    Skyfall.SetFeatureEnabled("ai_crew", cv_pve:GetBool())
    Skyfall.SetFeatureEnabled("boarding", cv_boarding:GetBool())
    Skyfall.SetFeatureEnabled("weather", cv_weather:GetBool())
    Skyfall.SetFeatureEnabled("blueprints", cv_blueprints:GetBool())
end

apply_feature_settings()
for _, name in ipairs({"aw_skyfall_enable_pve", "aw_skyfall_enable_boarding", "aw_skyfall_enable_weather", "aw_skyfall_enable_blueprints"}) do
    cvars.AddChangeCallback(name, apply_feature_settings, "Skyfall_FeatureSettings")
end

local function list_options(ply, label, values)
    local entries = {}
    for id, data in SortedPairs(values) do
        local name = istable(data) and data.name or tostring(data)
        table.insert(entries, id .. (name ~= "" and (" (" .. name .. ")") or ""))
    end
    ply:ChatPrint(label .. ": " .. table.concat(entries, ", "))
end

local function load_identity(ply)
    if not IsValid(ply) then return end
    local title = ply.GetDataValue and ply:GetDataValue("skyfall_title") or nil
    local livery = ply.GetDataValue and ply:GetDataValue("skyfall_livery") or nil
    title = Skyfall.Titles[tostring(title or "none")] and tostring(title) or "none"
    livery = Skyfall.Liveries[tostring(livery or "brass")] and tostring(livery) or "brass"
    ply:SetNWString("skyfall_title", title)
    ply:SetNWString("skyfall_livery", livery)
end

hook.Add("PlayerInitialSpawn", "Skyfall_LoadIdentity", function(ply)
    timer.Simple(1, function() if IsValid(ply) then load_identity(ply) end end)
end)

concommand.Add("aw_title", function(ply, _, args)
    if not IsValid(ply) then return end
    local id = string.lower(tostring(args[1] or ""))
    if id == "" or id == "list" then list_options(ply, "Crew titles", Skyfall.Titles) return end
    if Skyfall.Titles[id] == nil then ply:ChatPrint("Unknown title. Use aw_title list") return end
    ply:SetNWString("skyfall_title", id)
    if ply.SetDataValue then ply:SetDataValue("skyfall_title", id) end
    ply:ChatPrint(id == "none" and "Crew title cleared." or ("Crew title: " .. Skyfall.Titles[id]))
end)

concommand.Add("aw_livery", function(ply, _, args)
    if not IsValid(ply) then return end
    local id = string.lower(tostring(args[1] or ""))
    if id == "" or id == "list" then list_options(ply, "Ship liveries", Skyfall.Liveries) return end
    if not Skyfall.Liveries[id] then ply:ChatPrint("Unknown livery. Use aw_livery list") return end
    ply:SetNWString("skyfall_livery", id)
    if ply.SetDataValue then ply:SetDataValue("skyfall_livery", id) end
    ply:ChatPrint("Primary ship livery: " .. Skyfall.Liveries[id].name .. " (applies next round)")
end)

Skyfall.TutorialSteps = {
    [1] = "Choose a crew specialty with: aw_role crew|pilot|engineer|gunner",
    [2] = "Build a ship or load one quickly with: aw_prefab cutter",
    [3] = "Start a round (or an Alliance mission with: aw_pve_start hunt)",
    [4] = "Board your ship and use the steering wheel. Pilot controls: movement keys, jump/shift for altitude, reload to exit station.",
    [5] = "Operate a ship weapon and fire it. Reload at an ammo crate; select special ammunition with aw_ammo <type>.",
    [6] = "Aim at an enemy vessel and run aw_spot. Pilots keep targets spotted longer.",
    [7] = "Training complete. Engineers repair/rebuild with the Engineer Tool; boarders sabotage with the Sabotage Kit; aw_capture can seize crippled ships."
}

local function tutorial_step(ply)
    return IsValid(ply) and ply:GetNWInt("skyfall_tutorial_step", 0) or 0
end

function Skyfall.SetTutorialStep(ply, step)
    if not IsValid(ply) then return end
    step = math.Clamp(math.floor(tonumber(step) or 0), 0, #Skyfall.TutorialSteps)
    ply:SetNWInt("skyfall_tutorial_step", step)
    if step > 0 and Skyfall.TutorialSteps[step] then
        ply:ChatPrint("[Skyfall Tutorial " .. step .. "/" .. #Skyfall.TutorialSteps .. "] " .. Skyfall.TutorialSteps[step])
    end
    if step >= #Skyfall.TutorialSteps then
        ply:SetNWBool("skyfall_tutorial_complete", true)
    end
end

local function advance_if(ply, expected)
    if tutorial_step(ply) == expected then Skyfall.SetTutorialStep(ply, expected + 1) end
end

concommand.Add("aw_tutorial", function(ply, _, args)
    if not IsValid(ply) then return end
    local arg = string.lower(tostring(args[1] or ""))
    if arg == "reset" or tutorial_step(ply) == 0 then
        ply:SetNWBool("skyfall_tutorial_complete", false)
        Skyfall.SetTutorialStep(ply, 1)
        return
    end
    local step = tutorial_step(ply)
    ply:ChatPrint("[Skyfall Tutorial] " .. (Skyfall.TutorialSteps[step] or "Complete. Use aw_tutorial reset to repeat."))
end)

hook.Add("Skyfall_PlayerRoleChanged", "Skyfall_TutorialRole", function(ply) advance_if(ply, 1) end)
hook.Add("Skyfall_BuildTemplateLoaded", "Skyfall_TutorialBuild", function(ply) advance_if(ply, 2) end)
hook.Add("AirWars_RoundStart", "Skyfall_TutorialRound", function()
    for _, ply in ipairs(player.GetAll()) do advance_if(ply, 3) end
end)
hook.Add("Skyfall_PlayerEnteredControl", "Skyfall_TutorialHelm", function(ply, ent)
    if IsValid(ent) and ent:GetClass() == "aw_ship_controller" then advance_if(ply, 4) end
end)
hook.Add("Skyfall_WeaponFired", "Skyfall_TutorialWeapon", function(_, ply)
    if IsValid(ply) then advance_if(ply, 5) end
end)
hook.Add("Skyfall_TargetSpotted", "Skyfall_TutorialSpot", function(ply)
    if tutorial_step(ply) == 6 then
        Skyfall.SetTutorialStep(ply, 7)
        ply:ChatPrint("[Skyfall Tutorial] Complete! You can restart it anytime with aw_tutorial reset.")
    end
end)

local training_target_id
concommand.Add("aw_training", function(ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end
    if not istable(game_state) or game_state.state == GAME_STATE_FIGHT then
        ply:ChatPrint("Training must start from the build phase.")
        return
    end

    aw_developer = true
    Skyfall.SetRole(ply, "crew")
    local ok, message = Skyfall.SpawnBuildDescriptors(ply, Skyfall.Prefabs.cutter.parts, nil, true)
    if not ok then ply:ChatPrint("Training setup failed: " .. tostring(message)) return end
    AirWars:StartRound()

    timer.Simple(0.75, function()
        if not IsValid(ply) or not istable(game_state) or game_state.state ~= GAME_STATE_FIGHT then return end
        local player_ship = world_ships[ply:GetAWTeam()]
        local position = player_ship and (player_ship.position + Vector(2800, 0, 0)) or Vector(2800, 0, 1200)
        local target = Skyfall.SpawnAIShip("cutter", {faction = "enemy", passive = true, stationary = true, repair = 0, health = 1.5, position = position, name = "Training Target"})
        training_target_id = target and target.id or nil
        Skyfall.SetTutorialStep(ply, 4)
        ply:ChatPrint("Training range ready. Use aw_training_end when finished.")
    end)
end)

concommand.Add("aw_training_end", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if training_target_id and world_ships[training_target_id] then AirWars:DestroyShip(world_ships[training_target_id]) end
    training_target_id = nil
    if istable(game_state) and game_state.state == GAME_STATE_FIGHT then AirWars:ResetRound() end
    aw_developer = false
end)

concommand.Add("aw_server_settings", function(ply)
    if IsValid(ply) and not ply:IsAdmin() then return end
    local lines = {
        "pve=" .. cv_pve:GetString(),
        "boarding=" .. cv_boarding:GetString(),
        "weather=" .. cv_weather:GetString(),
        "auto_weather=" .. cv_auto_weather:GetString(),
        "blueprints=" .. cv_blueprints:GetString(),
        "ai_difficulty=" .. cv_ai_difficulty:GetString()
    }
    local text = "[Skyfall Settings] " .. table.concat(lines, " | ")
    if IsValid(ply) then ply:PrintMessage(HUD_PRINTCONSOLE, text) else print(text) end
end)

Skyfall.SetFeatureEnabled("tutorials", true)
Skyfall.Info("Fleet", "Tutorial, training range, cosmetics, and server settings enabled")
