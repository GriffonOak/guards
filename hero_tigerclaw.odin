package guards

/// Tigerclaw

//  Ult: After you perform a basic action, you may\nrepeat it once; if you repeat an attack\naction, you cannot target the same unit.

tigerclaw_cards := []Card_Data {
    Card_Data { name = "Blink Strike",
        color =         .Gold,
        values =        #partial{.Initiative = 13, .Defense = 1, .Attack = 3, .Movement = 1},
        primary =       .Attack,
        text =          "Before the attack: Move 2 spaces in a straight\nline through an enemy unit: target that unit.\nIf you cannot make this move, you cannot attack.)",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you that you can move through.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Targets {
                                conditions = {
                                    Target_Within_Distance{Previous_Target{}, {1, 1}},
                                    Target_Within_Distance{Self{}, {2, 2}},
                                    Target_In_Straight_Line_With{Self{}},
                                    Target_Empty{},
                                },
                            }, 0,
                        },
                    },
                },
            },
            Action {
                tooltip = "Move through the unit.",
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 2,
                    max_distance = 2,
                    flags = {.Ignoring_Obstacles, .Straight_Line},
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                            Target_Empty{},
                        },
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
    Card_Data { name = "Blend into Shadows",  // @Incomplete, attack immunity
        color =         .Silver,
        values =        #partial{.Initiative = 6, .Defense = 2, .Radius = 2},
        primary =       .Skill,
        text =          "If you are adjacent to terrain, place yourself\ninto a space in radius; if you do, Next turn:\nYou are immune to enemy attack actions.",
        primary_effect = []Action {
            Action {
                tooltip = "Place yourself into a space in radius.",
                condition = And {
                    Greater_Than {
                        Count_Targets {
                            conditions = {
                                Target_Within_Distance{Self{}, {1, 1}},
                                Target_Contains_Any{{.Terrain}},
                            },
                        }, 0,
                    },
                    Not{Contains_Any{Self{}, {.Cannot_Place}}},
                },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
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
    Card_Data { name = "Hit and Run",
        color =         .Red,
        tier =          1,
        values =        #partial{.Initiative = 9, .Defense = 3, .Attack = 3, .Movement = 4},
        primary =       .Attack,
        text =          "Target a unit adjacent to you.\nAfter the attack: You may move 1 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
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
    Card_Data { name = "Light-Fingered",
        color =         .Green,
        tier =          1,
        values =        #partial{.Initiative = 2, .Defense = 1, .Movement = 3},
        primary =       .Skill,
        text =          "You may move 1 space.\nTake 1 coin from an enemy hero adjacent\nto you; if you do, you may move 1 space.",
        primary_effect = []Action {
            Action {
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 1},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
            Action {
                tooltip = "Take 1 coin from an enemy hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Hero_Coins{Current_Target{}}, 0,
                        },
                    },
                },
            },
            Action {
                variant = Gain_Coins_Action{
                    target = Self{},
                    gain = 1,
                },
            },
            Action {
                variant = Gain_Coins_Action{
                    target = Previously_Chosen_Target{},
                    gain = -1,
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
    Card_Data { name = "Dodge",
        color =         .Blue,
        tier =          1,
        values =        #partial{.Initiative = 10, .Defense = 0, .Movement = 3},
        primary =       .Defense,
        text =          "Block a ranged attack.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
                },
            },
        },
    },
    Card_Data { name = "Combat Reflexes",
        color =         .Red,
        tier =          2,
        values =        #partial{.Initiative = 9, .Defense = 3, .Attack = 4, .Movement = 4},
        primary =       .Attack,
        item =          .Initiative,
        text =          "Before the attack: You may move 1 space.\nTarget a unit adjacent to you.\nAfter the attack: If you did not move before\nthe attack, you may move 1 space.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 4},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {  // Have to move next to an enemy unit
                            Greater_Than {
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
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 3
                variant = Halt_Action{},
            },
            Action {  // 4
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
            Action {  // 5
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 6
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
    Card_Data { name = "Backstab",
        color =         .Red,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 9, .Defense = 5, .Attack = 5, .Movement = 5},
        primary =       .Attack,
        primary_sign =  .Plus,
        item =          .Defense,
        text =          "Target a unit adjacent to you; if a friendly\nunit is adjacent to the target, +2 Attack.",
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
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack},
                        Ternary {
                            {2, 0},
                            Greater_Than {
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                                        Target_Contains_Any{UNIT_FLAGS},
                                        Target_Is_Friendly_Unit{},
                                    },
                                }, 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Pick Pocket",
        color =         .Green,
        tier =          2,
        values =        #partial{.Initiative = 2, .Defense = 1, .Movement = 3},
        primary =       .Skill,
        item =          .Attack,
        text =          "Move up to 2 spaces.\nTake 1 coin from an enemy hero adjacent\nto you; if you do, you may move 1 space.",
        primary_effect = []Action {
            Action {
                tooltip = "Move up to 2 spaces.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                },
            },
            Action {
                tooltip = "Take 1 coin from an enemy hero adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Hero_Coins{Current_Target{}}, 0,
                        },
                    },
                },
            },
            Action {
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 1,
                },
            },
            Action {
                variant = Gain_Coins_Action {
                    target = Previously_Chosen_Target{},
                    gain = -1,
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
    Card_Data { name = "Poisoned Dagger",
        color =         .Green,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 2, .Defense = 1, .Movement = 3, .Range = 3},
        primary =       .Skill,
        item =          .Initiative,
        text =          "Give a hero in range a Poison marker.\nThe hero with a poison marker has\n-1 Initiative, -1 Attack and -1 Defense.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose a hero in range to give the Poison marker to.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                    },
                },
            },
            Action {
                variant = Give_Marker_Action {
                    target = Previously_Chosen_Target{},
                    marker = .Tigerclaw_Weak_Poison,
                },
            },
        },
    },
    Card_Data { name = "Sidestep",
        color =         .Blue,
        tier =          2,
        values =        #partial{.Initiative = 11, .Defense = 0, .Movement = 3},
        primary =       .Defense,
        item =          .Attack,
        text =          "Block a ranged attack.\nYou may move 1 space.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
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
    Card_Data { name = "Parry",
        color =         .Blue,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 11, .Defense = 0, .Movement = 3},
        primary =       .Defense,
        item =          .Defense,
        text =          "Block a non-ranged attack.\nThe attacker discards a card, if able.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Not{Attack_Contains_Flag{.Ranged}},
                },
            },
            Action {
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Attacker{},
                },
            },
        },
    },
    Card_Data { name = "Leaping Strike",
        color =         .Red,
        tier =          3,
        values =        #partial{.Initiative = 10, .Defense = 4, .Attack = 4, .Movement = 4},
        primary =       .Attack,
        item =          .Radius,
        text =          "Before the attack: You may move 1 space.\nTarget a unit adjacent to you.\nAfter the attack: You may move 1 space.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 1},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
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
                },
            },
            Action {  // 1
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 6
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
    Card_Data { name = "Backstab with a Ballista",
        color =         .Red,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 10, .Defense = 6, .Attack = 5, .Movement = 5, .Range = 1},
        primary =       .Attack,
        primary_sign =  .Plus,
        item =          .Defense,
        text =          "Target a unit in range;\nif a friendly unit is adjacent to the target\n+2 Attack, and the target cannot\nperform a primary action to defend.",
        primary_effect = []Action {
            Action {  // 0
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
            Action {  // 1
                tooltip = error_tooltip,
                // This choice action is basically acting as a switch in this case, maybe that could have its own separate type?
                variant = Choice_Action {
                    choices = {
                        {name = "ERROR no adjacent", jump_index = {index = 2}},
                        {name = "ERROR adjacent", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for the opponent to defend...",
                // Condition here is basically that there are no friendly units adjacent to the target
                condition = Equal {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                            Target_Contains_Any{UNIT_FLAGS},
                            Target_Is_Friendly_Unit{},
                            Not{Target_Is{Self{}}},
                        },
                    }, 0,
                },
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {  // 3
                variant = Halt_Action{},
            },
            Action {  // 4
                tooltip = "Waiting for the opponent to defend...",
                // Condition here is that there are friendly units adjacent to the target
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                            Target_Contains_Any{UNIT_FLAGS},
                            Target_Is_Friendly_Unit{},
                            Not{Target_Is{Self{}}},
                        },
                    }, 0,
                },
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Sum {
                        Card_Value{.Attack},
                        2,
                    },
                    flags = {.Disallow_Primary_Defense},
                },
            },
        },
    },
    Card_Data { name = "Master Thief",
        color =         .Green,
        tier =          3,
        values =        #partial{.Initiative = 1, .Defense = 2, .Movement = 3},
        primary =       .Skill,
        item =          .Movement,
        text =          "Move up to 2 spaces. Take 1 or 2 coins\nfrom an enemy hero adjacent to you;\nif you do, you may move 2 spaces.",
        primary_effect = []Action {
            Action {
                tooltip = "Move up to 2 spaces.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = 2,
                },
            },
            Action {
                tooltip = "Target an enemy hero adjacent to you.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Hero_Coins{Current_Target{}}, 0,
                        },
                    },
                },
            },
            Action {
                tooltip = "Choose how many coins to take from the hero.",
                variant = Choose_Quantity_Action {
                    bounds = {1, Min{2, Count_Hero_Coins{Previously_Chosen_Target{}}}},
                },
            },
            Action {
                variant = Gain_Coins_Action{
                    target = Self{},
                    gain = Previous_Quantity_Choice{},
                },
            },
            Action {
                variant = Gain_Coins_Action{
                    target = Previously_Chosen_Target{},
                    gain = Product{-1, Previous_Quantity_Choice{}},
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
    Card_Data { name = "Poisoned Dart",
        color =         .Green,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 1, .Defense = 2, .Movement = 3, .Range = 3},
        primary =       .Skill,
        item =          .Initiative,
        text =          "Give a hero in range a Poison marker.\nThe hero with a poison marker has\n-2 Initiative, -2 Attack and -2 Defense.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose a hero in range to give the Poison marker to.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                    },
                },
            },
            Action {
                variant = Give_Marker_Action {
                    target = Previously_Chosen_Target{},
                    marker = .Tigerclaw_Strong_Poison,
                },
            },
        },
    },
    Card_Data { name = "Evade",
        color =         .Blue,
        tier =          3,
        values =        #partial{.Initiative = 11, .Defense = 0, .Movement = 3},
        primary =       .Defense,
        item =          .Attack,
        text =          "Block a ranged attack.\nYou may move 1 space. You may retrieve\nyour resolved or discarded basic skill card.",
        primary_effect = []Action {
            Action {  // 0
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
                },
            },
            Action {  // 1
                tooltip = "You may move 1 space.",
                optional = true,
                skip_index = {index = 2},
                variant = Movement_Action {
                    target = Self{},
                    min_distance = 1,
                    max_distance = 1,
                },
            },
            Action {  // 2
                tooltip = "You may retrieve your basic skill card.",
                optional = true,
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_Color_Is{.Silver},
                        Or {
                            Card_State_Is{.Resolved},
                            Card_State_Is{.Discarded},
                        },
                    },
                },
            },
            Action {
                variant = Retrieve_Card_Action{Previous_Card_Choice{}},
            },
        },
    },
    Card_Data { name = "Riposte",
        color =         .Blue,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 11, .Defense = 0, .Movement = 3},
        primary =       .Defense,
        item =          .Range,
        text =          "Block a non-ranged attack.\nThe attacker discards a card, or is defeated.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Not{Attack_Contains_Flag{.Ranged}},
                },
            },
            Action {
                tooltip = "Waiting for opponent to discard...",
                variant = Force_Discard_Action {
                    target = Attacker{},
                    or_is_defeated = true,
                },
            },
        },
    },
}
