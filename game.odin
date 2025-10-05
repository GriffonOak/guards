package guards

// import "core:fmt"
import "core:math/rand"
import "core:log"
import "core:net"
import "core:sync"
import "core:strings"
import "core:reflect"
import "core:fmt"

_ :: rand

Direction :: enum {
    North,
    North_East,
    South_EAST,
    South,
    South_West,
    North_West,
}

Team :: enum {
    Red,
    Blue,
}

Game_Stage :: enum {
    Pre_Lobby,
    In_Lobby,
    Selection,
    Resolution,
    Minion_Battle,
    Upgrades,
}

Active_Effect_Kind :: enum {
    None,
    Xargatha_Freeze,
    Xargatha_Defeat,
    Swift_Delayed_Jump,
}

End_Of_Turn :: struct {
    extra_action_index: Action_Index,
}

End_Of_Round :: struct {
    extra_action_index: Action_Index,
}

Single_Turn :: Implicit_Quantity

Effect_Timing :: union {
    End_Of_Turn,
    End_Of_Round,
    Single_Turn,
}

Active_Effect_ID :: struct {
    kind: Active_Effect_Kind,
    parent_card_id: Card_ID,
}

Active_Effect :: struct {
    using id: Active_Effect_ID,

    timing: Effect_Timing,
    target_set: Selection_Criteria,
}

Wave_Push_Interrupt :: struct {
    pushing_team: Team,
}

Attack_Flag :: enum {
    Ranged,
    Disallow_Primary_Defense,
}

Attack_Flags :: bit_set[Attack_Flag]

Attack_Interrupt :: struct {
    strength: int,
    flags: Attack_Flags,
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
    using interrupt: Interrupt,
    previous_stage: Player_Stage,
    on_resolution: Event,
    global_resolution: bool,
    previous_action_index: Action_Index,
}

become_interrupted :: proc(
    gs: ^Game_State,
    interrupting_player_id: Player_ID,
    interrupt_variant: Interrupt_Variant,
    on_resolution: Event,
    global_resolution: bool = false,
) {
    interrupt := Interrupt {
        gs.my_player_id, interrupting_player_id,
        interrupt_variant,
    }
    append(&gs.interrupt_stack, Expanded_Interrupt {
        interrupt,
        get_my_player(gs).stage,
        on_resolution,
        global_resolution,
        get_my_player(gs).hero.current_action_index,
    })

    broadcast_game_event(gs, Begin_Interrupt_Event{interrupt})
}

Action_Value_Label :: enum {
    None,
    Attack_Target,
    Movement_Target,
    Place_Target,
}

Chosen_Quantity :: struct {
    quantity: int,
}

Repeat_Count :: struct {
    count: int,
}

Saved_Boolean :: struct {
    boolean: bool,
}

Action_Value_Variant :: union {
    Target,
    Path,
    Card_ID,
    Chosen_Quantity,
    Repeat_Count,
    Saved_Boolean,
}

Action_Value :: struct {
    action_index: Action_Index,
    action_count: int,
    label: Action_Value_Label,
    variant: Action_Value_Variant,
}


Game_State :: struct {
    players: [dynamic]Player,  // @Note: Might be better to use sa or fixed array here so entries don't move around (problem for username strings)
    my_player_id: Player_ID,
    team_captains: [Team]Player_ID,
    minion_counts: [Team]int,
    dead_minions: [Team][dynamic]Space_Flag,
    life_counters: [Team]int,
    heroes_defeated_this_round: int,
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
    action_count: int,
    action_memory: [dynamic]Action_Value,

    event_queue: [dynamic]Event,
    board: [GRID_WIDTH][GRID_HEIGHT]Space,
    
    tooltip: Tooltip,

    ui_stack: [UI_Domain][dynamic]UI_Element,
    toasts: [dynamic]Toast,

    side_button_manager: Side_Button_Manager,
    game_over: bool,

    is_host: bool,

    host_socket: net.TCP_Socket,

    net_queue_mutex: sync.Mutex,
    network_queue: [dynamic]Network_Packet,

    // Secret host global vars
    initiative_tied: bool,
    blocked_spawns: [Team][dynamic]Target,
}

@rodata
team_colors := [Team]Colour{
    .Red  = {237, 92, 2, 255},
    .Blue = {22, 147, 255, 255},
}

// Directed_Target :: [2]i8

@rodata
direction_vectors := [Direction]Target {
    .North = {0, 1},
    .North_East = {1, 0},
    .South_EAST = {1, max(u8)},
    .South = {0, max(u8)},
    .South_West = {max(u8), 0},
    .North_West = {max(u8), 1},
}

// lamayo
@rodata
num_life_counters := [?]int {
    0, 1, 1, 1, 2, 2, 2, 3, 3,
}

