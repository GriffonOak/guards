package guards

/// Bain

//  Ult: After you give a hero the Bounty marker, that hero discards a card, if able.

bain_cards := []Card_Data {
    Card_Data { name = "Dead or Alive",
        color           = .Gold,
        values          = #partial{.Initiative = 11, .Defense = 2, .Attack = 4, .Movement = 1, .Radius = 4},
        primary         = .Attack,
        text            = "Target a unit adjacent to you.\nAfter the attack: You may give an enemy\nhero in radius the Bounty marker.\nA hero with the Bounty marker spends\n1 additional Life counter when defeated.",
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
                tooltip = "You may give an enemy hero in radius the Bounty marker.",
                optional = true,
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                variant = Give_Marker_Action {
                    target = Player_ID_Of{Previously_Chosen_Target{}},
                    marker = .Bain_Bounty,
                },
            },
        },
    },
    Card_Data { name = "Get over here!",
        color           = .Silver,
        values          = #partial{.Initiative = 13, .Defense = 2, .Range = 4},
        primary         = .Skill,
        text            = "Target a unit in range and in a\nstraight line, with no obstacles between you\nand the target. Move the target towards you\nin a straight line, until you are adjacent.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range and in a straight line, with no obstacles in between.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Not{Target_Contains_Any{{.Cannot_Move}}},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Nothing_Between{Self{}, OBSTACLE_FLAGS},
                    },
                },
            },
            Action {
                tooltip = "Move the target towards you in a straight line, until you are adjacent.",
                variant = Movement_Action {
                    target = Previously_Chosen_Target{},
                    max_distance = 99,
                    destination_criteria = {
                        conditions = {
                            Target_Within_Distance{Self{}, {1, 1}},
                        },
                    },
                    flags = {.Straight_Line},
                },
            },
        },
    },
    Card_Data { name = "Light Crossbow",
        color           = .Red,
        tier            = 1,
        values          = #partial{.Initiative = 8, .Defense = 5, .Attack = 5, .Movement = 4, .Range = 2},
        primary         = .Attack,
        text            = "Target a unit in range and in a straight line,\nwith no units or terrain between you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range and in a straight line, with no units or terrain in between.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Nothing_Between{Self{}, UNIT_FLAGS + {.Terrain}},
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
    Card_Data { name = "Close Call",
        color           = .Green,
        tier            = 1,
        values          = #partial{.Initiative = 4, .Defense = 0, .Movement = 2},
        primary         = .Defense,
        text            = "If a hero in play has a Bounty marker,\nblock the attack and that hero\ngives the marker to you.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = And {
                        Marker_Deployed{.Bain_Bounty},
                        Not{Has_Marker{Self{}, .Bain_Bounty}},
                    },
                },
            },
            Action {
                variant = Give_Marker_Action {
                    target = Player_ID_Of{Self{}},
                    marker = .Bain_Bounty,
                },
            },
        },
    },
    Card_Data { name = "A Game of Chance",
        color           = .Blue,
        tier            = 1,
        values          = #partial{.Initiative = 9, .Defense = 4, .Movement = 3, .Radius = 2},
        primary         = .Skill,
        text            = "An enemy hero in radius with two or more\ncards in hand chooses one of those cards.\nGuess that card's color, then reveal it.\nIf you guessed correctly, discard that card;\notherwise you gain 1 coin.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target an enemy hero in radius with two or more cards in hand.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.In_Hand},
                            }, 1,
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "Waiting for opponent to choose a card...",
                variant = Force_Interrupt_Action {
                    target = Previously_Chosen_Target{},
                    action_index = Card_Primary{Current_Card{}, 7},
                },
            },
            Action {  // 2
                tooltip = "Guess the chosen card's color.",
                variant = Choose_Variable_Action {  // @Cleanup this is so stupid lol
                    label = .Bain_Color_Guess,
                    choices = {
                        {
                            name = "Red",
                            variable = int(Card_Color.Red),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Red},
                                }, 0,
                            },
                        },
                        {
                            name = "Green",
                            variable = int(Card_Color.Green),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Green},
                                }, 0,
                            },
                        },
                        {
                            name = "Blue",
                            variable = int(Card_Color.Blue),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Blue},
                                }, 0,
                            },
                        },
                        {
                            name = "Silver",
                            variable = int(Card_Color.Silver),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Silver},
                                }, 0,
                            },
                        },
                        {
                            name = "Gold",
                            variable = int(Card_Color.Gold),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Gold},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 3
                condition = Equal{Color_Of{Labelled_Global_Variable{.Bain_Color_Answer}}, Labelled_Local_Variable{.Bain_Color_Guess}},
                skip_index = {index = 5},
                variant = Discard_Card_Action {
                    card = Labelled_Global_Variable{.Bain_Color_Answer},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 1,
                },
            },
            Action {  // 6
                variant = Halt_Action{},
            },
            Action {  // 7
                tooltip = "Choose a card from your hand. If guessed correctly, it will be discarded.",
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.In_Hand},
                    },
                },
            },
            Action {  // 8
                variant = Save_Variable_Action {
                    variable = Implicit_Card_ID(Previous_Card_Choice{}),
                    global = true,
                    label = .Bain_Color_Answer,
                },
            },
        },
    },
    Card_Data { name = "Heavy Crossbow",
        color           = .Red,
        tier            = 2,
        values          = #partial{.Initiative = 8, .Defense = 5, .Attack = 5, .Movement = 4, .Range = 3},
        primary         = .Attack,
        item            = .Defense,
        text            = "Target a unit in range and in a straight line,\nwith no units or terrain between you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range and in a straight line, with no units or terrain in between.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Nothing_Between{Self{}, UNIT_FLAGS + {.Terrain}},
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
    Card_Data { name = "Hand Crossbow",
        color           = .Red,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 8, .Defense = 6, .Attack = 4, .Movement = 4, .Range = 3},
        primary         = .Attack,
        item            = .Initiative,
        text            = "Choose one -\n* Target a hero in range with\na Bounty marker.\n* Target a unit adjacent to you.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Choose one:",
                variant = Choice_Action {
                    choices = {
                        Choice {name = "Hero with bounty", jump_index = {index = 1}},
                        Choice {name = "Unit adjacent", jump_index = {index = 99}},
                    },
                },
            },
            Action {  // 1
                tooltip = "Target a hero in range with a Bounty marker.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Has_Marker{Current_Target{}, .Bain_Bounty},
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
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previously_Chosen_Target{},
                    strength = Card_Value{.Attack},
                },
            },
        },
    },
    Card_Data { name = "Narrow Escape",
        color           = .Green,
        tier            = 2,
        values          = #partial{.Initiative = 4, .Defense = 0, .Movement = 2},
        primary         = .Defense,
        item            = .Initiative,
        text            = "If a hero in play has a Bounty marker,\nblock the attack and retrieve the marker.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = And {
                        Marker_Deployed{.Bain_Bounty},
                        Not{Has_Marker{Self{}, .Bain_Bounty}},
                    },
                },
            },
            Action {
                variant = Give_Marker_Action {
                    target = -1,
                    marker = .Bain_Bounty,
                },
            },
        },
    },
    Card_Data { name = "Vantage Point",
        color           = .Green,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 4, .Defense = 3, .Movement = 2},
        primary         = .Movement,
        primary_sign    = .Plus,
        item            = .Attack,
        text            = "Ignore obstacles. If a hero in play has\na Bounty marker, +1 movement.",
        primary_effect  = []Action {
            Action {
                tooltip = "Move ignoring obstacles.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Sum {
                        Card_Value{.Movement},
                        Ternary {
                            {1, 0},
                            And {
                                Marker_Deployed{.Bain_Bounty},
                                Not{Has_Marker{Self{}, .Bain_Bounty}},
                            },
                        },
                    },
                    flags = {.Ignoring_Obstacles},
                },
            },
        },
    },
    Card_Data { name = "Dead Man's Hand",
        color           = .Blue,
        tier            = 2,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Defense,
        text            = "An enemy hero in radius with two or more\ncards in hand chooses one of those cards.\nGuess that card's color, then reveal it.\nIf you guessed correctly, discard that card;\notherwise you gain 2 coins.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target an enemy hero in radius with two or more cards in hand.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.In_Hand},
                            }, 1,
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "Waiting for opponent to choose a card...",
                variant = Force_Interrupt_Action {
                    target = Previously_Chosen_Target{},
                    action_index = Card_Primary{Current_Card{}, 7},
                },
            },
            Action {  // 2
                tooltip = "Guess the chosen card's color.",
                variant = Choose_Variable_Action {  // @Cleanup this is so stupid lol
                    label = .Bain_Color_Guess,
                    choices = {
                        {
                            name = "Red",
                            variable = int(Card_Color.Red),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Red},
                                }, 0,
                            },
                        },
                        {
                            name = "Green",
                            variable = int(Card_Color.Green),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Green},
                                }, 0,
                            },
                        },
                        {
                            name = "Blue",
                            variable = int(Card_Color.Blue),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Blue},
                                }, 0,
                            },
                        },
                        {
                            name = "Silver",
                            variable = int(Card_Color.Silver),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Silver},
                                }, 0,
                            },
                        },
                        {
                            name = "Gold",
                            variable = int(Card_Color.Gold),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Gold},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 3
                condition = Equal{Color_Of{Labelled_Global_Variable{.Bain_Color_Answer}}, Labelled_Local_Variable{.Bain_Color_Guess}},
                skip_index = {index = 5},
                variant = Discard_Card_Action {
                    card = Labelled_Global_Variable{.Bain_Color_Answer},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 2,
                },
            },
            Action {  // 6
                variant = Halt_Action{},
            },
            Action {  // 7
                tooltip = "Choose a card from your hand. If guessed correctly, it will be discarded.",
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.In_Hand},
                    },
                },
            },
            Action {  // 8
                variant = Save_Variable_Action {
                    variable = Implicit_Card_ID(Previous_Card_Choice{}),
                    global = true,
                    label = .Bain_Color_Answer,
                },
            },
        },
    },
    Card_Data { name = "Drinking Buddies",
        color           = .Blue,
        tier            = 2,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 4, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "You may have a hero in radius retrieve a\ndiscarded card. If they do, you may\nalso retrieve a discarded card.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "You may target a hero in radius with one or more cards in the discard.",
                optional = true,
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.Discarded},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "Waiting for the hero to retrieve a card.",
                variant = Force_Interrupt_Action {
                    target = Previously_Chosen_Target{},
                    action_index = Card_Primary{Current_Card{}, 5},
                },
            },
            Action {  // 2
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {  // 3
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a discarded card to retrieve.",
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {  // 6
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
        },
    },
    Card_Data { name = "Arbalest",
        color           = .Red,
        tier            = 3,
        values          = #partial{.Initiative = 9, .Defense = 6, .Attack = 6, .Movement = 4, .Range = 4},
        primary         = .Attack,
        item            = .Defense,
        text            = "Target a unit in range and in a straight line,\nwith no units or terrain between you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Target a unit in range and in a straight line, with no units or terrain in between.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{UNIT_FLAGS},
                        Target_Is_Enemy_Unit{},
                        Target_In_Straight_Line_With{Self{}},
                        Target_Nothing_Between{Self{}, UNIT_FLAGS + {.Terrain}},
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
    Card_Data { name = "Hunter-Seeker",
        color           = .Red,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 9, .Defense = 7, .Attack = 5, .Movement = 4, .Range = 3},
        primary         = .Attack,
        item            = .Movement,
        text            = "Choose one, or both, on different targets -\n* Target a hero in range with a Bounty\nmarker.\n* Target a unit adjacent to you.",
        primary_effect  = []Action {
            Action {
                tooltip = "Choose one:",
                optional = Greater_Than{Choices_Taken{}, 0},
                variant = Choice_Action{
                    choices = {
                        {name = "Hero with bounty", jump_index = {index = 1}},
                        {name = "Unit adjacent", jump_index = {index = 4}},
                    },
                    cannot_repeat = true,
                },
            },
            Action {  // 1
                tooltip = "Target a hero in range with a Bounty marker.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Range}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Has_Marker{Current_Target{}, .Bain_Bounty},
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
            Action {  // 3
                variant = Jump_Action { jump_index = Action_Index{index = 0} },
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
            Action {  // 3
                variant = Jump_Action { jump_index = Action_Index{index = 0} },
            },
        },
    },
    Card_Data { name = "Perfect Getaway",
        color           = .Green,
        tier            = 3,
        values          = #partial{.Initiative = 3, .Defense = 0, .Movement = 2},
        primary         = .Defense,
        item            = .Initiative,
        text            = "If a hero in play has a Bounty marker,\nblock the attack.",
        primary_effect  = []Action {
            Action {
                variant = Defend_Action {
                    block_condition = And {
                        Marker_Deployed{.Bain_Bounty},
                        Not{Has_Marker{Self{}, .Bain_Bounty}},
                    },
                },
            },
        },
    },
    Card_Data { name = "High Ground",
        color           = .Green,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 3, .Defense = 4, .Movement = 2},
        primary         = .Movement,
        primary_sign    = .Plus,
        item            = .Radius,
        text            = "Ignore obstacles. If a hero in play has\na Bounty marker, +2 movement.",
        primary_effect  = []Action {
            Action {
                tooltip = "Move ignoring obstacles.",
                variant = Movement_Action {
                    target = Self{},
                    max_distance = Sum {
                        Card_Value{.Movement},
                        Ternary {
                            {2, 0},
                            And {
                                Marker_Deployed{.Bain_Bounty},
                                Not{Has_Marker{Self{}, .Bain_Bounty}},
                            },
                        },
                    },
                    flags = {.Ignoring_Obstacles},
                },
            },
        },
    },
    Card_Data { name = "We're Not Done Yet!",
        color           = .Blue,
        tier            = 3,
        values          = #partial{.Initiative = 10, .Defense = 5, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Range,
        text            = "An enemy hero in radius with two or more\ncards in hand chooses one of those cards.\nGuess that card's color, then reveal it.\nIf you guessed correctly, discard that card;\notherwise may repeat once or gain 2 coins.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "Target an enemy hero in radius with two or more cards in hand.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Target_Is_Enemy_Unit{},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.In_Hand},
                            }, 1,
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "Waiting for opponent to choose a card...",
                variant = Force_Interrupt_Action {
                    target = Previously_Chosen_Target{},
                    action_index = Card_Primary{Current_Card{}, 9},
                },
            },
            Action {  // 2
                tooltip = "Guess the chosen card's color.",
                variant = Choose_Variable_Action {  // @Cleanup this is so stupid lol
                    label = .Bain_Color_Guess,
                    choices = {
                        {
                            name = "Red",
                            variable = int(Card_Color.Red),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Red},
                                }, 0,
                            },
                        },
                        {
                            name = "Green",
                            variable = int(Card_Color.Green),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Green},
                                }, 0,
                            },
                        },
                        {
                            name = "Blue",
                            variable = int(Card_Color.Blue),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Blue},
                                }, 0,
                            },
                        },
                        {
                            name = "Silver",
                            variable = int(Card_Color.Silver),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Silver},
                                }, 0,
                            },
                        },
                        {
                            name = "Gold",
                            variable = int(Card_Color.Gold),
                            valid = Greater_Than {
                                Count_Card_Targets{
                                    Card_Owner_Is{Previously_Chosen_Target{}},
                                    Card_State_Is{.In_Hand},
                                    Card_Color_Is{.Gold},
                                }, 0,
                            },
                        },
                    },
                },
            },
            Action {  // 3
                condition = Equal{Color_Of{Labelled_Global_Variable{.Bain_Color_Answer}}, Labelled_Local_Variable{.Bain_Color_Guess}},
                skip_index = {index = 5},
                variant = Discard_Card_Action {
                    card = Labelled_Global_Variable{.Bain_Color_Answer},
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "You may repeat once or gain two coins.",
                condition = Greater_Than{1, Repeat_Count{}},
                variant = Choice_Action {
                    choices = {
                        {name = "Gain coins", jump_index = {index = 6}},
                        {name = "Repeat once", jump_index = {index = 8}},
                    },
                },
            },
            Action {  // 6
                variant = Gain_Coins_Action {
                    target = Self{},
                    gain = 2,
                },
            },
            Action {  // 7
                variant = Halt_Action{},
            },
            Action {  // 8
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
            Action {  // 9
                tooltip = "Choose a card from your hand. If guessed correctly, it will be discarded.",
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.In_Hand},
                    },
                },
            },
            Action {  // 10
                variant = Save_Variable_Action {
                    variable = Implicit_Card_ID(Previous_Card_Choice{}),
                    global = true,
                    label = .Bain_Color_Answer,
                },
            },
        },
    },
    Card_Data { name = "Another One!",
        color           = .Blue,
        tier            = 3,
        alternate       = true,
        values          = #partial{.Initiative = 10, .Defense = 5, .Movement = 3, .Radius = 3},
        primary         = .Skill,
        item            = .Attack,
        text            = "You may have a hero in radius retrieve a\ndiscarded card. If they do, you may\nalso retrieve a discarded card.\nEnd of turn: May repeat once.",
        primary_effect  = []Action {
            Action {  // 0
                tooltip = "You may target a hero in radius with one or more cards in the discard.",
                optional = true,
                skip_index = {index = 4},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    conditions = {
                        Target_Within_Distance{Self{}, {1, Card_Value{.Radius}}},
                        Target_Contains_Any{{.Hero}},
                        Greater_Than {
                            Count_Card_Targets {
                                Card_Owner_Is{Current_Target{}},
                                Card_State_Is{.Discarded},
                            }, 0,
                        },
                    },
                },
            },
            Action {  // 1
                tooltip = "Waiting for the hero to retrieve a card.",
                variant = Force_Interrupt_Action {
                    target = Previously_Chosen_Target{},
                    action_index = Card_Primary{Current_Card{}, 7},
                },
            },
            Action {  // 2
                tooltip = "You may retrieve a discarded card.",
                optional = true,
                skip_index = {index = 4},
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {  // 3
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
            Action {  // 4
                condition = Greater_Than{1, Repeat_Count{}},
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .Bain_Another_One,
                        timing = End_Of_Turn {
                            extra_action_index = {index = 6},
                        },
                    },
                },
            },
            Action {  // 5
                variant = Halt_Action{},
            },
            Action {  // 6
                variant = Repeat_Action {
                    max_repeats = 1,
                },
            },
            Action {  // 7
                tooltip = "Choose a discarded card to retrieve.",
                variant = Choose_Card_Action {
                    criteria = {
                        Card_Owner_Is{Self{}},
                        Card_State_Is{.Discarded},
                    },
                },
            },
            Action {  // 8
                variant = Retrieve_Card_Action {
                    card = Previous_Card_Choice{},
                },
            },
        },
    },
}
