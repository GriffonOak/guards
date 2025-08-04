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
fast_travel_targets: [dynamic]IVec2
clear_targets: [dynamic]IVec2

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

make_targets :: proc(value: int, kind: Button_Kind) -> bool {
    #partial switch kind {
    case .SECONDARY_MOVEMENT:
        make_movement_targets(value)
        return len(movement_targets) > 0
    case .SECONDARY_FAST_TRAVEL:
        make_fast_travel_targets()
        return len(fast_travel_targets) > 0
    case .SECONDARY_CLEAR:
        make_clear_targets()
        return len(clear_targets) > 0
    }

    assert(false)
    return false
}

make_movement_targets :: proc(value: int) {
    hero_loc := player.hero_location
    visited_set: map[IVec2]int
    unvisited_set: map[IVec2]int
    defer delete(visited_set)
    defer delete(unvisited_set)
    unvisited_set[hero_loc] = 0

    // dijkstra's algorithm!

    clear(&movement_targets)

    for len(unvisited_set) > 0 {
        // find minimum
        min_value := 1e6
        min_loc := IVec2{-1, -1}
        for loc, val in unvisited_set {
            if val < min_value {
                min_loc = loc
                min_value = val
            }
        }

        for vector in direction_vectors {
            next_loc := min_loc + vector
            if next_loc.x < 0 || next_loc.x >= GRID_WIDTH || next_loc.y < 0 || next_loc.y >= GRID_HEIGHT do continue
            if OBSTACLE_FLAGS & board[next_loc.x][next_loc.y].flags != {} do continue
            if next_loc in visited_set do continue
            next_val := min_value + 1
            prev_val, ok := unvisited_set[next_loc]
            new_val := min(prev_val, next_val) if ok else next_val
            if new_val > value do continue
            unvisited_set[next_loc] = new_val
        }

        visited_set[min_loc] = min_value
        delete_key(&unvisited_set, min_loc)
    }

    for key, value in visited_set {
        append(&movement_targets, key)
    }
}

make_fast_travel_targets :: proc() {
    hero_loc := player.hero_location
    region := board[hero_loc.x][hero_loc.y].region_id

    clear(&fast_travel_targets)

    for loc in zone_indices[region] {
        space := board[loc.x][loc.y]
        if UNIT_FLAGS & space.flags != {} && space.unit_team != player.team {
            return
        }
    }

    for loc in zone_indices[region] {
        append(&fast_travel_targets, loc)
    }

    outer: for other_region in Region_ID {
        if other_region not_in fast_travel_adjacencies[region] do continue
        for loc in zone_indices[other_region] {
            space := board[loc.x][loc.y]
            if UNIT_FLAGS & space.flags != {} && space.unit_team != player.team {
                continue outer
            }
        }
        for loc in zone_indices[other_region] {
            append(&fast_travel_targets, loc)
        }
    }
}

make_clear_targets :: proc() {
    hero_loc := player.hero_location

    clear(&clear_targets)
    for vector in direction_vectors {
        other_loc := hero_loc + vector
        if .TOKEN in board[other_loc.x][other_loc.y].flags {
            append(&clear_targets, other_loc)
        }
    }

    fmt.println(clear_targets)
}