package guards

import "core:fmt"

// Target :: struct {
//     loc: IVec2,
//     prev_loc: IVec2,
// }

Target :: IVec2

movement_targets: [dynamic]IVec2
fast_travel_targets: [dynamic]IVec2
clear_targets: [dynamic]IVec2

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
        if OBSTACLE_FLAGS & board[loc.x][loc.y].flags != {} do continue
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
            if OBSTACLE_FLAGS & board[loc.x][loc.y].flags != {} do continue
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

// calculate_targets :: proc(selection: Get_Target_Selection) {

// }