spawn_minions :: proc(gs: ^Game_State, zone: Region_ID) {
    for index in zone_indices[zone] {
        space := &gs.board[index.x][index.y]
        spawnpoint_flags := space.flags & (SPAWNPOINT_FLAGS - {.Hero_Spawnpoint})
        if spawnpoint_flags != {} {
            spawnpoint_type := get_first_set_bit(spawnpoint_flags).?

            minion_to_spawn := spawnpoint_to_minion[spawnpoint_type]
            // if minion_to_spawn == .Melee_Minion && space.spawnpoint_team == .Red do continue

            if (space.flags - {.Token}) & OBSTACLE_FLAGS != {} {
                broadcast_game_event(gs, Minion_Blocked_Event{index})
            } else {
                broadcast_game_event(gs, Minion_Spawn_Event{index, minion_to_spawn, space.spawnpoint_team})
            }
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
        log.assert(spawnpoint_marker.spawnpoint_flag == .Hero_Spawnpoint)
        spawnpoint_space: ^Space

        if team == .Blue {
            spawnpoint_space = get_symmetric_space(gs, spawnpoint_marker.loc)
            player.hero.location = {GRID_WIDTH, GRID_HEIGHT} - spawnpoint_marker.loc - 1
        } else {
            spawnpoint_space = &gs.board[spawnpoint_marker.loc.x][spawnpoint_marker.loc.y]
            player.hero.location = spawnpoint_marker.loc
        }

        spawnpoint_space.flags += {.Hero}
        spawnpoint_space.unit_team = team
        spawnpoint_space.hero_id = player.hero.id
        spawnpoint_space.owner = player_id

        player.hero.coins = 0
        player.hero.level = 1

    }
}

create_card_textures :: proc() {
    for &hero_deck in hero_cards {
        for &card in hero_deck {
            create_texture_for_card(&card)
        }
    }
}

setup_hero_cards :: proc(gs: ^Game_State) {

    // Do the heroes!
    hero_cards = {
        .Xargatha   = xargatha_cards,
        .Dodger     = dodger_cards,
        .Swift      = swift_cards,
        .Brogan     = brogan_cards,
        .Tigerclaw  = tigerclaw_cards,
        .Wasp       = wasp_cards,
        .Arien      = arien_cards,
        .Sabina     = sabina_cards,
    }

    for player_id in 0..<len(gs.players) {
        player := get_player_by_id(gs, player_id)
        hero_id := player.hero.id

        for &card, index in hero_cards[hero_id] {
            if card.background_image == {} {
                enum_name, _ := reflect.enum_name_from_value(card.color)
                enum_name = strings.to_lower(enum_name, context.temp_allocator)
                hero_name, _ := reflect.enum_name_from_value(hero_id)
                card_filename := fmt.tprintf(
                    "%v_t%v_%v%v.png",
                    strings.to_lower(string(hero_name), context.temp_allocator),
                    card.tier,
                    enum_name,
                    "_alt" if card.alternate else "",
                )
                // fmt.println(card_filename)
                for file in assets {
                    if file.name == card_filename {
                        card.background_image = load_texture_from_image(load_image_from_memory(".png", raw_data(file.data), i32(len(file.data))))
                        // fmt.printfln("Loaded swift card! %v", card_filename)
                    }
                }
            }
            if index >= 5 do continue
            player_card := &player.hero.cards[card.color]
            player_card.id = card.id
            player_card.state = .In_Hand
            player_card.hero_id = hero_id
            player_card.owner_id = player_id
        }
    }

when !ODIN_TEST {
    create_card_textures()
}
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
        if space.flags & {.Heavy_Minion} != {} {
            space.flags -= {.Immune}
        }
    }
}


add_pre_lobby_ui_elements :: proc (gs: ^Game_State) {
    clear(&gs.ui_stack[.Buttons])

    text_box_location := Rectangle {
        WIDTH / 2 - SELECTION_BUTTON_SIZE.x,
        (HEIGHT - BUTTON_PADDING) / 2 - 2 * SELECTION_BUTTON_SIZE.y,
        SELECTION_BUTTON_SIZE.x * 2,
        SELECTION_BUTTON_SIZE.y,
    }

    button_1_location := text_box_location
    button_1_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING


    button_2_location := button_1_location
    button_2_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING

    button_3_location := button_2_location
    button_3_location.y += SELECTION_BUTTON_SIZE.y + BUTTON_PADDING

    append(&gs.ui_stack[.Buttons], UI_Element {
        text_box_location, UI_Text_Box_Element {
            default_string = "Enter IP Address...",
        },
        text_box_input_proc,
        draw_text_box,
        {},
    })

    add_generic_button(gs, button_1_location, "Join Game", Join_Network_Game_Chosen_Event{})
    // add_generic_button(gs, button_2_location, "Join Local Game", Join_Local_Game_Chosen_Event{})
    add_generic_button(gs, button_3_location, "Host Game", Host_Game_Chosen_Event{})
}
