package guards

// import "core:fmt"
import "core:math/rand"
import "core:log"
import "core:net"
import "core:sync"
import "core:strings"
import "core:reflect"
import "core:fmt"
import sa "core:container/small_array"

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

Game_Screen :: enum {
    Title,
    Lobby,
    Game,
}

Game_Stage :: enum {
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
    Swift_Farm,

    Arien_Spell_Break,
    Arien_Limit_Movement,
    Arien_Duelist,

    Dodger_Attack_Debuff,

    Wasp_Magnetic_Dagger,
    Wasp_Static_Barrier,

    Tigerclaw_Blend_Into_Shadows,

    Brogan_Bulwark,
    Brogan_Shield,

    Garrus_Howl,
}

End_Of_Turn :: struct {
    extra_action_index: Action_Index,
}

End_Of_Round :: struct {
    extra_action_index: Action_Index,
}

Single_Turn :: Implicit_Quantity

Round :: struct {}

Effect_Timing :: union {
    End_Of_Turn,
    End_Of_Round,
    Single_Turn,
    Round,
}

Active_Effect_ID :: struct {
    kind: Active_Effect_Kind,
    parent_card_id: Card_ID,
}

Disallow_Action :: []Implicit_Condition
Target_Counts_As :: struct {
    flags: Space_Flags,
}
Limit_Movement :: struct {
    limit: int,
    conditions: []Implicit_Condition,
}
Augment_Card_Value :: struct {
    value_kind: Card_Value_Kind,
    augment: int,
}
Interrupt_On_Defeat :: struct {
    interrupt_index: Action_Index,
}

// @Note: It would be nice to just have swift interrupt here
// with a Gain_Coins action, but I'm not sure how to handle
// two people interrupting a defeat at the same time 
// (Imagine brogan shield overlaps with swift farm)
Gain_Extra_Coins_On_Defeat :: struct {}

Active_Effect_Outcome :: union {
    Disallow_Action,
    Target_Counts_As,
    Limit_Movement,
    Augment_Card_Value,
    Gain_Extra_Coins_On_Defeat,
    Interrupt_On_Defeat,
}

Active_Effect :: struct {
    kind: Active_Effect_Kind,

    generating_cards: sa.Small_Array(4, Card_ID),
    timing: Effect_Timing,
    affected_targets: []Implicit_Condition,
    outcomes: []Active_Effect_Outcome,
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

    Arien_Dueling_Partner,
    Swift_Farm_Defeat_Count,
    Brogan_Prevent_Next_Minion_Removal,
}

Chosen_Quantity :: struct {
    quantity: int,
}

Choice_Taken :: struct {
    choice_index: int,
}

Repeat_Count :: struct {
    count: int,
}

Saved_Boolean :: struct {
    boolean: bool,
}

Saved_Integer :: struct {
    integer: int,
}

Chosen_Minion_Type :: struct {
    minion_type: Space_Flag,
}


// @Cleanup: seems to be some semantic overlap between this union and the labelling system.
// Might be better to trim this union down and rely more on labelling.
Action_Value_Variant :: union {
    Target,
    Path,
    Card_ID,
    Chosen_Quantity,
    Repeat_Count,
    Saved_Boolean,
    Saved_Integer,
    Choice_Taken,
    Chosen_Minion_Type,
}

Action_Value :: struct {
    action_index: Action_Index,
    action_count: int,
    label: Action_Value_Label,
    variant: Action_Value_Variant,
}

Game_Length :: enum {
    Quick,
    Long,
}

Preview_Mode :: enum {
    Self_Only,
    Partial,
    Full,
}


