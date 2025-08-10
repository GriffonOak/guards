package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:reflect"
import "core:strings"

import "core:log"



Spawnpoint_Marker :: struct {
    loc: IVec2,
    spawnpoint_flag: Space_Flag,
    team: Team,
}

Space_Flag :: enum {
    TERRAIN,
    MELEE_MINION_SPAWNPOINT,
    RANGED_MINION_SPAWNPOINT,
    HEAVY_MINION_SPAWNPOINT,
    HERO_SPAWNPOINT,
    HERO,
    MELEE_MINION,
    RANGED_MINION,
    HEAVY_MINION,
    TOKEN,
    IMMUNE,
}


Region_ID :: enum {
    NONE,
    RED_JUNGLE,
    RED_BASE,
    RED_BEACH,
    CENTRE,
    BLUE_BEACH,
    BLUE_BASE,
    BLUE_JUNGLE,
}

Space_Flags :: bit_set[Space_Flag]

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
    spawnpoint_team: Team,
    unit_team: Team,
    hero_id: Hero_ID,
    owner: ^Player,
}



VERTICAL_SPACING :: 67

// sqrt 3
HORIZONTAL_SPACING :: 1.732 * VERTICAL_SPACING * 0.5

GRID_WIDTH  :: 21
GRID_HEIGHT :: 20

BOARD_TEXTURE_SIZE :: Vec2{1200, 1200}
// BOARD_TEXTURE_SIZE :: Vec2{1080, 1080}
BOARD_POSITION_RECT :: rl.Rectangle{0, 0, BOARD_TEXTURE_SIZE.x, BOARD_TEXTURE_SIZE.y}

WATER_COLOR  :: rl.Color{54, 186, 228, 255}
CLIFF_COLOR  :: rl.Color{80, 76, 75, 255}
SAND_COLOR   :: rl.Color{219, 182, 127, 255}
STONE_COLOR  :: rl.Color{185, 140, 93, 255}
JUNGLE_COLOR :: rl.Color{157, 177, 58, 255}

SPAWNPOINT_FLAGS :: Space_Flags{.MELEE_MINION_SPAWNPOINT, .RANGED_MINION_SPAWNPOINT, .HEAVY_MINION_SPAWNPOINT, .HERO_SPAWNPOINT}
PERMANENT_FLAGS  :: SPAWNPOINT_FLAGS + {.TERRAIN}
MINION_FLAGS     :: Space_Flags{.MELEE_MINION, .RANGED_MINION, .HEAVY_MINION}
UNIT_FLAGS       :: MINION_FLAGS + {.HERO}
OBSTACLE_FLAGS   :: UNIT_FLAGS + {.TERRAIN, .TOKEN}


starting_terrain := [?]IVec2 {
    {1,8}, {1,9}, {1,10}, {1,13}, {1,14}, {1,15}, {1,16}, {1,17}, {1,18},
    {2,14}, {2,15}, {2,16}, {2,17}, 
    {3,14}, {3,15},
    {4,5}, {4,11},
    {5,4}, {5,10}, {5,11}, {5,14},
    {6,3},
    {7,2},
    {8,1}, {8,2},
    {9,1}, {9,7},
    {10,1}, {10,9},
    {13,1}, {13,2}, {13,3},
    {14,1},
    {15,1}, {15,4},
    {16,1},
    {17,1},
    {18,1},
}

fast_travel_adjacencies := [Region_ID]bit_set[Region_ID] {
    .NONE = {},
    .RED_JUNGLE = {.RED_BASE, .CENTRE},
    .RED_BASE = {.RED_BEACH, .RED_JUNGLE},
    .RED_BEACH = {.RED_BASE, .CENTRE},
    .CENTRE = {.RED_BEACH, .RED_JUNGLE, .BLUE_BEACH, .BLUE_JUNGLE},
    .BLUE_BEACH = {.BLUE_BASE, .CENTRE},
    .BLUE_BASE = {.BLUE_BEACH, .BLUE_JUNGLE},
    .BLUE_JUNGLE = {.BLUE_BASE, .CENTRE}
}

spawnpoints := [?]Spawnpoint_Marker {
    {{2, 11}, .HERO_SPAWNPOINT, .RED},
    {{3, 9}, .HERO_SPAWNPOINT, .RED},
    {{3, 7}, .HERO_SPAWNPOINT, .RED},

    {{5, 5}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 7}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 8}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 12}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{7, 5}, .HEAVY_MINION_SPAWNPOINT, .RED},
    {{7, 7}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{7, 12}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{8, 4}, .RANGED_MINION_SPAWNPOINT, .RED},
    {{8, 5}, .HEAVY_MINION_SPAWNPOINT, .BLUE},
    {{9, 4}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{9, 6}, .RANGED_MINION_SPAWNPOINT, .BLUE},
    {{9, 9}, .RANGED_MINION_SPAWNPOINT, .RED},
    {{11, 2}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{11, 3}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{11, 5}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{11, 9}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{13, 6}, .HEAVY_MINION_SPAWNPOINT, .RED},
    
}

spawnpoint_to_minion := #partial [Space_Flag]Space_Flag {
    .MELEE_MINION_SPAWNPOINT = .MELEE_MINION,
    .RANGED_MINION_SPAWNPOINT = .RANGED_MINION,
    .HEAVY_MINION_SPAWNPOINT = .HEAVY_MINION,
}

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

minion_initials := #partial [Space_Flag]cstring {
    .MELEE_MINION  = "M",
    .RANGED_MINION = "R",
    .HEAVY_MINION  = "H",
}

zone_indices: [Region_ID][dynamic]IVec2

board: [GRID_WIDTH][GRID_HEIGHT]Space

board_render_texture: rl.RenderTexture2D

