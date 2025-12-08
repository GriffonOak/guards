package guards

/// Garrus

//  Ult: Each time after one of your resolved cards is discarded, you may perform its primary action.

garrus_cards := []Card_Data {
    Card_Data { name = "Angry Strike",
        color           = .Gold,
        values          = #partial{.Initiative = 11, .Defense = 3, .Attack = 4, .Movement = 1},
        primary         = .Attack,
        primary_sign    = .Plus,
        text            = "Target a unit adjacent to you;\n+1 Attack for every card in your discard.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
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
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack},
                        Count_Card_Targets {
                            Card_Owner_Is{Self{}},
                            Card_State_Is{.Discarded},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Chilling Howl",
        color           = .Silver,
        values          = #partial{.Initiative = 13, .Defense = 3, .Radius = 3},
        primary         = .Skill,
        text            = "You may discard one of your resolved cards.\nThis round: Enemy heroes in radius\ncannot fast travel, or move more than\n2 spaces with a movement action.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "You may choose a resolved card to discard.",
                optional = true,
                skip_index = {index = 2},
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Resolved},
                    },
                },
            },
            Action {  // 1
                variant = Discard_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
            Action {  // 2
                variant = Add_Active_Effect_Action {
                    effect = {
                        kind = .Garrus_Howl,
                        timing = Round{},
                        affected_targets = {
                            Target_Within_Distance {
                                origin = Card_Owner{},
                                bounds = {1, Card_Value{.Radius}},
                            },
                            Target_Contains_Any{{.Hero}},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Disallow_Action {
                                Action_Variant_At_Index_Is{Fast_Travel_Action},
                            },
                            Limit_Movement {
                                limit = 2,
                                conditions = {
                                    Or {
                                        Action_Index_Sequence_Is{.Basic_Movement},
                                        And {
                                            Action_Index_Sequence_Is{.Primary},
                                            Action_Index_Card_Primary_Is{.Movement},
                                        },
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Trace",
        color           = .Red,
        tier            = 1,
        values          = #partial{.Initiative = 7, .Defense = 5, .Attack = 3, .Movement = 4},
        primary         = .Attack,
        text            = "Choose one -\n* Before the attack: if you have one or more\ncards in the discard, you may move 1 space.\nTarget a hero adjacent to you.\n* Target a unit adjacent to you.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        Choice {
                            name = "Move to hero",
                            jump_index = {index = 1},
                        },
                        Choice {
                            name = "Target adjacent",
                            jump_index = {index = 5},
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "You may move 1 space to a space adjacent to an enemy hero.",
                condition = Greater_Than {
                    Count_Card_Targets {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{{.Hero}},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_To_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Target a hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Hold Ground",
        color           = .Green,
        tier            = 1,
        values          = #partial{.Initiative = 5, .Defense = 3, .Movement = 2, .Radius = 3},
        primary         = .Skill,
        text            = "If there are at least two enemy heroes in\nradius, you may retrieve a discarded card.",
        primary_effect  = []Action {
            Action {
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
        },
    },
    Card_Data { name = "Menace",
        color           = .Blue,
        tier            = 1,
        values          = #partial{.Initiative = 9, .Defense = 6, .Movement = 3, .Range = 2},
        primary         = .Skill,
        text            = "Move an enemy unit in range 1 space\nto a space farther away from you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target an enemy unit in range.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space to a space farther away from you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Target_Distance_To{Self{}},
                                Distance_Between{Self{}, Previously_Chosen_Target{}},
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Chase",
        color           = .Red,
        tier            = 2,
        values          = #partial{.Initiative = 8, .Defense = 5, .Attack = 4, .Movement = 4},
        primary         = .Attack,
        item            = .Defense,
        text            = "Choose one -\n* Before the attack: if you have one or more\ncards in the discard, move up to 2 spaces.\nTarget a hero adjacent to you.\n* Target a unit adjacent to you.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        Choice {
                            name = "Move to hero",
                            jump_index = {index = 1},
                        },
                        Choice {
                            name = "Target adjacent",
                            jump_index = {index = 5},
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "You may move 1 space to a space adjacent to an enemy hero.",
                condition = Greater_Than {
                    Count_Card_Targets {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                    destination_criteria = {
                        conditions = {
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{{.Hero}},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_To_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Target a hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Blunt Force",
        color           = .Red,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 8, .Defense = 7, .Attack = 7, .Movement = 4},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Target a unit adjacent to you.\nAfter the attack: You may move 1 space to a space adjacent to an enemy hero; if you do,\npush that hero 3 spaces, ignoring obstacles",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
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
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may move 1 space to a space adjacent to an enemy hero.",
                condition = Greater_Than {
                    Count_Card_Targets {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{{.Hero}},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_To_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {
                tooltip = "Target a hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = 3,
                    ignoring_obstacles = true,
                },
            },
        },
    },
    Card_Data { name = "Make a Stand",
        color           = .Green,
        tier            = 2,
        values          = #partial{.Initiative = 4, .Defense = 4, .Movement = 2, .Radius = 4},
        primary         = .Skill,
        item            = .Initiative,
        text            = "If there are at least two enemy heroes in\nradius, you may retrieve a discarded card.",
        primary_effect  = []Action {
            Action {
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
        },
    },
    Card_Data { name = "Light Pilum",
        color           = .Green,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 4, .Defense = 4, .Movement = 2, .Range = 2},
        primary         = .Skill,
        item            = .Attack,
        text            = "An enemy hero in range discards a card,\nif able. You may move 1 space.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target an enemy hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                },
            },
            Action {
                tooltip = "You may move one space.",
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
        },
    },
    Card_Data { name = "Threaten",
        color           = .Blue,
        tier            = 2,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3, .Range = 2},
        primary         = .Skill,
        item            = .Defense,
        text            = "Move an enemy unit in range 1 space\nto a space farther away from you.\nMay repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target an enemy unit in range.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space to a space farther away from you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Target_Distance_To{Self{}},
                                Distance_Between{Self{}, Previously_Chosen_Target{}},
                            },
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
    Card_Data { name = "Form Up!",
        color           = .Blue,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3, .Range = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Move a friendly unit in range 1 space\nto a space closer to you.\nMay repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a friendly unit in range.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space to a space closer to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Distance_Between{Self{}, Previously_Chosen_Target{}},
                                Target_Distance_To{Self{}},
                            },
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
    Card_Data { name = "Hunt Down",
        color           = .Red,
        tier            = 3,
        values          = #partial{.Initiative = 8, .Defense = 6, .Attack = 4, .Movement = 4},
        primary         = .Attack,
        item            = .Range,
        text            = "Choose one -\n* Before the attack: if you have one or more\ncards in the discard, move up to 3 spaces.\nTarget a hero adjacent to you.\n* Target a unit adjacent to you.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        Choice {
                            name = "Move to hero",
                            jump_index = {index = 1},
                        },
                        Choice {
                            name = "Target adjacent",
                            jump_index = {index = 5},
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "You may move 1 space to a space adjacent to an enemy hero.",
                condition = Greater_Than {
                    Count_Card_Targets {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 3,
                    destination_criteria = {
                        conditions = {
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{{.Hero}},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_To_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Target a hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Send Flying",
        color           = .Red,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 8, .Defense = 8, .Attack = 7, .Movement = 4},
        primary         = .Attack,
        item            = .Radius,
        text            = "Target a unit adjacent to you.\nAfter the attack: You may move up to 2 spaces to a space\nadjacent to an enemy hero; if you do, push\nthat hero 3 spaces, ignoring obstacles",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
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
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may move up to 2 spaces to a space adjacent to an enemy hero.",
                condition = Greater_Than {
                    Count_Card_Targets {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                    destination_criteria = {
                        conditions = {
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{{.Hero}},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_To_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {
                tooltip = "Target a hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = 3,
                    ignoring_obstacles = true,
                },
            },
        },
    },
    Card_Data { name = "Battle Ready",
        color           = .Green,
        tier            = 3,
        values          = #partial{.Initiative = 4, .Defense = 4, .Movement = 2, .Radius = 4},
        primary         = .Skill,
        item            = .Initiative,
        text            = "If there are at least two enemy heroes\nin radius, you may retrieve up to\ntwo discarded cards.",
        primary_effect  = []Action {
            Action {
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
                tooltip = "You may retrieve another discarded card.",
                optional = true,
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
        },
    },
    Card_Data { name = "Heavy Pilum",
        color           = .Green,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 4, .Defense = 4, .Movement = 2, .Range = 2},
        primary         = .Skill,
        item            = .Movement,
        text            = "An enemy hero in range discards a card,\nor is defeated. You may move up to 2 spaces.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target an enemy hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                    or_is_defeated = true,
                },
            },
            Action {
                tooltip = "You may move up to 2 spaces.",
                optional = true,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                },
            },
        },
    },
    Card_Data { name = "Terrify",
        color           = .Blue,
        tier            = 3,
        values          = #partial{.Initiative = 10, .Defense = 7, .Movement = 3, .Range = 2},
        primary         = .Skill,
        item            = .Defense,
        text            = "Move an enemy unit in range 1 space\nto a space farther away from you.\nMay repeat up to two times.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target an enemy unit in range.",
                            arg2 = "May repeat again.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space to a space farther away from you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Target_Distance_To{Self{}},
                                Distance_Between{Self{}, Previously_Chosen_Target{}},
                            },
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
    Card_Data { name = "Testudo!",
        color           = .Blue,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 7, .Movement = 3, .Range = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Move a friendly unit in range 1 space\nto a space closer to you.\nMay repeat up to two times.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a friendly unit in range.",
                            arg2 = "May repeat again.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Friendly_Unit{},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space to a space closer to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Distance_Between{Self{}, Previously_Chosen_Target{}},
                                Target_Distance_To{Self{}},
                            },
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
}
