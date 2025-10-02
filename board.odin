package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:reflect"
import "core:strings"

import "core:log"

_ :: fmt


Spawnpoint_Marker :: struct {
    loc: Target,
    spawnpoint_flag: Space_Flag,
    team: Team,
}

Space_Flag :: enum {
    Terrain,
    Melee_Minion_Spawnpoint,
    Ranged_Minion_Spawnpoint,
    Heavy_Minion_Spawnpoint,
    Hero_Spawnpoint,
    Hero,
    Melee_Minion,
    Ranged_Minion,
    Heavy_Minion,
    Token,
    Immune,
}


Region_ID :: enum {
    None,
    Red_Jungle,
    Red_Throne,
    Red_Beach,
    Centre,
    Blue_Beach,
    Blue_Throne,
    Blue_Jungle,
}

Space_Flags :: bit_set[Space_Flag]

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
    spawnpoint_team: Team,
    unit_team: Team,
    hero_id: Hero_ID,
    owner: Player_ID,
}


VERTICAL_SPACING :: 67

// sqrt 3
HORIZONTAL_SPACING :: 1.732 * VERTICAL_SPACING * 0.5

GRID_WIDTH  :: 21
GRID_HEIGHT :: 20

BOARD_TEXTURE_SIZE :: Vec2{1200, 1200}
// BOARD_TEXTURE_SIZE :: Vec2{1080, 1080}
BOARD_POSITION_RECT :: rl.Rectangle{0, 0, BOARD_TEXTURE_SIZE.x, BOARD_TEXTURE_SIZE.y}

WATER_COLOR  :: rl.Color{54, 186, 228, 255}
CLIFF_COLOR  :: rl.Color{80, 76, 75, 255}
SAND_COLOR   :: rl.Color{219, 182, 127, 255}
STONE_COLOR  :: rl.Color{185, 140, 93, 255}
JUNGLE_COLOR :: rl.Color{157, 177, 58, 255}

SPAWNPOINT_FLAGS :: Space_Flags{.Melee_Minion_Spawnpoint, .Ranged_Minion_Spawnpoint, .Heavy_Minion_Spawnpoint, .Hero_Spawnpoint}
PERMANENT_FLAGS  :: SPAWNPOINT_FLAGS + {.Terrain}
MINION_FLAGS     :: Space_Flags{.Melee_Minion, .Ranged_Minion, .Heavy_Minion}
UNIT_FLAGS       :: MINION_FLAGS + {.Hero}
OBSTACLE_FLAGS   :: UNIT_FLAGS + {.Terrain, .Token}


@rodata
starting_terrain := [?]Target {
    {1,8}, {1,9}, {1,10}, {1,13}, {1,14}, {1,15}, {1,16}, {1,17}, {1,18},
    {2,14}, {2,15}, {2,16}, {2,17}, 
    {3,14}, {3,15},
    {4,5}, {4,11},
    {5,4}, {5,10}, {5,11}, {5,14},
    {6,3},
    {7,2},
    {8,1}, {8,2},
    {9,1}, {9,7},
    {10,1}, {10,9},
    {13,1}, {13,2}, {13,3},
    {14,1},
    {15,1}, {15,4},
    {16,1},
    {17,1},
    {18,1},
}

@rodata
fast_travel_adjacencies := [Region_ID]bit_set[Region_ID] {
    .None = {},
    .Red_Jungle = {.Red_Throne, .Centre},
    .Red_Throne = {.Red_Beach, .Red_Jungle},
    .Red_Beach = {.Red_Throne, .Centre},
    .Centre = {.Red_Beach, .Red_Jungle, .Blue_Beach, .Blue_Jungle},
    .Blue_Beach = {.Blue_Throne, .Centre},
    .Blue_Throne = {.Blue_Beach, .Blue_Jungle},
    .Blue_Jungle = {.Blue_Throne, .Centre},
}

