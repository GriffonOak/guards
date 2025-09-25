package guards

/// BROGAN

//  Ult: During minion battle you count as a heavy\nminion; if you would be removed, lose the push instead.

brogan_cards := []Card_Data {
    Card_Data { name = "Onslaught",
        color =         .GOLD,
        values =        #partial{.INITIATIVE = 11, .DEFENSE = 3, .ATTACK = 4, .MOVEMENT = 1},
        primary =       .ATTACK,
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
                    strength = Card_Value{.ATTACK},
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
    Card_Data { name = "Bulwark",  // @Incomplete
        color =         .SILVER,
        values =        #partial{.INITIATIVE = 12, .DEFENSE = 4, .RADIUS = 4},
        primary =       .SKILL,
        text =          "You may retrieve a discarded card.\nThis turn: You and friendly units in radius\ncannot be moved, pushed, swapped\nor placed by enemy heroes.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose a discarded card to retrieve.",
                variant = Choose_Card_Action{
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.DISCARDED},
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
    Card_Data { name = "Mad Dash",
        color =         .RED,
        tier =          1,
        values =        #partial{.INITIATIVE = 7, .DEFENSE = 7, .ATTACK = 6, .MOVEMENT = 3},
        primary =       .ATTACK,
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
                                    conditions = {
                                        Target_Within_Distance{Previous_Target{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                }, 0,
                            },
                        },
                    },
                    flags = {.STRAIGHT_LINE},
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
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Shield",  // @Unimplemented.
        color =         .GREEN,
        tier =          1,
        values =        #partial{.INITIATIVE = 6, .DEFENSE = 4, .MOVEMENT = 2},
        primary =       .SKILL,
        text =          "This round: When any friendly minion in radius\nis defeated you may discard a silver card.\nIf you do, the minion is not removed.\n(The enemy hero still gains the coins for defeating the minion.)",
        primary_effect = []Action {},
    },
    Card_Data { name = "Brutal Jab",
        color =         .BLUE,
        tier =          1,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 5, .MOVEMENT = 2},
        primary =       .SKILL,
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
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.TOKEN}},
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
        color =         .RED,
        tier =          2,
        values =        #partial{.INITIATIVE = 7, .DEFENSE = 8, .ATTACK = 6, .MOVEMENT = 3},
        primary =       .ATTACK,
        item =          .ATTACK,
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
                                    conditions = {
                                        Target_Within_Distance{Previous_Target{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                }, 0,
                            },
                        },
                    },
                    flags = {.STRAIGHT_LINE},
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
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Throwing Axe",
        color =         .RED,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 7, .DEFENSE = 7, .ATTACK = 3, .MOVEMENT = 4, .RANGE = 2},
        primary =       .ATTACK,
        item =          .DEFENSE,
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
                    strength = Card_Value{.ATTACK},
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
                        Card_State_Is{.IN_HAND},
                    },
                },
            },
            Action {  // 5
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
            Action {  // 6
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Bolster",  // @Unimplemented
        color =         .GREEN,
        tier =          2,
        values =        #partial{.INITIATIVE = 5, .DEFENSE = 5, .MOVEMENT = 2, .RADIUS = 2},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "This round: When any friendly minion in radius\nis defeated you may discard a silver card.\nIf you do, the minion is not removed.",
        primary_effect = []Action {},
    },
    Card_Data { name = "War Drummer",
        color =         .GREEN,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 5, .DEFENSE = 5, .MOVEMENT = 2, .RANGE = 4},
        primary =       .SKILL,
        item =          .DEFENSE,
        text =          "A friendly hero in range gains 1 coin;\nif any hero was defeated this round,\nthat friendly hero gains 3 coins instead.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a friendly hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RANGE}}},
                        Target_Contains_Any{{.HERO}},
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
        color =         .BLUE,
        tier =          2,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 6, .MOVEMENT = 2},
        primary =       .SKILL,
        item =          .INITIATIVE,
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
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.TOKEN}},
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
        color =         .BLUE,
        tier =          2,
        alternate =     true,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 6, .MOVEMENT = 2},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "An enemy hero adjacent to you who\nhas played an attack card this turn\ndiscards a card, if able.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero adjacent to you who has played an attack card.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_Primary_Is{.ATTACK},
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
                },
            },
        },
    },
    Card_Data { name = "Furious Charge",
        color =         .RED,
        tier =          3,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 8, .ATTACK = 7, .MOVEMENT = 3},
        primary =       .ATTACK,
        item =          .MOVEMENT,
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
                                    conditions = {
                                        Target_Within_Distance{Previous_Target{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Enemy_Unit{},
                                    },
                                }, 0,
                            },
                        },
                    },
                    flags = {.STRAIGHT_LINE},
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
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Throwing Spear",
        color =         .RED,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 8, .DEFENSE = 7, .ATTACK = 4, .MOVEMENT = 4, .RANGE = 2},
        primary =       .ATTACK,
        item =          .RADIUS,
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
                    strength = Card_Value{.ATTACK},
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
                        Card_State_Is{.IN_HAND},
                    },
                },
            },
            Action {  // 5
                tooltip = "Target a unit in range.",
                condition = Greater_Than {
                    Count_Card_Targets{
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.DISCARDED},
                    }, 0,
                },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RANGE}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Fortify",  // @Unimplemented
        color =         .GREEN,
        tier =          3,
        values =        #partial{.INITIATIVE = 5, .DEFENSE = 5, .MOVEMENT = 2, .RADIUS = 2},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "This round: when any friendly minion in radius\nis defeated you may discard a basic card.\nIf you do, the minion is not removed.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Master Skald",
        color =         .GREEN,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 5, .DEFENSE = 5, .MOVEMENT = 2, .RANGE = 4},
        primary =       .SKILL,
        item =          .DEFENSE,
        text =          "A friendly hero in range gains 2 coins;\nif any hero was defeated this round,\nthat friendly hero gains 4 coins instead.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a friendly hero in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.RANGE}}},
                        Target_Contains_Any{{.HERO}},
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
        color =         .BLUE,
        tier =          3,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 6, .MOVEMENT = 2},
        primary =       .SKILL,
        item =          .INITIATIVE,
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
                        Or {
                            And {
                                Target_Contains_Any{UNIT_FLAGS},
                                Target_Is_Enemy_Unit{},
                            },
                            Target_Contains_Any{{.TOKEN}},
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
        color =         .BLUE,
        tier =          3,
        alternate =     true,
        values =        #partial{.INITIATIVE = 9, .DEFENSE = 6, .MOVEMENT = 2},
        primary =       .SKILL,
        item =          .RANGE,
        text =          "An enemy hero adjacent to you who\nhas played an attack card this turn\ndiscards a card, or is defeated.",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero adjacent to you who has played an attack card.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_Primary_Is{.ATTACK},
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
