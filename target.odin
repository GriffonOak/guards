package guards

// import "core:fmt"
import "core:log"



Target :: IVec2

Target_Info :: struct {
    dist: int,
    prev_node: Target,
    invalid: bool,  // True if we can move to the space along the way to a valid endpoint but the space itself is not a valid endpoint
    // We flag invalid rather than valid here so spaces default to being valid
}

Target_Set :: map[Target]Target_Info


validate_action :: proc(index: Action_Index) -> bool {
    if index.sequence == .HALT do return true

    xarg_freeze: { // Disable movement on xargatha freeze
        freeze, ok := game_state.ongoing_active_effects[.XARGATHA_FREEZE]
        if !ok do break xarg_freeze
        if calculate_implicit_quantity(freeze.duration.(Single_Turn), freeze.parent_card_id) != game_state.turn_counter do break xarg_freeze
        context.allocator = context.temp_allocator
        if get_my_player().hero.location not_in make_arbitrary_targets(freeze.target_set, freeze.parent_card_id) do break xarg_freeze
        played_card, ok2 := find_played_card()
        log.assert(ok2, "Could not find played card when checking for Xargatha freeze")
        if index.sequence == .BASIC_MOVEMENT || (index.index == 0 && played_card.primary == .MOVEMENT) {
            // phew
            return false
        }
    }


    action := get_action_at_index(index)
    if action == nil do return false
    if action.condition != nil && !calculate_implicit_condition(action.condition, index.card_id) do return false

    switch &variant in action.variant {
    case Movement_Action:
        action.targets =  make_movement_targets(
            calculate_implicit_quantity(variant.distance, index.card_id),
            calculate_implicit_target(variant.target, index.card_id),
            make_arbitrary_targets(variant.valid_destinations, index.card_id),
            variant.flags,
        )
        return len(action.targets) > 0

    case Fast_Travel_Action:
        action.targets =  make_fast_travel_targets()
        return len(action.targets) > 0

    case Clear_Action:
        action.targets =  make_clear_targets()
        return len(action.targets) > 0

    case Choose_Target_Action:
        action.targets =  make_arbitrary_targets(variant.criteria, index.card_id)
        return len(action.targets) > 0

    case Choice_Action:
        out := false
        for &choice in &variant.choices {
            jump_index := choice.jump_index
            if jump_index.card_id == NULL_CARD_ID do jump_index.card_id = index.card_id
            choice.valid = validate_action(jump_index)
            out ||= choice.valid
        }
        return out

    // @Note maybe respawn should check if we're dead
    case Halt_Action, Attack_Action, Add_Active_Effect_Action, Minion_Removal_Action, Jump_Action, Minion_Spawn_Action, Get_Defeated_Action, Respawn_Action:
        return true

    case Choose_Card_Action:
        variant.card_targets = make_card_targets(variant.criteria)
        return len(variant.card_targets) > 0

    case Discard_Card_Action:
        return true

    case Retrieve_Card_Action:
        return true
    }
    return false
}

