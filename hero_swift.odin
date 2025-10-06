package guards

/// Swift

// Ult: "After you resolve a basic card, you may\nperform the primary action on that card;\nyou cannot target the same enemy hero\ntwice in the same turn this way."

swift_cards := []Card_Data {
    Card_Data { name = "Reload!",
        color =         .Gold,
        values =        #partial{.Initiative = 6, .Defense = 1, .Movement = 1},
        primary =       .Skill,
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
        color =         .Silver,
        values =        #partial{.Initiative = 12, .Defense = 2},
        primary =       .Skill,
        text =          "Move 2 spaces in a straight line, ignoring\nobstacles; if this card is already resolved as\nyou perform this action, may repeat once.",
        primary_effect = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Move 2 spaces in a straight line, ignoring obstacles.",
                            arg2 = "This card is already resolved, so you may repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 2,
                    flags = {.Ignoring_Obstacles, .Straight_Line},
                },
            },
            Action {
                condition = Card_State_Is{.Resolved},
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Snipe",
        color =         .Red,
        tier =          1,
        values =        #partial{.Initiative = 8, .Defense = 4, .Attack = 5, .Movement = 4, .Range = 4},
        primary =       .Attack,
        text =          "Target a unit at maximum range,\nand in a straight line.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit at maximum range, and in a straight line.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {Card_Value{.Range}, Card_Value{.Range}}},
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Suppress",
        color =         .Green,
        tier =          1,
        values =        #partial{.Initiative = 4, .Defense = 2, .Movement = 2, .Radius = 3},
        primary =       .Skill,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.Terrain}},
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
        color =         .Blue,
        tier =          1,
        values =        #partial{.Initiative = 9, .Defense = 3, .Movement = 2, .Radius = 3},
        primary =       .Skill,
        text =          "Place yourself into a space in a straight line\nin radius. Push an enemy unit\nadjacent to you up to 1 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line in radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
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
        color =         .Red,
        tier =          2,
        values =        #partial{.Initiative = 8, .Defense = 5, .Attack = 5, .Movement = 4, .Range = 4},
        primary =       .Attack,
        item =          .Defense,
        text =          "Target a unit in range, in a straight\nline, and not adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range, in a straight\nline, and not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Range}}},
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Shotgun",
        color =         .Red,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 8, .Defense = 6, .Attack = 4, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Initiative,
        text =          "Target a unit in range. Before the attack:\nAn enemy hero adjacent to the target\ndiscards a card, if able.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
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
                        Target_Contains_Any{{.Hero}},
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
                    target = Labelled_Target{.Attack_Target},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Pin Down",
        color =         .Green,
        tier =          2,
        values =        #partial{.Initiative = 4, .Defense = 2, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Attack,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.Terrain}},
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
        color =         .Green,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 4, .Defense = 2, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Initiative,
        text =          "Move an enemy minion in radius up\nto 3 spaces to a space in radius.\nNext turn: The first time an enemy minion\nin radius is defeated, gain 1 coin.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Assault Jump",
        color =         .Blue,
        tier =          2,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Attack,
        text =          "Place yourself into a space in a straight line\nin radius. Push an enemy unit\nadjacent to you up to 2 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line\nin radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
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
        color =         .Blue,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 1, .Radius = 2},
        primary =       .Skill,
        item =          .Defense,
        text =          "End of turn: Place yourself into a space\nin radius not in a straight line from you.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Swift_Delayed_Jump,
                        timing = End_Of_Turn {
                            extra_action_index = Action_Index {
                                sequence = .Primary,
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
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Target_Empty{},
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
        color =         .Red,
        tier =          3,
        values =        #partial{.Initiative = 9, .Defense = 5, .Attack = 6, .Movement = 4, .Range = 5},
        primary =       .Attack,
        item =          .Defense,
        text =          "Target a unit in range, in a straight\nline, and not adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range, in a straight\nline, and not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Range}}},
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Super-Shotgun",
        color =         .Red,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 9, .Defense = 6, .Attack = 5, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Radius,
        text =          "Target a unit in range. Before the attack:\nAn enemy hero adjacent to the target\ndiscards a card, or is defeated.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
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
                        Target_Contains_Any{{.Hero}},
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
                    target = Labelled_Target{.Attack_Target},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Killing Ground",
        color =         .Green,
        tier =          3,
        values =        #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Range,
        text =          "An enemy hero in radius who is not\nadjacent to terrain discards a card, or is defeated.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius not adjacent to terrain.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{1, Count_Targets{
                            conditions = {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{{.Terrain}},
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
        color =         .Green,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Initiative,
        text =          "Move up to two enemy minions in radius,\nupto 3 spaces each, to a space in radius.\nNext turn: The first two times an enemy\nminion in radius is defeated, gain 1 coin.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Drop Trooper",
        color =         .Blue,
        tier =          3,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 2, .Radius = 4},
        primary =       .Skill,
        item =          .Attack,
        text =          "Place yourself into a space in a straight line\nin radius. Push up to two enemy units\nadjacent to you up to 2 spaces.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in a straight line\nin radius.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
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
                    num_targets = 2,
                    flags = {.Up_To},
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
        color =         .Blue,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 1, .Radius = 2},
        primary =       .Skill,
        item =          .Movement,
        text =          "End of turn: Place yourself into a space in\nradius not in a straight line from you.\nYou may then fast travel, if able.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Swift_Delayed_Jump,
                        timing = End_Of_Turn {
                            extra_action_index = Action_Index {
                                sequence = .Primary,
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
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Target_Empty{},
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
