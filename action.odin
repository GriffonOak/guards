package guards

import "core:log"

Within_Distance :: struct {
    origin: Implicit_Target,
    min: Implicit_Quantity,
    max: Implicit_Quantity,
}

Closest_Spaces :: struct {
    origin: Implicit_Target,
}

Contains_Any :: Space_Flags
Contains_All :: Space_Flags

Is_Enemy_Unit :: struct {}
Is_Friendly_Unit :: struct {}
Not_Previously_Targeted :: struct {}

Ignoring_Immunity :: struct {}
In_Battle_Zone :: struct {}
Empty :: struct {}

Selection_Criterion :: union {
    Within_Distance,
    Closest_Spaces,  // Important to list this one last in any list of criteria
    Contains_Any,
    // Contains_All,
    Is_Enemy_Unit,
    Is_Friendly_Unit,
    Not_Previously_Targeted,
    Ignoring_Immunity,
    In_Battle_Zone,
    Empty,
}



Path :: struct {
    num_locked_spaces: int,
    spaces: [dynamic]Target,
}

Movement_Action :: struct {
    target: Implicit_Target,
    distance: Implicit_Quantity,
    valid_destinations: Implicit_Target_Set,

    path: Path
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

Choice_Action :: struct {
    choices: []Choice,
    result: Action_Index,
}

Add_Active_Effect_Action :: struct {
    effect: Active_Effect,
}

Halt_Action :: struct {}

Minion_Removal_Action :: struct {}
Minion_Spawn_Action :: struct {
    location, spawnpoint: Implicit_Target,
}

Choose_Card_Action :: struct {}

Retrieve_Card_Action :: struct {}

Jump_Action :: struct {
    jump_index: Action_Index
}

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Attack_Action,
    Clear_Action,
    Choose_Target_Action,
    Choice_Action,
    Add_Active_Effect_Action,
    Halt_Action,
    Choose_Card_Action,
    Retrieve_Card_Action,
    Jump_Action,

    Minion_Removal_Action,
    Minion_Spawn_Action,
}

Action :: struct {
    tooltip: Tooltip,
    optional: bool,
    condition: Implicit_Condition,
    skip_index: Action_Index,
    variant: Action_Variant,
    targets: Target_Set,
}

Action_Sequence_ID :: enum {
    PRIMARY,
    HALT,
    FIRST_CHOICE,
    BASIC_MOVEMENT,
    BASIC_FAST_TRAVEL,
    BASIC_CLEAR,

    MINION_REMOVAL,
    MINION_SPAWN,
}

Action_Index :: struct {
    sequence: Action_Sequence_ID,
    index: int,
}



player_movement_tooltip: cstring : "Choose a space to move to."

error_tooltip: cstring : "You should never see this. Tell Griffon if you do!"

first_choice_tooltip: cstring : "Choose an action to take with your played card."



first_choice_action := []Action {
    Action {
        tooltip = first_choice_tooltip,
        variant = Choice_Action {
            choices = []Choice {
                {name = "Primary",      jump_index = {sequence=.PRIMARY}},
                {name = "Movement",     jump_index = {sequence=.BASIC_MOVEMENT}},
                {name = "Fast Travel",  jump_index = {sequence=.BASIC_FAST_TRAVEL}},
                {name = "Clear",        jump_index = {sequence=.BASIC_CLEAR}},
                {name = "Hold",         jump_index = {sequence=.HALT}},
            }
        }
    }
}

basic_movement_action := []Action {
    {
        tooltip = player_movement_tooltip,
        condition = And{Primary_Is_Not{.MOVEMENT}, Greater_Than{Card_Value{kind=.MOVEMENT}, 0}},
        variant = Movement_Action {
            target   = Self{},
            distance = Card_Value{kind=.MOVEMENT},
        }
    }
}

basic_fast_travel_action := []Action {
    Action {
        tooltip = "Choose a space to fast travel to.",
        condition = Greater_Than{Card_Value{kind=.MOVEMENT}, 0},
        variant = Fast_Travel_Action{},
    }
}

basic_clear_action := []Action {
    Action {
        tooltip = "Choose any number of tokens adjacent to you to remove.",
        variant = Clear_Action{}
    }
}

basic_defense_action := []Action {
    
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
                }
            }
        },
        variant = Choose_Target_Action {
            num_targets = Minion_Difference{},
            criteria = {
                Contains_Any({.MELEE_MINION, .RANGED_MINION}),
                Is_Friendly_Unit{},
            }
        }
    },
    Action {
        variant = Minion_Removal_Action {}
    }
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
                    origin = Top_Blocked_Spawnpoint{}
                },
            }
        }
    },
    Action {
        variant = Minion_Spawn_Action {
            location = Previous_Choice{},
            spawnpoint = Top_Blocked_Spawnpoint{},
        }
    },
    Action {
        variant = Jump_Action {
            jump_index = {.MINION_SPAWN, 0}
        }
    }
}




get_current_action :: proc() -> ^Action {
    return get_action_at_index(get_my_player().hero.current_action_index)
}

get_action_at_index :: proc(index: Action_Index) -> ^Action {
    action_sequence: []Action

    switch index.sequence {
    case .PRIMARY:
        card, ok := find_played_card()
        log.assert(ok, "no played card!!?!?!?!?!")
        action_sequence = card.primary_effect
    case .HALT:              return nil
    case .FIRST_CHOICE:      action_sequence = first_choice_action
    case .BASIC_MOVEMENT:    action_sequence = basic_movement_action
    case .BASIC_FAST_TRAVEL: action_sequence = basic_fast_travel_action
    case .BASIC_CLEAR:       action_sequence = basic_clear_action
    case .MINION_REMOVAL:    action_sequence = minion_removal_action
    case .MINION_SPAWN:      action_sequence = minion_spawn_action
    }

    if index.index < len(action_sequence) {
        return &action_sequence[index.index]
    }

    return nil
}