@rodata
spawnpoints := [?]Spawnpoint_Marker {
    {{2, 11}, .Hero_Spawnpoint, .Red},
    {{3, 9}, .Hero_Spawnpoint, .Red},
    {{3, 7}, .Hero_Spawnpoint, .Red},

    {{5, 5}, .Melee_Minion_Spawnpoint, .Red},
    {{6, 7}, .Melee_Minion_Spawnpoint, .Red},
    {{6, 8}, .Melee_Minion_Spawnpoint, .Red},
    {{6, 12}, .Melee_Minion_Spawnpoint, .Red},
    {{7, 5}, .Heavy_Minion_Spawnpoint, .Red},
    {{7, 7}, .Melee_Minion_Spawnpoint, .Blue},
    {{7, 12}, .Melee_Minion_Spawnpoint, .Red},
    {{8, 4}, .Ranged_Minion_Spawnpoint, .Red},
    {{8, 5}, .Heavy_Minion_Spawnpoint, .Blue},
    {{9, 4}, .Melee_Minion_Spawnpoint, .Blue},
    {{9, 6}, .Ranged_Minion_Spawnpoint, .Blue},
    {{9, 9}, .Ranged_Minion_Spawnpoint, .Red},
    {{11, 2}, .Melee_Minion_Spawnpoint, .Red},
    {{11, 3}, .Melee_Minion_Spawnpoint, .Blue},
    {{11, 5}, .Melee_Minion_Spawnpoint, .Red},
    {{11, 9}, .Melee_Minion_Spawnpoint, .Red},
    {{13, 6}, .Heavy_Minion_Spawnpoint, .Red},
    
}

@rodata
spawnpoint_to_minion := #partial [Space_Flag]Space_Flag {
    .Melee_Minion_Spawnpoint = .Melee_Minion,
    .Ranged_Minion_Spawnpoint = .Ranged_Minion,
    .Heavy_Minion_Spawnpoint = .Heavy_Minion,
}

@rodata
region_colors := [Region_ID]rl.Color {
    .None = rl.MAGENTA,
    .Red_Throne = STONE_COLOR,
    .Red_Beach = SAND_COLOR,
    .Red_Jungle = JUNGLE_COLOR,
    .Centre = STONE_COLOR,
    .Blue_Jungle = JUNGLE_COLOR,
    .Blue_Beach = SAND_COLOR,
    .Blue_Throne = STONE_COLOR,
}

@rodata
minion_initials := #partial [Space_Flag]cstring {
    .Melee_Minion  = "M",
    .Ranged_Minion = "R",
    .Heavy_Minion  = "H",
}



get_symmetric_space :: proc(gs: ^Game_State, pos: Target) -> ^Space {
    sym_idx := Target{GRID_WIDTH, GRID_HEIGHT} - pos - 1
    return &gs.board[sym_idx.x][sym_idx.y]
}

setup_space_positions :: proc(gs: ^Game_State) {
    for &x_arr, x_idx in gs.board {
        for &space, y_idx in x_arr {
            x_value := BOARD_TEXTURE_SIZE.x / 2 + HORIZONTAL_SPACING * f32(x_idx - GRID_WIDTH / 2)
            // I don't even really know how this works but it does 
            y_value := BOARD_TEXTURE_SIZE.y / 2 - (0.5 * f32(x_idx + 1) + 0.25 - 0.25 * GRID_WIDTH + f32(y_idx) - 0.5 * GRID_HEIGHT) * VERTICAL_SPACING
            space.position = {x_value, y_value}
        }
    }
}

set_terrain_symmetric :: proc(gs: ^Game_State, target: Target) {
    gs.board[target.x][target.y].flags += {.Terrain}
    get_symmetric_space(gs, target).flags += {.Terrain}
}

setup_terrain :: proc(gs: ^Game_State) {
    for x_idx in 0..<GRID_WIDTH {
        for y_idx in 0..<GRID_HEIGHT {
            if x_idx == 0 || y_idx == 0 || x_idx + y_idx <= 8 {
                set_terrain_symmetric(gs, Target{u8(x_idx), u8(y_idx)})
            }
        }
    }

    for vec in starting_terrain {
        set_terrain_symmetric(gs, vec)
    }
}

setup_regions :: proc(gs: ^Game_State) {
    for slice, region_id in zone_indices {
        for target in slice {
            gs.board[target.x][target.y].region_id = region_id
        }
    }
}

setup_spawnpoints :: proc(gs: ^Game_State) {
    for marker in spawnpoints {
        log.assert(marker.spawnpoint_flag in SPAWNPOINT_FLAGS, "Provided spawnpoint has no spawnpoint marker")
        space := &gs.board[marker.loc.x][marker.loc.y]
        symmetric_space := get_symmetric_space(gs, marker.loc)
        space.flags += {marker.spawnpoint_flag}
        symmetric_space.flags += {marker.spawnpoint_flag}

        space.spawnpoint_team = marker.team
        symmetric_space.spawnpoint_team = get_enemy_team(marker.team)
    }
}

