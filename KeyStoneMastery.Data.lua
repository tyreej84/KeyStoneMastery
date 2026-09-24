local ns = _G.KeyStoneMasteryNS
if type(ns) ~= "table" then
    ns = {}
    _G.KeyStoneMasteryNS = ns
end

ns.ENEMY_FORCES_TOTAL_UNITS_BY_MAP_ID = {
    [402] = 460, -- Algethar Academy
    [239] = 568, -- Seat of the Triumvirate
    [556] = 643, -- Pit of Saron
    [557] = 591, -- Windrunner Spire
    [558] = 597, -- Magisters Terrace
    [559] = 596, -- Nexus Point Xenas
    [560] = 607, -- Maisara Caverns
    [161] = 431, -- Skyreach
    [12345] = 470, -- Murder Row (custom map id in reference data)
}

ns.ENEMY_FORCES_TOTAL_UNITS_BY_DUNGEON = {
    ["algethar academy"] = 460,
    ["pit of saron"] = 643,
    ["seat of the triumvirate"] = 568,
    ["windrunners spire"] = 591,
    ["magisters terrace"] = 597,
    ["magisters terrace"] = 597,
    ["nexus point xenas"] = 596,
    ["maisara caverns"] = 607,
    ["skyreach"] = 431,
    ["murder row"] = 470,
}
