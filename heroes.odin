package guards

/// XARGATHA

smem := Card_Reach{&xargatha_cards[4]}

xargatha_cards := [?]Card {
    {
        name        = "Cleave",
        color       = .GOLD,
        initiative  = 11,
        tier        = 0,
        values      = #partial{.ATTACK = 4, .DEFENSE = 2, .MOVEMENT = 1},
        primary     = .ATTACK,
        text        = "Target a unit adjacent to you.\nAfter the attack: May repeat once\non a different enemy hero.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    }
                }
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{.ATTACK},
                }
            },
            Action {
                tooltip = "May repeat once on a different enemy hero.",
                optional = true,
                skip_index = -1,
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1
                        },
                        Contains_Any({.HERO}),
                        Is_Enemy_Unit{},
                        Not_Previously_Targeted{},
                    }
                }
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Card_Value{.ATTACK},
                }
            },
        }
    },
    {
        name        = "Siren's Call",
        color       = .SILVER,
        initiative  = 3,
        tier        = 0,
        values      = #partial{.DEFENSE = 3},
        primary     = .SKILL,
        reach       = Range(3),
        text        = "Target an enemy unit not adjacent to you\nand in range; if able, move the target\nup to 3 spaces to a space adjacent to you.",
        primary_effect = []Action {
            Action { 
                tooltip = "Target an enemy unit not adjacent to you and in range.",
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 2,
                            max = Card_Reach{},
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    }
                }
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
                        }
                    }
                }
            }
        }
    },
    {
        name        = "Threatening Slash",
        color       = .RED,
        initiative  = 7,
        tier        = 1,
        values      = #partial{.ATTACK = 5, .DEFENSE = 6, .MOVEMENT = 5},
        primary     = .ATTACK,
        primary_sign = PLUS_SIGN,
        text        = "Target a unit adjacent to you. +1 Attack\nfor each other enemy unit adjacent to you.",
        primary_effect = []Action {
            Action {
                tooltip = "Target a unit adjacent to you.",
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self{},
                            min = 1,
                            max = 1
                        },
                        Contains_Any(UNIT_FLAGS),
                        Is_Enemy_Unit{},
                    }
                }
            },
            Action {
                tooltip = "Waiting for opponent to defend...",
                variant = Attack_Action {
                    target = Previous_Choice{},
                    strength = Sum {
                        Card_Value{.ATTACK}, 
                        Count_Targets {
                            Within_Distance {
                                origin = Self{},
                                min = 1,
                                max = 1
                            },
                            Contains_Any(UNIT_FLAGS),
                            Is_Enemy_Unit{},
                        },
                        -1
                    }
                }
            },
        }
    },
    {
        name        = "Charm",
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
                        {"Move self", 1},
                        {"Move minion", 5},
                    },
                }
            },
            Action {  // 1
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    distance = Card_Value{.MOVEMENT},
                }
            },
            Action {  // 2
                optional = true,
                skip_index = -1,
                tooltip = "You may choose a ranged minion to move, or you may skip.",
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self {},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION}),
                        Is_Enemy_Unit{},
                    }
                }
            },
            Action {  // 3
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                }
            },
            Action {  // 4
                variant = Halt_Action{}
            },
            Action {  // 5
                tooltip = "Choose a ranged minion to move.",
                variant = Choose_Target_Action {
                    criteria = {
                        Within_Distance {
                            origin = Self {},
                            min = 1,
                            max = Card_Reach{},
                        },
                        Contains_Any({.RANGED_MINION}),
                        Is_Enemy_Unit{},
                    }
                }
            },
            Action {  // 6
                tooltip = "Move the ranged minion up to 2 spaces.",
                variant = Movement_Action {
                    target = Previous_Choice{},
                    distance = 2,
                }
            },
            Action {  // 7
                tooltip = player_movement_tooltip,
                variant = Movement_Action {
                    target = Self{},
                    distance = Card_Value{.MOVEMENT},
                }
            },
        }
    },
    {
        name        = "Stone Gaze",
        color       = .BLUE,
        initiative  = 9,
        tier        = 1,
        values      = #partial{.DEFENSE = 5, .MOVEMENT = 3},
        primary     = .SKILL,
        reach       = Radius(2),
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions.",
        primary_effect = {
            Action {
                tooltip = "You should never see this.",
                variant = Add_Active_Effect_Action {
                    effect = Active_Effect_Descriptor {
                        id = .XARGATHA_FREEZE,
                        duration = Single_Turn(Sum{Current_Turn{}, 1}),
                        target_set = []Selection_Criterion {
                            Within_Distance {
                                Self{},  // @Note Self is not technically correct here, needs to *always* target xargatha
                                0,
                                smem,
                            },
                            Contains_Any({.HERO}),
                            // Is_Enemy_Unit{}
                        }
                    }
                }
            }
        }
    }
}