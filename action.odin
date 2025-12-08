package guards

import "core:log"

_ :: log


Movement_Flag :: enum {
    Shortest_Path,
    Ignoring_Obstacles,
    Straight_Line,
    // etc...
}

Movement_Criteria :: struct {
    min_distance: Implicit_Quantity,
    max_distance: Implicit_Quantity,
    destination_criteria: Selection_Criteria,
    flags: bit_set[Movement_Flag],
}

Path :: struct {
    num_locked_spaces: int,
    spaces: [dynamic]Target,
}

Movement_Action :: struct {
    target: Implicit_Target,
    using criteria: Movement_Criteria,
}

Fast_Travel_Action :: struct {}

Clear_Action :: struct {}

Selection_Criteria :: struct {
    conditions: []Implicit_Condition,
    closest_to: Implicit_Target,
    flags: Selection_Flags,
}

Choose_Target_Action :: struct {
    using criteria: Selection_Criteria,
    num_targets: Implicit_Quantity,
    label: Action_Value_Label,
}

Choice :: struct {
    name: string,
    valid: bool,
    jump_index: Action_Index,
}

Attack_Action :: struct {
    target: Implicit_Target,
    strength: Implicit_Quantity,
    flags: Attack_Flags,
}

Force_Discard_Action :: struct {
    target: Implicit_Target,
    or_is_defeated: bool,
}

Choice_Action :: struct {
    choices: []Choice,
    cannot_repeat: bool,
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
    location: Implicit_Target,
    minion_type: Implicit_Space_Flag,
}

Card_ID_Set :: map[Card_ID]Void

Choose_Card_Action :: struct {
    criteria: []Implicit_Condition,
    card_targets: Card_ID_Set,
}

Defend_Action :: struct {
    strength: Implicit_Quantity,
    block_condition: Implicit_Condition,
}

Retrieve_Card_Action :: struct {
    card: Implicit_Card_ID,
}

Discard_Card_Action :: struct {
    card: Implicit_Card_ID,
}

Jump_Action :: struct {
    jump_index: Implicit_Action_Index,
}

Repeat_Action :: struct {
    max_repeats: int,
}

Get_Defeated_Action :: struct {}

Respawn_Action :: struct {
    location: Implicit_Target,
}

Gain_Coins_Action :: struct {
    target: Implicit_Target,
    gain: Implicit_Quantity,
}

Place_Action :: struct {
    source, destination: Implicit_Target,
}

Choose_Quantity_Action :: struct {
    bounds: []Implicit_Quantity,
}

Push_Action :: struct {
    origin: Implicit_Target,
    targets: Implicit_Target_Slice,
    num_spaces: Implicit_Quantity,
    ignoring_obstacles: bool,
}

Give_Marker_Action :: struct {
    target: Implicit_Target,
    marker: Marker,
}

Swap_Action :: struct {
    targets: Implicit_Target_Slice,
}

Action_Variable :: union {
    Implicit_Condition,
    Implicit_Quantity,
}

Save_Variable_Action :: struct {
    variable: Action_Variable,
    label: Action_Value_Label,
    global: bool,
}

Choose_Dead_Minion_Type_Action :: struct {}

Gain_Item_Action :: struct {
    card_id: Implicit_Card_ID,
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
    Repeat_Action,
    Get_Defeated_Action,
    Respawn_Action,
    Gain_Coins_Action,
    Place_Action,
    Choose_Quantity_Action,
    Push_Action,
    Give_Marker_Action,
    Swap_Action,
    Save_Variable_Action,
    Choose_Dead_Minion_Type_Action,
    Gain_Item_Action,

    Minion_Removal_Action,
    Minion_Defeat_Action,
    Minion_Spawn_Action,
}

Action :: struct {
    tooltip: Tooltip,
    optional: Implicit_Condition,
    condition: Implicit_Condition,

    // I'm redoing this slightly to allow skipping non-optional actions.
    // Now the action will always jump to the skip index if impossible, even if the action is non-optional.
    // This has a nice knock-on effect as now optional actions with no given skip index
    // will halt if they are impossible.
    skip_index: Action_Index,
    skip_name: string,
    variant: Action_Variant,
    
    targets: Target_Set,
}

Action_Sequence_ID :: enum {
    // Requires Card ID
    Primary,
    Basic_Movement,
    Basic_Fast_Travel,
    Basic_Clear,
    Basic_Defense,
    First_Choice,

    // Doesn't require Card ID
    Halt,
    Die,
    Respawn,
    Minion_Removal,
    Minion_Spawn,
    Minion_Outside_Zone,
    Discard_If_Able,
    Discard_Or_Die,

    Invalid,
}

Action_Index :: struct {
    sequence: Action_Sequence_ID,
    card_id: Card_ID,
    index: int,
}



player_movement_tooltip :: "Choose a space to move to."

error_tooltip :: "You should never see this. Tell Griffon if you do!"

first_choice_tooltip :: "Choose an action to take with your played card."


first_choice_action := []Action {
    Action {
        tooltip = first_choice_tooltip,
        variant = Choice_Action {
            choices = []Choice {
                {name = "Primary",      jump_index = {sequence=.Primary}},
                {name = "Movement",     jump_index = {sequence=.Basic_Movement}},
                {name = "Fast Travel",  jump_index = {sequence=.Basic_Fast_Travel}},
                {name = "Clear",        jump_index = {sequence=.Basic_Clear}},
                {name = "Hold",         jump_index = {sequence=.Halt}},
            },
        },
    },
}

