package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:reflect"
import "core:strings"



Spawnpoint_Marker :: struct {
    loc: IVec2,
    spawnpoint_flag: Space_Flag,
    team: Team,
}

Space_Flag :: enum {
    TERRAIN,
    MELEE_MINION_SPAWNPOINT,
    RANGED_MINION_SPAWNPOINT,
    HEAVY_MINION_SPAWNPOINT,
    HERO_SPAWNPOINT,
    HERO,
    MELEE_MINION,
    RANGED_MINION,
    HEAVY_MINION,
    TOKEN,
}


Region_ID :: enum {
    NONE,
    RED_JUNGLE,
    RED_BASE,
    RED_BEACH,
    CENTRE,
    BLUE_BEACH,
    BLUE_BASE,
    BLUE_JUNGLE,
}

Space_Flags :: bit_set[Space_Flag]

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
    spawnpoint_team: Team,
    unit_team: Team,
    hero_id: Hero_ID,
    owner: ^Player,
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

SPAWNPOINT_FLAGS :: Space_Flags{.MELEE_MINION_SPAWNPOINT, .RANGED_MINION_SPAWNPOINT, .HEAVY_MINION_SPAWNPOINT, .HERO_SPAWNPOINT}
PERMANENT_FLAGS  :: SPAWNPOINT_FLAGS + {.TERRAIN}
MINION_FLAGS     :: Space_Flags{.MELEE_MINION, .RANGED_MINION, .HEAVY_MINION}
UNIT_FLAGS       :: MINION_FLAGS + {.HERO}
OBSTACLE_FLAGS   :: UNIT_FLAGS + {.TERRAIN, .TOKEN}


starting_terrain := [?]IVec2 {
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

fast_travel_adjacencies := [Region_ID]bit_set[Region_ID] {
    .NONE = {},
    .RED_JUNGLE = {.RED_BASE, .CENTRE},
    .RED_BASE = {.RED_BEACH, .RED_JUNGLE},
    .RED_BEACH = {.RED_BASE, .CENTRE},
    .CENTRE = {.RED_BEACH, .RED_JUNGLE, .BLUE_BEACH, .BLUE_JUNGLE},
    .BLUE_BEACH = {.BLUE_BASE, .CENTRE},
    .BLUE_BASE = {.BLUE_BEACH, .BLUE_JUNGLE},
    .BLUE_JUNGLE = {.BLUE_BASE, .CENTRE}
}

spawnpoints := [?]Spawnpoint_Marker {
    {{2, 11}, .HERO_SPAWNPOINT, .RED},
    {{3, 9}, .HERO_SPAWNPOINT, .RED},
    {{3, 7}, .HERO_SPAWNPOINT, .RED},

    {{5, 5}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 7}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 8}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{6, 12}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{7, 5}, .HEAVY_MINION_SPAWNPOINT, .RED},
    {{7, 7}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{7, 12}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{8, 4}, .RANGED_MINION_SPAWNPOINT, .RED},
    {{8, 5}, .HEAVY_MINION_SPAWNPOINT, .BLUE},
    {{9, 4}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{9, 6}, .RANGED_MINION_SPAWNPOINT, .BLUE},
    {{9, 9}, .RANGED_MINION_SPAWNPOINT, .RED},
    {{11, 2}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{11, 3}, .MELEE_MINION_SPAWNPOINT, .BLUE},
    {{11, 5}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{11, 9}, .MELEE_MINION_SPAWNPOINT, .RED},
    {{13, 6}, .HEAVY_MINION_SPAWNPOINT, .RED},
    
}

spawnpoint_to_minion := #partial [Space_Flag]Space_Flag {
    .MELEE_MINION_SPAWNPOINT = .MELEE_MINION,
    .RANGED_MINION_SPAWNPOINT = .RANGED_MINION,
    .HEAVY_MINION_SPAWNPOINT = .HEAVY_MINION,
}

