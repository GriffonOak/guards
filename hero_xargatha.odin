package guards

/// Xargatha

// Ult: +1 ini & movement for each enemy unit you are adjacent to. You may move through obstacles.

xargatha_cards := []Card_Data {
    Card_Data { name = "Cleave",
        color       = .Gold,
        values      = #partial{.Initiative = 11, .Attack = 4, .Defense = 2, .Movement = 1},
        primary     = .Attack,
        text        = "Target a unit adjacent to you.\nAfter the attack: May repeat once\non a different enemy hero.",
        primary_effect = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit adjacent to you.",
                            arg2 = "May repeat once on a different enemy hero.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Or {
                            And {
                                Equal{Repeat_Count{}, 0},
                                Target_Contains_Any{MINION_FLAGS},
                            },
                            Target_Contains_Any{{.Hero}},
                        },
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
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Siren's Call",
        color       = .Silver,
        values      = #partial{.Initiative = 3, .Defense = 3, .Range = 3},
        primary     = .Skill,
        text        = "Target an enemy unit not adjacent to you\nand in range; if able, move the target\nup to 3 spaces to a space adjacent to you.",
        primary_effect = []Action {
            Action { 
                tooltip = "Target an enemy unit not adjacent to you and in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            Self{}, 
                            {2, Card_Value{.Range}},
                        },
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Move the target up to 3 spaces to a space adjacent to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 3,
                    destination_criteria = {
                        conditions = {Target_Within_Distance{Self{}, {1, 1}}},
                    },
                },
            },
        },
    },
    Card_Data { name = "Threatening Slash",
        color       = .Red,
        tier        = 1,
        values      = #partial{.Initiative = 7, .Attack = 5, .Defense = 6, .Movement = 5},
        primary     = .Attack,
        primary_sign = .Plus,
        text        = "Target a unit adjacent to you. +1 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack}, 
                        Count_Targets {
                            conditions = {
                                Target_Within_Distance{Self{}, {1, 1}},
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            flags = {.Ignoring_Immunity},
                        },
                        -1,
                    },
                },
            },
        },
    },
    Card_Data { name = "Charm",
        color       = .Green,
        tier        = 1,
        values      = #partial{.Initiative = 5, .Movement = 2, .Defense = 3, .Radius = 2},
        primary     = .Movement,
        text        = "Before or after movement, you may\nmove an enemy ranged minion\nin radius up to 2 spaces.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may either move yourself or a ranged minion.",
                variant = Choice_Action {
                    choices = {
                        {name = "Move self",    jump_index = {index=1}},
                        {name = "Move minion",  jump_index = {index=5}},
                    },
                },
            },
            Action {  // 1
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
            Action {  // 2
                optional = true,
                tooltip = "You may choose a ranged minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{{.Ranged_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a ranged minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{{.Ranged_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
        },
    },
    Card_Data { name = "Stone Gaze",  // @Incomplete: "count as terrain"
        color       = .Blue,
        tier        = 1,
        values      = #partial{.Initiative = 9, .Defense = 5, .Movement = 3, .Radius = 2},
        primary     = .Skill,
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Xargatha_Freeze,
                        timing = Single_Turn(Sum{Card_Turn_Played{}, 1}),
                        target_set = {
                            conditions = {
                                Target_Within_Distance {
                                    origin = Card_Owner{},
                                    bounds = {1, Card_Value{.Radius}},
                                },
                                Target_Contains_Any{{.Hero}},
                                Target_Is_Enemy_Of{Card_Owner{}},
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Deadly Swipe",
        color       = .Red,
        tier        = 2,
        values      = #partial{.Initiative = 8, .Attack = 5, .Defense = 7, .Movement = 5},
        primary     = .Attack,
        primary_sign = .Plus,
        item        = .Initiative,
        text        = "Target a unit adjacent to you. +2 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack},
                        Product {
                            Sum {
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance{Self{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                    flags = {.Ignoring_Immunity},
                                },
                                -1,
                            },
                            2,
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Long Thrust",
        color       = .Red,
        tier        = 2,
        alternate   = true,
        values      = #partial{.Initiative = 8, .Attack = 3, .Defense = 4, .Movement = 4, .Range = 1},
        primary     = .Attack,
        reach_sign  = .Plus,
        item        = .Defense,
        text        = "Target a unit in range. +1 Range\nfor each enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Sum {
                                Card_Value{.Range},
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance{Self{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                    flags = {.Ignoring_Immunity},
                                },
                            }},
                        },
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
    Card_Data { name = "Control",
        color       = .Green,
        tier        = 2,
        values      = #partial{.Initiative = 4, .Defense = 3, .Movement = 2, .Radius = 2},
        primary     = .Movement,
        item        = .Attack,
        text        = "Before or after movement, you may move\nan enemy ranged or melee minion\nin radius up to 2 spaces.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may either move yourself or a ranged or melee minion.",
                variant = Choice_Action {
                    choices = {
                        {name = "Move self",    jump_index = {index=1}},
                        {name = "Move minion",  jump_index = {index=5}},
                    },
                },
            },
            Action {  // 1
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
            Action {  // 2
                optional = true,
                tooltip = "You may choose a ranged or melee minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{{.Ranged_Minion, .Melee_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a ranged or melee minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{{.Ranged_Minion, .Melee_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
        },
    },
    Card_Data { name = "Constrict",
        color       = .Green,
        tier        = 2,
        alternate   = true,
        values      = #partial{.Initiative = 4, .Defense = 3, .Movement = 2},
        primary     = .Skill,
        item        = .Initiative,
        text        = "End of round: Defeat an enemy\nmelee minion adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Xargatha_Defeat,
                        timing = End_Of_Round {
                            extra_action_index = Action_Index {
                                sequence = .Primary,
                                index = 2,
                            },
                        },
                    },
                },
            },
            Action {  // "Turn action" stops here
                variant = Halt_Action{},
            },
            Action {  // "Extra action" at end of round starts here
                tooltip = "Defeat an enemy melee minion adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Melee_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Minion_Defeat_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Petrifying Stare",  // @Incomplete: "count as terrain"
        color       = .Blue,
        tier        = 2,
        values      = #partial{.Initiative = 10, .Defense = 6, .Movement = 3, .Radius = 3},
        primary     = .Skill,
        item        = .Defense,
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Xargatha_Freeze,
                        timing = Single_Turn(Sum{Card_Turn_Played{}, 1}),
                        target_set = {
                            conditions = {
                                Target_Within_Distance {
                                    origin = Card_Owner{},
                                    bounds = {1, Card_Value{.Radius}},
                                },
                                Target_Contains_Any{{.Hero}},
                                Target_Is_Enemy_Of{Card_Owner{}},
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Fresh Converts",
        color       = .Blue,
        tier        = 2,
        alternate   = true,
        values      = #partial{.Initiative = 10, .Defense = 6, .Movement = 3},
        primary     = .Skill,
        item        = .Attack,
        text        = "If you are adjacent to an enemy minion,\nyou may retrieve a discarded card.",\
        primary_effect = []Action {
            Action {
                tooltip = "Choose a discarded card to retrieve.",
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, 1}},
                            Target_Contains_Any{MINION_FLAGS},
                            Target_Is_Enemy_Unit{},
                        },
                        flags = {.Ignoring_Immunity},
                    },
                    0,
                },
                variant = Choose_Card_Action{
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Lethal Spin",
        color       = .Red,
        tier        = 3,
        values      = #partial{.Initiative = 8, .Attack = 5, .Defense = 7, .Movement = 5},
        primary     = .Attack,
        primary_sign = .Plus,
        item        = .Radius,
        text        = "Target a unit adjacent to you. +3 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack},
                        Product {
                            Sum {
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance{Self{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                    flags = {.Ignoring_Immunity},
                                },
                                -1,
                            },
                            3,
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Rapid Thrusts",
        color       = .Red,
        tier        = 3,
        alternate   = true,
        values      = #partial{.Initiative = 8, .Attack = 3, .Defense = 4, .Movement = 4, .Range = 1},
        primary     = .Attack,
        reach_sign  = .Plus,
        item        = .Defense,
        text        = "Target a unit in range. +1 Range\nfor each enemy unit adjacent to you.\nMay repeat once on a different enemy\nhero.",
        primary_effect = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit adjacent to you.",
                            arg2 = "May repeat once on a different enemy hero.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Sum {
                                Card_Value{.Range},
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance{Self{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                    flags = {.Ignoring_Immunity},
                                },
                            }},
                        },
                        Or {
                            And {
                                Equal{Repeat_Count{}, 0},
                                Target_Contains_Any{MINION_FLAGS},
                            },
                            Target_Contains_Any{{.Hero}},
                        },
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
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Dominate",
        color       = .Green,
        tier        = 3,
        values      = #partial{.Initiative = 4, .Defense = 3, .Movement = 2, .Radius = 2},
        primary     = .Movement,
        item        = .Attack,
        text        = "Before or after movement, you may move\nan enemy minion in radius up to 2 spaces;\nignore heavy minion immunity.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may either move yourself or a minion.",
                variant = Choice_Action {
                    choices = {
                        {name = "Move self",    jump_index = Action_Index{index=1}},
                        {name = "Move minion",  jump_index = Action_Index{index=5}},
                    },
                },
            },
            Action {  // 1
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
            Action {  // 2
                optional = true,
                tooltip = "You may choose a minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Ignoring_Immunity},
                },
            },
            Action {  // 3
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{MINION_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Ignoring_Immunity},
                },
            },
            Action {  // 6
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Card_Value{.Movement},
                },
            },
        },
    },
    Card_Data { name = "Final Embrace",
        color       = .Green,
        tier        = 3,
        alternate   = true,
        values      = #partial{.Initiative = 4, .Defense = 3, .Movement = 2},
        primary     = .Skill,
        item        = .Initiative,
        text        = "End of round: Defeat an enemy\nmelee or ranged minion adjacent to you.",  // @Todo check wording here
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Xargatha_Defeat,
                        timing = End_Of_Round {
                            extra_action_index = Action_Index {
                                sequence = .Primary,
                                index = 2,
                            },
                        },
                    },
                },
            },
            Action {  // "Turn action" stops here
                variant = Halt_Action{},
            },
            Action {  // "Extra action" at end of round starts here
                tooltip = "Defeat an enemy melee or ranged minion adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Melee_Minion, .Ranged_Minion}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Minion_Defeat_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Turn Into Statues",  // @Incomplete: "count as terrain"
        color       = .Blue,
        tier        = 3,
        values      = #partial{.Initiative = 10, .Defense = 6, .Movement = 3, .Radius = 4},
        primary     = .Skill,
        item        = .Defense,
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Xargatha_Freeze,
                        timing = Single_Turn(Sum{Card_Turn_Played{}, 1}),
                    },
                },
            },
        },
    },
    Card_Data { name = "Devoted Followers",
        color       = .Blue,
        tier        = 3,
        alternate   = true,
        values      = #partial{.Initiative = 10, .Defense = 6, .Movement = 3},
        primary     = .Skill,
        item        = .Attack,
        text        = "If you are adjacent to an enemy unit,\nyou may retrieve a discarded card.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose a discarded card to retrieve.",
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, 1}},
                            Target_Contains_Any{UNIT_FLAGS},
                            Target_Is_Enemy_Unit{},
                        },
                        flags = {.Ignoring_Immunity},
                    },
                    0,
                },
                variant = Choose_Card_Action{
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
        },
    },
}