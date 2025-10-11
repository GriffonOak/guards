package guards

/// Wasp

//  Ult: Each time after you perform a basic skill,\nyou may defeat an enemy minion in radius;\nan enemy hero who was adjacent to that\nminion discards a card, if able.

wasp_cards := []Card_Data {
    Card_Data { name = "Magnetic Dagger",
        color           = .Gold,
        values          = #partial{.Initiative = 12, .Defense = 2, .Attack = 3, .Movement = 1, .Radius = 3},
        primary         = .Attack,
        text            = "Target a unit adjacent to you.\nAfter the attack: This turn: Enemy units\nin radius cannot be swapped or placed\nby themselves or by enemy heroes.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Wasp_Magnetic_Dagger,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Are_Enemies{Self{}, Card_Owner{}},
                            Target_Within_Distance{Card_Owner{}, {1, Card_Value{.Radius}}},
                            Target_Contains_Any{UNIT_FLAGS},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Target_Counts_As{{.Cannot_Swap, .Cannot_Place}},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Static Barrier",
        color           = .Silver,
        values          = #partial{.Initiative = 13, .Defense = 2, .Radius = 2},
        primary         = .Skill,
        text            = "This turn: While an enemy hero outside of\nradius is performing an action, spaces in\nradius count as obstacles. While an enemy\nhero in radius is performing an action,\nspaces outside of radius count as obstacles.",
        primary_effect  = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Wasp_Static_Barrier,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {  // Phew! this one is kind of a looker but I think it works
                            Are_Enemies{Self{}, Card_Owner{}},
                            Or {
                                And {
                                    Target_Within_Distance {Card_Owner{}, {1, Card_Value{.Radius}}},
                                    Greater_Than{Distance_Between{Self{}, Card_Owner{}}, Card_Value{.Radius}},
                                },
                                And {
                                    Not{Target_Within_Distance{Card_Owner{}, {1, Card_Value{.Radius}}}},
                                    Not{Greater_Than{Distance_Between{Self{}, Card_Owner{}}, Card_Value{.Radius}}},
                                },
                            },
                        },
                        outcomes = {
                            Target_Counts_As{{.Obstacle}},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Shock",
        color           = .Red,
        tier            = 1,
        values          = #partial{.Initiative = 8, .Defense = 6, .Attack = 5, .Movement = 4, .Radius = 2},
        primary         = .Attack,
        text            = "Target a unit adjacent to you.\nAfter the attack: An enemy hero in radius and\nnot adjacent to you discards a card, if able.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "Target an enemy hero not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
    Card_Data { name = "Stop Projectiles",
        color           = .Green,
        tier            = 1,
        values          = #partial{.Initiative = 3, .Defense = 0, .Movement = 2},
        primary         = .Defense,
        text            = "Block a ranged attack.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
                },
            },
        },
    },
    Card_Data { name = "Lift Up",
        color           = .Blue,
        tier            = 1,
        values          = #partial{.Initiative = 10, .Defense = 5, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        text            = "Move a unit, or a token, in radius 1 space,\nwithout moving it away from you or closer to you.\nMay repeat once on the same target.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit or token in radius.",
                            arg2 = "May repeat once on the same target.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Or {
                            And {
                                Equal{Repeat_Count{}, 0},
                                Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                                Target_Contains_Any{UNIT_FLAGS + {.Token}},
                            },
                            And {
                                Greater_Than{Repeat_Count{}, 0},
                                Target_Is{Previously_Chosen_Target{}},
                            },
                        },
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space, without moving it away from you or closer to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{
                                Self{},
                                {
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                },
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
    Card_Data { name = "Electrocute",
        color           = .Red,
        tier            = 2,
        values          = #partial{.Initiative = 9, .Defense = 6, .Attack = 5, .Movement = 4, .Radius = 3},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Target a unit adjacent to you.\nAfter the attack: An enemy hero in radius and\nnot adjacent to you discards a card, if able.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "Target an enemy hero not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
    Card_Data { name = "Charged Boomerang",
        color           = .Red,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 3, .Attack = 3, .Movement = 4, .Range = 3},
        primary         = .Attack,
        item            = .Defense,
        text            = "Target a unit in range and not in a straight line.\n(Units adjacent to you are in a straight line from you.)",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range and not in a straight line.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Range}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
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
    Card_Data { name = "Deflect Projectiles",
        color           = .Green,
        tier            = 2,
        values          = #partial{.Initiative = 3, .Defense = 0, .Movement = 2, .Range = 3},
        primary         = .Defense,
        item            = .Initiative,
        text            = "Block a ranged attack; if you do, an enemy\nhero in range, other than the attacker,\ndiscards a card, if able.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
                },
            },
            Action {
                tooltip = "Target an enemy hero in range, other than the attacker.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Not{Target_Is{Attacker{}}},
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
    Card_Data { name = "Telekinesis",
        color           = .Green,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 3, .Defense = 3, .Movement = 2, .Range = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Place a unit or a token in range, which is not\nin a straight line, into a space adjacent to you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit or token in range and not in a straight line.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Place_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS + {.Token}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Not{Target_Contains_Any{{.Cannot_Place}}},
                    },
                },
            },
            Action {
                tooltip = "Place the target in a space adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Empty{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Labelled_Target{.Place_Target},
                    destination = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Control Gravity",
        color           = .Blue,
        tier            = 2,
        values          = #partial{.Initiative = 10, .Defense = 5, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Defense,
        text            = "Move a unit, or a token, in radius 1 space,\nwithout moving it away from you or closer to\nyou.\nMay repeat once on the same target.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit or token in radius.",
                            arg2 = "May repeat once on the same target.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                        Or {
                            And {
                                Equal{Repeat_Count{}, 0},
                                Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                                Target_Contains_Any{UNIT_FLAGS + {.Token}},
                            },
                            And {
                                Greater_Than{Repeat_Count{}, 0},
                                Target_Is{Previously_Chosen_Target{}},
                            },
                        },
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space, without moving it away from you or closer to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{
                                Self{},
                                {
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                },
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
    Card_Data { name = "Kinetic Repulse",  // @Unimplemented, this one is just kinda hard, also need same target stuff likely
        color           = .Blue,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 5, .Movement = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Push up to 2 enemy units adjacent to you\n3 spaces; if a pushed hero is stopped by an\nobstacle, that hero discards a card, if able.",
        primary_effect  = []Action {},
    },
    Card_Data { name = "Electroblast",
        color           = .Red,
        tier            = 3,
        values          = #partial{.Initiative = 9, .Defense = 7, .Attack = 6, .Movement = 4, .Radius = 3},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Target a unit adjacent to you. After the attack:\nAn enemy hero in radius and not adjacent\nto you discards a card, or is defeated.",
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "Target an enemy hero not adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
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
    Card_Data { name = "Thunder Boomerang",
        color           = .Red,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 4, .Attack = 4, .Movement = 4, .Range = 3},
        primary         = .Attack,
        item            = .Movement,
        text            = "Target a unit in range and not in a straight line.\nAfter the attack: If you targeted a hero,\nmay repeat once on a different target.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit in range and not in a straight line.",
                            arg2 = "May repeat once on a different target.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {2, Card_Value{.Range}}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Not_Previously_Targeted},
                },
            },
            Action {
                variant = Save_Variable_Action {
                    Greater_Than {  // @Note: It would be nice to have a better way of expressing this
                        Count_Targets {
                            conditions = {
                                Target_Is{Previously_Chosen_Target{}},
                                Target_Contains_Any{{.Hero}},
                            },
                        }, 0,
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
                condition = Previously_Saved_Boolean{},
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Reflect Projectiles",
        color           = .Green,
        tier            = 3,
        values          = #partial{.Initiative = 2, .Defense = 0, .Movement = 2, .Range = 3},
        primary         = .Defense,
        item            = .Radius,
        text            = "Block a ranged attack; if you do, an enemy\nhero in range discards a card, if able.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = Attack_Contains_Flag{.Ranged},
                },
            },
            Action {
                tooltip = "Target an enemy hero in range, other than the attacker.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Not{Target_Is{Attacker{}}},
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
    Card_Data { name = "Mass Telekinesis",
        color           = .Green,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 2, .Defense = 4, .Movement = 2, .Range = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "Place a unit or a token in range, which\nis not in a straight line, into a space\nadjacent to you. May repeat once.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit or token in range and not in a straight line.",
                            arg2 = "May repeat once.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    label = .Place_Target,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS + {.Token}},
                        Not{Target_In_Straight_Line_With{Self{}}},
                        Not{Target_Contains_Any{{.Cannot_Place}}},
                    },
                },
            },
            Action {
                tooltip = "Place the target in a space adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Empty{},
                    },
                },
            },
            Action {
                tooltip = error_tooltip,
                variant = Place_Action {
                    source = Labelled_Target{.Place_Target},
                    destination = Previously_Chosen_Target{},
                },
            },
            Action {
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
        },
    },
    Card_Data { name = "Center of Mass",
        color           = .Blue,
        tier            = 3,
        values          = #partial{.Initiative = 11, .Defense = 6, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Defense,
        text            = "Move a unit, or a token, in radius 1 space,\nwithout moving it away from you or closer\nto you.\nMay repeat up to two times\non the same target.",
        primary_effect  = []Action {
            Action {
                tooltip = Formatted_String {
                    format = "%v",
                    arguments = {
                        Conditional_String_Argument {
                            condition = Equal{Repeat_Count{}, 0},
                            arg1 = "Target a unit or token in radius.",
                            arg2 = "May repeat again on the same target.",
                        },
                    },
                },
                optional = Greater_Than{Repeat_Count{}, 0},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                        Or {
                            And {
                                Equal{Repeat_Count{}, 0},
                                Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                                Target_Contains_Any{UNIT_FLAGS + {.Token}},
                            },
                            And {
                                Greater_Than{Repeat_Count{}, 0},
                                Target_Is{Previously_Chosen_Target{}},
                            },
                        },
                    },
                },
            },
            Action {
                tooltip = "Move the target 1 space, without moving it away from you or closer to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{
                                Self{},
                                {
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                    Distance_Between{Self{}, Previously_Chosen_Target{}},
                                },
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
    Card_Data { name = "Kinetic Blast",  // @Unimplemented
        color           = .Blue,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 11, .Defense = 6, .Movement = 3},
        primary         = .Skill,
        item            = .Range,
        text            = "Push up to 2 enemy units adjacent to you\n3 or 4 spaces; if a pushed hero is stopped by\nan obstacle, that hero discards a card, if able.",
        primary_effect  = []Action {},
    },
}
