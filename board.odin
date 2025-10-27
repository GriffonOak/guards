package guards

import "core:fmt"
import "core:math"
import "core:reflect"
import "core:strings"

import "core:log"

_ :: fmt
_ :: reflect
_ :: strings


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
    Obstacle,

    Cannot_Move,
    Cannot_Push,
    Cannot_Swap,
    Cannot_Place,

    Immune,
    Immune_To_Attacks,
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

Space_Permanent :: struct {
    position: Vec2,
    region_id: Region_ID,
    spawnpoint_team: Team,
}

Space_Transient :: struct {
    unit_team: Team,
    hero_id: Hero_ID,
    owner: Player_ID,
}

Space :: struct {
    flags: Space_Flags,
    using permanent: Space_Permanent,
    using transient: Space_Transient,
}

@rodata
dead_minion_target_indices := [5]Target {
    {1, 10},
    {1, 9},
    {1, 8},
    {1, 7},
    {2, 6},
}

GRID_WIDTH  :: 21
GRID_HEIGHT :: 20

// BOARD_TEXTURE_SIZE :: Vec2{1200, 1200}
// BOARD_TEXTURE_SIZE :: Vec2{1080, 1080}
// BOARD_POSITION_RECT :: Rectangle{0, 0, BOARD_TEXTURE_SIZE.x, BOARD_TEXTURE_SIZE.y}

WATER_COLOR  :: Colour{54, 186, 228, 255}
CLIFF_COLOR  :: Colour{80, 76, 75, 255}
SAND_COLOR   :: Colour{219, 182, 127, 255}
STONE_COLOR  :: Colour{185, 140, 93, 255}
JUNGLE_COLOR :: Colour{157, 177, 58, 255}

SPAWNPOINT_FLAGS :: Space_Flags{.Melee_Minion_Spawnpoint, .Ranged_Minion_Spawnpoint, .Heavy_Minion_Spawnpoint, .Hero_Spawnpoint}
PERMANENT_FLAGS  :: SPAWNPOINT_FLAGS + {.Terrain}
MINION_FLAGS     :: Space_Flags{.Melee_Minion, .Ranged_Minion, .Heavy_Minion}
UNIT_FLAGS       :: MINION_FLAGS + {.Hero}
OBSTACLE_FLAGS   :: UNIT_FLAGS + {.Terrain, .Token, .Obstacle}


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
region_colors := [Region_ID]Colour {
    .None = MAGENTA,
    .Red_Throne = STONE_COLOR,
    .Red_Beach = SAND_COLOR,
    .Red_Jungle = JUNGLE_COLOR,
    .Centre = STONE_COLOR,
    .Blue_Jungle = JUNGLE_COLOR,
    .Blue_Beach = SAND_COLOR,
    .Blue_Throne = STONE_COLOR,
}


get_symmetric_space :: proc(gs: ^Game_State, pos: Target) -> ^Space {
    sym_idx := Target{GRID_WIDTH, GRID_HEIGHT} - pos - 1
    return &gs.board[sym_idx.x][sym_idx.y]
}

