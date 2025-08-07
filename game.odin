package guards

import "core:fmt"
import rl "vendor:raylib"

Direction :: enum {
    NORTH,
    NORTH_EAST,
    SOUTH_EAST,
    SOUTH,
    SOUTH_WEST,
    NORTH_WEST,
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
    players: [dynamic]^Player,
    confirmed_players: int,
    resolved_players,
    turn_counter: int,
    stage: Game_Stage,
    current_battle_zone: Region_ID
}



game_state: Game_State = {
    num_players = 1, 
    confirmed_players = 0,
    stage = .SELECTION,
    current_battle_zone = .CENTRE,
}

team_colors := [Team]rl.Color{
    .NONE = rl.MAGENTA,
    .RED  = {237, 92, 2, 255},
    .BLUE = {22, 147, 255, 255},
}

direction_vectors := [Direction]IVec2 {
    .NORTH = {0, 1},
    .NORTH_EAST = {1, 0},
    .SOUTH_EAST = {1, -1},
    .SOUTH = {0, -1},
    .SOUTH_WEST = {-1, 0},
    .NORTH_WEST = {-1, 1}
}



spawn_minions :: proc(zone: Region_ID) {
    for index in zone_indices[zone] {
        space := &board[index.x][index.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT})
        if spawnpoint_flags != {} {
            spawnpoint_type := get_first_set_bit(spawnpoint_flags).?

            minion_to_spawn := spawnpoint_to_minion[spawnpoint_type]
            space.flags += {minion_to_spawn}
            space.unit_team = space.spawnpoint_team
        }

    }
}

spawn_heroes_at_start :: proc() {
    num_spawns: [Team]int
    for &player in game_state.players {
        team := player.team
        spawnpoint_marker := spawnpoints[num_spawns[team]]
        assert(spawnpoint_marker.spawnpoint_flag == .HERO_SPAWNPOINT)
        spawnpoint: ^Space
        if team == .BLUE {
            spawnpoint = get_symmetric_space(spawnpoint_marker.loc)
        } else {
            spawnpoint = &board[spawnpoint_marker.loc.x][spawnpoint_marker.loc.y]
        }

        spawnpoint.flags += {.HERO}
        spawnpoint.unit_team = team
        spawnpoint.hero_id = player.hero.id
        spawnpoint.owner = player

        player.hero.location = spawnpoint_marker.loc
    }
}

begin_game :: proc() {
    game_state.current_battle_zone = .CENTRE

    spawn_minions(game_state.current_battle_zone)

    spawn_heroes_at_start()
}
