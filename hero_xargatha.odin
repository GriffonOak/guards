package guards

// XARGATHA

xargatha_cards := []Card {
    Card { name = "Cleave",
        color       = .GOLD,
        initiative  = 11,
        values      = #partial{.ATTACK = 4, .DEFENSE = 2, .MOVEMENT = 1},
        primary     = .ATTACK,
        text        = "Target a unit adjacent to you.\nAfter the attack: May repeat once\non a different enemy hero.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{kind=.ATTACK},
                },
            },
            Action {
                tooltip = "May repeat once on a different enemy hero.",
                optional = true,
                skip_index = {sequence=.HALT},
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                        Contains_Any({.HERO}),
                        Is_Enemy_Unit{},
                        Not_Previously_Targeted{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{kind=.ATTACK},
                },
            },
        },
    },
    Card { name = "Siren's Call",
        color       = .SILVER,
        initiative  = 3,
        values      = #partial{.DEFENSE = 3},
        primary     = .SKILL,
        reach       = Range(3),
        text        = "Target an enemy unit not adjacent to you\nand in range; if able, move the target\nup to 3 spaces to a space adjacent to you.",
        primary_effect = []Action {
            Action { 
                tooltip = "Target an enemy unit not adjacent to you and in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 2,
                            max = Card_Reach{},
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Move the target up to 3 spaces to a space adjacent to you.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 3,
                    valid_destinations = []Selection_Criterion {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                    },
                },
            },
        },
    },
    Card { name = "Threatening Slash",
        color       = .RED,
        initiative  = 7,
        tier        = 1,
        values      = #partial{.ATTACK = 5, .DEFENSE = 6, .MOVEMENT = 5},
        primary     = .ATTACK,
        primary_sign = .PLUS,
        text        = "Target a unit adjacent to you. +1 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Sum {
                        Card_Value{kind=.ATTACK}, 
                        Count_Targets {
                            Within_Distance {
                                origin = Self{},
                                min = 1,
                                max = 1,
                            },
                            Contains_Any(UNIT_FLAGS),
                            Is_Enemy_Unit{},
                            Ignoring_Immunity{},
                        },
                        -1,
                    },
                },
            },
        },
    },
    Card { name = "Charm",
        color       = .GREEN,
        initiative  = 5,
        tier        = 1,
        values      = #partial{.MOVEMENT = 2, .DEFENSE = 3},
        primary     = .MOVEMENT,
        reach       = Radius(2),
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
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
            Action {  // 2
                optional = true,
                skip_index = {sequence=.HALT},
                tooltip = "You may choose a ranged minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION}),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a ranged minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION}),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
        },
    },
    Card { name = "Stone Gaze",
        color       = .BLUE,
        initiative  = 9,
        tier        = 1,
        values      = #partial{.DEFENSE = 5, .MOVEMENT = 3},
        primary     = .SKILL,
        reach       = Radius(2),
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .XARGATHA_FREEZE,
                        duration = Single_Turn(Sum{Turn_Played{}, 1}),
                        target_set = []Selection_Criterion {
                            Within_Distance {
                                Card_Owner{},
                                1,
                                Card_Reach{},
                            },
                            Contains_Any({.HERO}),
                            Is_Enemy_Of{Card_Owner{}},
                        },
                    },
                },
            },
        },
    },
    Card { name = "Deadly Swipe",
        color       = .RED,
        initiative  = 8,
        tier        = 2,
        values      = #partial{.ATTACK = 5, .DEFENSE = 7, .MOVEMENT = 5},
        primary     = .ATTACK,
        primary_sign = .PLUS,
        item        = .INITIATIVE,
        text        = "Target a unit adjacent to you. +2 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Sum {
                        Card_Value{kind=.ATTACK},
                        Product {
                            Sum {
                                Count_Targets {
                                    Within_Distance {
                                        origin = Self{},
                                        min = 1,
                                        max = 1,
                                    },
                                    Contains_Any(UNIT_FLAGS),
                                    Is_Enemy_Unit{},
                                    Ignoring_Immunity{},
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
    Card { name = "Long Thrust",
        color       = .RED,
        initiative  = 8,
        tier        = 2,
        alternate   = true,
        values      = #partial{.ATTACK = 3, .DEFENSE = 4, .MOVEMENT = 4},
        primary     = .ATTACK,
        reach       = Range(1),
        reach_sign  = .PLUS,
        item        = .DEFENSE,
        text        = "Target a unit in range. +1 Range\nfor each enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Sum {
                                Card_Reach{},
                                Count_Targets {
                                    Within_Distance {
                                        origin = Self{},
                                        min = 1,
                                        max = 1,
                                    },
                                    Contains_Any(UNIT_FLAGS),
                                    Is_Enemy_Unit{},
                                    Ignoring_Immunity{},
                                },
                            },
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{kind=.ATTACK},
                },
            },
        },
    },
    Card { name = "Control",
        color       = .GREEN,
        initiative  = 4,
        tier        = 2,
        values      = #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary     = .MOVEMENT,
        reach       = Radius(2),
        item        = .ATTACK,
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
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
            Action {  // 2
                optional = true,
                skip_index = {sequence=.HALT},
                tooltip = "You may choose a ranged or melee minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION, .MELEE_MINION}),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a ranged or melee minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION, .MELEE_MINION}),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
        },
    },
    Card { name = "Constrict",  // @incomplete
        color       = .GREEN,
        initiative  = 4,
        tier        = 2,
        alternate   = true,
        values      = #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary     = .SKILL,
        item        = .INITIATIVE,
        text        = "End of round: Defeat an enemy\nmelee minion adjacent to you.",
        primary_effect = []Action {
            // Action {
            //     tooltip = error_tooltip,
            //     variant = Add_Active_Effect_Action {
            //         effect = Active_Effect {
            //             kind = .XARGATHA_DEFEAT,
            //             duration = End_Of_Round{},
            //         },
            //     },
            // },
            // Action {
            //     variant = Halt_Action{},
            // },
        },
    },
    Card { name = "Petrifying Stare",
        color       = .BLUE,
        initiative  = 10,
        tier        = 2,
        values      = #partial{.DEFENSE = 6, .MOVEMENT = 3},
        primary     = .SKILL,
        reach       = Radius(3),
        item        = .DEFENSE,
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .XARGATHA_FREEZE,
                        duration = Single_Turn(Sum{Turn_Played{}, 1}),
                    },
                },
            },
        },
    },
    Card { name = "Fresh Converts",  // @incomplete
        color       = .BLUE,
        initiative  = 10,
        tier        = 2,
        alternate   = true,
        values      = #partial{.DEFENSE = 6, .MOVEMENT = 3},
        primary     = .SKILL,
        item        = .ATTACK,
        text        = "If you are adjacent to an enemy minion,\nyou may retrieve a discarded card.",\
        primary_effect = []Action {
            // Action {
            //     tooltip = "Choose a discarded card to retrieve.",
            //     optional = true,
            //     variant = Choose_Card_Action{},
            // },
            // Action {
            //     tooltip = error_tooltip,
            //     variant = Retrieve_Card_Action{},
            // },
        },
    },
    Card { name = "Lethal Spin",
        color       = .RED,
        initiative  = 8,
        tier        = 3,
        values      = #partial{.ATTACK = 5, .DEFENSE = 7, .MOVEMENT = 5},
        primary     = .ATTACK,
        primary_sign = .PLUS,
        item        = .RADIUS,
        text        = "Target a unit adjacent to you. +2 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1,
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Sum {
                        Card_Value{kind=.ATTACK},
                        Product {
                            Sum {
                                Count_Targets {
                                    Within_Distance {
                                        origin = Self{},
                                        min = 1,
                                        max = 1,
                                    },
                                    Contains_Any(UNIT_FLAGS),
                                    Is_Enemy_Unit{},
                                    Ignoring_Immunity{},
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
    Card { name = "Rapid Thrusts",
        color       = .RED,
        initiative  = 8,
        tier        = 2,
        alternate   = true,
        values      = #partial{.ATTACK = 3, .DEFENSE = 4, .MOVEMENT = 4},
        primary     = .ATTACK,
        reach       = Range(1),
        reach_sign  = .PLUS,
        item        = .DEFENSE,
        text        = "Target a unit in range. +1 Range\nfor each enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit in range.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Sum {
                                Card_Reach{},
                                Count_Targets {
                                    Within_Distance {
                                        origin = Self{},
                                        min = 1,
                                        max = 1,
                                    },
                                    Contains_Any(UNIT_FLAGS),
                                    Is_Enemy_Unit{},
                                    Ignoring_Immunity{},
                                },
                            },
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{kind=.ATTACK},
                },
            },
            Action {
                tooltip = "May repeat once on a different enemy hero.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Sum {
                                Card_Reach{},
                                Count_Targets {
                                    Within_Distance {
                                        origin = Self{},
                                        min = 1,
                                        max = 1,
                                    },
                                    Contains_Any(UNIT_FLAGS),
                                    Is_Enemy_Unit{},
                                    Ignoring_Immunity{},
                                },
                            },
                        },
                        Contains_Any({.HERO}),
                        Is_Enemy_Unit{},
                        Not_Previously_Targeted{},
                    },
                },
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{kind=.ATTACK},
                },
            },
        },
    },
    Card { name = "Dominate",
        color       = .GREEN,
        initiative  = 4,
        tier        = 3,
        values      = #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary     = .MOVEMENT,
        reach       = Radius(2),
        item        = .ATTACK,
        text        = "Before or after movement, you may move\nan enemy minion in radius up to 2 spaces;\nignore heavy minion immunity.",
        primary_effect = []Action {
            Action {  // 0
                tooltip = "You may either move yourself or a minion.",
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
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
            Action {  // 2
                optional = true,
                skip_index = {sequence=.HALT},
                tooltip = "You may choose a minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any(MINION_FLAGS),
                        Is_Enemy_Unit{},
                        Ignoring_Immunity{},
                    },
                },
            },
            Action {  // 3
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 4
                variant = Halt_Action{},
            },
            Action {  // 5
                tooltip = "Choose a minion to move.",
                variant = Choose_Target_Action {
                    num_targets = 1,
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any(MINION_FLAGS),
                        Is_Enemy_Unit{},
                        Ignoring_Immunity{},
                    },
                },
            },
            Action {  // 6
                tooltip = "Move the minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                },
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    distance = Card_Value{kind=.MOVEMENT},
                },
            },
        },
    },
    Card { name = "Final Embrace",  // @incomplete
        color       = .GREEN,
        initiative  = 4,
        tier        = 3,
        alternate   = true,
        values      = #partial{.DEFENSE = 3, .MOVEMENT = 2},
        primary     = .SKILL,
        item        = .INITIATIVE,
        text        = "End of round: Defeat an enemy\nmelee minion adjacent to you.",
        primary_effect = []Action {
            // Action {
            //     tooltip = error_tooltip,
            //     variant = Add_Active_Effect_Action {
            //         effect = Active_Effect {
            //             kind = .XARGATHA_DEFEAT,
            //             duration = End_Of_Round{},
            //         },
            //     },
            // },
            // Action {
            //     variant = Halt_Action{},
            // },
        },
    },
    Card { name = "Turn Into Statues",
        color       = .BLUE,
        initiative  = 10,
        tier        = 3,
        values      = #partial{.DEFENSE = 6, .MOVEMENT = 3},
        primary     = .SKILL,
        reach       = Radius(4),
        item        = .DEFENSE,
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = []Action {
            Action {
                tooltip = error_tooltip,
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect {
                        kind = .XARGATHA_FREEZE,
                        duration = Single_Turn(Sum{Turn_Played{}, 1}),
                    },
                },
            },
        },
    },
    Card { name = "Devoted Followers",  // @incomplete
        color       = .BLUE,
        initiative  = 10,
        tier        = 2,
        alternate   = true,
        values      = #partial{.DEFENSE = 6, .MOVEMENT = 3},
        primary     = .SKILL,
        item        = .ATTACK,
        text        = "If you are adjacent to an enemy minion,\nyou may retrieve a discarded card.",\
        primary_effect = []Action {
            // Action {
            //     tooltip = "Choose a discarded card to retrieve.",
            //     optional = true,
            //     variant = Choose_Card_Action{},
            // },
            // Action {
            //     tooltip = error_tooltip,
            //     variant = Retrieve_Card_Action{},
            // },
        },
    },
}