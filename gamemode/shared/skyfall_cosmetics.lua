-- AirWars: Skyfall cosmetic-only identity options.

Skyfall = Skyfall or {}

Skyfall.Titles = Skyfall.Titles or {
    none = "",
    deckhand = "Deckhand",
    aeronaut = "Aeronaut",
    engineer = "Chief Engineer",
    gunner = "Master Gunner",
    captain = "Sky Captain",
    stormrider = "Stormrider",
    privateer = "Sky Privateer",
    salvager = "Aether Salvager"
}

Skyfall.Liveries = Skyfall.Liveries or {
    brass = {name = "Old Brass", color = Color(210, 170, 92)},
    iron = {name = "Gunmetal", color = Color(165, 172, 180)},
    navy = {name = "Royal Navy", color = Color(115, 145, 185)},
    crimson = {name = "Crimson Corsair", color = Color(185, 105, 92)},
    verdigris = {name = "Verdigris", color = Color(105, 165, 150)},
    ivory = {name = "Ivory Cloud", color = Color(205, 198, 170)}
}

function Skyfall.GetLivery(name)
    return Skyfall.Liveries[string.lower(tostring(name or "brass"))] or Skyfall.Liveries.brass
end

function Skyfall.GetTitle(name)
    return Skyfall.Titles[string.lower(tostring(name or "none"))] or ""
end
