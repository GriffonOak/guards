package guards

Region_ID :: enum {
    NONE,
    RED_JUNGLE,
    RED_BASE,
    RED_BEACH,
    CENTRE,
    BLUE_BEACH,
    BLUE_BASE,
    BLUE_JUNGLE,
}

Team :: enum {
    NONE,
    RED,
    BLUE,
}

Game_Stage :: enum {
    SELECTION,
    RESOLUTION,
    UPGRADES,
}

Game_State :: struct {
    num_players: int,
    confirmed_players: int,
    stage: Game_Stage,
    current_battle_zone: Region_ID
}

game_state: Game_State = {
    1, 0,
    .SELECTION,
    .CENTRE,
}

begin_game :: proc() {
    
}
