package guards

import "core:fmt"



Target :: IVec2

Target_Info :: struct {
    dist: int,
    prev_node: Target,
}

Target_Set :: map[Target]Target_Info



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
        action.targets =  make_arbitrary_targets(variant.criteria)
        clear(&variant.result)
    case Choice_Action:
        for choice in variant.choices {
            populate_targets(choice.jump_index)
        }
    case Halt_Action, Attack_Action, Add_Active_Effect_Action, Minion_Removal_Action:

    case Choose_Card_Action:
        // todo ???

    case Retrieve_Card_Action:

    }
}

action_can_be_taken :: proc(index: int = 0) -> bool {
    if index == HALT_INDEX do return true

    // Disable movement on xargatha freeze
    if freeze, ok := game_state.ongoing_active_effects[.XARGATHA_FREEZE]; ok {
        if calculate_implicit_quantity(freeze.duration.(Single_Turn)) == game_state.turn_counter {
            context.allocator = context.temp_allocator
            if get_my_player().hero.location in calculate_implicit_target_set(freeze.target_set) {
                played_card, ok := find_played_card()
                assert(ok, "Could not find played card when checking for Xargatha freeze")
                if index == BASIC_MOVEMENT_INDEX || (index == 0 && played_card.primary == .MOVEMENT) {
                    // phew
                    return false
                }
            }
        }
    }

    action := get_action_at_index(index)
    if action.condition != nil && !calculate_implicit_condition(action.condition) do return false

    switch variant in action.variant {
    case Movement_Action, Fast_Travel_Action, Clear_Action, Choose_Target_Action:
        return len(action.targets) > 0
    case Halt_Action, Attack_Action, Add_Active_Effect_Action, Minion_Removal_Action:
        return true
    case Choice_Action:
        // Not technically correct! Need to see if all child actions are takeable
        return true

    case Choose_Card_Action:
        // @todo!

    case Retrieve_Card_Action:
    }
    return false
}

Dijkstra_Info :: struct {
    dist: int,
    prev_node: IVec2,
}

make_movement_targets :: proc(distance: Implicit_Quantity, origin: Implicit_Target, valid_destinations: Implicit_Target_Set = nil, allocator := context.allocator) -> (out: Target_Set) {

    context.allocator = allocator

    visited_set: map[IVec2]Dijkstra_Info
    unvisited_set: map[IVec2]Dijkstra_Info

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
            if get_my_player().stage == .RESOLVING {
                #partial switch &action in get_current_action().variant {
                case Movement_Action:
                    // Can't path to places we have already stepped on
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
            endpoint_info, ok := visited_set[valid_endpoint]
            if !ok do continue
            reachable_targets_from_endpoint := make_movement_targets(
                real_distance,
                valid_endpoint,
                allocator = context.temp_allocator,
            )
            for potential_target, potential_info in visited_set {
                target_info, ok := reachable_targets_from_endpoint[potential_target]

                if ok && target_info.dist + potential_info.dist <= real_distance {
                    out[potential_target] = Target_Info{potential_info.dist, potential_info.prev_node}
                } 
            }
        }
    } else {
        add_loop: for loc, info in visited_set {
            out[loc] = Target_Info{info.dist, info.prev_node}
        }
    }

    // if start in out do delete_key(&out, start)

    return out
}

make_fast_travel_targets :: proc() -> (out: Target_Set) {
    hero_loc := get_my_player().hero.location
    region := board[hero_loc.x][hero_loc.y].region_id

    for loc in zone_indices[region] {
        space := board[loc.x][loc.y]
        if UNIT_FLAGS & space.flags != {} && space.unit_team != get_my_player().team {
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
            if UNIT_FLAGS & space.flags != {} && space.unit_team != get_my_player().team {
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
    hero_loc := get_my_player().hero.location

    for vector in direction_vectors {
        other_loc := hero_loc + vector
        if .TOKEN in board[other_loc.x][other_loc.y].flags {
            out[other_loc] = {}
        }
    }
    return out
}

target_fulfills_criterion :: proc(target: Target, criterion: Selection_Criterion) -> bool {
    space := board[target.x][target.y]

    switch selector in criterion {
    case Within_Distance:

        origin := calculate_implicit_target(selector.origin)
        min_dist := calculate_implicit_quantity(selector.min)
        max_dist := calculate_implicit_quantity(selector.max)

        distance := calculate_hexagonal_distance(origin, target)
        return distance <= max_dist && distance >= min_dist

    case Contains_Any:

        intersection := space.flags & selector
        return intersection != {}

    case Is_Enemy_Unit:

        if get_my_player().team != .NONE && space.unit_team != .NONE && get_my_player().team != space.unit_team {
            return true
        }
        return false

    case Is_Friendly_Unit:
        if get_my_player().team != .NONE && space.unit_team != .NONE && get_my_player().team == space.unit_team {
            return true
        }
        return false

    case Ignoring_Immunity, Not_Previously_Targeted:
    }
    return true
}

make_arbitrary_targets :: proc(criteria: []Selection_Criterion, allocator := context.allocator) -> (out: Target_Set) {

    context.allocator = allocator

    // Start with completely populated board (Inefficient!)
    // @Speed
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            target := Target{x, y}
            if target_fulfills_criterion(target, criteria[0]) {
                out[target] = {}
            }
        }
    }

    ignore_immunity := false

    for criterion in criteria[1:] {
        switch variant in criterion {
        case Within_Distance, Contains_Any, Is_Enemy_Unit, Is_Friendly_Unit:
            for target, info in out {
                if !target_fulfills_criterion(target, criterion) {
                    delete_key(&out, target)
                }
            }

        case Not_Previously_Targeted:
            previous_target := calculate_implicit_target(Previous_Choice{})
            delete_key(&out, previous_target)

        case Ignoring_Immunity:
            ignore_immunity = true

        }
    }

    if !ignore_immunity {
        for target, info in out {
            space := board[target.x][target.y]
            if space.flags & {.IMMUNE} != {} {
                delete_key(&out, target)
            }
        }
    }


    return out
}
