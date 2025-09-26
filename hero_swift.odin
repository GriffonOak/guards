package guards

/// SWIFT

// Ult: "After you resolve a basic card, you may\nperform the primary action on that card;\nyou cannot target the same enemy hero\ntwice in the same turn this way."

swift_cards := []Card_Data {
    Card_Data { name = "Reload!",
        color =         .GOLD,
        values =        #partial{.INITIATIVE = 6, .DEFENSE = 1, .MOVEMENT = 1},
        primary =       .SKILL,
        text =          "Choose one -\n* Perform the primary action of your rightmost resolved card.\n*Defeat a minion adjacent to you.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices =  {
                        {name = "Previous primary", jump_index = {index = 1}},
                        {name = "Defeat adjacent",  jump_index = {index = 2}},
                    },
                },
            },
            Action {  // 1
                variant = Jump_Action {
                    jump_index = Other_Card_Primary{Rightmost_Resolved_Card{}},
                },
            },
            Action {  // 2
                tooltip = "Defeat a minion adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = error_tooltip,
                variant = Minion_Defeat_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Bounce",
        color =         .SILVER,
        values =        #partial{.INITIATIVE = 12, .DEFENSE = 2},
        primary =       .SKILL,
        text =          "Move 2 spaces in a straight line, ignoring\nobstacles; if this card is already resolved as\nyou perform this action, may repeat once.",
        primary_effect = []Action {
            Action {
                tooltip = "Move 2 spaces in a straight line, ignoring obstacles.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 2,
                    flags = {.IGNORING_OBSTACLES, .STRAIGHT_LINE},
                },
            },
            Action {
                tooltip = "This card is already resolved, so you may repeat once.",
                condition = Card_State_Is{.RESOLVED},
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 2,
                    flags = {.IGNORING_OBSTACLES, .STRAIGHT_LINE},
                },
            },
        },
    },
    Card_Data { name = "Snipe",
        color =         .RED,
        tier =          1,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 4, .ATTACK = 5, .MOVEMENT = 4, .RANGE = 4},
        primary =       .ATTACK,
        text =          "Target a unit at maximum range,\nand in a straight line.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit at maximum range, and in a straight line.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {Card_Value{.RANGE}, Card_Value{.RANGE}}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Suppress",
        color =         .GREEN,
        tier =          1,
        values =        #partial{.INITIATIVE = 4, .DEFENSE = 2, .MOVEMENT = 2, .RADIUS = 3},
        primary =       .SKILL,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.TERRAIN}},
                            },
                        }},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Steam Jump",
        color =         .BLUE,
        tier =          1,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 3, .MOVEMENT = 2, .RADIUS = 3},
        primary =       .SKILL,
        text =          "Place yourself into a space in a straight line\nin radius. Push an enemy unit\nadjacent to you up to 1 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line in radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Empty,
                        Target_In_Straight_Line_With{Self{}},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Self{},
                    destination = Previously_Chosen_Target{},
                },
            },
            Action {
                tooltip = "Target an enemy unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Choose how many spaces to push the unit.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 1},
                },
            },
            Action {
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Prepared Shot",
        color =         .RED,
        tier =          2,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 5, .ATTACK = 5, .MOVEMENT = 4, .RANGE = 4},
        primary =       .ATTACK,
        item =          .DEFENSE,
        text =          "Target a unit in range, in a straight\nline, and not adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range, in a straight\nline, and not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.RANGE}}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Shotgun",
        color =         .RED,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 6, .ATTACK = 4, .MOVEMENT = 4, .RANGE = 2},
        primary =       .ATTACK,
        item =          .INITIATIVE,
        text =          "Target a unit in range. Before the attack:\nAn enemy hero adjacent to the target\ndiscards a card, if able.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RANGE}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target an enemy hero adjacent to the target.",
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                },
            },
            Action {  // 3
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{skips = 1},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Pin Down",
        color =         .GREEN,
        tier =          2,
        values =        #partial{.INITIATIVE = 4, .DEFENSE = 2, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.TERRAIN}},
                            },
                        }},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Mark for Death",  // @Unimplemented
        color =         .GREEN,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 4, .DEFENSE = 2, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .INITIATIVE,
        text =          "Move an enemy minion in radius up\nto 3 spaces to a space in radius.\nNext turn: The first time an enemy minion\nin radius is defeated, gain 1 coin.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Assault Jump",
        color =         .BLUE,
        tier =          2,
        values =        #partial{.INITIATIVE = 10, .DEFENSE = 4, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "Place yourself into a space in a straight line\nin radius. Push an enemy unit\nadjacent to you up to 2 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line\nin radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Empty,
                        Target_In_Straight_Line_With{Self{}},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Self{},
                    destination = Previously_Chosen_Target{},
                },
            },
            Action {
                tooltip = "Target an enemy unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Choose how many spaces to push the unit.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 2},
                },
            },
            Action {
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Delayed Jump",
        color =         .BLUE,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 10, .DEFENSE = 4, .MOVEMENT = 1, .RADIUS = 2},
        primary =       .SKILL,
        item =          .DEFENSE,
        text =          "End of turn: Place yourself into a space\nin radius not in a straight line from you.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .SWIFT_DELAYED_JUMP,
                        timing = End_Of_Turn {
                            extra_action_index = Action_Index {
                                sequence = .PRIMARY,
                                index = 2,
                            },
                        },
                    },
                },
            },
            Action {  // 1
                variant = Halt_Action{},
            },
            Action {  // 2
                tooltip = "Place yourself into a space in radius not in a straight line from you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Target_Empty,
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Self{},
                    destination = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Killshot",
        color =         .RED,
        tier =          3,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 5, .ATTACK = 6, .MOVEMENT = 4, .RANGE = 5},
        primary =       .ATTACK,
        item =          .DEFENSE,
        text =          "Target a unit in range, in a straight\nline, and not adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range, in a straight\nline, and not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.RANGE}}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Super-Shotgun",
        color =         .RED,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 6, .ATTACK = 5, .MOVEMENT = 4, .RANGE = 2},
        primary =       .ATTACK,
        item =          .RADIUS,
        text =          "Target a unit in range. Before the attack:\nAn enemy hero adjacent to the target\ndiscards a card, or is defeated.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RANGE}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target an enemy hero adjacent to the target.",
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                    or_is_defeated = true,
                },
            },
            Action {  // 3
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{skips = 1},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Killing Ground",
        color =         .GREEN,
        tier =          3,
        values =        #partial{.INITIATIVE = 3, .DEFENSE = 3, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .RANGE,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, or is defeated.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.TERRAIN}},
                            },
                        }},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                    or_is_defeated = true,
                },
            },
        },
    },
    Card_Data { name = "Hunting Season",  // @Unimplemented
        color =         .GREEN,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 3, .DEFENSE = 3, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .INITIATIVE,
        text =          "Move up to two enemy minions in radius,\nupto 3 spaces each, to a space in radius.\nNext turn: The first two times an enemy\nminion in radius is defeated, gain 1 coin.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Drop Trooper",
        color =         .BLUE,
        tier =          3,
        values =        #partial{.INITIATIVE = 10, .DEFENSE = 4, .MOVEMENT = 2, .RADIUS = 4},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "Place yourself into a space in a straight line\nin radius. Push up to two enemy units\nadjacent to you up to 2 spaces.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line\nin radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Target_Empty,
                        Target_In_Straight_Line_With{Self{}},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Self{},
                    destination = Previously_Chosen_Target{},
                },
            },
            Action {
                tooltip = "Target up to two enemy units adjacent to you.",
                variant = Choose_Target_Action {
                    up_to = true,
                    num_targets = 2,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Choose how many spaces to push the units.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 2},
                },
            },
            Action {
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Mobile Scout",
        color =         .BLUE,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 10, .DEFENSE = 4, .MOVEMENT = 1, .RADIUS = 2},
        primary =       .SKILL,
        item =          .MOVEMENT,
        text =          "End of turn: Place yourself into a space in\nradius not in a straight line from you.\nYou may then fast travel, if able.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .SWIFT_DELAYED_JUMP,
                        timing = End_Of_Turn {
                            extra_action_index = Action_Index {
                                sequence = .PRIMARY,
                                index = 2,
                            },
                        },
                    },
                },
            },
            Action {  // 1
                variant = Halt_Action{},
            },
            Action {  // 2
                tooltip = "Place yourself into a space in radius not in a straight line from you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RADIUS}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Target_Empty,
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Self{},
                    destination = Previously_Chosen_Target{},
                },
            },
            Action {
                tooltip = "You may fast travel.",
                optional = true,
                variant = Fast_Travel_Action{},
            },
        },
    },
}
