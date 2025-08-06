package guards

import "core:fmt"

// Target :: struct {
//     loc: IVec2,
// }

Void :: struct {}

Target :: IVec2

// These would be better off being maps for faster lookup
movement_targets: map[Target]Void
fast_travel_targets: map[Target]Void
clear_targets: map[Target]Void
arbitrary_targets: map[Target]Void

make_targets :: proc(action: Action_Temp) -> map[Target]Void {
    switch action_type in action {
    case Hold_Action:
        return {}  // ?
    case Movement_Action:
        make_movement_targets(action_type.distance, calculate_implicit_target(action_type.target))
        return movement_targets
    case Fast_Travel_Action:
        make_fast_travel_targets()
        return fast_travel_targets
    case Clear_Action:
        make_clear_targets()
        return clear_targets
    case Choose_Target_Action:
        make_arbitrary_targets(..action_type.criteria)
        return arbitrary_targets
    }

    assert(false)
    return {}
}

Dijkstra_Info :: struct {
    dist: int,
    prev_node: IVec2,
}

make_movement_targets :: proc(distance: int, origin: IVec2) {

    visited_set: map[IVec2]Dijkstra_Info
    unvisited_set: map[IVec2]Dijkstra_Info
    defer delete(visited_set)
    defer delete(unvisited_set)
    unvisited_set[origin] = {0, {-1, -1}}

    // dijkstra's algorithm!

    clear(&movement_targets)

    for len(unvisited_set) > 0 {
        // find minimum
        min_info := Dijkstra_Info{1e6, {-1, -1}}
        min_loc := IVec2{-1, -1}
        for loc, info in unvisited_set {
            if info.dist < min_info.dist {
                min_loc = loc
                min_info = info
            }
        }

        directions: for vector in direction_vectors {
            next_loc := min_loc + vector
            if next_loc.x < 0 || next_loc.x >= GRID_WIDTH || next_loc.y < 0 || next_loc.y >= GRID_HEIGHT do continue
            if OBSTACLE_FLAGS & board[next_loc.x][next_loc.y].flags != {} do continue
            if next_loc in visited_set do continue
            for traversed_loc in player.hero.chosen_targets do if traversed_loc == next_loc do continue directions
            next_dist := min_info.dist + 1
            if next_dist > distance do continue
            existing_info, ok := unvisited_set[next_loc]
            if !ok || next_dist < existing_info.dist do unvisited_set[next_loc] = {next_dist, min_loc}
        }

        visited_set[min_loc] = min_info
        delete_key(&unvisited_set, min_loc)
    }

    add_loop: for loc, info in visited_set {
        // movement_targets[loc] = Target_Info{prev_loc = info.prev_node}
        movement_targets[loc] = {}
    }
}

// Unify dijkstra implementations at some point if possible
find_shortest_path :: proc(start, end: Target) -> (out: [dynamic]Target) {

    visited_set: map[IVec2]Dijkstra_Info
    unvisited_set: map[IVec2]Dijkstra_Info
    defer delete(visited_set)
    defer delete(unvisited_set)
    unvisited_set[start] = {0, {-1, -1}}

    // dijkstra's algorithm!

    for len(unvisited_set) > 0 {
        // find minimum
        min_info := Dijkstra_Info{1e6, {-1, -1}}
        min_loc := IVec2{-1, -1}
        for loc, info in unvisited_set {
            if info.dist < min_info.dist || (info.dist == min_info.dist && loc.x + loc.y * GRID_WIDTH < min_loc.x + min_loc.y * GRID_WIDTH) {
                min_loc = loc
                min_info = info
            }
        }

        // found the endpoint! prepare the way
        if min_loc == end {
            visited_set[min_loc] = min_info
            for ; min_loc != {-1, -1} && min_loc != start; min_loc = visited_set[min_loc].prev_node {
                inject_at(&out, 0, min_loc)
            }
            return
        }

        directions: for vector in direction_vectors {
            next_loc := min_loc + vector
            if next_loc.x < 0 || next_loc.x >= GRID_WIDTH || next_loc.y < 0 || next_loc.y >= GRID_HEIGHT do continue
            if OBSTACLE_FLAGS & board[next_loc.x][next_loc.y].flags != {} do continue
            if next_loc in visited_set do continue
            for traversed_loc in player.hero.chosen_targets do if traversed_loc == next_loc do continue directions
            next_dist := min_info.dist + 1
            existing_info, ok := unvisited_set[next_loc]
            if !ok || next_dist < existing_info.dist do unvisited_set[next_loc] = {next_dist, min_loc}
        }

        visited_set[min_loc] = min_info
        delete_key(&unvisited_set, min_loc)
    }
    assert(false)
    return
}

make_fast_travel_targets :: proc() {
    hero_loc := player.hero.location
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
        // fast_travel_targets[loc] = Target_Info{prev_loc=hero_loc}
        fast_travel_targets[loc] = {}
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
            // fast_travel_targets[loc] = Target_Info{prev_loc=hero_loc}
            fast_travel_targets[loc] = {}
        }
    }
}

make_clear_targets :: proc() {
    hero_loc := player.hero.location

    clear(&clear_targets)
    for vector in direction_vectors {
        other_loc := hero_loc + vector
        if .TOKEN in board[other_loc.x][other_loc.y].flags {
            clear_targets[other_loc] = {}
        }
    }

    fmt.println(clear_targets)
}

// Varargs is cute here but it may not be necessary
make_arbitrary_targets :: proc(criteria: ..Selection_Criterion) {
    clear(&arbitrary_targets)

    // Start with completely populated board (Inefficient!)
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            arbitrary_targets[{x, y}] = {}
        }
    }

    for criterion in criteria {
        for target, info in arbitrary_targets {
            space := board[target.x][target.y]

            switch selector in criterion {
            case Within_Distance:

                origin := calculate_implicit_target(selector.origin)
                min_dist := calculate_implicit_quantity(selector.min)
                max_dist := calculate_implicit_quantity(selector.max)

                distance := calculate_hexagonal_distance(origin, target)
                if distance > max_dist || distance < min_dist do delete_key(&arbitrary_targets, target)

            case Contains_Any:

                intersection := space.flags & selector
                if intersection == {} do delete_key(&arbitrary_targets, target)

            case Is_Enemy:

                if player.team == .NONE || space.unit_team == .NONE || player.team == space.unit_team {
                    delete_key(&arbitrary_targets, target)
                }  
            }
        }
    }
}
