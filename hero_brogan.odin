package guards

/// Brogan

//  Ult: During minion battle you count as a heavy\nminion; if you would be removed, lose the push instead.

brogan_cards := []Card_Data {
    Card_Data { name = "Onslaught",
        color =         .Gold,
        values =        #partial{.Initiative = 11, .Defense = 3, .Attack = 4, .Movement = 1},
        primary =       .Attack,
        text =          "Target a unit adjacent to you. After the attack:\nMove into the space it occupied, if able.",
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
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "Move into the space it occupied, if able.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Is{Previously_Chosen_Target{}},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Bulwark",
        color =         .Silver,
        values =        #partial{.Initiative = 12, .Defense = 4, .Radius = 4},
        primary =       .Skill,
        text =          "You may retrieve a discarded card.\nThis turn: You and friendly units in radius\ncannot be moved, pushed, swapped\nor placed by enemy heroes.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose a discarded card to retrieve.",
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
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Brogan_Bulwark,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Are_Enemies{Self{}, Card_Owner{}},
                            Target_Within_Distance{Card_Owner{}, {0, Card_Value{.Radius}}},
                            Target_Contains_Any{UNIT_FLAGS},
                            Not{Target_Is_Enemy_Of{Card_Owner{}}},
                        },
                        outcomes = {
                            Target_Counts_As{{
                                .Cannot_Move,
                                .Cannot_Push,
                                .Cannot_Swap,
                                .Cannot_Place,
                            }},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Mad Dash",
        color =         .Red,
        tier =          1,
        values =        #partial{.Initiative = 7, .Defense = 7, .Attack = 6, .Movement = 3},
        primary =       .Attack,
        text =          "Before the attack: Move 2 spaces in\na straight line to a space adjacent to\nan enemy unit, then target that unit.\n(If you cannot make this move, you cannot attack.)",
        primary_effect = []Action {
            Action {
                tooltip = "Move 2 spaces in a straight line to a space adjacent to an enemy unit.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 2,
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{UNIT_FLAGS},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                    flags = {.Straight_Line},
                },
            },
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Shield",  // @Unimplemented.
        color =         .Green,
        tier =          1,
        values =        #partial{.Initiative = 6, .Defense = 4, .Movement = 2},
        primary =       .Skill,
        text =          "This round: When any friendly minion in radius\nis defeated you may discard a silver card.\nIf you do, the minion is not removed.\n(The enemy hero still gains the coins for defeating the minion.)",
        primary_effect = []Action {},
    },
    Card_Data { name = "Brutal Jab",
        color =         .Blue,
        tier =          1,
        values =        #partial{.Initiative = 8, .Defense = 5, .Movement = 2},
        primary =       .Skill,
        text =          "You may move 1 space. Push an enemy unit\nor a token adjacent to you up to 1 space.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 1},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
            Action {  // 1
                tooltip = "Target an enemy unit or a token adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Not{Target_Contains_Any{{.Cannot_Push}}},
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.Token}},
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Choose how many spaces to push the target.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 1},
                },
            },
            Action {  // 3
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Bullrush",
        color =         .Red,
        tier =          2,
        values =        #partial{.Initiative = 7, .Defense = 8, .Attack = 6, .Movement = 3},
        primary =       .Attack,
        item =          .Attack,
        text =          "Before the attack: Move 2 or 3 spaces in\na straight line to a space adjacent to an\nenemy unit, then target that unit.",
        primary_effect = []Action {
            Action {
                tooltip = "Move 2 or 3 spaces in a straight line to a space adjacent to an enemy unit.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 3,
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{UNIT_FLAGS},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                    flags = {.Straight_Line},
                },
            },
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Throwing Axe",
        color =         .Red,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 7, .Defense = 7, .Attack = 3, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Defense,
        text =          "Choose one -\n*Target a unit adjacent to you.\n*You may discard a card;\nif you do, target a unit in range.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "Discard range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
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
            Action {  // 2
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 3
                variant = Halt_Action{},
            },
            Action {  // 4
                tooltip = "You may discard a card.",
                optional = true,
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.In_Hand},
                    },
                },
            },
            Action {  // 5
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
            Action {  // 6
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Bolster",  // @Unimplemented
        color =         .Green,
        tier =          2,
        values =        #partial{.Initiative = 5, .Defense = 5, .Movement = 2, .Radius = 2},
        primary =       .Skill,
        item =          .Attack,
        text =          "This round: When any friendly minion in radius\nis defeated you may discard a silver card.\nIf you do, the minion is not removed.",
        primary_effect = []Action {},
    },
    Card_Data { name = "War Drummer",
        color =         .Green,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 5, .Defense = 5, .Movement = 2, .Range = 4},
        primary =       .Skill,
        item =          .Defense,
        text =          "A friendly hero in range gains 1 coin;\nif any hero was defeated this round,\nthat friendly hero gains 3 coins instead.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a friendly hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Friendly_Unit{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Gain_Coins_Action {
                    target = Previously_Chosen_Target{},
                    gain = Ternary {
                        terms = {3, 1},
                        condition = Greater_Than{Heroes_Defeated_This_Round{}, 0},
                    },
                },
            },
        },
    },
    Card_Data { name = "Mighty Punch",
        color =         .Blue,
        tier =          2,
        values =        #partial{.Initiative = 9, .Defense = 6, .Movement = 2},
        primary =       .Skill,
        item =          .Initiative,
        text =          "You may move 1 space. Push an enemy unit\nor a token adjacent to you up to 2 spaces.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 1},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
            Action {  // 1
                tooltip = "Target an enemy unit or a token adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Not{Target_Contains_Any{{.Cannot_Push}}},
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.Token}},
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Choose how many spaces to push the target.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 2},
                },
            },
            Action {  // 3
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Shield Bash",
        color =         .Blue,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 9, .Defense = 6, .Movement = 2},
        primary =       .Skill,
        item =          .Attack,
        text =          "An enemy hero adjacent to you who\nhas played an attack card this turn\ndiscards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero adjacent to you who has played an attack card.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_Primary_Is{.Attack},
                                Equal{Card_Turn_Played{}, Current_Turn{}},
                            }, 0,
                        },
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.In_Hand},
                            }, 0,
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
    Card_Data { name = "Furious Charge",
        color =         .Red,
        tier =          3,
        values =        #partial{.Initiative = 8, .Defense = 8, .Attack = 7, .Movement = 3},
        primary =       .Attack,
        item =          .Movement,
        text =          "Before the attack: Move 2, 3, or 4 spaces\n in a straight line to a space adjacent to an\nenemy unit, then target that unit.",
        primary_effect = []Action {
            Action {
                tooltip = "Move 2 to 4 spaces in a straight line to a space adjacent to an enemy unit.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 4,
                    destination_criteria = {
                        conditions = {
                            Greater_Than{
                                Count_Targets {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Contains_Any{UNIT_FLAGS},
                                    Target_Is_Enemy_Unit{},
                                    Not{Target_Contains_Any{{.Immune, .Immune_Attacks}}},
                                }, 0,
                            },
                        },
                    },
                    flags = {.Straight_Line},
                },
            },
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
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Throwing Spear",
        color =         .Red,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 8, .Defense = 7, .Attack = 4, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Radius,
        text =          "Choose one -\n*Target a unit adjacent to you.\n*You may discard a card. If you have a card\nin the discard, target a unit in range.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "Discard range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
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
            Action {  // 2
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 3
                variant = Halt_Action{},
            },
            Action {  // 4
                tooltip = "You may discard a card.",
                optional = true,
                skip_index = {index = 5},
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.In_Hand},
                    },
                },
            },
            Action {  // 5
                tooltip = "Target a unit in range.",
                condition = Greater_Than {
                    Count_Card_Targets{
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    }, 0,
                },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Fortify",  // @Unimplemented
        color =         .Green,
        tier =          3,
        values =        #partial{.Initiative = 5, .Defense = 5, .Movement = 2, .Radius = 2},
        primary =       .Skill,
        item =          .Attack,
        text =          "This round: when any friendly minion in radius\nis defeated you may discard a basic card.\nIf you do, the minion is not removed.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Master Skald",
        color =         .Green,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 5, .Defense = 5, .Movement = 2, .Range = 4},
        primary =       .Skill,
        item =          .Defense,
        text =          "A friendly hero in range gains 2 coins;\nif any hero was defeated this round,\nthat friendly hero gains 4 coins instead.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a friendly hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Friendly_Unit{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Gain_Coins_Action {
                    target = Previously_Chosen_Target{},
                    gain = Ternary {
                        terms = {4, 2},
                        condition = Greater_Than{Heroes_Defeated_This_Round{}, 0},
                    },
                },
            },
        },
    },
    Card_Data { name = "Savage Kick",
        color =         .Blue,
        tier =          3,
        values =        #partial{.Initiative = 9, .Defense = 6, .Movement = 2},
        primary =       .Skill,
        item =          .Initiative,
        text =          "Move up to 2 spaces. Push an enemy unit\nor a token adjacent to you up to 2 spaces.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Move up to 2 spaces.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                },
            },
            Action {  // 1
                tooltip = "Target an enemy unit or a token adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Not{Target_Contains_Any{{.Cannot_Push}}},
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.Token}},
                        },
                    },
                },
            },
            Action {  // 2
                tooltip = "Choose how many spaces to push the target.",
                variant = Choose_Quantity_Action {
                    bounds = {0, 2},
                },
            },
            Action {  // 3
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Counterattack",
        color =         .Blue,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 9, .Defense = 6, .Movement = 2},
        primary =       .Skill,
        item =          .Range,
        text =          "An enemy hero adjacent to you who\nhas played an attack card this turn\ndiscards a card, or is defeated.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero adjacent to you who has played an attack card.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_Primary_Is{.Attack},
                                Equal{Card_Turn_Played{}, Current_Turn{}},
                            }, 0,
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
}