setup_board :: proc(gs: ^Game_State) {
    
    setup_space_positions(gs)

    setup_terrain(gs)

    setup_regions(gs)

    setup_spawnpoints(gs)
}

board_input_proc: UI_Input_Proc : proc(gs: ^Game_State, input: Input_Event, element: ^UI_Element) -> bool {

    board_element := assert_variant(&element.variant, UI_Board_Element)
    prev_hovered_space := board_element.hovered_space
    defer {
        if board_element.hovered_space != prev_hovered_space {
            append(&gs.event_queue, Space_Hovered_Event{board_element.hovered_space})
        }
    }

    #partial switch var in input {
    case Mouse_Pressed_Event:
        if .Hovered not_in element.flags || board_element.hovered_space == INVALID_TARGET do break
        append(&gs.event_queue, Space_Clicked_Event{board_element.hovered_space})
    case Mouse_Motion_Event:
        board_element.hovered_space = INVALID_TARGET
        mouse_within_board := ui_state.mouse_pos - {element.bounding_rect.x, element.bounding_rect.y}

        mouse_within_board *= BOARD_TEXTURE_SIZE / {element.bounding_rect.width, element.bounding_rect.height}

        closest_idx := INVALID_TARGET
        closest_dist: f32 = 1e6
        for arr, x in gs.board {
            for space, y in arr {
                diff := (mouse_within_board - space.position)
                dist := diff.x * diff.x + diff.y * diff.y
                if dist < closest_dist && dist < VERTICAL_SPACING * VERTICAL_SPACING * 0.5 {
                    closest_idx = {u8(x), u8(y)}
                    closest_dist = dist
                }
            }
        }
        if closest_idx != INVALID_TARGET  {
            board_element.hovered_space = closest_idx
        } 
    }

    return true
}

