package guards

import rl "vendor:raylib"

Vec2 :: [2]f32

IVec2 :: [2]int

WIDTH :: 2000
HEIGHT :: 1500

team_colors := [Team]rl.Color{
    .NONE = rl.MAGENTA,
    .RED  = {237, 92, 2, 255},
    .BLUE = {22, 147, 255, 255},
}

spawnpoint_initials := #partial [Space_Flag]cstring {
    .MELEE_MINION_SPAWNPOINT  = "M",
    .RANGED_MINION_SPAWNPOINT = "R",
    .HEAVY_MINION_SPAWNPOINT  = "H",
}

CLIFF_COLOR :: rl.Color{80, 76, 75, 255}
SAND_COLOR :: rl.Color{219, 182, 127, 255}
STONE_COLOR :: rl.Color{185, 140, 93, 255}
JUNGLE_COLOR :: rl.Color{157, 177, 58, 255}

region_colors := [Region_ID]rl.Color {
    .NONE = rl.MAGENTA,
    .RED_BASE = STONE_COLOR,
    .RED_BEACH = SAND_COLOR,
    .RED_JUNGLE = JUNGLE_COLOR,
    .CENTRE = STONE_COLOR,
    .BLUE_JUNGLE = JUNGLE_COLOR,
    .BLUE_BEACH = SAND_COLOR,
    .BLUE_BASE = STONE_COLOR,
}