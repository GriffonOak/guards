package guards

// import "core:fmt"
import "core:log"



Target :: [2]i8

INVALID_TARGET :: Target{}

Target_Info :: struct {
    dist: int,
    prev_loc: Target,
    member: bool,
    invalid: bool,  // True if we can move to the space along the way to a valid endpoint but the space itself is not a valid endpoint
    // We flag invalid rather than valid here so spaces default to being valid
}

Target_Set :: [GRID_WIDTH][GRID_HEIGHT]Target_Info

Target_Set_Iterator :: struct {
    index: Target,
    set: ^Target_Set,
}

Selection_Flag :: enum {
    NOT_PREVIOUSLY_TARGETED,
    IGNORING_IMMUNITY,
}

Selection_Flags :: bit_set[Selection_Flag]

index_target_set :: proc(set: ^Target_Set, index: Target) -> ^Target_Info {
    // if index.x < 0 || index.y < 0 || index.x >= GRID_WIDTH || index.y >= GRID_HEIGHT do return nil
    return &set[index.x][index.y]
}

make_target_set_iterator :: proc(target_set: ^Target_Set) -> Target_Set_Iterator {
    return {set = target_set}
}

target_set_iter_members :: proc(it: ^Target_Set_Iterator) -> (info: ^Target_Info, index: Target, cond: bool) {
    cond = it.index.y < GRID_HEIGHT

    update_index :: proc(it: ^Target_Set_Iterator) {
        it.index.x += 1
        if it.index.x >= GRID_WIDTH {
            it.index.x = 0
            it.index.y += 1
        }
    }

    for ; cond ; cond = it.index.y < GRID_HEIGHT {
        info = index_target_set(it.set, it.index)
        if !info.member {
            update_index(it)
            continue
        }
        index = it.index

        update_index(it)
        break
    }
    return
}

count_members :: proc(target_set: ^Target_Set) -> (count: int) {
    // @Speed we can probably just keep track of when we add and remove members and then dispense with this
    iter := make_target_set_iterator(target_set)

    for _ in target_set_iter_members(&iter) {
        count += 1
    }
    return
}

validate_action :: proc(gs: ^Game_State, index: Action_Index) -> bool {
    if index.sequence == .HALT do return true

    xarg_freeze: { // Disable movement on xargatha freeze
        freeze, ok := gs.ongoing_active_effects[.XARGATHA_FREEZE]
        if !ok do break xarg_freeze
        if calculate_implicit_quantity(gs, freeze.timing.(Single_Turn), {card_id = freeze.parent_card_id}) != gs.turn_counter do break xarg_freeze
        context.allocator = context.temp_allocator
        my_location := get_my_player(gs).hero.location
        freeze_targets := make_arbitrary_targets(gs, freeze.target_set, {card_id = freeze.parent_card_id})
        if !freeze_targets[my_location.x][my_location.y].member do break xarg_freeze
        played_card, ok2 := find_played_card(gs)
        log.assert(ok2, "Could not find played card when checking for Xargatha freeze")
        played_card_data, ok3 := get_card_data_by_id(gs, played_card)
        log.assert(ok3, "Could not find played card data when checking for Xargatha freeze")
        if index.sequence == .BASIC_MOVEMENT || index.sequence == .BASIC_FAST_TRAVEL || (index.index == 0 && index.sequence == .PRIMARY && played_card_data.primary == .MOVEMENT) {
            // phew
            return false
        }
    }


    action := get_action_at_index(gs, index)
    calc_context := Calculation_Context{card_id = index.card_id}
    if action == nil do return false
    if action.condition != nil && !calculate_implicit_condition(gs, action.condition, calc_context) do return false

    switch &variant in action.variant {
    case Movement_Action:
        action.targets = make_movement_targets(gs, variant.criteria, calc_context)
        origin := calculate_implicit_target(gs, variant.target, calc_context)
        clear(&variant.path.spaces)
        append(&variant.path.spaces, origin)
        variant.path.num_locked_spaces = 1
        return count_members(&action.targets) > 0

    case Fast_Travel_Action:
        action.targets =  make_fast_travel_targets(gs)
        return count_members(&action.targets) > 0

    case Clear_Action:
        action.targets =  make_clear_targets(gs)
        return count_members(&action.targets) > 0

    case Choose_Target_Action:
        action.targets =  make_arbitrary_targets(gs, variant.criteria, calc_context)
        clear(&variant.result)
        return count_members(&action.targets) > 0

    case Choice_Action:
        out := false
        for &choice in &variant.choices {
            jump_index := &choice.jump_index
            jump_index.card_id = index.card_id
            choice.valid = validate_action(gs, jump_index^)
            out ||= choice.valid
        }
        return out

    // @Note maybe respawn should check if we're dead
    case Halt_Action, Attack_Action, Add_Active_Effect_Action, Minion_Defeat_Action, Minion_Removal_Action, Jump_Action, Minion_Spawn_Action, Get_Defeated_Action, Respawn_Action, Force_Discard_Action:
        return true

    case Gain_Coins_Action:
        return true

    case Choose_Card_Action:
        variant.card_targets = make_card_targets(gs, variant.criteria, calc_context)
        return len(variant.card_targets) > 0

    case Discard_Card_Action:
        return true

    case Defend_Action:
        return true

    case Retrieve_Card_Action:
        return true
    }
    return false
}