setup_space_positions :: proc(gs: ^Game_State, bounding_rect: Rectangle) {
    VERTICAL_SPACING := bounding_rect.height / 17.9
    HORIZONTAL_SPACING := 1.732 * VERTICAL_SPACING * 0.5
    offset := Vec2{bounding_rect.x, bounding_rect.y}
    for &x_arr, x_idx in gs.board {
        for &space, y_idx in x_arr {
            x_value := bounding_rect.width / 2 + HORIZONTAL_SPACING * f32(x_idx - GRID_WIDTH / 2)
            // I don't even really know how this works but it does 
            y_value := bounding_rect.height / 2 - (0.5 * f32(x_idx + 1) + 0.25 - 0.25 * GRID_WIDTH + f32(y_idx) - 0.5 * GRID_HEIGHT) * VERTICAL_SPACING
            space.position = offset + {x_value, y_value}
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
        // mouse_within_board := ui_state.mouse_pos - {element.bounding_rect.x, element.bounding_rect.y}

        // mouse_within_board *= BOARD_TEXTURE_SIZE / {element.bounding_rect.width, element.bounding_rect.height}

        closest_idx := INVALID_TARGET
        // closest_dist: f32 = 1e6
        // for arr, x in gs.board {
        //     for space, y in arr {
        //         // diff := (mouse_within_board - space.position)
        //         // dist := diff.x * diff.x + diff.y * diff.y
        //         // if dist < closest_dist && dist < VERTICAL_SPACING * VERTICAL_SPACING * 0.5 {
        //         //     closest_idx = {u8(x), u8(y)}
        //         //     closest_dist = dist
        //         // }
        //     }
        // }
        if closest_idx != INVALID_TARGET  {
            board_element.hovered_space = closest_idx
        }
    }

    return true
}

render_board :: proc(gs: ^Game_State, bounding_rect: Rectangle, board_element: Board_Element) {
    context.allocator = context.temp_allocator
    
    offset := Vec2{bounding_rect.x, bounding_rect.y}

    VERTICAL_SPACING := bounding_rect.height / 17.9
    // HORIZONTAL_SPACING := 1.732 * VERTICAL_SPACING * 0.5

    highlight_action_targets :: proc(gs: ^Game_State, action_index: Action_Index, v_spacing: f32) {

        action := get_action_at_index(gs, action_index)
        if action == nil do return

        frequency: f64 = 4
        time := get_time()

        #partial switch variant in action.variant {
        case Choice_Action:
            for choice in variant.choices {
                jump_index := choice.jump_index
                if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
                highlight_action_targets(gs, jump_index, v_spacing)
            }
            return

        case Jump_Action:
            jump_index := calculate_implicit_action_index(gs, variant.jump_index, {card_id = action_index.card_id})
            if jump_index.card_id == {} do jump_index.card_id = action_index.card_id
            highlight_action_targets(gs, jump_index, v_spacing)

        case Choose_Target_Action:
            frequency = 14
            target_slice := get_memory_slice_for_index(gs, action_index, gs.action_count)
            for action_value in target_slice {
                target := action_value.variant.(Target)
                space := gs.board[target.x][target.y]
                selected_color := LIGHTGRAY
                pulse := f32(math.sin(1.5 * time) * 0.03) * v_spacing

                draw_ring(space.position, v_spacing * 0.4 + pulse, v_spacing * 0.5 + pulse, 0, 360, 20, selected_color)
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
            base_color := DARKGRAY
            highlight_color := LIGHTGRAY
            color := color_lerp(base_color, highlight_color, color_blend)
            if info.invalid {
                draw_circle_v(space.position, v_spacing * 0.08, color)
            } else {
                draw_poly_lines_ex(space.position, 6, v_spacing / 2, 0, v_spacing * 0.08, color)
            }
        }
    }

    clear_background(WATER_COLOR)

    // Draw the board tiles
    for arr in gs.board {
        for space in arr {
            color := WHITE
            if .Terrain in space.flags do color = CLIFF_COLOR
            else do color = region_colors[space.region_id]
            draw_poly(space.position, 6, VERTICAL_SPACING / math.sqrt_f32(3), 0, color)

            // Make the highlight
            brightness_increase :: 50
            if .Terrain not_in space.flags {
                lighter_color := WHITE
                for &val, idx in lighter_color do val = 255 if color[idx] + brightness_increase < color[idx] else color[idx] + brightness_increase
                lighter_color.a = 255
                draw_poly(space.position, 6, 0.9 * VERTICAL_SPACING / math.sqrt_f32(3), 0, lighter_color)
                draw_circle_v(space.position, 0.92 * VERTICAL_SPACING / 2, color)

                darker_color := BLACK
                for val, idx in color.rgb do darker_color[idx] = 0 if val - 25 > val else val - 25
                darker_color.a = 255
                draw_poly_lines_ex(space.position, 6, VERTICAL_SPACING / math.sqrt_f32(3), 0, 1, darker_color)
            }
        }
    }

    // Draw hovered space
    space_pos: Vec2
    if board_element.hovered_space != INVALID_TARGET {
        space_pos = gs.board[board_element.hovered_space.x][board_element.hovered_space.y].position
        draw_poly_lines_ex(space_pos, 6, VERTICAL_SPACING * (1 / math.sqrt_f32(3) + 0.05), 0, VERTICAL_SPACING * 0.05, WHITE)
    }

    // Draw hover effect
    #partial switch get_my_player(gs).stage {
    case .Resolving, .Interrupting:
        action_index := get_my_player(gs).hero.current_action_index
        action := get_action_at_index(gs, action_index)
        if action == nil do break
        #partial  switch variant in action.variant {
        case Fast_Travel_Action:
            if board_element.hovered_space == INVALID_TARGET do break
            if index_target_set(&action.targets, board_element.hovered_space).member {
                player_loc := get_my_player(gs).hero.location
                player_pos := gs.board[player_loc.x][player_loc.y].position
                draw_line_ex(space_pos, player_pos, 4, VIOLET)
            }
        case Movement_Action:
            path := get_top_action_value_of_type(gs, Path)
            if len(path.spaces) == 0 do break
            current_loc := path.spaces[0]
            for target in path.spaces[1:] {
                draw_line_ex(gs.board[current_loc.x][current_loc.y].position, gs.board[target.x][target.y].position, 4, VIOLET)
                current_loc = target
            }
        case Choice_Action:
            // See if any side buttons are hovered
            for button_data in gs.side_button_manager.button_data {
                if button_data.id != hot_element_id do continue
                event, ok := button_data.event.(Choice_Taken_Event)
                if !ok do continue
                next_index := event.jump_index
                if next_index.card_id == {} do next_index.card_id = action_index.card_id
                highlight_action_targets(gs, next_index, VERTICAL_SPACING)
            }
        }

        if _, ok := action.variant.(Choice_Action); !ok && action != nil {
            highlight_action_targets(gs, action_index, VERTICAL_SPACING)
        }
    }

    DEST_RECT_WIDTH := VERTICAL_SPACING * 0.7
    draw_icon_at_position :: proc(texture: Texture, position: Vec2, width: f32, tint: Colour = WHITE) {
        texture_rect := Rectangle {
            0, 0, 
            f32(texture.width), f32(texture.height),
        }

        dest_rect := Rectangle {
            position.x - width / 2,
            position.y - width / 2,
            width, width,
        }

        draw_texture_pro(texture, texture_rect, dest_rect, {}, 0, tint)
    }

    // Draw entities
    for arr in gs.board {
        for space in arr {
            color: Colour
            spawnpoint_flags := space.flags & SPAWNPOINT_FLAGS
            if spawnpoint_flags != {} {
                color = team_colors[space.spawnpoint_team]
                if .Hero_Spawnpoint in space.flags {
                    draw_ring(space.position, VERTICAL_SPACING * 0.35, VERTICAL_SPACING * 0.26, 0, 360, 20, color)
                } else {
                    spawnpoint_type := get_first_set_bit(spawnpoint_flags).?
                    // minion_type := spawnpoint_to_minion[spawnpoint_type]
                    spawnpoint_texture := minion_icons[spawnpoint_type]
                    // texture := minion_icons[minion_type]

                    draw_icon_at_position(spawnpoint_texture, space.position, DEST_RECT_WIDTH, color)
                }
            }

            if space.flags & UNIT_FLAGS != {} {
                texture: Texture
                color = team_colors[space.unit_team]

                if .Hero in space.flags {
                    hero_id := get_player_by_id(gs, space.owner).hero.id
                    texture = hero_icons[hero_id]
                } else {
                    minion_flags := space.flags & MINION_FLAGS 
                    minion_type := get_first_set_bit(minion_flags).?
                    texture = minion_icons[minion_type]
                }

                draw_circle_v(space.position, VERTICAL_SPACING * 0.42, color)
                draw_icon_at_position(texture, space.position, DEST_RECT_WIDTH)
            }
        }
    }

    // Draw Tiebreaker Coin
    // tiebreaker_pos := offset + {VERTICAL_SPACING, VERTICAL_SPACING}
    draw_circle_v({100, 100}, 75, team_colors[gs.tiebreaker_coin])
    draw_ring({100, 100}, 70, 75, 0, 360, 100, RAYWHITE)

    // Draw wave counters
    for wave_counter_index in 0..<5 {
        angle: f32 = math.TAU / 8 - math.TAU / 6  // @Magic
        angle += f32(wave_counter_index) * math.TAU / (3 * 4)
        wave_counter_position := Vec2{100, 100} + 140 * {math.cos_f32(angle), math.sin_f32(angle)}
        color := RAYWHITE if wave_counter_index < gs.wave_counters else GRAY
        draw_circle_v(wave_counter_position, VERTICAL_SPACING * 0.4, color)
        draw_ring(wave_counter_position, VERTICAL_SPACING * 0.4, VERTICAL_SPACING * 0.5, 0, 360, 100, RAYWHITE)
    }

    for team in Team {
        // Draw life counters 
        for life_counter_index in 0..<6 {
            LIFE_COUNTER_RADIUS := VERTICAL_SPACING / 3
            LIFE_COUNTER_PADDING := VERTICAL_SPACING / 6.7
            life_counter_position := Vec2{0, bounding_rect.height} + {LIFE_COUNTER_RADIUS, -LIFE_COUNTER_RADIUS} + {LIFE_COUNTER_PADDING, -LIFE_COUNTER_PADDING}
            life_counter_position.x += f32(life_counter_index) * (LIFE_COUNTER_RADIUS * 2 + LIFE_COUNTER_PADDING)
            if team == .Blue do life_counter_position = {bounding_rect.width, bounding_rect.height} - life_counter_position
            life_counter_position += offset
            darker_team_color := team_colors[team] / 2
            darker_team_color.a = 255
            color := team_colors[team] if life_counter_index < gs.life_counters[team] else darker_team_color
            draw_circle_v(life_counter_position, LIFE_COUNTER_RADIUS, color)
            draw_ring(life_counter_position, LIFE_COUNTER_RADIUS - 5, LIFE_COUNTER_RADIUS, 0, 360, 100, team_colors[team])
        }

        // Draw dead minions
        for minion_type, minion_index in gs.dead_minions[team] {
            color := team_colors[team]
            target := dead_minion_target_indices[minion_index]
            if team == .Blue do target = {GRID_WIDTH-1, GRID_HEIGHT-1} - target
            position := gs.board[target.x][target.y].position
            texture := minion_icons[minion_type]
            draw_circle_v(position, VERTICAL_SPACING * 0.42, color)
            draw_icon_at_position(texture, position, DEST_RECT_WIDTH)
        }
    }

    when ODIN_DEBUG {
        for x in 0..<GRID_WIDTH {
            for y in 0..<GRID_HEIGHT {
                space := gs.board[x][y]
                coords := fmt.ctprintf("%d,%d", x, y)
                bound := measure_text_ex(default_font, coords, 30, 0)
                draw_text_ex(default_font, coords, space.position - bound / 2, 30, 0, BLACK)
            }
        }
    }

    end_texture_mode()
}

draw_board: UI_Render_Proc : proc(_: ^Game_State, element: UI_Element) {

//     board_element := element.variant.(UI_Board_Element)
// when !ODIN_TEST {
//     draw_texture_pro(board_element.texture.texture, {0, 0, BOARD_TEXTURE_SIZE.x, -BOARD_TEXTURE_SIZE.y}, element.bounding_rect, {0, 0}, 0, WHITE)
// }

}
