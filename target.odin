package guards

import "core:fmt"



Target :: IVec2

Target_Info :: struct {
    dist: int,
    prev_node: Target,
}

Target_Set :: map[Target]Target_Info

Implicit_Target_Set :: union {
    Target_Set,
    []Selection_Criterion,
}

Self :: struct {}

Previous_Choice :: struct {}

Implicit_Target :: union {
    Target,
    Self,
    Previous_Choice,
}




populate_targets :: proc(index: int = 0) {
    action := get_action_at_index(index)
    if action == nil do return 

    switch &variant in action.variant {
    case Movement_Action:
        action.targets =  make_movement_targets(variant.distance, variant.target, variant.valid_destinations)
    case Fast_Travel_Action:
        action.targets =  make_fast_travel_targets()
    case Clear_Action:
        action.targets =  make_clear_targets()
    case Choose_Target_Action:
        action.targets =  make_arbitrary_targets(..variant.criteria)
    case Choice_Action:
        for choice in variant.choices {
            populate_targets(choice.jump_index)
        }
    case Halt_Action, Attack_Action:

    }
}

action_can_be_taken :: proc(action: Action) -> bool {
    if action.condition != nil && !calculate_implicit_condition(action.condition) do return false

    switch variant in action.variant {
    case Movement_Action, Fast_Travel_Action, Clear_Action, Choose_Target_Action:
        return len(action.targets) > 0
    case Halt_Action, Attack_Action:
        return true
    case Choice_Action:
        // Not technically correct! Need to see if all child actions are takeable
        return true
    }
    return false
}

Dijkstra_Info :: struct {
    dist: int,
    prev_node: IVec2,
}

make_movement_targets :: proc(distance: Implicit_Quantity, origin: Implicit_Target, valid_destinations: Implicit_Target_Set = nil) -> (out: Target_Set) {

    visited_set: map[IVec2]Dijkstra_Info
    unvisited_set: map[IVec2]Dijkstra_Info
    defer delete(visited_set)
    defer delete(unvisited_set)
    start := calculate_implicit_target(origin)
    unvisited_set[start] = {0, {-1, -1}}

    real_distance := calculate_implicit_quantity(distance)

    // dijkstra's algorithm!

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
            if player.stage == .RESOLVING {
                #partial switch &action in get_current_action().variant {
                case Movement_Action:
                    for traversed_loc in action.path.spaces do if traversed_loc == next_loc do continue directions
                }
            }
            next_dist := min_info.dist + 1
            if next_dist > real_distance do continue
            existing_info, ok := unvisited_set[next_loc]
            if !ok || next_dist < existing_info.dist do unvisited_set[next_loc] = {next_dist, min_loc}
        }

        visited_set[min_loc] = min_info
        delete_key(&unvisited_set, min_loc)
    }

    if valid_destinations != nil {
        destination_set := calculate_implicit_target_set(valid_destinations)
        for valid_endpoint in destination_set {
            for potential_target, info in visited_set {
                // @Speed this is kind of abismal, we will be duplicating a lot of work here
                path, ok := find_shortest_path(potential_target, valid_endpoint).?
                if !ok do break 
                defer delete(path)
                if len(path) + info.dist <= real_distance do out[potential_target] = {} 
            }
        }
    } else {
        add_loop: for loc, info in visited_set {
            out[loc] = Target_Info{info.dist, info.prev_node}
        }
    }

    if start in out do delete_key(&out, start)

    return out
}

// Unify dijkstra implementations at some point if possible
find_shortest_path :: proc(start, end: Target) -> Maybe([dynamic]Target) {

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
            out: [dynamic]Target
            visited_set[min_loc] = min_info
            for ; min_loc != {-1, -1} && min_loc != start; min_loc = visited_set[min_loc].prev_node {
                inject_at(&out, 0, min_loc)
            }
            return out
        }

        directions: for vector in direction_vectors {
            next_loc := min_loc + vector
            if next_loc.x < 0 || next_loc.x >= GRID_WIDTH || next_loc.y < 0 || next_loc.y >= GRID_HEIGHT do continue
            if OBSTACLE_FLAGS & board[next_loc.x][next_loc.y].flags != {} do continue
            if next_loc in visited_set do continue
            if player.stage == .RESOLVING {
                #partial switch &action in get_current_action().variant {
                case Movement_Action:
                    for traversed_loc in action.path.spaces do if traversed_loc == next_loc do continue directions
                }
            }
            next_dist := min_info.dist + 1
            existing_info, ok := unvisited_set[next_loc]
            if !ok || next_dist < existing_info.dist do unvisited_set[next_loc] = {next_dist, min_loc}
        }

        visited_set[min_loc] = min_info
        delete_key(&unvisited_set, min_loc)
    }
    return nil
}

make_fast_travel_targets :: proc() -> (out: Target_Set) {
    hero_loc := player.hero.location
    region := board[hero_loc.x][hero_loc.y].region_id

    for loc in zone_indices[region] {
        space := board[loc.x][loc.y]
        if UNIT_FLAGS & space.flags != {} && space.unit_team != player.team {
            return
        }
    }

    for loc in zone_indices[region] {
        if OBSTACLE_FLAGS & board[loc.x][loc.y].flags != {} do continue
        out[loc] = {}
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
            out[loc] = {}
        }
    }
    return out
}

make_clear_targets :: proc() -> (out: Target_Set) {
    hero_loc := player.hero.location

    for vector in direction_vectors {
        other_loc := hero_loc + vector
        if .TOKEN in board[other_loc.x][other_loc.y].flags {
            out[other_loc] = {}
        }
    }
    return out
}

// Varargs is cute here but it may not be necessary
make_arbitrary_targets :: proc(criteria: ..Selection_Criterion) -> (out: Target_Set) {

    // Start with completely populated board (Inefficient!)
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            out[{x, y}] = {}
        }
    }

    for criterion in criteria {
        for target, info in out {
            space := board[target.x][target.y]

            switch selector in criterion {
            case Within_Distance:

                origin := calculate_implicit_target(selector.origin)
                min_dist := calculate_implicit_quantity(selector.min)
                max_dist := calculate_implicit_quantity(selector.max)

                distance := calculate_hexagonal_distance(origin, target)
                if distance > max_dist || distance < min_dist do delete_key(&out, target)

            case Contains_Any:

                intersection := space.flags & selector
                if intersection == {} do delete_key(&out, target)

            case Is_Enemy_Unit:

                if player.team == .NONE || space.unit_team == .NONE || player.team == space.unit_team {
                    delete_key(&out, target)
                }
            
            case Not_Previously_Targeted:

                // Inefficient, could just look at the very end
                previous_target := calculate_implicit_target(Previous_Choice{})
                if target == previous_target {
                    delete_key(&out, target)
                }
            }
        }
    }
    return out
}
