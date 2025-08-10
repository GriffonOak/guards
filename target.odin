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

action_can_be_taken :: proc(index: int = 0) -> bool {
    if index == HALT_INDEX do return true

    // Disable movement on xargatha freeze
    if freeze, ok := game_state.ongoing_active_effects[.XARGATHA_FREEZE]; ok {
        if calculate_implicit_quantity(freeze.duration.(Single_Turn)) == game_state.turn_counter {
            context.allocator = context.temp_allocator
            if player.hero.location in calculate_implicit_target_set(freeze.target_set) {
                if index == BASIC_MOVEMENT_INDEX || (index == 0 && find_played_card().primary == .MOVEMENT) {
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
    }
    return false
}

Dijkstra_Info :: struct {
    dist: int,
    prev_node: IVec2,
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

        if player.team != .NONE && space.unit_team != .NONE && player.team != space.unit_team {
            return true
        }
        return false

    case Is_Friendly_Unit:
        if player.team != .NONE && space.unit_team != .NONE && player.team == space.unit_team {
            return true
        }
        return false

    case Ignoring_Immunity, Not_Previously_Targeted:
    }
    return true
}

make_arbitrary_targets :: proc(criteria: []Selection_Criterion, allocator := context.allocator) -> (out: Target_Set) {

    // context.allocator = allocator

    // // Start with completely populated board (Inefficient!)
    // // @Speed
    // for x in 0..<GRID_WIDTH {
    //     for y in 0..<GRID_HEIGHT {
    //         target := Target{x, y}
    //         if target_fulfills_criterion(target, criteria[0]) {
    //             out[target] = {}
    //         }
    //     }
    // }

    // ignore_immunity := false

    // for criterion in criteria[1:] {
    //     switch variant in criterion {
    //     case Within_Distance, Contains_Any, Is_Enemy_Unit, Is_Friendly_Unit:
    //         for target, info in out {
    //             if !target_fulfills_criterion(target, criterion) {
    //                 delete_key(&out, target)
    //             }
    //         }

    //     case Not_Previously_Targeted:
    //         previous_target := calculate_implicit_target(Previous_Choice{})
    //         delete_key(&out, previous_target)

    //     case Ignoring_Immunity:
    //         ignore_immunity = true

    //     }
    // }

    // if !ignore_immunity {
    //     for target, info in out {
    //         space := board[target.x][target.y]
    //         if space.flags & {.IMMUNE} != {} {
    //             delete_key(&out, target)
    //         }
    //     }
    // }


    return out
}
