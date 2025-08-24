package guards

import "core:fmt"
import "core:net"
import "core:strings"
import rl "vendor:raylib"
import "core:reflect"


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
    NONE,
    XARGATHA,
}

Hero :: struct {
    id: Hero_ID,
    location: IVec2,

    current_action_index: Action_Index,
    action_list: []Action,
    cards: [Card_Color]Card,  // soon, my love
    coins: int,
    level: int,
    // target_list: map[Target]Void,
    // num_locked_targets: int,
    // chosen_targets: [dynamic]Target,
}

Player_ID :: int

Player :: struct {
    id: Player_ID,
    stage: Player_Stage,
    hero: Hero,
    
    team: Team,
    is_team_captain: bool,
    socket: net.TCP_Socket,  // For host use only
}



my_player_id: Player_ID



@(private="file")
INFO_FONT_SIZE :: 40

@(private="file")
TEXT_PADDING :: 6



render_player_info :: proc(player_id: Player_ID) {
    text_pos := Vec2{CARD_PLAYED_POSITION_RECT.x + CARD_PLAYED_POSITION_RECT.width, BOARD_POSITION_RECT.height} + TEXT_PADDING
    render_player_info_at_position(player_id, text_pos)
}

player_offset :: proc(player_id: Player_ID) -> int {
    if player_id > my_player_id do return player_id - 1
    return player_id
}

render_other_player_info :: proc() {
    for player, player_id in game_state.players {
        if player_id == my_player_id do continue
        player_offset := player_offset(player_id)
        x := BOARD_TEXTURE_SIZE.x + TEXT_PADDING + RESOLVED_CARD_WIDTH / 2
        y := TOOLTIP_FONT_SIZE + f32(player_offset) * BOARD_HAND_SPACE
        render_player_info_at_position(player_id, {x, y})
    }
}

render_player_info_at_position :: proc(player_id: Player_ID, pos: Vec2) {
    pos := pos
    player := get_player_by_id(player_id)
    context.allocator = context.temp_allocator
    name, ok := reflect.enum_name_from_value(player.hero.id)
    // hero_name := strings.clone_to_cstring(strings.to_ada_case(name))
    hero_name := fmt.ctprintf("[%v%v] %v", player_id, "!" if player.is_team_captain else "", strings.to_ada_case(name))
    
    rl.DrawTextEx(default_font, hero_name, pos, INFO_FONT_SIZE, FONT_SPACING, team_colors[player.team])
    pos.y += INFO_FONT_SIZE + TEXT_PADDING

    level_string := fmt.ctprintf("Level %v", player.hero.level)
    rl.DrawTextEx(default_font, level_string, pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
    pos.y += INFO_FONT_SIZE + TEXT_PADDING

    coins_string := fmt.ctprintf("%v coin%v", player.hero.coins, "" if player.hero.coins == 1 else "s")
    rl.DrawTextEx(default_font, coins_string, pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
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

get_player_by_id :: proc(player_id: Player_ID) -> ^Player {
    if player_id >= len(game_state.players) {
        return nil
    }
    return &game_state.players[player_id]
}

get_my_player :: proc() -> ^Player {
    return get_player_by_id(my_player_id)
}