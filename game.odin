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
    PRE_LOBBY,
    IN_LOBBY,
    SELECTION,
    RESOLUTION,
    MINION_BATTLE,
    UPGRADES,
}

Active_Effect_ID :: enum {
    NONE,
    XARGATHA_FREEZE,
    XARGATHA_DEFEAT,
}

End_Of_Round :: struct {}

Single_Turn :: Implicit_Quantity

Effect_Duration :: union {
    // End_Of_Turn,
    End_Of_Round,
    Single_Turn,
}

Active_Effect :: struct {
    id: Active_Effect_ID,
    duration: Effect_Duration,
    target_set: Implicit_Target_Set,
    parent_card_id: Card_ID,
}

// Interrupt :: struct {
//     event_when_resolved: Event
// }


Game_State :: struct {
    players: [dynamic]Player,
    minion_counts: [Team]int,
    confirmed_players: int,
    resolved_players,
    turn_counter: int,
    wave_counters: int,
    ongoing_active_effects: map[Active_Effect_ID]Active_Effect,
    stage: Game_Stage,
    current_battle_zone: Region_ID,
    // current_interrupt: Interrupt,
}



game_state: Game_State = {
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
            // if minion_to_spawn == .RANGED_MINION && space.spawnpoint_team == .RED do continue
            space.flags += {minion_to_spawn}
            if minion_to_spawn == .HEAVY_MINION {
                space.flags += {.IMMUNE}
            }
            space.unit_team = space.spawnpoint_team
            game_state.minion_counts[space.spawnpoint_team] += 1
        }

    }
}

spawn_heroes_at_start :: proc() {
    num_spawns: [Team]int
    for &player, player_id in game_state.players {
        team := player.team
        spawnpoint_marker := spawnpoints[num_spawns[team]]
        num_spawns[team] += 1
        log.assert(spawnpoint_marker.spawnpoint_flag == .HERO_SPAWNPOINT)
        spawnpoint_space: ^Space

        if team == .BLUE {
            spawnpoint_space = get_symmetric_space(spawnpoint_marker.loc)
        } else {
            spawnpoint_space = &board[spawnpoint_marker.loc.x][spawnpoint_marker.loc.y]
        }

        spawnpoint_space.flags += {.HERO}
        spawnpoint_space.unit_team = team
        spawnpoint_space.hero_id = player.hero.id
        spawnpoint_space.owner = player_id

        player.hero.coins = 1
        player.hero.level = 1

        if player.team == .RED {
            player.hero.location = spawnpoint_marker.loc
        } else {
            player.hero.location = {GRID_WIDTH, GRID_HEIGHT} - spawnpoint_marker.loc - 1
        }
    }
}

setup_hero_cards :: proc() {
    for player_id in 0..<len(game_state.players) {
        player := get_player_by_id(player_id)
        hero_id := player.hero.id

        for &card, index in hero_cards[hero_id] {
            create_texture_for_card(&card)
            if index < 5 {
                player_card := &player.hero.cards[card.color]
                player_card^ = card
                player_card.state = .IN_HAND
                player_card.owner = player_id
            }
        }
    }
}

begin_game :: proc() {
    game_state.current_battle_zone = .CENTRE
    game_state.wave_counters = 5

    spawn_minions(game_state.current_battle_zone)

    spawn_heroes_at_start()

    setup_hero_cards()

    append(&event_queue, Begin_Card_Selection_Event{})
}

defeat_minion :: proc(target: Target) -> (will_interrupt: bool){
    space := &board[target.x][target.y]
    minion := space.flags & MINION_FLAGS
    log.assert(space.flags & MINION_FLAGS != {}, "Tried to defeat a minion in a space with no minions!")
    minion_team := space.unit_team

    if .HEAVY_MINION in minion {
        log.assert(game_state.minion_counts[minion_team] == 1, "Heavy minion defeated with an invalid number of minions left!")
        get_my_player().hero.coins += 4
    } else {
        get_my_player().hero.coins += 2
    }

    return remove_minion(target)
}

remove_minion :: proc(target: Target) -> (will_interrupt: bool) {
    space := &board[target.x][target.y]
    log.assert(space.flags & MINION_FLAGS != {}, "Tried to remove a minion from a space with no minions!")
    minion_team := space.unit_team
    log.assert(game_state.minion_counts[minion_team] > 0, "Removing a minion but the game state claims there are 0 minions")
    space.flags -= MINION_FLAGS

    game_state.minion_counts[minion_team] -= 1

    log.infof("Minion removed, new counts: %v", game_state.minion_counts)

    if game_state.minion_counts[minion_team] == 0 {
        append(&event_queue, Begin_Wave_Push_Event{get_enemy_team(minion_team)})
        return true
    } else if game_state.minion_counts[minion_team] == 1 {
        remove_heavy_immunity(minion_team)
    }
    return false
}

remove_heavy_immunity :: proc(team: Team) {
    zone := zone_indices[game_state.current_battle_zone]
    for target in zone {
        space := &board[target.x][target.y]
        if space.flags & {.HEAVY_MINION} != {} {
            space.flags -= {.IMMUNE}
        }
    }
}


add_choose_host_ui_elements :: proc () {
    clear(&ui_stack)
    button_1_location := rl.Rectangle {
        (WIDTH - SELECTION_BUTTON_SIZE.x) / 2,
        (HEIGHT - BUTTON_PADDING) / 2 - SELECTION_BUTTON_SIZE.y,
        SELECTION_BUTTON_SIZE.x,
        SELECTION_BUTTON_SIZE.y,
    }

    button_2_location := rl.Rectangle {
        (WIDTH - SELECTION_BUTTON_SIZE.x) / 2,
        (HEIGHT + BUTTON_PADDING) / 2,
        SELECTION_BUTTON_SIZE.x,
        SELECTION_BUTTON_SIZE.y,
    }

    add_generic_button(button_1_location, "Join Game", Join_Game_Chosen_Event{})
    add_generic_button(button_2_location, "Host Game", Host_Game_Chosen_Event{})
}
