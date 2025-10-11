package guards

/// Sabina

//  Ult: Your basic attack has +2 Range and\n+2 Attack. If you push an enemy hero,\nthat hero discards a card, or is defeated.

sabina_cards := []Card_Data {
    Card_Data { name = "Point Blank Shot",
        color           = .Gold,
        values          = #partial{.Initiative = 12, .Defense = 2, .Attack = 2, .Movement = 1, .Range = 1},
        primary         = .Attack,
        text            = "Target a unit in range. After the attack:\nIf the target is adjacent to you, push it 1 space.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                condition = And{
                    Equal{Distance_Between{Self{}, Previously_Chosen_Target{}}, 1},
                    Not{Contains_Any{Previously_Chosen_Target{}, {.Cannot_Push}}},
                },
                variant = Push_Action{
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = 1,
                },
            },
        },
    },
    Card_Data { name = "Back to Back",
        color           = .Silver,
        values          = #partial{.Initiative = 8, .Defense = 2, .Radius = 2},
        primary         = .Skill,
        text            = "Swap with a friendly minion in radius.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a friendly minion in radius.",
                condition = Not{Contains_Any{Self{}, {.Cannot_Swap}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                    },
                },
            },
            Action {
                variant = Swap_Action {
                    targets = []Implicit_Target{
                        Self{},
                        Previously_Chosen_Target{},
                    },
                },
            },
        },
    },
    Card_Data { name = "Quickdraw",
        color           = .Red,
        tier            = 1,
        values          = #partial{.Initiative = 8, .Defense = 6, .Attack = 2, .Movement = 4, .Range = 2},
        primary         = .Attack,
        primary_sign    = .Plus,
        text            = "Target a unit in range. +3 Attack if the\ntarget played an attack card this turn.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Sum {
                        Card_Value{.Attack},
                        Ternary {
                            {3, 0},
                            Greater_Than {
                                Count_Card_Targets {
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_Primary_Is{.Attack},
                                    Equal{Card_Turn_Played{}, Current_Turn{}},
                                }, 0,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Troop Movement",
        color           = .Green,
        tier            = 1,
        values          = #partial{.Initiative = 4, .Defense = 2, .Movement = 2, .Radius = 2},
        primary         = .Skill,
        text            = "Move a friendly minion in radius 1 space,\nto a space in radius. May repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a friendly minion in radius.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space, to a space in radius",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        },
                    },
                },
            },
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Listen Up",
        color           = .Blue,
        tier            = 1,
        values          = #partial{.Initiative = 9, .Defense = 3, .Movement = 3, .Radius = 1},
        primary         = .Skill,
        text            = "Swap two minions in radius.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target two minions in radius.",
                variant = Choose_Target_Action {
                    num_targets = 2,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                    },
                },
            },
            Action {
                variant = Swap_Action {
                    targets = Previous_Choices{},
                },
            },
        },
    },
    Card_Data { name = "Gunslinger",
        color           = .Red,
        tier            = 2,
        values          = #partial{.Initiative = 9, .Defense = 6, .Attack = 3, .Movement = 4, .Range = 2},
        primary         = .Attack,
        primary_sign    = .Plus,
        item            = .Initiative,
        text            = "Target a unit in range. +3 Attack if the\ntarget played an attack card this turn.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Sum {
                        Card_Value{.Attack},
                        Ternary {
                            {3, 0},
                            Greater_Than {
                                Count_Card_Targets {
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_Primary_Is{.Attack},
                                    Equal{Card_Turn_Played{}, Current_Turn{}},
                                }, 0,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Shootout",
        color           = .Red,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 6, .Attack = 3, .Movement = 4, .Range = 2},
        primary         = .Attack,
        item            = .Defense,
        text            = "Target a unit in range. After the attack:\nIf the target was adjacent to you, remove\nup to one enemy minion adjacent to you.\n(You gain no coins for removing a minion, only for defeating.)",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Save_Variable_Action {
                    variable = Implicit_Condition(Equal{Distance_Between{Self{}, Previously_Chosen_Target{}}, 1}),
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may remove up to one enemy minion adjacent to you",
                condition = Previously_Saved_Boolean{},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Up_To},
                },
            },
            Action {
                variant = Minion_Removal_Action {
                    targets = Previous_Choices{},
                },
            },
        },
    },
    Card_Data { name = "Marching Orders",
        color           = .Green,
        tier            = 2,
        values          = #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Move a friendly minion in radius 1 space,\nto a space in radius. May repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a friendly minion in radius.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space, to a space in radius",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        },
                    },
                },
            },
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Close Support",
        color           = .Green,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 3},
        primary         = .Skill,
        item            = .Initiative,
        text            = "An enemy hero in radius adjacent to your\nfriendly minion discards a card, if able.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Targets {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{MINION_FLAGS},
                                Target_Is_Friendly_Unit{},
                            },
                        },
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
    Card_Data { name = "Roger Roger",
        color           = .Blue,
        tier            = 2,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        item            = .Attack,
        text            = "Swap two minions in radius.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target two minions in radius.",
                variant = Choose_Target_Action {
                    num_targets = 2,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                    },
                },
            },
            Action {
                variant = Swap_Action {
                    targets = Previous_Choices{},
                },
            },
        },
    },
    Card_Data { name = "Steady Advance",
        color           = .Blue,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        item            = .Defense,
        text            = "If there are two or more friendly minions in\nradius, you may retrieve a discarded card;\nif you do, you may move 1 space.",
        primary_effect  = []Action {
            Action {
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                    }, 1,
                },
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
            Action {
                tooltip = "You may move 1 space.",
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
        },
    },
    Card_Data { name = "Dead Shot",
        color           = .Red,
        tier            = 3,
        values          = #partial{.Initiative = 9, .Defense = 7, .Attack = 3, .Movement = 4, .Range = 2},
        primary         = .Attack,
        primary_sign    = .Plus,
        item            = .Movement,
        text            = "Target a unit in range. +4 Attack if the\ntarget played an attack card this turn.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Sum {
                        Card_Value{.Attack},
                        Ternary {
                            {4, 0},
                            Greater_Than {
                                Count_Card_Targets {
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_Primary_Is{.Attack},
                                    Equal{Card_Turn_Played{}, Current_Turn{}},
                                }, 0,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Bullet Hell",
        color           = .Red,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 7, .Attack = 3, .Movement = 4, .Range = 2},
        primary         = .Attack,
        item            = .Radius,
        text            = "Target a unit in range. After the attack:\nIf the target was adjacent to you, remove\nup to two enemy minions adjacent to you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Save_Variable_Action {
                    variable = Implicit_Condition(Equal{Distance_Between{Self{}, Previously_Chosen_Target{}}, 1}),
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may remove up to two enemy minions adjacent to you",
                condition = Previously_Saved_Boolean{},
                variant = Choose_Target_Action {
                    num_targets = 2,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Up_To},
                },
            },
            Action {
                variant = Minion_Removal_Action {
                    targets = Previous_Choices{},
                },
            },
        },
    },
    Card_Data { name = "Path to Victory",
        color           = .Green,
        tier            = 3,
        values          = #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 3},
        primary         = .Skill,
        item            = .Range,
        text            = "Move a friendly minion in radius 1 space, to a\nspace in radius. May repeat up to two times.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a friendly minion in radius.",
                            arg2 = "May repeat again.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space, to a space in radius",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        },
                    },
                },
            },
            Action {
                variant = Repeat_Action {
                    max_repeats = 2,
                },
            },
        },
    },
    Card_Data { name = "Covering Fire",
        color           = .Green,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Radius = 3},
        primary         = .Skill,
        item            = .Initiative,
        text            = "An enemy hero in radius adjacent to your\nfriendly minion discards a card, or is defeated.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Targets {
                                Target_Within_Distance{Previous_Target{}, {1, 1}},
                                Target_Contains_Any{MINION_FLAGS},
                                Target_Is_Friendly_Unit{},
                            },
                        },
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
    Card_Data { name = "Ready and Waiting",
        color           = .Blue,
        tier            = 3,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        item            = .Attack,
        text            = "Swap two minions in radius,\nignoring heavy minion immunity.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target two minions in radius, ignoring heavy minion immunity.",
                variant = Choose_Target_Action {
                    num_targets = 2,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                    },
                    flags = {.Ignoring_Immunity},
                },
            },
            Action {
                variant = Swap_Action {
                    targets = Previous_Choices{},
                },
            },
        },
    },
    Card_Data { name = "Unwavering Resolve",
        color           = .Blue,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        item            = .Defense,
        text            = "If there are two or more friendly minions in\nradius, you may retrieve a discarded card;\nif you do, you may move up to 2 spaces.",
        primary_effect  = []Action {
            Action {
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Friendly_Unit{},
                    }, 1,
                },
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
            Action {
                tooltip = "You may move up to 2 spaces.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                },
            },
        },
    },
}
