package guards

import "core:fmt"

Direction :: enum {
    NORTH,
    NORTH_EAST,
    SOUTH_EAST,
    SOUTH,
    SOUTH_WEST,
    NORTH_WEST,
}

direction_vectors := [Direction]IVec2 {
    .NORTH = {0, 1},
    .NORTH_EAST = {1, 0},
    .SOUTH_EAST = {1, -1},
    .SOUTH = {0, -1},
    .SOUTH_WEST = {-1, 0},
    .NORTH_WEST = {-1, 1}
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

Team :: enum {
    NONE,
    RED,
    BLUE,
}

Game_Stage :: enum {
    SELECTION,
    RESOLUTION,
    UPGRADES,
}

Game_State :: struct {
    num_players: int,
    players: [dynamic]^Player,
    confirmed_players: int,
    resolved_players,
    turn_counter: int,
    stage: Game_Stage,
    current_battle_zone: Region_ID
}

game_state: Game_State = {
    num_players = 1, 
    confirmed_players = 0,
    stage = .SELECTION,
    current_battle_zone = .CENTRE,
}

movement_targets: [dynamic]IVec2

spawn_minions :: proc(zone: Region_ID) {
    for index in zone_indices[zone] {
        space := &board[index.x][index.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT})
        if spawnpoint_flags != {} {
            spawnpoint_type: Space_Flag
            for flag in minion_spawnpoint_array {
                if flag in spawnpoint_flags {
                    spawnpoint_type = flag
                    break
                }
            }

            minion_to_spawn := spawnpoint_to_minion[spawnpoint_type]
            space.flags += {minion_to_spawn}
            space.unit_team = space.spawnpoint_team
        }

    }
}

spawn_heroes_at_start :: proc() {
    num_spawns: [Team]int
    fmt.println(game_state.players)
    for &player in game_state.players {
        team := player.team
        spawnpoint_marker := spawnpoints[num_spawns[team]]
        assert(spawnpoint_marker.spawnpoint_flag == .HERO_SPAWNPOINT)
        spawnpoint: ^Space
        if team == .BLUE {
            spawnpoint = get_symmetric_space(spawnpoint_marker.loc)
        } else {
            spawnpoint = &board[spawnpoint_marker.loc.x][spawnpoint_marker.loc.y]
        }

        spawnpoint.flags += {.HERO}
        spawnpoint.unit_team = team
        spawnpoint.hero_id = player.hero

        player.hero_location = spawnpoint_marker.loc
        fmt.println(player.hero_location)
    }
}

begin_game :: proc() {
    game_state.current_battle_zone = .CENTRE

    spawn_minions(game_state.current_battle_zone)

    spawn_heroes_at_start()
}

make_targets :: proc(value: int, kind: Action_Kind) {
    #partial switch kind {
    case .MOVEMENT:
        make_movement_targets(value)
    }
}

make_movement_targets :: proc(value: int) {
    hero_loc := player.hero_location
    visited_set: map[IVec2]int
    unvisited_set: map[IVec2]int
    unvisited_set[hero_loc] = 0

    // for {

    // }

    // dijkstra's algorithm!

    clear(&movement_targets)
    for x in clamp(hero_loc.x - value, 0, GRID_WIDTH - 1)..=clamp(hero_loc.x+value, 0, GRID_WIDTH - 1) {
        for y in clamp(hero_loc.y - value, 0, GRID_HEIGHT - 1)..=clamp(hero_loc.y+value, 0, GRID_HEIGHT - 1) {
            if OBSTACLE_FLAGS & board[x][y].flags != {} do continue
            delta := hero_loc - {x, y}
            if abs(delta.x + delta.y) > value do continue
            append(&movement_targets, IVec2{x, y})

        }
    }
}