region_colors := [Region_ID]rl.Color {
    .NONE = rl.MAGENTA,
    .RED_BASE = STONE_COLOR,
    .RED_BEACH = SAND_COLOR,
    .RED_JUNGLE = JUNGLE_COLOR,
    .CENTRE = STONE_COLOR,
    .BLUE_JUNGLE = JUNGLE_COLOR,
    .BLUE_BEACH = SAND_COLOR,
    .BLUE_BASE = STONE_COLOR,
}

minion_initials := #partial [Space_Flag]cstring {
    .MELEE_MINION  = "M",
    .RANGED_MINION = "R",
    .HEAVY_MINION  = "H",
}

zone_indices: [Region_ID][dynamic]IVec2

board: [GRID_WIDTH][GRID_HEIGHT]Space

board_render_texture: rl.RenderTexture2D



get_symmetric_space :: proc(pos: IVec2) -> ^Space {
    sym_idx := IVec2{GRID_WIDTH, GRID_HEIGHT} - pos - 1
    return &board[sym_idx.x][sym_idx.y]
}

setup_space_positions :: proc() {
    for &x_arr, x_idx in board {
        for &space, y_idx in x_arr {
            x_value := BOARD_TEXTURE_SIZE.x / 2 + HORIZONTAL_SPACING * f32(x_idx - GRID_WIDTH / 2)
            // I don't even really know how this works but it does 
            y_value := BOARD_TEXTURE_SIZE.y / 2 - (0.5 * f32(x_idx + 1) + 0.25 - 0.25 * GRID_WIDTH + f32(y_idx) - 0.5 * GRID_HEIGHT) * VERTICAL_SPACING
            space.position = {x_value, y_value}
        }
    }
}

set_terrain_symmetric :: proc(x, y: int) {
    board[x][y].flags += {.TERRAIN}
    get_symmetric_space({x, y}).flags += {.TERRAIN}
}

setup_terrain :: proc() {
    for x_idx in 0..<GRID_WIDTH {
        for y_idx in 0..<GRID_HEIGHT {
            if x_idx == 0 || y_idx == 0 || x_idx + y_idx <= 8 {
                set_terrain_symmetric(x_idx, y_idx)
            }
        }
    }

    for vec in starting_terrain {
        set_terrain_symmetric(vec.x, vec.y)
    }
}

assign_region_symmetric :: proc(x, y: int, region_id: Region_ID) {
    board[x][y].region_id = region_id
    append(&zone_indices[region_id], IVec2{x, y})
    other_index := IVec2{GRID_WIDTH - x - 1, GRID_HEIGHT - y - 1}
    other_region := Region_ID(len(Region_ID) - int(region_id))
    board[other_index.x][other_index.y].region_id = other_region
    append(&zone_indices[other_region], other_index)
}

setup_regions :: proc() {
    // Bases
    for x_idx in 1..=4 {
        for y_idx in 6..=17 {
            if .TERRAIN in board[x_idx][y_idx].flags do continue
            if y_idx <= 14-x_idx {
                assign_region_symmetric(x_idx, y_idx, .RED_BASE)
            } else {
                assign_region_symmetric(x_idx, y_idx, .RED_JUNGLE)
            }
        }
    }

    for x_idx in 5..=8 {
        for y_idx in 3..=17 {
            if .TERRAIN in board[x_idx][y_idx].flags do continue
            if x_idx <= 6 && y_idx >= 16 {
                assign_region_symmetric(x_idx, y_idx, .RED_JUNGLE)
            } else if y_idx <= 16 - x_idx {
                assign_region_symmetric(x_idx, y_idx, .RED_BEACH)
            }
        }
    }

    for x_idx in 9..=12 {
        for y_idx in 1..=15-x_idx {
            if .TERRAIN in board[x_idx][y_idx].flags do continue
            assign_region_symmetric(x_idx, y_idx, .RED_BEACH)
        }
    }

    for x_idx in 5..=14 {
        for y_idx in 16-x_idx..=19-x_idx {
            if .TERRAIN in board[x_idx][y_idx].flags || board[x_idx][y_idx].region_id != .NONE do continue
            assign_region_symmetric(x_idx, y_idx, .CENTRE)
        }
    }
}

