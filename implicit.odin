package guards



Card_Creating_Effect :: struct {
    effect: Active_Effect_ID
}



/// COMMENT THIS UNION IN / OUT IN HERE & ACTION.ODIN FOR BUG
// Implicit_Card :: union {
//     ^Card,
//     Card_Creating_Effect,
// }


Card_Reach :: struct {
    card: Implicit_Card,
}

Card_Value :: struct {
    card: Implicit_Card,
    kind: Ability_Kind,
}

Sum :: []Implicit_Quantity

Count_Targets :: []Selection_Criterion

Turn_Played :: struct {
    card: Implicit_Card
}

Minion_Difference :: struct {}

Implicit_Quantity :: union {
    int,
    Card_Reach,
    Card_Value,
    Sum,
    Count_Targets,
    // Current_Turn,
    Turn_Played,
    Minion_Difference,
}






Greater_Than :: struct {
    term_1, term_2: Implicit_Quantity
}

And :: []Implicit_Condition

Primary_Is_Not :: struct {
    kind: Ability_Kind
}

Implicit_Condition :: union {
    bool,
    Greater_Than,
    Primary_Is_Not,
    And,
}


SMEM :: 42
