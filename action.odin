package guards

import "core:log"

_ :: log

Within_Distance :: struct {
    origin: Implicit_Target,
    min: Implicit_Quantity,
    max: Implicit_Quantity,
}

// Nearby_At_Least :: struct {
//     reach, count: int,
//     criteria: []Selection_Criterion,
// }

Fulfills_Condition :: struct {
    condition: Implicit_Condition,
}

Adjacent := Within_Distance{Self{}, 1, 1}

Closest_Spaces :: struct {
    origin: Implicit_Target,
}

Contains_Any :: struct { flags: Space_Flags }
Contains_No  :: struct { flags: Space_Flags }
Contains_All :: struct { flags: Space_Flags }

Is_Enemy_Unit :: struct {}
Is_Friendly_Unit :: struct {}
Is_Losing_Team_Unit :: struct {}
Is_Enemy_Of :: struct {
    target: Implicit_Target,
}
Is_Friendly_Spawnpoint :: struct {}
Not_Previously_Targeted :: struct {}

Ignoring_Immunity :: struct {}
In_Battle_Zone :: struct {}
Outside_Battle_Zone :: struct {}
Empty :: struct {}

Selection_Criterion :: union {
    Within_Distance,
    Fulfills_Condition,
    Closest_Spaces,  // Important to list this one last in any list of criteria
    Contains_Any,
    Contains_No,
    Contains_All,
    Is_Enemy_Unit,
    Is_Friendly_Unit,
    Is_Losing_Team_Unit,
    Is_Enemy_Of,
    Is_Friendly_Spawnpoint,
    Not_Previously_Targeted,
    Ignoring_Immunity,
    In_Battle_Zone,
    Outside_Battle_Zone,
    Empty,
}



Path :: struct {
    num_locked_spaces: int,
    spaces: [dynamic]Target,
}

Movement_Flag :: enum {
    SHORTEST_PATH,
    // IGNORING_OBSTACLES,
    // STRAIGHT_LINE,
    // etc...
}

Movement_Flags :: bit_set[Movement_Flag]

Movement_Action :: struct {
    target: Implicit_Target,
    distance: Implicit_Quantity,
    destination_criteria: []Selection_Criterion,
    flags: Movement_Flags,

    path: Path,
}

Fast_Travel_Action :: struct {
    result: Target,
}

Clear_Action :: struct {}

Choose_Target_Action :: struct {
    criteria: []Selection_Criterion,
    num_targets: Implicit_Quantity,
    result: [dynamic]Target,
    // result: Target
}

Choice :: struct {
    name: cstring,
    valid: bool,
    jump_index: Action_Index,
}

Attack_Action :: struct {
    target: Implicit_Target,
    strength: Implicit_Quantity,
}

Force_Discard_Action :: struct {
    target: Implicit_Target,
    or_is_defeated: bool,
}

Choice_Action :: struct {
    choices: []Choice,
    result: Action_Index,
}

Add_Active_Effect_Action :: struct {
    effect: Active_Effect,
}

Halt_Action :: struct {}

Minion_Defeat_Action :: struct {
    target: Implicit_Target,
}

Minion_Removal_Action :: struct {
    targets: Implicit_Target_Slice,
}

Minion_Spawn_Action :: struct {
    location, spawnpoint: Implicit_Target,
}

Can_Defend :: struct {}

Card_Selection_Criterion :: union {
    Can_Defend,
    Card_State,
}

Choose_Card_Action :: struct {
    criteria: []Card_Selection_Criterion,
    card_targets: [dynamic]Card_ID,
    result: Card_ID,
}

Defend_Action :: struct {
    card: Implicit_Card,
}

Retrieve_Card_Action :: struct {
    card: Implicit_Card,
}

Discard_Card_Action :: struct {
    card: Implicit_Card,
}

Jump_Action :: struct {
    jump_index: Action_Index,
}

Get_Defeated_Action :: struct {}

Respawn_Action :: struct {
    location: Implicit_Target,
}

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Attack_Action,
    Defend_Action,
    Clear_Action,
    Choose_Target_Action,
    Choice_Action,
    Add_Active_Effect_Action,
    Halt_Action,
    Choose_Card_Action,
    Force_Discard_Action,
    Retrieve_Card_Action,
    Discard_Card_Action,
    Jump_Action,
    Get_Defeated_Action,
    Respawn_Action,

    Minion_Removal_Action,
    Minion_Defeat_Action,
    Minion_Spawn_Action,
}

