package guards

/// Arien

//  Ult: Once per turn, before performing an\nAttack action, you may move 1 space.

arien_cards := []Card_Data {
    Card_Data { name = "Noble Blade",
        color           = .Gold,
        values          = #partial{.Initiative = 11, .Defense = 2, .Attack = 4, .Movement = 1},
        primary         = .Attack,
        text            = "Target a unit adjacent to you.\nBefore the attack: You may move another\nunit that is adjacent to the target 1 space.\n(\"Another unit\" never includes you.)",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 1
                tooltip = "You may move another unit adjacent to the target.",
                optional = true,
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Previously_Chosen_Target{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Not{Target_Is{Self{}}},
                    },
                },
            },
            Action {
                tooltip = "You may move the target 1 space.",
                optional = true,
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
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
    Card_Data { name = "Spell Break",
        color           = .Silver,
        values          = #partial{.Initiative = 13, .Defense = 3, .Radius = 3},
        primary         = .Skill,
        text            = "This turn: Enemy heroes in radius cannot\nperform skill actions, except on gold cards.\n(Skill is an action type. Other action types are unaffected.)",
        primary_effect  = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Arien_Spell_Break,
                        timing = Single_Turn(Card_Turn_Played{}),
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
                                Action_Index_Sequence_Is{.Primary},
                                Action_Index_Card_Primary_Is{.Skill},
                                Not{Action_Index_Card_Color_Is{.Gold}},
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Dangerous Current",
        color           = .Red,
        tier            = 1,
        values          = #partial{.Initiative = 8, .Defense = 6, .Attack = 6, .Movement = 4},
        primary         = .Attack,
        text            = "Target a unit adjacent to you. Before the\nattack: up to 1 enemy hero in any of the\n2 spaces in a straight line directly behind\nthe target discards a card, or is defeated.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 1
                tooltip = "You may force an enemy hero behind the target to discard.",
                optional = true,
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, 3}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_In_Straight_Line_With{Previously_Chosen_Target{}},
                        Greater_Than {
                            Target_Distance_To{Self{}},
                            Target_Distance_To{Previously_Chosen_Target{}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for the opponent to discard...",
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
    Card_Data { name = "Liquid Leap",
        color           = .Green,
        tier            = 1,
        values          = #partial{.Initiative = 4, .Defense = 3, .Movement = 2, .Range = 2},
        primary         = .Skill,
        text            = "Place yourself into a space in range\nwithout a spawn point and not adjacent\nto an empty spawn point.",
        primary_effect  = []Action {
            Action {
                tooltip = "Choose a space in range without a spawn point and not adjacent to an empty spawn point.",
                condition = Not{Self_Contains_Any{{.Cannot_Place}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Empty{},
                        Equal {
                            Count_Targets {
                                conditions = {
                                    Target_Within_Distance{Previous_Target{}, {0, 1}},
                                    Target_Empty{},
                                    Target_Contains_Any{SPAWNPOINT_FLAGS},
                                },
                            }, 0,
                        },
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
    Card_Data { name = "Aspiring Duelist",
        color           = .Blue,
        tier            = 1,
        values          = #partial{.Initiative = 9, .Defense = 5, .Movement = 3},
        primary         = .Defense,
        text            = "Ignore all minion defense modifiers.\n(This includes your minions, as well as enemy minions.)",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {  // No minion modifiers as part of this calculation...
                    strength = Card_Value{.Defense},
                },
            },
        },
    },
    Card_Data { name = "Raging Stream",
        color           = .Red,
        tier            = 2,
        values          = #partial{.Initiative = 8, .Defense = 7, .Attack = 7, .Movement = 4},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Target a unit adjacent to you. Before the\nattack: up to 1 enemy hero in any of the\n3 spaces in a straight line directly behind\nthe target discards a card, or is defeated.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 1
                tooltip = "You may force an enemy hero behind the target to discard.",
                optional = true,
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, 4}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_In_Straight_Line_With{Previously_Chosen_Target{}},
                        Greater_Than {
                            Target_Distance_To{Self{}},
                            Target_Distance_To{Previously_Chosen_Target{}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for the opponent to discard...",
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
    Card_Data { name = "Rogue Wave",
        color           = .Red,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 8, .Defense = 4, .Attack = 4, .Movement = 4, .Range = 2},
        primary         = .Attack,
        item            = .Defense,
        text            = "Target a unit in range.\nAfter the attack: You may push an enemy\nunit adjacent to you up to 2 spaces.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may push an enemy unit adjacent to you.",
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
                tooltip = error_tooltip,
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Magical Current",
        color           = .Green,
        tier            = 2,
        values          = #partial{.Initiative = 4, .Defense = 3, .Movement = 2, .Range = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Place yourself into a space in range\nwithout a spawn point and not adjacent\nto an empty spawn point.",
        primary_effect  = []Action {
            Action {
                tooltip = "Choose a space in range without a spawn point and not adjacent to an empty spawn point.",
                condition = Not{Self_Contains_Any{{.Cannot_Place}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Empty{},
                        Equal {
                            Count_Targets {
                                conditions = {
                                    Target_Within_Distance{Previous_Target{}, {0, 1}},
                                    Target_Empty{},
                                    Target_Contains_Any{SPAWNPOINT_FLAGS},
                                },
                            }, 0,
                        },
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
    Card_Data { name = "Arcane Whirlpool",
        color           = .Green,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 4, .Defense = 3, .Movement = 2, .Range = 4},
        primary         = .Skill,
        item            = .Defense,
        text            = "Swap with an enemy minion in range.\n(Swap places with the target. This is not a movement.)",
        primary_effect  = []Action {
            Action {
                tooltip = "Target an enemy minion in range.",
                condition = Not{Self_Contains_Any{{.Cannot_Swap}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                        Target_Is_Enemy_Unit{},
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
    Card_Data { name = "Expert Duelist",  // @Incomplete, active effect
        color           = .Blue,
        tier            = 2,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3},
        primary         = .Defense,
        item            = .Initiative,
        text            = "Ignore all minion defense modifiers.\nThis turn: You are immune to attack actions\nof all enemy heroes, except this attacker.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {  // No minion modifiers as part of this calculation...
                    strength = Card_Value{.Defense},
                },
            },
        },
    },
    Card_Data { name = "Slippery Ground",
        color           = .Blue,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3},
        primary         = .Movement,
        item            = .Attack,
        text            = "This turn: Enemy heroes adjacent\nto you cannot fast travel, or move more\nthan 1 space with a movement action.",
        primary_effect  = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Arien_Limit_Movement,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Target_Within_Distance {Card_Owner{}, {1, 1}},
                            Target_Contains_Any{{.Hero}},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Disallow_Action {
                                Action_Variant_At_Index_Is{Fast_Travel_Action},
                            },
                            Limit_Movement {
                                limit = 1,
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
    Card_Data { name = "Violent Torrent",
        color           = .Red,
        tier            = 3,
        values          = #partial{.Initiative = 9, .Defense = 7, .Attack = 7, .Movement = 4},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Target a unit adjacent to you. Before the\nattack: Up to 1 enemy hero in any of the 5\nspaces in a straight line directly behind the\target discards a card, or is defeated.\nMay repeat once on a different unit.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit adjacent to you.",
                            arg2 = "May repeat once on a different unit.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Attack_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Not_Previously_Targeted},
                },
            },
            Action {  // 1
                tooltip = "You may force an enemy hero behind the target to discard.",
                optional = true,
                skip_index = {index = 3},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, 4}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_In_Straight_Line_With{Previously_Chosen_Target{}},
                        Greater_Than {
                            Target_Distance_To{Self{}},
                            Target_Distance_To{Previously_Chosen_Target{}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 2
                tooltip = "Waiting for the opponent to discard...",
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
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Tidal Blast",
        color           = .Red,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 4, .Attack = 4, .Movement = 4, .Range = 2},
        primary         = .Attack,
        item            = .Movement,
        text            = "Target a unit in range.\nAfter the attack: You may push an enemy\nunit adjacent to you up to 3 spaces.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may push an enemy unit adjacent to you.",
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
                    bounds = {0, 3},
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Push_Action {
                    origin = Self{},
                    targets = Previous_Choices{},
                    num_spaces = Previous_Quantity_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Stranger Tide",
        color           = .Green,
        tier            = 3,
        values          = #partial{.Initiative = 3, .Defense = 4, .Movement = 2, .Range = 3},
        primary         = .Skill,
        item            = .Radius,
        text            = "Place yourself into a space in\nrange without a spawn point.",
        primary_effect  = []Action {
            Action {
                tooltip = "Choose a space in range without a spawn point.",
                condition = Not{Self_Contains_Any{{.Cannot_Place}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Empty{},
                        Not{Target_Contains_Any{SPAWNPOINT_FLAGS}},
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
    Card_Data { name = "Ebb and Flow",
        color           = .Green,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 3, .Defense = 4, .Movement = 2, .Range = 4},
        primary         = .Skill,
        item            = .Defense,
        text            = "Swap with an enemy minion in range;\nif it was adjacent to you, may repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target an enemy minion in range.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                condition = Not{Self_Contains_Any{{.Cannot_Swap}}},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Swap}}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Save_Variable_Action {
                    variable = Equal{Distance_Between{Self{}, Previously_Chosen_Target{}}, 1},
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
            Action {
                condition = Previously_Saved_Boolean{},
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Master Duelist",  // @Incomplete, active effect
        color           = .Blue,
        tier            = 3,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3},
        primary         = .Defense,
        item            = .Range,
        text            = "Ignore all minion defense modifiers.\nThis round: You are immune to attack actions\nof all enemy heroes, except this attacker.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {  // No minion modifiers as part of this calculation...
                    strength = Card_Value{.Defense},
                },
            },
        },
    },
    Card_Data { name = "Deluge",
        color           = .Blue,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 6, .Movement = 3, .Radius = 1},
        primary         = .Movement,
        item            = .Attack,
        text            = "This turn: Enemy heroes in radius\ncannot fast travel, or move more than\n1 space with a movement action.",
        primary_effect  = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Arien_Limit_Movement,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Target_Within_Distance {Card_Owner{}, {1, 1}},
                            Target_Contains_Any{{.Hero}},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Disallow_Action {
                                Action_Variant_At_Index_Is{Fast_Travel_Action},
                            },
                            Limit_Movement {
                                limit = 1,
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
}
