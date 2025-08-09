package guards


Card_Creating_Effect :: struct {
    effect: Active_Effect_ID
}

Implicit_Card :: union {
    ^Card,
    Card_Creating_Effect,
}

Card_Reach :: struct {
    card: Implicit_Card,
}

Card_Value :: struct {
    card: Implicit_Card,
    kind: Ability_Kind,
}

Sum :: []Implicit_Quantity

Count_Targets :: []Selection_Criterion

// Current_Turn :: struct {}

Turn_Played :: struct {
    card: Implicit_Card
}

Implicit_Quantity :: union {
    int,
    Card_Reach,
    Card_Value,
    Sum,
    Count_Targets,
    // Current_Turn,
    Turn_Played,
}

Within_Distance :: struct {
    origin: Implicit_Target,
    min: Implicit_Quantity,
    max: Implicit_Quantity,
}

Contains_Any :: Space_Flags
Contains_All :: Space_Flags

Is_Enemy_Unit :: struct {}
Not_Previously_Targeted :: struct {}

Selection_Criterion :: union {
    Within_Distance,
    Contains_Any,
    // Contains_All,
    Is_Enemy_Unit,
    Not_Previously_Targeted,
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
    result: Target,
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

Action_Variant :: union {
    Movement_Action,
    Fast_Travel_Action,
    Attack_Action,
    Clear_Action,
    Choose_Target_Action,
    Choice_Action,
    Add_Active_Effect_Action,
    Halt_Action,
}

Greater_Than :: struct {
    term_1, term_2: Implicit_Quantity
}

And :: []Implicit_Condition

Primary_Is_Not :: struct {
    kind: Ability_Kind
}

Implicit_Condition :: union {
    bool,
    Greater_Than,
    Primary_Is_Not,
    And,
}

Action :: struct {
    tooltip: cstring,
    optional: bool,
    condition: Implicit_Condition,
    skip_index: int,
    variant: Action_Variant,
    targets: Target_Set,
}

player_movement_tooltip: cstring = "Choose a space to move to."

HALT_INDEX :: -999
FIRST_PRIMARY_INDEX :: 0
BASIC_MOVEMENT_INDEX :: -2
BASIC_FAST_TRAVEL_INDEX :: -3
BASIC_CLEAR_INDEX :: -4
BASIC_HOLD_INDEX :: -5

first_choice_action := Action {
    tooltip = "Choose an action to take with your played card.",
    variant = Choice_Action {
        choices = {
            {"Primary", FIRST_PRIMARY_INDEX},
            {"Movement", BASIC_MOVEMENT_INDEX},
            {"Fast Travel", BASIC_FAST_TRAVEL_INDEX},
            {"Clear", BASIC_CLEAR_INDEX},
            {"Hold", HALT_INDEX}
        }
    }
}

first_choice_action2 := Action {
    tooltip = "Choose an action to take sdugh card.",
    variant = Choice_Action {
        choices = {
            {"Primary", FIRST_PRIMARY_INDEX},
            {"Movement", BASIC_MOVEMENT_INDEX},
            {"Fast Travel", BASIC_FAST_TRAVEL_INDEX},
            {"Clear", BASIC_CLEAR_INDEX},
            {"Hold", HALT_INDEX}
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
    variant = Fast_Travel_Action{},
    condition = Greater_Than{Card_Value{kind=.MOVEMENT}, 0}
}

basic_clear_action := Action {
    tooltip = "Choose any number of tokens adjacent to you to remove.",
    variant = Clear_Action{}
}

basic_actions: [5]Action
    // {},
    // first_choice_action,
    // basic_movement_action,
    // basic_fast_travel_action,
    // basic_clear_action,

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
    return nil
}