Action :: struct {
    tooltip: Tooltip,
    optional: bool,
    condition: Implicit_Condition,
    skip_index: Action_Index,
    skip_name: cstring,
    variant: Action_Variant,
    targets: Target_Set,
}

Action_Sequence_ID :: enum {
    // Requires Card ID
    PRIMARY,
    BASIC_MOVEMENT,
    BASIC_FAST_TRAVEL,
    BASIC_CLEAR,
    BASIC_DEFENSE,

    FIRST_CHOICE,

    // Doesn't require Card ID
    HALT,
    RESPAWN,
    MINION_REMOVAL,
    MINION_SPAWN,
    MINION_OUTSIDE_ZONE,
    DISCARD_ABLE,
    DISCARD_DEFEAT,
}

Action_Index :: struct {
    sequence: Action_Sequence_ID,
    card_id: Card_ID,
    index: int,
}



player_movement_tooltip: cstring : "Choose a space to move to."

error_tooltip: cstring : "You should never see this. Tell Griffon if you do!"

first_choice_tooltip: cstring : "Choose an action to take with your played card."


first_choice_action := []Action {
    Action {
        condition = Alive{},
        tooltip = first_choice_tooltip,
        variant = Choice_Action {
            choices = []Choice {
                {name = "Primary",      jump_index = {sequence=.PRIMARY}},
                {name = "Movement",     jump_index = {sequence=.BASIC_MOVEMENT}},
                {name = "Fast Travel",  jump_index = {sequence=.BASIC_FAST_TRAVEL}},
                {name = "Clear",        jump_index = {sequence=.BASIC_CLEAR}},
                {name = "Hold",         jump_index = {sequence=.HALT}},
            },
        },
    },
}

basic_movement_action := []Action {
    {
        tooltip = player_movement_tooltip,
        condition = And{Primary_Is_Not{.MOVEMENT}, Greater_Than{Card_Value{kind=.MOVEMENT}, 0}},
        variant = Movement_Action {
            target   = Self{},
            distance = Card_Value{kind=.MOVEMENT},
        },
    },
}

basic_fast_travel_action := []Action {
    Action {
        tooltip = "Choose a space to fast travel to.",
        condition = Greater_Than{Card_Value{kind=.MOVEMENT}, 0},
        variant = Fast_Travel_Action{},
    },
}

basic_clear_action := []Action {
    Action {
        tooltip = "Choose any number of tokens adjacent to you to remove.",
        variant = Clear_Action{},
    },
}

basic_defense_action := []Action {
    Action {
        tooltip = "Choose a card to defend with. You may also choose to die.",
        optional = true,
        skip_index = {index = 3},
        skip_name = "Die",
        variant = Choose_Card_Action {
            criteria = {
                Card_State.IN_HAND,
                Can_Defend{},
            },
        },
    },
    Action {
        tooltip = error_tooltip,
        variant = Defend_Action {
            Previous_Card_Choice{},
        },
    },
    Action {
        variant = Halt_Action{},
    },
    Action {
        variant = Get_Defeated_Action{},
    },
}

discard_if_able_action := []Action {
    Action {
        tooltip = "Choose a card to discard.",
        variant = Choose_Card_Action {
            criteria = {
                Card_State.IN_HAND,
            },
        },
    },
    Action {
        tooltip = error_tooltip,
        variant = Discard_Card_Action {
            Previous_Card_Choice{},
        },
    },
}

discard_or_defeated_action := []Action {
    Action {
        tooltip = "Choose a card to discard. You may also choose to die.",
        optional = true,
        skip_index = {index = 3},
        skip_name = "Die",
        variant = Choose_Card_Action {
            criteria = {
                Card_State.IN_HAND,
            },
        },
    },
    Action {
        tooltip = error_tooltip,
        variant = Discard_Card_Action {
            Previous_Card_Choice{},
        },
    },
    Action {
        variant = Halt_Action{},
    },
    Action {
        variant = Get_Defeated_Action{},
    },
}

