package guards

// import "core:fmt"
import rl "vendor:raylib"
import "core:math/rand"
import "core:log"
import "core:net"
import "core:sync"

Direction :: enum {
    NORTH,
    NORTH_EAST,
    SOUTH_EAST,
    SOUTH,
    SOUTH_WEST,
    NORTH_WEST,
}

Team :: enum {
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

Active_Effect_Kind :: enum {
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

Active_Effect_ID :: struct {
    kind: Active_Effect_Kind,
    parent_card_id: Card_ID,
}

Active_Effect :: struct {
    using id: Active_Effect_ID,

    duration: Effect_Duration,
    target_set: []Selection_Criterion,
}

Wave_Push_Interrupt :: struct {
    pushing_team: Team,
}

Attack_Interrupt :: struct {
    strength: int,
    minion_modifiers: int,
}

Interrupt_Variant :: union {
    Action_Index,
    Wave_Push_Interrupt,
    Attack_Interrupt,
}

Interrupt :: struct {
    interrupted_player, interrupting_player: Player_ID,
    variant: Interrupt_Variant,
}

Expanded_Interrupt :: struct {
    interrupt: Interrupt,
    previous_stage: Player_Stage,
    on_resolution: Event,
    previous_action_index: Action_Index,
}

become_interrupted :: proc(gs: ^Game_State, interrupt: Interrupt, on_resolution: Event) {

    append(&gs.interrupt_stack, Expanded_Interrupt {
        interrupt, 
        get_my_player(gs).stage,
        on_resolution,
        get_my_player(gs).hero.current_action_index,
    })

    broadcast_game_event(gs, Begin_Interrupt_Event{interrupt})
}


Game_State :: struct {
    players: [dynamic]Player,  // @Note: Might be better to use sa or fixed array here so entries don't move around (problem for username strings)
    my_player_id: Player_ID,
    team_captains: [Team]Player_ID,
    minion_counts: [Team]int,
    life_counters: [Team]int,
    confirmed_players: int,
    // resolved_players: int,
    upgraded_players: int,
    turn_counter: int,
    wave_counters: int,
    tiebreaker_coin: Team,
    ongoing_active_effects: map[Active_Effect_Kind]Active_Effect,
    stage: Game_Stage,
    current_battle_zone: Region_ID,
    interrupt_stack: [dynamic]Expanded_Interrupt,

    event_queue: [dynamic]Event,
    board: [GRID_WIDTH][GRID_HEIGHT]Space,

    
    tooltip: Tooltip,

    ui_stack: [dynamic]UI_Element,

    side_button_manager: Side_Button_Manager,

    is_host: bool,

    host_socket: net.TCP_Socket,

    net_queue_mutex: sync.Mutex,
    network_queue: [dynamic]Network_Packet,

    // Secret host global vars
    initiative_tied: bool,
    blocked_spawns: [Team][dynamic]Target,
}

@rodata
team_colors := [Team]rl.Color{
    .RED  = {237, 92, 2, 255},
    .BLUE = {22, 147, 255, 255},
}

@rodata
direction_vectors := [Direction]Target {
    .NORTH = {0, 1},
    .NORTH_EAST = {1, 0},
    .SOUTH_EAST = {1, -1},
    .SOUTH = {0, -1},
    .SOUTH_WEST = {-1, 0},
    .NORTH_WEST = {-1, 1},
}

// lamayo
@rodata
num_life_counters := [?]int {
    0, 1, 1, 1, 2, 2, 2, 3, 3,
}

spawn_minions :: proc(gs: ^Game_State, zone: Region_ID) {
    for index in zone_indices[zone] {
        space := &gs.board[index.x][index.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.HERO_SPAWNPOINT})
        if spawnpoint_flags != {} {
            spawnpoint_type := get_first_set_bit(spawnpoint_flags).?

            minion_to_spawn := spawnpoint_to_minion[spawnpoint_type]
            // if minion_to_spawn == .MELEE_MINION && space.spawnpoint_team == .RED do continue

            if (space.flags - {.TOKEN}) & OBSTACLE_FLAGS != {} {
                broadcast_game_event(gs, Minion_Blocked_Event{index})
                continue
            }
            broadcast_game_event(gs, Minion_Spawn_Event{index, minion_to_spawn, space.spawnpoint_team})
        }
    }
    return
}

spawn_heroes_at_start :: proc(gs: ^Game_State) {
    num_spawns: [Team]int
    for &player, player_id in gs.players {
        team := player.team
        spawnpoint_marker := spawnpoints[num_spawns[team]]
        num_spawns[team] += 1
        log.assert(spawnpoint_marker.spawnpoint_flag == .HERO_SPAWNPOINT)
        spawnpoint_space: ^Space

        if team == .BLUE {
            spawnpoint_space = get_symmetric_space(gs, spawnpoint_marker.loc)
            player.hero.location = {GRID_WIDTH, GRID_HEIGHT} - spawnpoint_marker.loc - 1
        } else {
            spawnpoint_space = &gs.board[spawnpoint_marker.loc.x][spawnpoint_marker.loc.y]
            player.hero.location = spawnpoint_marker.loc
        }

        spawnpoint_space.flags += {.HERO}
        spawnpoint_space.unit_team = team
        spawnpoint_space.hero_id = player.hero.id
        spawnpoint_space.owner = player_id

        player.hero.coins = 0
        player.hero.level = 1

    }
}

setup_hero_cards :: proc(gs: ^Game_State) {
    // Do the heroes!
    hero_cards = {
        .XARGATHA = xargatha_cards,
    }

    for player_id in 0..<len(gs.players) {
        player := get_player_by_id(gs, player_id)
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

begin_game :: proc(gs: ^Game_State) {
    gs.current_battle_zone = .CENTRE
    gs.wave_counters = 5
    gs.life_counters[.RED] = 6
    gs.life_counters[.BLUE] = 6

    spawn_heroes_at_start(gs)

    setup_hero_cards(gs)

    if gs.is_host {
        tiebreaker: Team = .RED if rand.int31_max(2) == 0 else .BLUE
        broadcast_game_event(gs, Update_Tiebreaker_Event{tiebreaker})
        spawn_minions(gs, gs.current_battle_zone)
    }

    add_game_ui_elements(gs)

    append(&gs.event_queue, Begin_Card_Selection_Event{})
}

defeat_minion :: proc(gs: ^Game_State, target: Target) -> (will_interrupt: bool) {

    broadcast_game_event(gs, Minion_Defeat_Event{target, gs.my_player_id})

    return remove_minion(gs, target)
}

remove_minion :: proc(gs: ^Game_State, target: Target) -> (will_interrupt: bool) {
    space := &gs.board[target.x][target.y]
    log.assert(space.flags & MINION_FLAGS != {}, "Tried to remove a minion from a space with no minions!")
    minion_team := space.unit_team
    log.assert(gs.minion_counts[minion_team] > 0, "Removing a minion but the game state claims there are 0 minions")

    broadcast_game_event(gs, Minion_Removal_Event{target, gs.my_player_id})

    return gs.minion_counts[minion_team] <= 1
}

remove_heavy_immunity :: proc(gs: ^Game_State, team: Team) {
    zone := zone_indices[gs.current_battle_zone]
    for target in zone {
        space := &gs.board[target.x][target.y]
        if space.flags & {.HEAVY_MINION} != {} {
            space.flags -= {.IMMUNE}
        }
    }
}


add_choose_host_ui_elements :: proc (gs: ^Game_State) {
    clear(&gs.ui_stack)
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

    add_generic_button(gs, button_1_location, "Join Game", Join_Game_Chosen_Event{})
    add_generic_button(gs, button_2_location, "Host Game", Host_Game_Chosen_Event{})
}
