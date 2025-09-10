package guards

import "core:fmt"
import "core:net"
import "core:strings"
import rl "vendor:raylib"
import "core:reflect"
import "core:log"


Player_Stage :: enum {
    NONE,
    SELECTING,
    CONFIRMED,
    RESOLVING,
    RESOLVED,
    UPGRADING,

    INTERRUPTING,
    INTERRUPTED,
}

Hero_ID :: enum {
    XARGATHA,
}

hero_cards: [Hero_ID][]Card

Hero :: struct {
    id: Hero_ID,
    location: Target,

    current_action_index: Action_Index,
    cards: [Card_Color]Card,
    coins: int,
    level: int,
    dead: bool,
    items: [10]Card_ID,  // lol
    item_count: int,
}

Player_ID :: int

Player :: struct {
    id: Player_ID,
    stage: Player_Stage,
    hero: Hero,

    _username_buf: [40]u8,
    username: cstring,
    
    team: Team,
    is_team_captain: bool,
    socket: net.TCP_Socket,  // For host use only
}



my_player_id: Player_ID



@(private="file")
INFO_FONT_SIZE :: 40

@(private="file")
TEXT_PADDING :: 6



player_offset :: proc(player_id: Player_ID) -> int {
    if player_id > my_player_id do return player_id - 1
    return player_id
}

render_player_info :: proc() {
    for _, player_id in game_state.players {
        pos := Vec2{0, BOARD_POSITION_RECT.height} + TEXT_PADDING
        if player_id != my_player_id {
            player_offset := player_offset(player_id)
            x := BOARD_TEXTURE_SIZE.x + TEXT_PADDING + RESOLVED_CARD_WIDTH / 2
            y := TOOLTIP_FONT_SIZE + f32(player_offset) * BOARD_HAND_SPACE
            pos = {x, y}
        }
        render_player_info_at_position(player_id, pos)
    }
}

count_hero_items :: proc(hero: Hero, kind: Item_Kind) -> (out: int) {
    for item_index in 0..<hero.item_count {
        card_id := hero.items[item_index]
        card, ok := get_card_by_id(card_id)
        log.assert(ok, "Invalid item!")
        if card.item == kind do out += 1
    }
    return out
}

render_player_info_at_position :: proc(player_id: Player_ID, pos: Vec2) {
    next_pos := pos
    player := get_player_by_id(player_id)
    context.allocator = context.temp_allocator
    name, _ := reflect.enum_name_from_value(player.hero.id)
    // hero_name := strings.clone_to_cstring(strings.to_ada_case(name))
    hero_name := fmt.ctprintf("[%v%v] %v", get_username(player.id), "!" if player.is_team_captain else "", strings.to_ada_case(name))
    
    rl.DrawTextEx(default_font, hero_name, next_pos, INFO_FONT_SIZE, FONT_SPACING, team_colors[player.team])
    next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    level_string := fmt.ctprintf("Level %v", player.hero.level)
    rl.DrawTextEx(default_font, level_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
    next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    coins_string := fmt.ctprintf("%v coin%v", player.hero.coins, "" if player.hero.coins == 1 else "s")
    rl.DrawTextEx(default_font, coins_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)


    next_pos = pos
    next_pos.x += 250 // @Magic

    for kind, index in Item_Kind {
        initial := item_initials[kind]
        item_string := fmt.ctprintf("+%v%v", count_hero_items(player.hero, kind), initial)
        rl.DrawTextEx(default_font, item_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
        next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

        if index == 2 {
            next_pos = pos
            next_pos.x += 350
        }
    }

    
}

add_or_update_player :: proc(player: Player) {
    if player.id >= len(game_state.players) {
        resize(&game_state.players, player.id + 1)
    }
    game_state.players[player.id] = player
    if player.is_team_captain {
        game_state.team_captains[player.team] = player.id
    }
}

get_username :: proc(player_id: Player_ID) -> cstring {
    return cstring(raw_data(game_state.players[player_id]._username_buf[:]))
}

get_player_by_id :: proc(player_id: Player_ID) -> ^Player {
    if player_id >= len(game_state.players) {
        return nil
    }
    return &game_state.players[player_id]
}

get_my_player :: proc() -> ^Player {
    return get_player_by_id(my_player_id)
}