render_board_to_texture :: proc(gs: ^Game_State, element: UI_Element) {
    context.allocator = context.temp_allocator

    highlight_action_targets :: proc(gs: ^Game_State, action_index: Action_Index) {

        action := get_action_at_index(gs, action_index)
        if action == nil do return

        origin: Target

        frequency: f64 = 4
        time := rl.GetTime()

        #partial switch variant in action.variant {
        case Choice_Action:
            for choice in variant.choices {
                jump_index := choice.jump_index
                if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
                highlight_action_targets(gs, jump_index)
            }
            return

        case Jump_Action:
            jump_index := calculate_implicit_action_index(gs, variant.jump_index, {card_id = action_index.card_id})
            if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
            highlight_action_targets(gs, jump_index)
        case Movement_Action:
            origin = variant.path.spaces[variant.path.num_locked_spaces - 1]

        case Choose_Target_Action:
            frequency = 14
            for target in variant.result {
                space := gs.board[target.x][target.y]
                selected_color := rl.LIGHTGRAY
                pulse := f32(math.sin(1.5 * time) * VERTICAL_SPACING * 0.03)

                rl.DrawRing(space.position, VERTICAL_SPACING * 0.4 + pulse, VERTICAL_SPACING * 0.5 + pulse, 0, 360, 20, selected_color)
            }
        }

        target_iter := make_target_set_iterator(&action.targets)
        for info, target in target_set_iter_members(&target_iter) {
            space := gs.board[target.x][target.y]
            phase: f64 = 0

            // Different effects for highlighted spaces
            #partial switch variant in action.variant {
            case Movement_Action:
                phase = -f64(info.dist)

            case Fast_Travel_Action:
                region_id := space.region_id
                phase = math.TAU * f64(region_id) / f64(len(Region_ID) - 1)

            // case Choose_Target_Action:
            //     delta := target.position
            //     phase = math.atan2()
            }

            

            color_blend := (math.sin(frequency * time + phase) + 1) / 2
            color_blend = color_blend * color_blend
            base_color := rl.DARKGRAY
            highlight_color := rl.LIGHTGRAY
            // color: = color_lerp(rl.Blue, rl.ORange, color_blend)
            color := color_lerp(base_color, highlight_color, color_blend)
            if info.invalid {
                rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.08, color)
            } else {
                rl.DrawPolyLinesEx(space.position, 6, VERTICAL_SPACING / 2, 0, VERTICAL_SPACING * 0.08, color)
            }
        }
    }

    board_element := assert_variant_rdonly(element.variant, UI_Board_Element)
    rl.BeginTextureMode(board_element.texture)

    rl.ClearBackground(WATER_COLOR)

    // Draw the board tiles
    for arr in gs.board {
        for space in arr {
            color := rl.WHITE
            if .Terrain in space.flags do color = CLIFF_COLOR
            else do color = region_colors[space.region_id]
            rl.DrawPoly(space.position, 6, VERTICAL_SPACING / math.sqrt_f32(3), 0, color)

            // Make the highlight
            brightness_increase :: 50
            if .Terrain not_in space.flags {
                lighter_color := rl.WHITE
                for &val, idx in lighter_color do val = 255 if color[idx] + brightness_increase < color[idx] else color[idx] + brightness_increase
                lighter_color.a = 255
                rl.DrawPoly(space.position, 6, 0.9 * VERTICAL_SPACING / math.sqrt_f32(3), 0, lighter_color)
                rl.DrawCircleV(space.position, 0.92 * VERTICAL_SPACING / 2, color)

                darker_color := rl.BLACK
                for val, idx in color.rgb do darker_color[idx] = 0 if val - 25 > val else val - 25
                darker_color.a = 255
                rl.DrawPolyLinesEx(space.position, 6, VERTICAL_SPACING / math.sqrt_f32(3), 0, 1, darker_color)
            }
        }
    }
    // Draw hovered space
    space_pos: Vec2
    if .Hovered not_in element.flags || board_element.hovered_space != INVALID_TARGET {
        space_pos = gs.board[board_element.hovered_space.x][board_element.hovered_space.y].position
        // rl.DrawRing(pos, VERTICAL_SPACING * 0.45, VERTICAL_SPACING * 0.5, 0, 360, 100, rl.WHITE)
        rl.DrawPolyLinesEx(space_pos, 6, VERTICAL_SPACING * (1 / math.sqrt_f32(3) + 0.05), 0, VERTICAL_SPACING * 0.05, rl.WHITE)
    }

    // Draw hover effect
    #partial switch get_my_player(gs).stage {
    case .Resolving, .Interrupting:
        action_index := get_my_player(gs).hero.current_action_index
        action := get_action_at_index(gs, action_index)
        #partial switch variant in action.variant {
        case Fast_Travel_Action:
            if .Hovered not_in element.flags || board_element.hovered_space == INVALID_TARGET do break
            if index_target_set(&action.targets, board_element.hovered_space).member {
                player_loc := get_my_player(gs).hero.location
                player_pos := gs.board[player_loc.x][player_loc.y].position
                rl.DrawLineEx(space_pos, player_pos, 4, rl.VIOLET)
            }
        case Movement_Action:
            current_loc := variant.path.spaces[0]
            for target in variant.path.spaces[1:] {
                rl.DrawLineEx(gs.board[current_loc.x][current_loc.y].position, gs.board[target.x][target.y].position, 4, rl.VIOLET)
                current_loc = target
            }
        case Choice_Action:
            // See if any side buttons are hovered
            for &ui_element in gs.side_button_manager.buttons {
                button_element := assert_variant(&ui_element.variant, UI_Button_Element)
                if .Hovered not_in ui_element.flags do continue
                event, ok := button_element.event.(Resolve_Current_Action_Event)
                if !ok do continue
                next_index := event.jump_index.?
                if next_index.card_id == {} do next_index.card_id = action_index.card_id
                highlight_action_targets(gs, next_index)
            }
        }

        if _, ok := action.variant.(Choice_Action); !ok && action != nil {
            highlight_action_targets(gs, action_index)
        }
    }


    // Draw entities
    for arr in gs.board {
        for space in arr {
            color: rl.Color
            spawnpoint_flags := space.flags & SPAWNPOINT_FLAGS
            if spawnpoint_flags != {} {
                color = team_colors[space.spawnpoint_team]
                if .Hero_Spawnpoint in space.flags {
                    rl.DrawRing(space.position, VERTICAL_SPACING * 0.35, VERTICAL_SPACING * 0.26, 0, 360, 20, color)
                } else {
                    // spawnpoint_type := Space_Flag(log2(transmute(int) spawnpoint_flags))
                    spawnpoint_type := get_first_set_bit(spawnpoint_flags).?
                    initial := minion_initials[spawnpoint_to_minion[spawnpoint_type]]

                    FONT_SIZE :: 0.8 * VERTICAL_SPACING

                    text_size := rl.MeasureTextEx(default_font, initial, FONT_SIZE, FONT_SPACING)
                    rl.DrawTextEx(default_font, initial, {space.position.x - text_size.x / 2, space.position.y - text_size.y / 2.2}, FONT_SIZE, FONT_SPACING, color)
                }
            }

            minion_flags := space.flags & MINION_FLAGS 
            if minion_flags != {} {
                color = team_colors[space.unit_team]
                minion_type := get_first_set_bit(minion_flags).?
                initial := minion_initials[minion_type]

                FONT_SIZE :: 0.8 * VERTICAL_SPACING

                text_size := rl.MeasureTextEx(default_font, initial, FONT_SIZE, FONT_SPACING)
                rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.42, color)
                rl.DrawTextEx(default_font, initial, {space.position.x - text_size.x / 2, space.position.y - text_size.y / 2.2}, FONT_SIZE, FONT_SPACING, rl.BLACK)

            }

            if .Hero in space.flags {
                color = team_colors[space.unit_team]
                name, ok := reflect.enum_name_from_value(space.hero_id); log.assert(ok, "Invalid hero name?")
                initial := strings.clone_to_cstring(name[:1])

                FONT_SIZE :: 0.8 * VERTICAL_SPACING

                text_size := rl.MeasureTextEx(default_font, initial, FONT_SIZE, FONT_SPACING)
                rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.42, color)
                rl.DrawTextEx(default_font, initial, {space.position.x - text_size.x / 2, space.position.y - text_size.y / 2.2}, FONT_SIZE, FONT_SPACING, rl.BLACK)
            }
        }
    }

    // Draw Tiebreaker Coin
    rl.DrawCircleV({100, 100}, 75, team_colors[gs.tiebreaker_coin])
    rl.DrawRing({100, 100}, 70, 75, 0, 360, 100, rl.RAYWHITE)

    // Draw wave counters
    for wave_counter_index in 0..<5 {
        angle: f32 = math.TAU / 8 - math.TAU / 6  // @Magic
        angle += f32(wave_counter_index) * math.TAU / (3 * 4)
        wave_counter_position := Vec2{100, 100} + 140 * {math.cos_f32(angle), math.sin_f32(angle)}
        color := rl.RAYWHITE if wave_counter_index < gs.wave_counters else rl.GRAY
        rl.DrawCircleV(wave_counter_position, 25, color)
        rl.DrawRing(wave_counter_position, 25, 30, 0, 360, 100, rl.RAYWHITE)
    }

    // Draw life counters 
    for team in Team {
        for life_counter_index in 0..<6 {
            LIFE_COUNTER_RADIUS :: 23
            LIFE_COUNTER_PADDING :: 10
            life_counter_position: Vec2 = {0, BOARD_TEXTURE_SIZE.y} + {LIFE_COUNTER_RADIUS, -LIFE_COUNTER_RADIUS} + {LIFE_COUNTER_PADDING, -LIFE_COUNTER_PADDING}
            life_counter_position.x += f32(life_counter_index) * (LIFE_COUNTER_RADIUS * 2 + LIFE_COUNTER_PADDING)
            if team == .Blue do life_counter_position = BOARD_TEXTURE_SIZE - life_counter_position
            darker_team_color := team_colors[team] / 2
            darker_team_color.a = 255
            color := team_colors[team] if life_counter_index < gs.life_counters[team] else darker_team_color
            rl.DrawCircleV(life_counter_position, LIFE_COUNTER_RADIUS, color)
            rl.DrawRing(life_counter_position, LIFE_COUNTER_RADIUS - 5, LIFE_COUNTER_RADIUS, 0, 360, 100, team_colors[team])
        }
    }

    when ODIN_DEBUG {
        for x in 0..<GRID_WIDTH {
            for y in 0..<GRID_HEIGHT {
                space := gs.board[x][y]
                coords := fmt.ctprintf("%d,%d", x, y)
                bound := rl.MeasureTextEx(default_font, coords, 30, 0)
                rl.DrawTextEx(default_font, coords, space.position - bound / 2, 30, 0, rl.BLACK)
            }
        }
    }

    rl.EndTextureMode()
}

draw_board: UI_Render_Proc : proc(_: ^Game_State, element: UI_Element) {

    board_element := element.variant.(UI_Board_Element)
when !ODIN_TEST {
    rl.DrawTexturePro(board_element.texture.texture, {0, 0, BOARD_TEXTURE_SIZE.x, -BOARD_TEXTURE_SIZE.y}, element.bounding_rect, {0, 0}, 0, rl.WHITE)
}

    // rl.DrawRectangleLinesEx(BOARD_POSITION_RECT, 4, rl.WHITE)
}
