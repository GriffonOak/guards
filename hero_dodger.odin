package guards

/// Dodger

// "While you are performing an action, all spaces\ncount as if they were in the battle zone and\nhad a friendly minion spawn point."

dodger_cards := []Card_Data {
    Card_Data { name = "Dread Razor",
        color =         .Gold,
        values =        #partial{.Initiative = 12, .Defense = 1, .Attack = 2, .Movement = 1, .Range = 3},
        primary =       .Attack,
        text =          "Choose one -\n* Target a unit adjacent to you.\n*If you are adjacent to an empty spawn point\nin the battle zone, target a unit in range",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "Choose one.",
                variant = Choice_Action {
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "In range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, 1},
                        },
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
            Action { variant = Halt_Action {} },  // 3
            Action {  // 4
                tooltip = "Target a unit in range.",
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                    }, 0,
                },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Range}},
                        },
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Death Trap",
        color =         .Silver,
        values =        #partial{.Initiative = 7, .Defense = 1, .Radius = 4},
        primary =       .Skill,
        text =          "An enemy hero in radius who is\nadjacent to an empty spawn point in\nthe battle zone discards a card, if able",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius adjacent to an empty spawn point in the battle zone.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Radius}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Targets {
                                Target_Within_Distance {
                                    origin = Previous_Target{},
                                    bounds = {1, 1},
                                },
                                Target_Empty{},
                                Target_Contains_Any{SPAWNPOINT_FLAGS},
                                Target_In_Battle_Zone{},
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
                tooltip = "Waiting for opponent to discard a card...",
                variant = Force_Discard_Action {
                    target = Previously_Chosen_Target{},
                },
            },
        },
    },
    Card_Data { name = "Littlefinger of Death",
        color =         .Red,
        tier =          1,
        values =        #partial{.Initiative = 9, .Defense = 5, .Attack = 4, .Movement = 4, .Range = 2},
        primary =       .Attack,
        text =          "Choose one -\n* Target a unit adjacent to you.\n*Target a hero in range who has one or\nmore cards in the discard.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose one:",
                variant = Choice_Action{
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "In range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, 1},
                        },
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
            Action { variant = Halt_Action {} },  // 3
            Action {  // 4
                tooltip = "Target a hero in range who has one or more cards in the discard.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Range}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Card_Targets{
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.Discarded},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Dark Ritual",
        color =         .Green,
        tier =          1,
        values =        #partial{.Initiative = 3, .Defense = 2, .Movement = 2, .Radius = 3},
        primary =       .Skill,
        text =          "If there are 2 or more empty spawn points\nin radius in the battle zone, gain 1 coin",
        primary_effect = []Action {
            Action {
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                    }, 1,
                },
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 1,
                },
            },
        },
    },
    Card_Data { name = "Shield of Decay",
        color =         .Blue,
        tier =          1,
        values =        #partial{.Initiative = 10, .Defense = 3, .Movement = 3, .Radius = 2},
        primary =       .Defense,
        primary_sign =  .Plus,
        text =          "+2 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    strength = Sum {
                        Card_Value{.Defense},
                        Minion_Modifiers{},
                        Ternary {
                            {2, 0},
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance {
                                        Self{}, {1, Card_Value{.Radius}},
                                    },
                                    Target_Empty{},
                                    Target_Contains_Any{SPAWNPOINT_FLAGS},
                                    Target_In_Battle_Zone{},
                                }, 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Finger of Death",
        color =         .Red,
        tier =          2,
        values =        #partial{.Initiative = 9, .Defense = 6, .Attack = 4, .Movement = 4, .Range = 3},
        primary =       .Attack,
        item =          .Initiative,
        text =          "Choose one -\n*Target a unit adjacent to you.\n*Target a hero in range who has one or\nmore cards in the discard.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose one:",
                variant = Choice_Action{
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "In range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, 1},
                        },
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
            Action { variant = Halt_Action {} },  // 3
            Action {  // 4
                tooltip = "Target a hero in range who has one or more cards in the discard.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Range}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Card_Targets{
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.Discarded},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Burning Skull",
        color =         .Red,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 9, .Defense = 5, .Attack = 3, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Defense,
        text =          "Target a unit in range. After the attack:\nMove up to 1 minion adjacent to you\n1 space, to a space not adjacent to you",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action {
                tooltip = "You may target a minion adjacent to you, or you may skip.",
                optional = true,
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space to a space not adjacent to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    min_distance = 1,
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance {Self{}, {2, 2}},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Darker Ritual",
        color =         .Green,
        tier =          2,
        values =        #partial{.Initiative = 3, .Defense = 2, .Movement = 2, .Radius = 3},
        primary =       .Skill,
        item =          .Defense,
        text =          "If there are 2 or more empty spawn points\nin radius in the battle zone, gain 2 coins",
        primary_effect = []Action {
            Action {
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                    }, 1,
                },
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 2,
                },
            },
        },
    },
    Card_Data { name = "Necromancy",
        color =         .Green,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 3, .Defense = 2, .Movement = 2},
        primary =       .Skill,
        item =          .Attack,
        text =          "Respawn a friendly minion in an empty friendly\nspawn point adjacent to you in the battle zone.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose an empty friendly spawn point adjacent to you in the battle zone.",
                condition = Greater_Than { My_Team_Total_Dead_Minions{}, 0 },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, 1}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                        Target_Is_Friendly_Spawnpoint{},
                    },
                },
            },
            Action {
                tooltip = "Choose which minion to respawn.",
                variant = Choose_Dead_Minion_Type_Action{},
            },
            Action {
                variant = Minion_Spawn_Action {
                    location = Previously_Chosen_Target{},
                    minion_type = Previously_Chosen_Dead_Minion{},
                },
            },
        },
    },
    Card_Data { name = "Vampiric Shield",
        color =         .Blue,
        tier =          2,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 2},
        primary =       .Defense,
        primary_sign =  .Plus,
        item =          .Initiative,
        text =          "+2 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    strength = Sum {
                        Card_Value{.Defense},
                        Minion_Modifiers{},
                        Ternary {
                            {2, 0},
                            Greater_Than {
                                Count_Targets {
                                    Target_Within_Distance {
                                        Self{}, {1, Card_Value{.Radius}},
                                    },
                                    Target_Empty{},
                                    Target_Contains_Any{SPAWNPOINT_FLAGS},
                                    Target_In_Battle_Zone{},
                                }, 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Weakness",
        color =         .Blue,
        tier =          2,
        alternate =     true,
        values =        #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 4},
        primary =       .Skill,
        item =          .Attack,
        text =          "This turn: Enemy heroes\nin radius have -4 Attack.\n(They can still attack, even with a negative attack value.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Dodger_Attack_Debuff,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Target_Within_Distance {Card_Owner{}, {1, Card_Value{.Radius}}},
                            Target_Contains_Any{{.Hero}},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Augment_Card_Value {
                                value_kind = .Attack,
                                augment = -4,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Middlefinger of Death",
        color =         .Red,
        tier =          3,
        values =        #partial{.Initiative = 10, .Defense = 6, .Attack = 5, .Movement = 4, .Range = 3},
        primary =       .Attack,
        item =          .Movement,
        text =          "Choose one, or both, on different targets -\n*Target a unit adjacent to you.\nTarget a hero in range who has one or\nmore cards in the discard",
        primary_effect = []Action {
            Action {
                tooltip = "Choose one:",
                optional = Greater_Than{Choices_Taken{}, 0},
                variant = Choice_Action{
                    choices = {
                        {name = "Adjacent", jump_index = {index = 1}},
                        {name = "In range", jump_index = {index = 4}},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, 1},
                        },
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                    flags = {.Not_Previously_Targeted},
                },
            },
            Action {  // 2
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action { variant = Jump_Action { jump_index = Action_Index{index = 0} } },  // 3
            Action {  // 4
                tooltip = "Target a hero in range who has one or more cards in the discard.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Value{.Range}},
                        },
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Card_Targets{
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.Discarded},
                            }, 0,
                        },
                    },
                    flags = {.Not_Previously_Targeted},
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
            Action { variant = Jump_Action { jump_index = Action_Index{index = 0} } },  // 6
        },
    },
    Card_Data { name = "Blazing Skull",
        color =         .Red,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 10, .Defense = 5, .Attack = 4, .Movement = 4, .Range = 2},
        primary =       .Attack,
        item =          .Radius,
        text =          "Target a unit in range. After the attack:\nMove up to 2 minions adjacent to you\n1 space, to spaces not adjacent to you",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, Card_Value{.Range}}},
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
                tooltip = "You may target a minion adjacent to you, or you may skip.",
                optional = true,
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space to a space not adjacent to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance {Self{}, {2, 2}},
                        },
                    },
                },
            },
            Action {
                tooltip = "You may target a minion adjacent to you, or you may skip.",
                optional = true,
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                    },
                },
            },
            Action {
                tooltip = "Move the minion 1 space to a space not adjacent to you.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 1,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance {Self{}, {2, 2}},
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Darkest Ritual",
        color =         .Green,
        tier =          3,
        values =        #partial{.Initiative = 2, .Defense = 3, .Movement = 2, .Radius = 3},
        primary =       .Skill,
        item =          .Defense,
        text =          "If there are 2 or more empty spawn points in\nradius in the battle zone, gain 2 coins. If you\nhave your Ultimate, gain an Attack item.",
        primary_effect = []Action {
            Action {
                condition = Greater_Than {
                    Count_Targets {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                    }, 1,
                },
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 2,
                },
            },
            Action {
                condition = Greater_Than{
                    My_Level{}, 8,
                },
                variant = Gain_Item_Action {
                    card_id = Card_ID{hero_id = .Dodger, color = .Red, tier = 5},
                },
            },
        },
    },
    Card_Data { name = "Necromastery",
        color =         .Green,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 2, .Defense = 3, .Movement = 2, .Radius = 1},
        primary =       .Skill,
        item =          .Range,
        text =          "Respawn a friendly minion in an empty friendly\nspawn point in radius in the battle zone.",
        primary_effect = []Action {
            Action {
                tooltip = "Choose an empty friendly spawn point adjacent to you in the battle zone.",
                condition = Greater_Than { My_Team_Total_Dead_Minions{}, 0 },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Empty{},
                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                        Target_In_Battle_Zone{},
                        Target_Is_Friendly_Spawnpoint{},
                    },
                },
            },
            Action {
                tooltip = "Choose which minion to respawn.",
                variant = Choose_Dead_Minion_Type_Action{},
            },
            Action {
                variant = Minion_Spawn_Action {
                    location = Previously_Chosen_Target{},
                    minion_type = Previously_Chosen_Dead_Minion{},
                },
            },
        },
    },
    Card_Data { name = "Aegis of Doom",
        color =         .Blue,
        tier =          3,
        values =        #partial{.Initiative = 11, .Defense = 4, .Movement = 3, .Radius = 2},
        primary =       .Defense,
        primary_sign =  .Plus,
        item =          .Initiative,
        text =          "+4 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Enfeeblement",
        color =         .Blue,
        tier =          3,
        alternate =     true,
        values =        #partial{.Initiative = 11, .Defense = 4, .Movement = 3, .Radius = 4},
        primary =       .Skill,
        item =          .Attack,
        text =          "This turn: Enemy heroes\nin radius have -6 Attack and cannot repeat actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Dodger_Attack_Debuff,
                        timing = Single_Turn(Card_Turn_Played{}),
                        affected_targets = {
                            Target_Within_Distance {Card_Owner{}, {1, Card_Value{.Radius}}},
                            Target_Contains_Any{{.Hero}},
                            Target_Is_Enemy_Of{Card_Owner{}},
                        },
                        outcomes = {
                            Augment_Card_Value {
                                value_kind = .Attack,
                                augment = -6,
                            },
                            Disallow_Action {
                                Action_Variant_At_Index_Is{Repeat_Action},
                            },
                        },
                    },
                },
            },
        },
    },



    Card_Data { name = "Attack Item",
        color =         .Red,
        tier =          5,
        item =          .Attack,
    },
}
