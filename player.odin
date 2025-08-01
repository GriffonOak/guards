package guards

Player_Stage :: enum {
    SELECTING,
    CONFIRMED,
    RESOLVING,
    RESOLVED,
    UPGRADING,
}

Player :: struct {
    stage: Player_Stage,
    cards: [Card_Color]^Card,
}

player: Player = {
    stage = .SELECTING
}