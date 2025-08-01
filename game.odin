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

spawn_minions :: proc(zone: Region_ID) {
    for index in zone_indices[zone] {
        space := &board[index.x][index.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT})
        if spawnpoint_flags != {} {
            spawnpoint_type: Space_Flag
            for flag in minion_spawnpoint_array {
                if flag in spawnpoint_flags {
                    spawnpoint_type = flag
                    break
                }
            }

            minion_to_spawn := spawnpoint_to_minion[spawnpoint_type]
            space.flags += {minion_to_spawn}
            space.unit_team = space.spawnpoint_team
        }

    }
}

begin_game :: proc() {
    game_state.current_battle_zone = .CENTRE

    spawn_minions(game_state.current_battle_zone)
}