basic_movement_action := []Action {
    {
        tooltip = player_movement_tooltip,
        condition = And{Not{Card_Primary_Is{.Movement}}, Greater_Than{Card_Value{.Movement}, 0}},
        variant = Movement_Action {
            target   = Self{},
            max_distance = Card_Value{.Movement},
        },
    },
}

basic_fast_travel_action := []Action {
    Action {
        tooltip = "Choose a space to fast travel to.",
        condition = Greater_Than{Card_Value{.Movement}, 0},
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
    Action {  // 0
        tooltip = "Choose a card to defend with. You may also choose to die.",
        optional = true,
        skip_index = {sequence = .Die},
        skip_name = "Die",
        variant = Choose_Card_Action {
            criteria = {
                Card_Owner_Is{Self{}},
                Card_State_Is{.In_Hand},  // Apparently you can just discard anything, even if it can't defend...
            },
        },
    },
    Action {  // 1
        tooltip = error_tooltip,
        variant = Discard_Card_Action {
            Previous_Card_Choice{},
        },
    },
    Action {  // 2
        tooltip = error_tooltip,
        variant = Jump_Action {
            jump_index = Card_Defense_Index{Previous_Card_Choice{}},
        },
    },
    Action {  // 3
        tooltip = error_tooltip,
        variant = Defend_Action {
            strength = Sum {
                Card_Value{.Defense},
                Minion_Modifiers{},
            },
        },
    },
}

die_action := []Action {
    Action {
        variant = Get_Defeated_Action{},
    },
}

discard_if_able_action := []Action {
    Action {
        tooltip = "Choose a card to discard.",
        variant = Choose_Card_Action {
            criteria = {
                Card_Owner_Is{Self{}},
                Card_State_Is{.In_Hand},
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
                Card_Owner_Is{Self{}},
                Card_State_Is{.In_Hand},
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
        skip_name = "Stay dead",
        tooltip = "Choose a spawnpoint to respawn in. You may also stay dead.",
        variant = Choose_Target_Action {
            num_targets = 1,
            conditions = {
                Target_Empty{},
                Target_Contains_Any{{.Hero_Spawnpoint}},
                Target_Is_Friendly_Spawnpoint{},
            },
        },
    },
    Action {
        variant = Respawn_Action {
            location = Previously_Chosen_Target{},
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
            conditions = {
                Target_Contains_Any{{.Melee_Minion, .Ranged_Minion}},
                Target_Is_Losing_Team_Unit{},
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
            conditions = {
                Target_In_Battle_Zone{},
                Target_Empty{},
            },
            closest_to = Top_Blocked_Spawnpoint{},
        },
    },
    Action {
        variant = Minion_Spawn_Action {
            location = Previously_Chosen_Target{},
            minion_type = Top_Blocked_Spawnpoint_Type{},
        },
    },
    Action {
        variant = Jump_Action {
            jump_index = Action_Index{sequence = .Minion_Spawn},
        },
    },
}

minion_outside_zone_action := []Action {  // Still need to handle the case where there is no valid path here
    Action {
        tooltip = "Choose which minion outside the zone to move.",
        variant = Choose_Target_Action {
            num_targets = 1,
            conditions = {
                Target_Contains_Any{MINION_FLAGS},
                Target_Is_Friendly_Unit{},
                Target_Outside_Battle_Zone{},
            },
        },
    },
    Action {
        tooltip = "Choose one of the closest spaces in the battle zone to move the minion to.",
        variant = Movement_Action {
            target = Previously_Chosen_Target{},
            destination_criteria = {
                conditions = {
                    Target_In_Battle_Zone{},
                },
            },
            flags = {.Shortest_Path},
        },
    },
}


get_current_action :: proc(gs: ^Game_State) -> ^Action {
    return get_action_at_index(gs, get_my_player(gs).hero.current_action_index)
}

get_action_at_index :: proc(gs: ^Game_State, index: Action_Index, loc := #caller_location) -> ^Action {
    action_sequence: []Action

    switch index.sequence {
    case .Primary:
        card_data, ok := get_card_data_by_id(index.card_id)
        if !ok do return nil
        action_sequence = card_data.primary_effect
    case .Halt:                 return nil
    case .Die:                  action_sequence = die_action
    case .Respawn:              action_sequence = respawn_action
    case .First_Choice:         action_sequence = first_choice_action
    case .Basic_Movement:       action_sequence = basic_movement_action
    case .Basic_Fast_Travel:    action_sequence = basic_fast_travel_action
    case .Basic_Clear:          action_sequence = basic_clear_action
    case .Basic_Defense:        action_sequence = basic_defense_action
    case .Minion_Removal:       action_sequence = minion_removal_action
    case .Minion_Spawn:         action_sequence = minion_spawn_action
    case .Minion_Outside_Zone:  action_sequence = minion_outside_zone_action
    case .Discard_If_Able:      action_sequence = discard_if_able_action
    case .Discard_Or_Die:       action_sequence = discard_or_defeated_action

    case .Invalid:              return nil
    }

    if index.index < len(action_sequence) {
        return &action_sequence[index.index]
    }

    return nil
}
