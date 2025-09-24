package guards

/// DODGER

// "While you are performing an action, all spaces\ncount as if they were in the battle zone and\nhad a friendly minion spawn point."

dodger_cards := []Card_Data {
    Card_Data { name = "Dread Razor",
        color =         .GOLD,
        initiative =    12,
        values =        #partial{.DEFENSE = 1, .ATTACK = 2, .MOVEMENT = 1},
        primary =       .ATTACK,
        reach =         Range(3),
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
                    strength = Card_Value{.ATTACK},
                },
            },
            Action { variant = Halt_Action {} },  // 3
            Action {  // 4
                tooltip = "Target a unit in range.",
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, 1}},
                            Target_Empty,
                            Target_Contains_Any{SPAWNPOINT_FLAGS},
                            Target_In_Battle_Zone{},
                        },
                    }, 0,
                },
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Reach{}},
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
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Death Trap",
        color =         .SILVER,
        initiative =    7,
        values =        #partial{.DEFENSE = 1},
        primary =       .SKILL,
        reach =         Radius(4),
        text =          "An enemy hero in radius who is\nadjacent to an empty spawn point in\nthe battle zone discards a card, if able",
        primary_effect = []Action {
            Action {
                tooltip = "Target an enemy hero in radius adjacent to an empty spawn point in the battle zone.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance {
                            origin = Self{},
                            bounds = {1, Card_Reach{}},
                        },
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Targets {
                                conditions = {
                                    Target_Within_Distance {
                                        origin = Previous_Target{},
                                        bounds = {1, 1},
                                    },
                                    Target_Empty,
                                    Target_Contains_Any{SPAWNPOINT_FLAGS},
                                    Target_In_Battle_Zone{},
                                },
                            },
                            0,
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
        color =         .RED,
        tier =          1,
        initiative =    9,
        values =        #partial{.DEFENSE = 5, .ATTACK = 4, .MOVEMENT = 4},
        primary =       .ATTACK,
        reach =         Range(2),
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
                    strength = Card_Value{.ATTACK},
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
                            bounds = {1, Card_Reach{}},
                        },
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Card_Targets{
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.DISCARDED},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Dark Ritual",
        color =         .GREEN,
        tier =          1,
        initiative =    3,
        values =        #partial{.DEFENSE = 2, .MOVEMENT = 2},
        primary =       .SKILL,
        reach =         Radius(3),
        text =          "If there are 2 or more empty spawn points\nin radius in the battle zone, gain 1 coin",
        primary_effect = []Action {
            Action {
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, Card_Reach{}}},
                            Target_Empty,
                            Target_Contains_Any{SPAWNPOINT_FLAGS},
                            Target_In_Battle_Zone{},
                        },
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
        color =         .BLUE,
        tier =          1,
        initiative =    10,
        values =        #partial{.DEFENSE = 3, .MOVEMENT = 3},
        primary =       .DEFENSE,
        primary_sign =  .PLUS,
        reach =         Radius(2),
        text =          "+2 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    strength = Sum {
                        Card_Value{.DEFENSE},
                        Minion_Modifiers{},
                        Ternary {
                            {2, 0},
                            Greater_Than {
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance {
                                            Self{}, {1, Card_Reach{}},
                                        },
                                        Target_Empty,
                                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                                        Target_In_Battle_Zone{},
                                    },
                                }, 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Finger of Death",
        color =         .RED,
        tier =          2,
        initiative =    9,
        values =        #partial{.DEFENSE = 6, .ATTACK = 4, .MOVEMENT = 4},
        primary =       .ATTACK,
        reach =         Range(3),
        item =          .INITIATIVE,
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
                    strength = Card_Value{.ATTACK},
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
                            bounds = {1, Card_Reach{}},
                        },
                        Target_Contains_Any{{.HERO}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than{
                            Count_Card_Targets{
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.DISCARDED},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 5
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
        },
    },
    Card_Data { name = "Burning Skull",
        color =         .RED,
        tier =          2,
        alternate =     true,
        initiative =    9,
        values =        #partial{.DEFENSE = 5, .ATTACK = 3, .MOVEMENT = 4},
        primary =       .ATTACK,
        reach =         Range(2),
        item =          .DEFENSE,
        text =          "Target a unit in range. After the attack:\nMove up to 1 minion adjacent to you\n1 space, to a space not adjacent to you",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, Card_Reach{}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
            Action {
                tooltip = "You may target a minion adjacent to you, or you may skip.",
                optional = true,
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
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
    Card_Data { name = "Darker Ritual",
        color =         .GREEN,
        tier =          2,
        initiative =    3,
        values =        #partial{.DEFENSE = 2, .MOVEMENT = 2},
        primary =       .SKILL,
        reach =         Radius(3),
        item =          .DEFENSE,
        text =          "If there are 2 or more empty spawn points\nin radius in the battle zone, gain 2 coins",
        primary_effect = []Action {
            Action {
                condition = Greater_Than {
                    Count_Targets {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, Card_Reach{}}},
                            Target_Empty,
                            Target_Contains_Any{SPAWNPOINT_FLAGS},
                            Target_In_Battle_Zone{},
                        },
                    }, 1,
                },
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 2,
                },
            },
        },
    },
    Card_Data { name = "Necromancy",  // @Unimplemented
        color =         .GREEN,
        tier =          2,
        alternate =     true,
        initiative =    3,
        values =        #partial{.DEFENSE = 2, .MOVEMENT = 2},
        primary =       .SKILL,
        item =          .ATTACK,
        text =          "Respawn a friendly minion in an empty friendly\nspawn point adjacent to you in the battle zone.",
        primary_effect = []Action {
            // Action {
            //     tooltip = "Choose an empty friendly spawn point adjacent to you in the battle zone.",
            //     // condition = Greater_Than { Total_Dead_Minions{My_Team{}}, 0 },  @Todo
            //     variant = Choose_Target_Action {
            //         conditions = {
            //             Target_Within_Distance{Self{}, {1, 1}},
            //             Target_Empty,
            //             Target_Contains_Any{SPAWNPOINT_FLAGS},
            //             Target_In_Battle_Zone{},
            //             Target_Is_Friendly_Spawnpoint{},
            //         },
            //     },
            // },
            // Action {
            //     tooltip = "Choose which type of minion to respawn",
            //     variant = Choose_Minion_Type_Action {},  // ??????
            // },
            // Action {
            //     variant = Minion_Spawn_Action {
            //         location = Previous_Choice{},
            //         spawnpoint = Previous_Choice{},
            //     },
            // },
        },
    },
    Card_Data { name = "Vampiric Shield",
        color =         .BLUE,
        tier =          2,
        initiative =    10,
        values =        #partial{.DEFENSE = 0, .MOVEMENT = 3},  // @Todo find out what this actually is
        primary =       .DEFENSE,
        primary_sign =  .PLUS,
        reach =         Radius(2),
        item =          .INITIATIVE,
        text =          "+2 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {
            Action {
                variant = Defend_Action {
                    strength = Sum {
                        Card_Value{.DEFENSE},
                        Minion_Modifiers{},
                        Ternary {
                            {2, 0},
                            Greater_Than {
                                Count_Targets {
                                    conditions = {
                                        Target_Within_Distance {
                                            Self{}, {1, Card_Reach{}},
                                        },
                                        Target_Empty,
                                        Target_Contains_Any{SPAWNPOINT_FLAGS},
                                        Target_In_Battle_Zone{},
                                    },
                                }, 1,
                            },
                        },
                    },
                },
            },
        },
    },
    Card_Data { name = "Weakness",  // @Unimplemented
        color =         .BLUE,
        tier =          2,
        alternate =     true,
        initiative =    10,
        values =        #partial{.DEFENSE = 4, .MOVEMENT = 3},
        primary =       .SKILL,
        reach =         Radius(4),
        item =          .ATTACK,
        text =          "This turn: Enemy heroes\nin radius have -4 Attack.\n(They can still attack, even with a negative attack value.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Middlefinger of Death",  // @Unimplemented
        color =         .RED,
        tier =          3,
        initiative =    10,
        values =        #partial{.DEFENSE = 6, .ATTACK = 5, .MOVEMENT = 4},
        primary =       .ATTACK,
        reach =         Range(3),
        item =          .MOVEMENT,
        text =          "Choose one, or both, on different targets -\n*Target a unit adjacent to you.\nTarget a hero in range who has one or\nmore cards in the discard",
        primary_effect = []Action {},
    },
    Card_Data { name = "Blazing Skull",
        color =         .RED,
        tier =          3,
        alternate =     true,
        initiative =    10,
        values =        #partial{.DEFENSE = 5, .ATTACK = 4, .MOVEMENT = 4},
        primary =       .ATTACK,
        reach =         Range(2),
        item =          .RADIUS,
        text =          "Target a unit in range. After the attack:\nMove up to 2 minions adjacent to you\n1 space, to spaces not adjacent to you",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, Card_Reach{}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for the opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.ATTACK},
                },
            },
            Action {
                tooltip = "You may target a minion adjacent to you, or you may skip.",
                optional = true,
                variant = Choose_Target_Action {
                    conditions = {
                        Target_Within_Distance {Self{}, {1, 1}},
                        Target_Contains_Any{MINION_FLAGS},
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
    Card_Data { name = "Darkest Ritual",  // @Unimplemented
        color =         .GREEN,
        tier =          3,
        initiative =    2,
        values =        #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary =       .SKILL,
        reach =         Radius(3),
        item =          .DEFENSE,
        text =          "If there are 2 or more empty spawn points in\nradius in the battle zone, gain 2 coins. If you\nhave your Ultimate, gain an Attack item.\n(Use any spare card from the box with the corresponding icon.",
        primary_effect = []Action {
            
        },
    },
    Card_Data { name = "Necromastery",  // @Unimplemented
        color =         .GREEN,
        tier =          3,
        alternate =     true,
        initiative =    2,
        values =        #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary =       .SKILL,
        reach =         Radius(1),
        item =          .RANGE,
        text =          "Respawn a friendly minion in an empty friendly\nspawn point in radius in the battle zone.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Aegis of Doom",
        color =         .BLUE,
        tier =          3,
        initiative =    11,
        values =        #partial{.DEFENSE = 0, .MOVEMENT = 3},
        primary =       .DEFENSE,
        primary_sign =  .PLUS,
        reach =         Radius(2),
        item =          .INITIATIVE,
        text =          "+4 Defense if there are 2 or more empty\nspawn points in radius in the battle zone.",
        primary_effect = []Action {},
    },
    Card_Data { name = "Enfeeblement",  // @Unimplemented
        color =         .BLUE,
        tier =          3,
        alternate =     true,
        initiative =    11,
        values =        #partial{.DEFENSE = 4, .MOVEMENT = 3},
        primary =       .SKILL,
        reach =         Radius(4),
        item =          .ATTACK,
        text =          "This turn: Enemy heroes\nin radius have -6 Attack and cannot repeat actions.",
        primary_effect = []Action {},
    },
}