setup_spawnpoints :: proc() {
    for marker in spawnpoints {
        assert(marker.spawnpoint_flag in SPAWNPOINT_FLAGS)
        assert(marker.team != .NONE)
        space := &board[marker.loc.x][marker.loc.y]
        symmetric_space := get_symmetric_space(marker.loc)
        space.flags += {marker.spawnpoint_flag}
        symmetric_space.flags += {marker.spawnpoint_flag}

        space.spawnpoint_team = marker.team
        symmetric_space.spawnpoint_team = .BLUE if marker.team == .RED else .RED
    }
}

setup_board :: proc() {
    
    setup_space_positions()

    setup_terrain()

    setup_regions()

    setup_spawnpoints()
}

board_input_proc: UI_Input_Proc : proc(input: Input_Event, element: ^UI_Element) -> (output: bool = false) {

    board_element := assert_variant(&element.variant, UI_Board_Element)

    if !check_outside_or_deselected(input, element^) {
        board_element.hovered_space = {-1, -1}
        action := get_current_action(&player.hero)
        if player.stage == .RESOLVING && action != nil {
            if move_action, ok := action.variant.(Movement_Action); ok {
                resize(&move_action.path.spaces, move_action.path.num_locked_spaces)
            }
        }
        return false
    }

    output = true

    #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, Space_Clicked_Event{board_element.hovered_space})
    case Mouse_Motion_Event:
        mouse_within_board := ui_state.mouse_pos - {element.bounding_rect.x, element.bounding_rect.y}

        mouse_within_board *= BOARD_TEXTURE_SIZE / {element.bounding_rect.width, element.bounding_rect.height}

        closest_idx := IVec2{-1, -1}
        closest_dist: f32 = 1e6
        for arr, x in board {
            for space, y in arr {
                diff := (mouse_within_board - space.position)
                dist := diff.x * diff.x + diff.y * diff.y
                if dist < closest_dist && dist < VERTICAL_SPACING * VERTICAL_SPACING * 0.5 {
                    closest_idx = {x, y}
                    closest_dist = dist
                }
            }
        }
        if closest_idx.x >= 0 &&  .TERRAIN not_in board[closest_idx.x][closest_idx.y].flags {
            board_element.hovered_space = closest_idx
        } else {
            board_element.hovered_space = {-1, -1}
        }


        #partial switch player.stage {
        case .RESOLVING:
            action := get_current_action(&player.hero)
            #partial switch &action_variant in action.variant {
            case Movement_Action:
                resize(&action_variant.path.spaces, action_variant.path.num_locked_spaces)
                if board_element.hovered_space not_in action.targets {
                    break
                }

                starting_space: Target
                if action_variant.path.num_locked_spaces > 0 {
                    starting_space = action_variant.path.spaces[action_variant.path.num_locked_spaces - 1]
                } else {
                    starting_space = calculate_implicit_target(action_variant.target)
                }

                path, ok := find_shortest_path(starting_space, board_element.hovered_space).?
                if !ok do break
                defer delete(path)
                for space in path do append(&action_variant.path.spaces, space)

            }
        }
    }

    return
}