make_movement_targets :: proc (
    gs: ^Game_State,
    criteria: Movement_Criteria,
    calc_context: Calculation_Context = {},
) -> (visited_set: Target_Set) {

    BIG_NUMBER :: 1e6
    origin := calculate_implicit_target(gs, criteria.target, calc_context)
    max_distance := calculate_implicit_quantity(gs, criteria.distance, calc_context)
    valid_destinations, destinations_ok := make_arbitrary_targets(gs, criteria.destination_criteria, calc_context)

    if .SHORTEST_PATH in criteria.flags {
        log.assert(destinations_ok, "Trying to calculate shortest path with no valid destination set given!")
        max_distance = BIG_NUMBER
    }

    // dijkstra's algorithm!   
    
    unvisited_set: Target_Set

    unvisited_set[origin.x][origin.y] = {member = true}

    for count_members(&unvisited_set) > 0 {
        // find minimum
        min_info := Target_Info{dist = BIG_NUMBER}
        min_loc := INVALID_TARGET
        unvisited_iter := make_target_set_iterator(&unvisited_set)
        for info, loc in target_set_iter_members(&unvisited_iter) {
            if info.dist < min_info.dist {
                min_loc = loc
                min_info = info^
            }
        }

        if .SHORTEST_PATH in criteria.flags && max_distance == BIG_NUMBER && valid_destinations[min_loc.x][min_loc.y].member {
            // Shortest distance found!
            max_distance = min_info.dist
        }

        directions: for vector in direction_vectors {
            next_loc := min_loc + vector

            {   // Validate next location
                if next_loc.x < 0 || next_loc.x >= GRID_WIDTH || next_loc.y < 0 || next_loc.y >= GRID_HEIGHT do continue
                if OBSTACLE_FLAGS & gs.board[next_loc.x][next_loc.y].flags != {} do continue
                if visited_set[next_loc.x][next_loc.y].member do continue
                if get_my_player(gs).stage == .RESOLVING {
                    #partial switch &action in get_current_action(gs).variant {
                    case Movement_Action:
                        // Can't path to places we have already stepped on
                        for traversed_loc in action.path.spaces do if traversed_loc == next_loc do continue directions
                    }
                }
            }

            next_dist := min_info.dist + 1
            if next_dist > max_distance do continue
            existing_info := unvisited_set[next_loc.x][next_loc.y]
            if !existing_info.member || next_dist < existing_info.dist do unvisited_set[next_loc.x][next_loc.y] = Target_Info {
                dist = next_dist,
                prev_loc = min_loc,
                member = true,
            }
        }

        visited_set[min_loc.x][min_loc.y] = min_info
        unvisited_set[min_loc.x][min_loc.y].member = false
    }

    // See if we have a set of valid destinations first
    if !destinations_ok do return 

    // Worry about valid destinations!

    // Check all spaces in the visited set to see if they can be reached by one of the valid endpoints.
    // If they can, they will be marked as invalid. Otherwise they will stay valid.
    valid_destinations_iter := make_target_set_iterator(&valid_destinations)
    for _, valid_endpoint in target_set_iter_members(&valid_destinations_iter) {
        if !visited_set[valid_endpoint.x][valid_endpoint.y].member do continue
        reachable_targets_from_endpoint := make_movement_targets(
            gs, {distance = max_distance, target = valid_endpoint},
        )
        visited_set_iter := make_target_set_iterator(&visited_set)
        for potential_info, potential_target in target_set_iter_members(&visited_set_iter) {
            target_info := reachable_targets_from_endpoint[potential_target.x][potential_target.y]

            if target_info.member && target_info.dist + potential_info.dist <= max_distance {
                potential_info.invalid = true
            } 
        }
    }

    // Remove all such marked unreachable spaces
    visited_set_iter := make_target_set_iterator(&visited_set)
    for info in target_set_iter_members(&visited_set_iter) {
        if !info.invalid do info.member = false
    }

    // Now the only spaces left in the visited set are those that can reach valid endpoints.
    // We now flag the spaces as invalid if they are not in the destination set.
    visited_set_iter = make_target_set_iterator(&visited_set)
    for info, target in target_set_iter_members(&visited_set_iter) {
        info.invalid = !valid_destinations[target.x][target.y].member
    }

    return
}