make_movement_targets :: proc (
    max_distance: int,
    origin: Target,
    valid_destinations: Target_Set = nil,
    flags: Movement_Flags = {},
    allocator := context.allocator,
) -> (visited_set: Target_Set) {

    context.allocator = allocator

    BIG_NUMBER :: 1e6
    max_distance := max_distance

    if .SHORTEST_PATH in flags {
        log.assert(valid_destinations != nil, "Trying to calculate shortest path with no valid destination set given!")
        max_distance = BIG_NUMBER
    }

    // dijkstra's algorithm!

    
    unvisited_set: Target_Set

    unvisited_set[origin] = {0, {-1, -1}, false}

    for len(unvisited_set) > 0 {
        // find minimum
        min_info := Target_Info{dist = BIG_NUMBER}
        min_loc := IVec2{-1, -1}
        for loc, info in unvisited_set {
            if info.dist < min_info.dist {
                min_loc = loc
                min_info = info
            }
        }

        if .SHORTEST_PATH in flags && max_distance == BIG_NUMBER && min_loc in valid_destinations {
            // Shortest distance found!
            max_distance = min_info.dist
        }

        directions: for vector in direction_vectors {
            next_loc := min_loc + vector

            {   // Validate next location
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
            }

            next_dist := min_info.dist + 1
            if next_dist > max_distance do continue
            existing_info, ok := unvisited_set[next_loc]
            if !ok || next_dist < existing_info.dist do unvisited_set[next_loc] = Target_Info {
                next_dist,
                min_loc,
                false,
            }
        }

        visited_set[min_loc] = min_info
        delete_key(&unvisited_set, min_loc)
    }

    if valid_destinations != nil {
        // first flag all nodes in the visited set as invalid (temporarily)
        for _, &info in visited_set {
            info.invalid = true
        }

        // Check all spaces in the visited set to see if they can be reached by one of the valid endpoints.
        // If they can, they will be marked as valid. Otherwise they will stay invalid.
        for valid_endpoint in valid_destinations {
            if valid_endpoint not_in visited_set do continue
            reachable_targets_from_endpoint := make_movement_targets(
                max_distance,
                valid_endpoint,
                allocator = context.temp_allocator,
            )
            for potential_target, &potential_info in visited_set {
                target_info, ok2 := reachable_targets_from_endpoint[potential_target]

                if ok2 && target_info.dist + potential_info.dist <= max_distance {
                    potential_info.invalid = false
                } 
            }
        }

        // Remove all unreachable spaces
        for target, info in visited_set {
            if info.invalid do delete_key(&visited_set, target)
        }

        // Now the only spaces left in the visited set are those that can reach valid endpoints.
        // We now flag the spaces as invalid if they are not in the destination set.
        for target, &info in visited_set {
            info.invalid = target not_in valid_destinations
        }

    }

    return visited_set
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

target_fulfills_criterion :: proc(target: Target, criterion: Selection_Criterion, card_id: Card_ID = NULL_CARD_ID) -> bool {
    space := board[target.x][target.y]

    switch selector in criterion {
    case Within_Distance:

        origin := calculate_implicit_target(selector.origin, card_id)
        min_dist := calculate_implicit_quantity(selector.min, card_id)
        max_dist := calculate_implicit_quantity(selector.max, card_id)

        distance := calculate_hexagonal_distance(origin, target)
        return distance <= max_dist && distance >= min_dist

    case Contains_Any:

        intersection := space.flags & selector
        return intersection != {}


    // @Note these don't actually test whether a unit is present in the space, only that the teams are the same / different
    case Is_Enemy_Unit:         return get_my_player().team != space.unit_team
    case Is_Friendly_Unit:      return get_my_player().team == space.unit_team
    case Is_Enemy_Of:
        other_target := calculate_implicit_target(selector.target, card_id)
        other_space := board[other_target.x][other_target.y]
        return other_space.unit_team != space.unit_team

    case Is_Friendly_Spawnpoint: return get_my_player().team == space.spawnpoint_team

    case In_Battle_Zone:        return space.region_id == game_state.current_battle_zone
    case Outside_Battle_Zone:   return space.region_id != game_state.current_battle_zone

    case Empty: return space.flags & OBSTACLE_FLAGS == {}

    case Ignoring_Immunity, Not_Previously_Targeted, Closest_Spaces:
    }
    return true
}

make_arbitrary_targets :: proc(criteria: []Selection_Criterion, card_id: Card_ID = NULL_CARD_ID, allocator := context.allocator) -> (out: Target_Set) {

    if criteria == nil do return nil
    context.allocator = allocator

    // Start with completely populated board (Inefficient!)
    // @Speed
    for x in 0..<GRID_WIDTH {
        for y in 0..<GRID_HEIGHT {
            target := Target{x, y}
            if target_fulfills_criterion(target, criteria[0], card_id) {
                out[target] = {}
            }
        }
    }

    ignore_immunity := false

    for criterion in criteria[1:] {
        switch variant in criterion {
        case Within_Distance, Contains_Any, Is_Enemy_Unit, Is_Friendly_Unit, Is_Enemy_Of, Is_Friendly_Spawnpoint, In_Battle_Zone, Outside_Battle_Zone, Empty:
            for target in out {
                if !target_fulfills_criterion(target, criterion, card_id) {
                    delete_key(&out, target)
                }
            }

        case Not_Previously_Targeted:
            previous_target := calculate_implicit_target(Previous_Choice{}, card_id)
            delete_key(&out, previous_target)

        case Ignoring_Immunity:
            ignore_immunity = true

        case Closest_Spaces:
            context.allocator = context.temp_allocator
            for dist := 1 ; true ; dist += 1 {
                dist_targets := make_arbitrary_targets(
                    {
                        Within_Distance {
                            origin = variant.origin,
                            min = dist,
                            max = dist,
                        },
                    },
                )
                overlap := false
                for dist_target in dist_targets {
                    if dist_target in out {
                        overlap = true
                        break
                    }
                }
                if !overlap do continue
                for target in out {
                    if target not_in dist_targets do delete_key(&out, target)
                }
                break
            }

        }
    }

    if !ignore_immunity {
        for target in out {
            space := board[target.x][target.y]
            if space.flags & {.IMMUNE} != {} {
                delete_key(&out, target)
            }
        }
    }


    return out
}


card_fulfills_criterion :: proc(card: Card, criterion: Card_Selection_Criterion, allocator := context.allocator) -> bool {
    switch variant in criterion {
    case Card_State: return card.state == variant
    case Can_Defend:
        // Phew
        // Find the attack first
        attack_strength := -1e6
        minion_modifiers := -1e6
        search_interrupts: #reverse for expanded_interrupt in game_state.interrupt_stack {
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
        defense_strength := calculate_implicit_quantity(Card_Value{.DEFENSE}, card.id)
        return defense_strength + minion_modifiers >= attack_strength
    }
    log.assert(false, "non-returning switch case in card criterion checker")
    return false
}

make_card_targets :: proc(criteria: []Card_Selection_Criterion) -> (out: [dynamic]Card_ID) {
    for card in get_my_player().hero.cards {
        if card_fulfills_criterion(card, criteria[0]) {
            append(&out, card.id)
        }
    }

    for criterion in criteria [1:] {
        #reverse for card_id, index in out {
            card, ok := get_card_by_id(card_id)
            log.assert(ok, "How would this even happen lol")
            if !card_fulfills_criterion(card^, criterion) {
                unordered_remove(&out, index)
            }
        }
    }

    return out
}