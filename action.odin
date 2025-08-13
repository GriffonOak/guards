package guards



Within_Distance :: struct {
    origin: Implicit_Target,
    min: Implicit_Quantity,
    max: Implicit_Quantity,
}

Contains_Any :: Space_Flags
Contains_All :: Space_Flags

Is_Enemy_Unit :: struct {}
Is_Friendly_Unit :: struct {}
Not_Previously_Targeted :: struct {}

Ignoring_Immunity :: struct {}

Selection_Criterion :: union {
    Within_Distance,
    Contains_Any,
    // Contains_All,
    Is_Enemy_Unit,
    Is_Friendly_Unit,
    Not_Previously_Targeted,
    Ignoring_Immunity,
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
    jump_index: int,
}

Attack_Action :: struct {
    target: Implicit_Target,
    strength: Implicit_Quantity,
}

Choice_Action :: struct {
    choices: []Choice,
    result: int,
}

Add_Active_Effect_Action :: struct {
    effect: Active_Effect,
}

Halt_Action :: struct {}

Minion_Removal_Action :: struct {}

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Attack_Action,
    Clear_Action,
    Choose_Target_Action,
    Choice_Action,
    Add_Active_Effect_Action,
    Halt_Action,
    Minion_Removal_Action,
}

Action :: struct {
    tooltip: cstring,
    optional: bool,
    condition: Implicit_Condition,
    skip_index: int,
    variant: Action_Variant,
    targets: Target_Set,
}

player_movement_tooltip: cstring : "Choose a space to move to."

first_choice_tooltip: cstring : "Choose an action to take with your played card."

HALT_INDEX :: -999
FIRST_PRIMARY_INDEX :: 0
BASIC_MOVEMENT_INDEX :: -2
BASIC_FAST_TRAVEL_INDEX :: -3
BASIC_CLEAR_INDEX :: -4
BASIC_HOLD_INDEX :: -5

first_choice_action := Action {
    tooltip = first_choice_tooltip,
    variant = Choice_Action {
        choices = []Choice {
            {"Primary", FIRST_PRIMARY_INDEX},
            {"Movement", BASIC_MOVEMENT_INDEX},
            {"Fast Travel", BASIC_FAST_TRAVEL_INDEX},
            {"Clear", BASIC_CLEAR_INDEX},
            {"Hold", HALT_INDEX},
        }
    }
}

basic_movement_action := Action {
    tooltip = player_movement_tooltip,
    condition = And{Primary_Is_Not{.MOVEMENT}, Greater_Than{Card_Value{kind=.MOVEMENT}, 0}},
    variant = Movement_Action {
        target   = Self{},
        distance = Card_Value{kind=.MOVEMENT},
    }
}

basic_fast_travel_action := Action {
    tooltip = "Choose a space to fast travel to.",
    condition = Greater_Than{Card_Value{kind=.MOVEMENT}, 0},
    variant = Fast_Travel_Action{},
}

basic_clear_action := Action {
    tooltip = "Choose any number of tokens adjacent to you to remove.",
    variant = Clear_Action{}
}

// basic_actions := []Action {
//     blank_action,
//     first_choice_action,
//     basic_movement_action,
//     basic_fast_travel_action,
//     basic_clear_action,
// }

minion_removal_action := []Action {
    {
        tooltip = "Choose minions to remove.",
        variant = Choose_Target_Action {
            num_targets = Minion_Difference{},
            criteria = {
                Contains_Any({.MELEE_MINION, .RANGED_MINION}),
                Is_Friendly_Unit{},
            }
        }
    },
    {
        variant = Minion_Removal_Action {}
    }
}

basic_actions: [5]Action

get_current_action :: proc() -> ^Action {
    return get_action_at_index(player.hero.current_action_index)
}

get_action_at_index :: proc(index: int) -> ^Action {
    if index == HALT_INDEX {
        return nil
    }
    if index < 0 {
        return &basic_actions[-index]
    }
    if index < len(player.hero.action_list) {
        return &player.hero.action_list[index]
    }
    if index >= 100 {
        return &minion_removal_action[index - 100]
    }
    return nil
}