render_board_to_texture :: proc(board_element: UI_Board_Element) {
    rl.BeginTextureMode(board_render_texture)

    rl.ClearBackground(WATER_COLOR)

    for arr in board {
        for space in arr {
            color := rl.WHITE
            if .TERRAIN in space.flags do color = CLIFF_COLOR
            else do color = region_colors[space.region_id]
            rl.DrawPoly(space.position, 6, VERTICAL_SPACING / math.sqrt_f32(3), 0, color)

            // Make the highlight
            brightness_increase :: 50
            if .TERRAIN not_in space.flags {
                new_color := rl.WHITE
                for &val, idx in new_color do val = 255 if color[idx] + brightness_increase < color[idx] else color[idx] + brightness_increase
                rl.DrawPoly(space.position, 6, 0.9 * VERTICAL_SPACING / math.sqrt_f32(3), 0, new_color)
                rl.DrawCircleV(space.position, 0.92 * VERTICAL_SPACING / 2, color)
            }
            // if space != 

            spawnpoint_flags := space.flags & SPAWNPOINT_FLAGS
            if spawnpoint_flags != {} {
                color = team_colors[space.spawnpoint_team]
                if .HERO_SPAWNPOINT in space.flags {
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
                rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.45, color)
                rl.DrawTextEx(default_font, initial, {space.position.x - text_size.x / 2, space.position.y - text_size.y / 2.2}, FONT_SIZE, FONT_SPACING, rl.BLACK)

            }

            if .HERO in space.flags {
                color = team_colors[space.unit_team]
                name, ok := reflect.enum_name_from_value(space.hero_id); assert(ok)
                initial := strings.clone_to_cstring(name[:1])

                FONT_SIZE :: 0.8 * VERTICAL_SPACING

                text_size := rl.MeasureTextEx(default_font, initial, FONT_SIZE, FONT_SPACING)
                rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.45, color)
                rl.DrawTextEx(default_font, initial, {space.position.x - text_size.x / 2, space.position.y - text_size.y / 2.2}, FONT_SIZE, FONT_SPACING, rl.BLACK)
            }
        }
    }

    space_pos: Vec2
    if board_element.hovered_space != {-1, -1} {
        space_pos = board[board_element.hovered_space.x][board_element.hovered_space.y].position
        // rl.DrawRing(pos, VERTICAL_SPACING * 0.45, VERTICAL_SPACING * 0.5, 0, 360, 100, rl.WHITE)
        rl.DrawPolyLinesEx(space_pos, 6, VERTICAL_SPACING * (1 / math.sqrt_f32(3) + 0.05), 0, VERTICAL_SPACING * 0.05, rl.WHITE)
    }

    draw_hover_effect: #partial switch player.stage {
    case .RESOLVING:
        action := get_current_action(&player.hero)
        for target in action.targets {
            space := board[target.x][target.y]

            time := rl.GetTime()

            color_blend := (math.sin(2 * time) + 1) / 2
            color: = color_lerp(rl.WHITE, rl.VIOLET, color_blend)
            rl.DrawPolyLinesEx(space.position, 6, VERTICAL_SPACING / 2, 0, VERTICAL_SPACING * 0.08, color)
        }

        #partial switch variant in action.variant {
        case Fast_Travel_Action:
            if board_element.hovered_space not_in action.targets do break draw_hover_effect
            player_loc := player.hero.location
            player_pos := board[player_loc.x][player_loc.y].position
            rl.DrawLineEx(space_pos, player_pos, 4, rl.VIOLET)
        case Movement_Action:
            // target_slice := player.chosen_targets[:] if board_element.space_in_target_list else player.chosen_targets[:player.num_locked_targets]
            current_loc := calculate_implicit_target(variant.target)
            for target in variant.path.spaces {
                rl.DrawLineEx(board[current_loc.x][current_loc.y].position, board[target.x][target.y].position, 4, rl.VIOLET)
                current_loc = target
            }
        }
    }

    when ODIN_DEBUG {
        for x in 0..<GRID_WIDTH {
            for y in 0..<GRID_HEIGHT {
                space := board[x][y]
                coords := fmt.ctprintf("%d,%d", x, y)
                bound := rl.MeasureTextEx(default_font, coords, 30, 0)
                rl.DrawTextEx(default_font, coords, space.position - bound / 2, 30, 0, rl.BLACK)
            }
        }
    }

    rl.EndTextureMode()
}

draw_board: UI_Render_Proc : proc(element: UI_Element) {
    board_element, ok := element.variant.(UI_Board_Element)
    assert(ok)
    // render_board_to_texture(board_element)
    rl.DrawTexturePro(board_render_texture.texture, {0, 0, BOARD_TEXTURE_SIZE.x, -BOARD_TEXTURE_SIZE.y}, element.bounding_rect, {0, 0}, 0, rl.WHITE)

    rl.DrawRectangleLinesEx(BOARD_POSITION_RECT, 4, rl.WHITE)
}
