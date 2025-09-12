package guards

// import "core:fmt"
import "core:log"



Target :: [2]i8

INVALID_TARGET :: Target{-1, -1}

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
        if calculate_implicit_quantity(gs, freeze.timing.(Single_Turn), freeze.parent_card_id) != gs.turn_counter do break xarg_freeze
        context.allocator = context.temp_allocator
        my_location := get_my_player(gs).hero.location
        freeze_targets := make_arbitrary_targets(gs, freeze.target_set, freeze.parent_card_id)
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
    if action == nil do return false
    if action.condition != nil && !calculate_implicit_condition(gs, action.condition, index.card_id) do return false

    switch &variant in action.variant {
    case Movement_Action:
        action.targets = make_movement_targets(
            gs,
            calculate_implicit_quantity(gs, variant.distance, index.card_id),
            calculate_implicit_target(gs, variant.target, index.card_id),
            resolve_movement_destinations(gs, variant.destination_criteria, index.card_id),
            variant.flags,
        )
        origin := calculate_implicit_target(gs, variant.target, index.card_id)
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
        action.targets =  make_arbitrary_targets(gs, variant.criteria, index.card_id)
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
    case Halt_Action, Attack_Action, Add_Active_Effect_Action, Minion_Defeat_Action, Minion_Removal_Action, Jump_Action, Minion_Spawn_Action, Get_Defeated_Action, Respawn_Action:
        return true

    case Choose_Card_Action:
        variant.card_targets = make_card_targets(gs, variant.criteria)
        return len(variant.card_targets) > 0

    case Discard_Card_Action:
        return true

    case Retrieve_Card_Action:
        return true
    }
    return false
}

make_movement_targets :: proc (
    gs: ^Game_State,
    max_distance: int,
    origin: Target,
    valid_destinations: Maybe(Target_Set) = nil,
    flags: Movement_Flags = {},
    allocator := context.allocator,
) -> (visited_set: Target_Set) {

    context.allocator = allocator

    BIG_NUMBER :: 1e6
    max_distance := max_distance

    valid_destinations, destinations_ok := valid_destinations.?

    if .SHORTEST_PATH in flags {
        log.assert(destinations_ok, "Trying to calculate shortest path with no valid destination set given!")
        max_distance = BIG_NUMBER
    }

    // dijkstra's algorithm!   
    
    unvisited_set: Target_Set

    unvisited_set[origin.x][origin.y] = {dist = 0, prev_loc = INVALID_TARGET, member = true, invalid = false}

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

        if destinations_ok && .SHORTEST_PATH in flags && max_distance == BIG_NUMBER && valid_destinations[min_loc.x][min_loc.y].member {
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
                invalid = false,
            }
        }

        visited_set[min_loc.x][min_loc.y] = min_info
        unvisited_set[min_loc.x][min_loc.y].member = false
    }

    // See if we have a set of valid destinations first
    if destinations_ok {
        // first flag all nodes in the visited set as invalid (temporarily)
        visited_set_iter := make_target_set_iterator(&visited_set)
        for info in target_set_iter_members(&visited_set_iter) {
            info.invalid = true
        }

        // Check all spaces in the visited set to see if they can be reached by one of the valid endpoints.
        // If they can, they will be marked as valid. Otherwise they will stay invalid.
        valid_destinations_iter := make_target_set_iterator(&valid_destinations)
        for _, valid_endpoint in target_set_iter_members(&valid_destinations_iter) {
            if !visited_set[valid_endpoint.x][valid_endpoint.y].member do continue
            reachable_targets_from_endpoint := make_movement_targets(
                gs,
                max_distance,
                valid_endpoint,
                allocator = context.temp_allocator,
            )
            visited_set_iter = make_target_set_iterator(&visited_set)
            for potential_info, potential_target in target_set_iter_members(&visited_set_iter) {
                target_info := reachable_targets_from_endpoint[potential_target.x][potential_target.y]

                if target_info.member && target_info.dist + potential_info.dist <= max_distance {
                    potential_info.invalid = false
                } 
            }
        }

        // Remove all unreachable spaces
        visited_set_iter = make_target_set_iterator(&visited_set)
        for info in target_set_iter_members(&visited_set_iter) {
            if info.invalid do info.member = false
        }

        // Now the only spaces left in the visited set are those that can reach valid endpoints.
        // We now flag the spaces as invalid if they are not in the destination set.
        visited_set_iter = make_target_set_iterator(&visited_set)
        for info, target in target_set_iter_members(&visited_set_iter) {
            info.invalid = !valid_destinations[target.x][target.y].member
        }

    }

    return visited_set
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