make_fast_travel_targets :: proc(gs: ^Game_State) -> (out: Target_Set) {
    hero_loc := get_my_player(gs).hero.location
    region := gs.board[hero_loc.x][hero_loc.y].region_id

    for loc in zone_indices[region] {
        space := gs.board[loc.x][loc.y]
        if UNIT_FLAGS & space.flags != {} && space.unit_team != get_my_player(gs).team {
            return
        }
    }

    for loc in zone_indices[region] {
        if OBSTACLE_FLAGS & gs.board[loc.x][loc.y].flags != {} do continue
        out[loc.x][loc.y].member = true
    }

    outer: for other_region in Region_ID {
        if other_region not_in fast_travel_adjacencies[region] do continue
        for loc in zone_indices[other_region] {
            space := gs.board[loc.x][loc.y]
            if UNIT_FLAGS & space.flags != {} && space.unit_team != get_my_player(gs).team {
                continue outer
            }
        }
        for loc in zone_indices[other_region] {
            if OBSTACLE_FLAGS & gs.board[loc.x][loc.y].flags != {} do continue
            out[loc.x][loc.y].member = true
        }
    }
    return out
}

make_clear_targets :: proc(gs: ^Game_State) -> (out: Target_Set) {
    hero_loc := get_my_player(gs).hero.location

    for vector in direction_vectors {
        other_loc := hero_loc + vector
        if .TOKEN in gs.board[other_loc.x][other_loc.y].flags {
            out[other_loc.x][other_loc.y].member = true
        }
    }
    return out
}

make_arbitrary_targets :: proc (
    gs: ^Game_State,
    criteria: Selection_Criteria,
    calc_context: Calculation_Context = {},
    loc := #caller_location
) -> (out: Target_Set, ok: bool) #optional_ok {

    if len(criteria.conditions) == 0 do return

    calc_context := calc_context
    calc_context.prev_target = calc_context.target
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            target := Target{i8(x), i8(y)}
            if target == {} do continue
            calc_context.target = target
            if calculate_implicit_condition(gs, criteria.conditions[0], calc_context, loc) {
                out[target.x][target.y].member = true
            }
        }
    }

    for condition in criteria.conditions[1:] {
        out_iter := make_target_set_iterator(&out)
        for info, target in target_set_iter_members(&out_iter) {
            calc_context.target = target
            if !calculate_implicit_condition(gs, condition, calc_context) {
                info.member = false
            }
        }
    }

    if .NOT_PREVIOUSLY_TARGETED in criteria.flags {
        previous_target := calculate_implicit_target(gs, Previous_Choice{}, calc_context)
        out[previous_target.x][previous_target.y].member = false
    }

    if .IGNORING_IMMUNITY not_in criteria.flags {
        target_set_iter := make_target_set_iterator(&out)
        for info, target in target_set_iter_members(&target_set_iter) {
            space := gs.board[target.x][target.y]
            if space.flags & {.IMMUNE} != {} {
                info.member = false
            }
        }
    }
    
    // Resolve "closest targets"
    if criteria.closest_to != nil {
        origin := calculate_implicit_target(gs, criteria.closest_to, calc_context, loc)
        lowest_dist := 1e6
        dist_iter := make_target_set_iterator(&out)
        for info, target in target_set_iter_members(&dist_iter) {
            info.dist = calculate_hexagonal_distance(origin, target)
            if info.dist < lowest_dist do lowest_dist = info.dist
        }
        dist_iter = make_target_set_iterator(&out)
        for info in target_set_iter_members(&dist_iter) {
            if info.dist > lowest_dist do info.member = false
        }
    }


    return out, true
}

make_card_targets :: proc(
    gs: ^Game_State,
    criteria: []Implicit_Condition,
    calc_context: Calculation_Context = {},
) -> (out: [dynamic]Card_ID) {
    calc_context := calc_context
    for card in get_my_player(gs).hero.cards {
        calc_context.card_id = card.id
        if calculate_implicit_condition(gs, criteria[0], calc_context) {
            append(&out, card.id)
        }
    }

    for criterion in criteria [1:] {
        #reverse for card_id, index in out {
            calc_context.card_id = card_id
            if !calculate_implicit_condition(gs, criterion, calc_context) {
                unordered_remove(&out, index)
            }
        }
    }

    return out
}