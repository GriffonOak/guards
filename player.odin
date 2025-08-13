package guards

import "core:fmt"
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
}

Hero_ID :: enum {
    NONE,
    XARGATHA,
}

Hero :: struct {
    id: Hero_ID,
    location: IVec2,

    current_action_index: int,
    action_list: []Action,
    coins: int,
    level: int,
    // target_list: map[Target]Void,
    // num_locked_targets: int,
    // chosen_targets: [dynamic]Target,
}

Player :: struct {
    stage: Player_Stage,
    // cards: [Card_Color]^Card,  // soon, my love
    hero: Hero,
    
    team: Team,
    is_team_captain: bool,
}


player := Player {
    hero = Hero{
        id = .XARGATHA
    },
    team = .RED,
    is_team_captain = true,
}

player2 := Player {
    hero = Hero {
        id = .NONE,
    },
    team = .BLUE,
}

render_player_info :: proc() {
    INFO_FONT_SIZE :: 40
    TEXT_PADDING :: 6
    context.allocator = context.temp_allocator
    name, ok := reflect.enum_name_from_value(player.hero.id)
    hero_name := strings.clone_to_cstring(strings.to_ada_case(name))
    text_pos := Vec2{CARD_PLAYED_POSITION_RECT.x + CARD_PLAYED_POSITION_RECT.width, BOARD_POSITION_RECT.height} + TEXT_PADDING
    rl.DrawTextEx(default_font, hero_name, text_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
    text_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    level_string := fmt.ctprintf("Level %v", player.hero.level)
    rl.DrawTextEx(default_font, level_string, text_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
    text_pos.y += INFO_FONT_SIZE + TEXT_PADDING

    coins_string := fmt.ctprintf("%v coin%v", player.hero.coins, "" if player.hero.coins == 1 else "s")
    rl.DrawTextEx(default_font, coins_string, text_pos, INFO_FONT_SIZE, FONT_SPACING, rl.WHITE)
    
}