respawn_action := []Action {
    Action {
        optional = true,
        skip_index = {sequence = .HALT},
        skip_name = "Stay dead",
        tooltip = "Choose a spawnpoint to respawn in. You may also stay dead.",
        variant = Choose_Target_Action {
            num_targets = 1,
            criteria = {
                Empty{},
                Contains_Any{{.HERO_SPAWNPOINT}},
                Is_Friendly_Spawnpoint{},
            },
        },
    },
    Action {
        variant = Respawn_Action {
            location = Previous_Choice{},
        },
    },
}

minion_removal_action := []Action {
    Action {
        tooltip = Formatted_String{
            format = "Choose %v minion%v to remove.",
            arguments = {
                Implicit_Quantity(Minion_Difference{}),
                Conditional_String_Argument {
                    condition = Greater_Than{Minion_Difference{}, 1},
                    arg1 = string("s"),
                    arg2 = string(""),
                },
            },
        },
        variant = Choose_Target_Action {
            num_targets = Minion_Difference{},
            criteria = {
                Contains_Any{{.MELEE_MINION, .RANGED_MINION}},
                Is_Losing_Team_Unit{},
            },
        },
    },
    Action {
        variant = Minion_Removal_Action{
            targets = Previous_Choices{},
        },
    },
}

minion_spawn_action := []Action {
    Action {
        tooltip = "Choose a space to spawn the blocked minion in.",
        condition = Blocked_Spawnpoints_Remain{},
        variant = Choose_Target_Action {
            num_targets = 1,
            criteria = {
                In_Battle_Zone{},
                Empty{},
                Closest_Spaces {
                    origin = Top_Blocked_Spawnpoint{},
                },
            },
        },
    },
    Action {
        variant = Minion_Spawn_Action {
            location = Previous_Choice{},
            spawnpoint = Top_Blocked_Spawnpoint{},
        },
    },
    Action {
        variant = Jump_Action {
            jump_index = {sequence = .MINION_SPAWN, index = 0},
        },
    },
}

minion_outside_zone_action := []Action {  // Still need to handle the case where there is no valid path here
    Action {
        tooltip = "Choose which minion outside the zone to move.",
        variant = Choose_Target_Action {
            num_targets = 1,
            criteria = {
                Contains_Any{MINION_FLAGS},
                Is_Friendly_Unit{},
                Outside_Battle_Zone{},
            },
        },
    },
    Action {
        tooltip = "Choose one of the closest spaces in the battle zone to move the minion to.",
        variant = Movement_Action {
            target = Previous_Choice{},
            destination_criteria = []Selection_Criterion {
                In_Battle_Zone{},
            },
            flags = {.SHORTEST_PATH},
        },
    },
}

resolve_movement_destinations :: proc(gs: ^Game_State, criteria: []Selection_Criterion, calc_context: Calculation_Context = {}) -> Maybe(Target_Set) {
    if len(criteria) > 0 {
        return make_arbitrary_targets(gs, criteria, calc_context)
    }
    return nil
}


get_current_action :: proc(gs: ^Game_State) -> ^Action {
    return get_action_at_index(gs, get_my_player(gs).hero.current_action_index)
}

get_action_at_index :: proc(gs: ^Game_State, index: Action_Index, loc := #caller_location) -> ^Action {
    action_sequence: []Action

    switch index.sequence {
    case .PRIMARY:
        card_data, ok := get_card_data_by_id(gs, index.card_id)
        if !ok do return nil
        // log.assert(ok, "no played card!!?!?!?!?!", loc)
        action_sequence = card_data.primary_effect
    case .HALT:                 return nil
    case .RESPAWN:              action_sequence = respawn_action
    case .FIRST_CHOICE:         action_sequence = first_choice_action
    case .BASIC_MOVEMENT:       action_sequence = basic_movement_action
    case .BASIC_FAST_TRAVEL:    action_sequence = basic_fast_travel_action
    case .BASIC_CLEAR:          action_sequence = basic_clear_action
    case .BASIC_DEFENSE:        action_sequence = basic_defense_action
    case .MINION_REMOVAL:       action_sequence = minion_removal_action
    case .MINION_SPAWN:         action_sequence = minion_spawn_action
    case .MINION_OUTSIDE_ZONE:  action_sequence = minion_outside_zone_action
    case .DISCARD_ABLE:         action_sequence = discard_if_able_action
    case .DISCARD_DEFEAT:       action_sequence = discard_or_defeated_action
    }

    if index.index < len(action_sequence) {
        return &action_sequence[index.index]
    }

    return nil
}