Game_State :: struct {
    players: [dynamic]Player,  // @Note: Might be better to use sa or fixed array here so entries don't move around (problem for username strings)
    my_player_id: Player_ID,
    team_captains: [Team]Player_ID,
    minion_counts: [Team]int,
    dead_minions: [Team][dynamic]Space_Flag,
    transcript: [dynamic]Transript_Entry,
    heroes_defeated_this_round: int,
    confirmed_players: int,
    // resolved_players: int,
    upgraded_players: int,
    round_counter: int,
    turn_counter: int,

    preview_mode: Preview_Mode,

    game_length: Game_Length,

    max_wave_counters: int,
    max_life_counters: int,

    wave_counters: int,
    life_counters: [Team]int,

    tiebreaker_coin: Team,
    ongoing_active_effects: map[Active_Effect_Kind]Active_Effect,
    screen: Game_Screen,
    stage: Game_Stage,
    current_battle_zone: Region_ID,
    interrupt_stack: [dynamic]Expanded_Interrupt,
    action_count: int,
    action_memory: [dynamic]Action_Value,
    global_memory: [dynamic]Action_Value,

    event_queue: [dynamic]Event,
    board: [GRID_WIDTH][GRID_HEIGHT]Space,
    
    tooltip: Tooltip,

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

// create_card_textures :: proc() {
//     for &hero_deck, hero_id in hero_cards {

//         for &card in hero_deck {
//             create_texture_for_card(&card, preview = false)
//             create_texture_for_card(&card, preview = true)
//         }
//     }
// }

setup_icons :: proc() {
    minion_images: [Space_Flag]Image

    for file in emoji {
        emoji_image := load_image_from_memory(".png", raw_data(file.data), i32(len(file.data)))
        image_flip_vertical(&emoji_image)
        emoji_texture := load_texture_from_image(emoji_image)
        set_texture_filter(emoji_texture, .BILINEAR)
        switch file.name {
        case "axe.png":                 hero_icons[.Brogan]     = emoji_texture
        case "goblin.png":              hero_icons[.Dodger]     = emoji_texture
        case "gun.png":                 hero_icons[.Swift]      = emoji_texture
        case "military-medal.png":      hero_icons[.Sabina]     = emoji_texture
        case "money-with-wings.png":    hero_icons[.Tigerclaw]  = emoji_texture
        case "skull.png":               hero_icons[.Wasp]       = emoji_texture
        case "snake.png":               hero_icons[.Xargatha]   = emoji_texture
        case "water-wave.png":          hero_icons[.Arien]      = emoji_texture
        case "dog-face.png":            hero_icons[.Garrus]     = emoji_texture

        case "file-box.png":            ui_icons[.File_Box]     = emoji_texture

        case "bow-and-arrow.png":
            minion_icons[.Ranged_Minion] = emoji_texture
            minion_images[.Ranged_Minion] = emoji_image
        case "dagger.png":
            minion_icons[.Melee_Minion] = emoji_texture
            minion_images[.Melee_Minion] = emoji_image
        case "moai.png":
            minion_icons[.Heavy_Minion] = emoji_texture
            minion_images[.Heavy_Minion] = emoji_image
        }
    }

    spawnpoint_flags := Space_Flags{.Heavy_Minion_Spawnpoint, .Melee_Minion_Spawnpoint, .Ranged_Minion_Spawnpoint}
    for spawnpoint_type in spawnpoint_flags {
        minion_type := spawnpoint_to_minion[spawnpoint_type]
        minion_image := minion_images[minion_type]
        spawnpoint_image := gen_image_colour(minion_image.width, minion_image.height, WHITE)

        num_pixels := spawnpoint_image.width * spawnpoint_image.height

        minion_image_data := cast([^]Colour) minion_image.data
        spawnpoint_image_data := cast([^]Colour) spawnpoint_image.data

        for i in 0..<num_pixels {
            spawnpoint_image_data[i].a = minion_image_data[i].a
        }

        // image_alpha_mask(&spawnpoint_image, minion_image)
        spawnpoint_texture := load_texture_from_image(spawnpoint_image)
        set_texture_filter(spawnpoint_texture, .BILINEAR)
        minion_icons[spawnpoint_type] = spawnpoint_texture
    }

    for file in icons {
        icon_image := load_image_from_memory(".png", raw_data(file.data), i32(len(file.data)))
        image_flip_vertical(&icon_image)
        icon_texture := load_texture_from_image(icon_image)
        set_texture_filter(icon_texture, .BILINEAR)
        switch file.name {
        case "attack.png":
            card_icons[.Attack] = icon_texture
            primary_icons[.Attack] = icon_texture
        case "defense.png":
            card_icons[.Defense] = icon_texture
            primary_icons[.Defense] = icon_texture
        case "initiative.png": card_icons[.Initiative] = icon_texture
        case "radius.png": card_icons[.Radius] = icon_texture
        case "movement.png":
            card_icons[.Movement] = icon_texture
            primary_icons[.Movement] = icon_texture
        case "range.png": card_icons[.Range] = icon_texture
        case "skill.png": primary_icons[.Skill] = icon_texture
        case "item_attack.png": item_icons[.Attack] = icon_texture
        case "item_defense.png": item_icons[.Defense] = icon_texture
        case "item_initiative.png": item_icons[.Initiative] = icon_texture
        case "item_range.png": item_icons[.Range] = icon_texture
        case "item_movement.png": item_icons[.Movement] = icon_texture
        case "item_radius.png": item_icons[.Radius] = icon_texture
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
        .Garrus     = garrus_cards,
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
                        image := load_image_from_memory(".png", raw_data(file.data), i32(len(file.data)))
                        image_flip_vertical(&image)
                        card.background_image = load_texture_from_image(image)
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
        when !ODIN_TEST {
            for &card in hero_cards[hero_id] {
                create_texture_for_card(&card, preview = false)
                create_texture_for_card(&card, preview = true)
            }
        }
    }
}