target_fulfills_criterion :: proc (
    gs: ^Game_State,
    target: Target,
    criterion: Selection_Criterion,
    card_id: Card_ID = NULL_CARD_ID,
) -> bool {
    space := gs.board[target.x][target.y]

    switch selector in criterion {
    case Within_Distance:

        origin := calculate_implicit_target(gs, selector.origin, card_id)
        min_dist := calculate_implicit_quantity(gs, selector.min, card_id)
        max_dist := calculate_implicit_quantity(gs, selector.max, card_id)

        distance := calculate_hexagonal_distance(origin, target)
        return distance <= max_dist && distance >= min_dist

    case Contains_Any:
        intersection := space.flags & selector.flags
        return intersection != {}

    case Contains_All:
        intersection := space.flags & selector.flags
        return intersection == selector.flags
    
    case Contains_No:
        intersection := space.flags & selector.flags
        return intersection == {}

    // @Note these don't actually test whether a unit is present in the space, only that the teams are the same / different
    case Is_Enemy_Unit:         return get_my_player(gs).team != space.unit_team
    case Is_Friendly_Unit:      return get_my_player(gs).team == space.unit_team
    case Is_Losing_Team_Unit:
        losing_team: Team = .RED if gs.minion_counts[.RED] < gs.minion_counts[.BLUE] else .BLUE
        return losing_team == space.unit_team
    case Is_Enemy_Of:
        other_target := calculate_implicit_target(gs, selector.target, card_id)
        other_space := gs.board[other_target.x][other_target.y]
        return other_space.unit_team != space.unit_team

    case Is_Friendly_Spawnpoint: return get_my_player(gs).team == space.spawnpoint_team

    case In_Battle_Zone:        return space.region_id == gs.current_battle_zone
    case Outside_Battle_Zone:   return space.region_id != gs.current_battle_zone

    case Empty: return space.flags & OBSTACLE_FLAGS == {}

    case Ignoring_Immunity, Not_Previously_Targeted, Closest_Spaces:
    }
    return true
}

make_arbitrary_targets :: proc(
    gs: ^Game_State,
    criteria: []Selection_Criterion,
    card_id: Card_ID = NULL_CARD_ID,
) -> (out: Target_Set) {

    if criteria == nil do return

    // Start with completely populated board (Inefficient!)
    // @Speed
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            target := Target{i8(x), i8(y)}
            if target_fulfills_criterion(gs, target, criteria[0], card_id) {
                out[target.x][target.y].member = true
            }
        }
    }

    ignore_immunity := false

    for criterion in criteria[1:] {
        #partial switch variant in criterion {
        case Not_Previously_Targeted:
            previous_target := calculate_implicit_target(gs, Previous_Choice{}, card_id)
            out[previous_target.x][previous_target.y].member = false

        case Ignoring_Immunity:
            ignore_immunity = true

        case Closest_Spaces:
            context.allocator = context.temp_allocator
            for dist := 1 ; true ; dist += 1 {
                dist_targets := make_arbitrary_targets(
                    gs,
                    {
                        Within_Distance {
                            origin = variant.origin,
                            min = dist,
                            max = dist,
                        },
                    },
                )
                overlap := false
                dist_iter := make_target_set_iterator(&dist_targets)
                for _, dist_target in target_set_iter_members(&dist_iter) {
                    if out[dist_target.x][dist_target.y].member {
                        overlap = true
                        break
                    }
                }
                if !overlap do continue
                out_iter := make_target_set_iterator(&out)
                for info, target in target_set_iter_members(&out_iter) {
                    if !dist_targets[target.x][target.y].member do info.member = false
                }
                break
            }
        case:
            out_iter := make_target_set_iterator(&out)
            for info, target in target_set_iter_members(&out_iter) {
                if !target_fulfills_criterion(gs, target, criterion, card_id) {
                    info.member = false
                }
            }

        }
    }

    if !ignore_immunity {
        target_set_iter := make_target_set_iterator(&out)
        for info, target in target_set_iter_members(&target_set_iter) {
            space := gs.board[target.x][target.y]
            if space.flags & {.IMMUNE} != {} {
                info.member = false
            }
        }
    }


    return out
}


card_fulfills_criterion :: proc(gs: ^Game_State, card: Card, criterion: Card_Selection_Criterion, allocator := context.allocator) -> bool {
    switch variant in criterion {
    case Card_State: return card.state == variant
    case Can_Defend:
        // Phew
        // Find the attack first
        attack_strength := -1e6
        minion_modifiers := -1e6
        search_interrupts: #reverse for expanded_interrupt in gs.interrupt_stack {
            #partial switch interrupt_variant in expanded_interrupt.interrupt.variant {
            case Attack_Interrupt:
                attack_strength = interrupt_variant.strength
                minion_modifiers = interrupt_variant.minion_modifiers
                break search_interrupts
            }
        }
        log.assert(attack_strength != -1e6, "No attack found in interrupt stack!!!!!" )

        log.infof("Defending attack of %v, minions %v, card value %v", attack_strength, minion_modifiers)

        // We do it this way so that defense items get calculated
        defense_strength := calculate_implicit_quantity(gs, Card_Value{.DEFENSE}, card.id)
        return defense_strength + minion_modifiers >= attack_strength
    }
    log.assert(false, "non-returning switch case in card criterion checker")
    return false
}

make_card_targets :: proc(gs: ^Game_State, criteria: []Card_Selection_Criterion) -> (out: [dynamic]Card_ID) {
    // @Note: At a later point, we probably have to consider cards from all heroes, as there are some actions that require choosing other players' cards
    for card in get_my_player(gs).hero.cards {
        if card_fulfills_criterion(gs, card, criteria[0]) {
            append(&out, card.id)
        }
    }

    for criterion in criteria [1:] {
        #reverse for card_id, index in out {
            card, ok := get_card_by_id(gs, card_id)
            log.assert(ok, "How would this even happen lol")
            if !card_fulfills_criterion(gs, card^, criterion) {
                unordered_remove(&out, index)
            }
        }
    }

    return out
}