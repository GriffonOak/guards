package guards

/// XARGATHA

xargatha_cards := [?]Card {
    {
        name        = "Cleave",
        color       = .GOLD,
        initiative  = 11,
        tier        = 0,
        secondaries = #partial{.DEFENSE = 2, .MOVEMENT = 1},
        primary     = .ATTACK,
        value       = 4,
        text        = "Target a unit adjacent to you.\nAfter the attack: May repeat once\non a different enemy hero."
    },
    {
        name        = "Siren's Call",
        color       = .SILVER,
        initiative  = 3,
        tier        = 0,
        secondaries = #partial{.DEFENSE = 3},
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
        secondaries = #partial{.DEFENSE = 6, .MOVEMENT = 5},
        primary     = .ATTACK,
        value       = 5,  // @Todo figure out dependent values
        text        = "Target a unit adjacent to you. +1 Attack\nfor each other enemy unit adjacent to you."
    },
    {
        name        = "Charm",
        color       = .GREEN,
        initiative  = 5,
        tier        = 1,
        secondaries = #partial{.DEFENSE = 3},
        primary     = .MOVEMENT,
        value       = 2,
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
                    distance = Card_Primary_Value{},
                }
            },
            Action {  // 2
                optional = true,
                skip_index = 4,
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
                    distance = Card_Primary_Value{},
                }
            },
        }
    },
    {
        name        = "Stone Gaze",
        color       = .BLUE,
        initiative  = 9,
        tier        = 1,
        secondaries = #partial{.DEFENSE = 5, .MOVEMENT = 3},
        primary     = .SKILL,
        reach       = Radius(2),
        text        = "Next turn: Enemy heroes in radius count\nas both heroes and terrain, and cannot\nperform movement actions."
    }
}