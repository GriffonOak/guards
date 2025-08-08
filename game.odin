package guards

import "core:fmt"
import rl "vendor:raylib"

import "core:log"

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

Active_Effect_ID :: enum {
    NONE,
    XARGATHA_STONE_GAZE,
}

Single_Turn :: int

Effect_Duration :: union {
    // End_Of_Turn,
    // End_Of_Round,
    Single_Turn,
}

Active_Effect :: struct {
    duration: Effect_Duration,
    target_set: Implicit_Target_Set,
    _criteria: [dynamic]Selection_Criterion
}

Active_Effect_Descriptor :: struct {
    id: Active_Effect_ID,
    duration_type: Effect_Duration,
    duration_value: Implicit_Quantity,
    target_set: Implicit_Target_Set
}

Game_State :: struct {
    num_players: int,
    players: [dynamic]^Player,
    minion_counts: [Team]int,
    confirmed_players: int,
    resolved_players,
    turn_counter: int,
    ongoing_active_effects: [Active_Effect_ID]Active_Effect,
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
        log.assert(spawnpoint_marker.spawnpoint_flag == .HERO_SPAWNPOINT)
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

        player.hero.coins = 0
        player.hero.level = 1

        player.hero.location = spawnpoint_marker.loc
    }
}

begin_game :: proc() {
    game_state.current_battle_zone = .CENTRE

    spawn_minions(game_state.current_battle_zone)

    spawn_heroes_at_start()

    append(&event_queue, Begin_Card_Selection_Event{})
}

defeat_minion :: proc(target: Target) {
    space := &board[target.x][target.y]
    minion := space.flags & MINION_FLAGS

    if .HEAVY_MINION in minion {
        player.hero.coins += 2
    } else {
        player.hero.coins += 2
    }

    remove_minion(target)
}

remove_minion :: proc(target: Target) {
    space := &board[target.x][target.y]
    if space.flags & MINION_FLAGS != {} {

    }
    minion_team := space.unit_team
    space.flags -= MINION_FLAGS
}