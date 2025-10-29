package guards

import "core:fmt"
import "core:net"
import "core:reflect"
import "core:log"



Player_Stage :: enum {
    None,
    Selecting,
    Confirmed,
    Resolving,
    Resolved,
    Upgrading,
    Upgraded,

    Interrupting,
    Interrupted,
}

Hero_ID :: enum {
    Xargatha,
    Dodger,
    Swift,
    Brogan,
    Tigerclaw,
    Wasp,
    Arien,
    Sabina,
}

number_names := [?]string {
    "0", 
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "10",
}

hero_cards: [Hero_ID][]Card_Data

Marker :: enum {
    Tigerclaw_Weak_Poison,
    Tigerclaw_Strong_Poison,
}

Marker_Set :: bit_set[Marker]

Hero :: struct {
    id: Hero_ID,
    location: Target,
    cards: [Card_Color]Card,

    coins: int,
    level: int,
    dead: bool,
    items: [10]Card_ID,  // lol
    item_count: int,
    markers: Marker_Set,
    remaining_upgrades: int,

    current_action_index: Action_Index,
}

Player_ID :: int

// For sending over the network
Player_Base :: struct {
    id: Player_ID,
    _username_buf: [40]u8,
    team: Team,
    hero: Hero,
}

Player :: struct {
    using base: Player_Base,

    socket: net.TCP_Socket,  // For host use only
    stage: Player_Stage,
}

@(private="file")
TEXT_PADDING :: 6



player_offset :: proc(gs: ^Game_State, player_id: Player_ID) -> int {
    if player_id > gs.my_player_id do return player_id - 1
    return player_id
}

render_player_info :: proc(gs: ^Game_State) {
    // for _, player_id in gs.players {
    //     pos := Vec2{0, BOARD_POSITION_RECT.height} + TEXT_PADDING
    //     if player_id != gs.my_player_id {
    //         player_offset := player_offset(gs, player_id)
    //         x := BOARD_TEXTURE_SIZE.x + TEXT_PADDING + RESOLVED_CARD_WIDTH / 2
    //         y := TOOLTIP_FONT_SIZE + f32(player_offset) * BOARD_HAND_SPACE
    //         pos = {x, y}
    //     }
    //     render_player_info_at_position(gs, player_id, pos)
    // }
}

count_hero_items :: proc(gs: ^Game_State, hero: Hero, kind: Card_Value_Kind) -> (out: int) {
    for item_index in 0..<hero.item_count {
        card_id := hero.items[item_index]
        card_data, ok := get_card_data_by_id(gs, card_id)
        log.assert(ok, "Invalid item!")
        if card_data.item == kind do out += 1
    }
    return out
}

render_player_info_at_position :: proc(gs: ^Game_State, player_id: Player_ID, pos: Vec2) {
    next_pos := pos
    player := get_player_by_id(gs, player_id)
    context.allocator = context.temp_allocator
    name, _ := reflect.enum_name_from_value(player.hero.id)
    hero_name := fmt.ctprintf("[%v%v] %v", get_username(gs, player_id), "!" if gs.team_captains[player.team] == player_id else "", name)
    
    draw_text_ex(default_font, hero_name, next_pos, INFO_FONT_SIZE, FONT_SPACING, team_colors[player.team])
    next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    level_string := fmt.ctprintf("Level %v", player.hero.level)
    draw_text_ex(default_font, level_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, WHITE)
    next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    coins_string := fmt.ctprintf("%v coin%v", player.hero.coins, "" if player.hero.coins == 1 else "s")
    draw_text_ex(default_font, coins_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, WHITE)


    next_pos = pos
    next_pos.x += 250 // @Magic

    for kind, index in Card_Value_Kind {
        initial := item_initials[kind]
        item_string := fmt.ctprintf("+%v%v", count_hero_items(gs, player.hero, kind), initial)
        draw_text_ex(default_font, item_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, WHITE)
        next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

        if index == 2 {
            next_pos = pos
            next_pos.x += 350
        }
    }

    
}

add_or_update_player :: proc(gs: ^Game_State, player_base: Player_Base) {

    // Setup player
    if player_base.id >= len(gs.players) {
        resize(&gs.players, player_base.id + 1)
    }
    gs.players[player_base.id].base = player_base
    slice := get_ui_card_slice(gs, player_base.id)
    for &element in slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        card_element.card_id = player_base.hero.cards[card_element.card_id.color]
    }
}

get_username :: proc(gs: ^Game_State, player_id: Player_ID) -> cstring {
    return cstring(raw_data(gs.players[player_id]._username_buf[:]))
}

get_player_by_id :: proc(gs: ^Game_State, player_id: Player_ID) -> ^Player {
    if player_id >= len(gs.players) {
        return nil
    }
    return &gs.players[player_id]
}

get_my_player :: proc(gs: ^Game_State) -> ^Player {
    return get_player_by_id(gs, gs.my_player_id)
}