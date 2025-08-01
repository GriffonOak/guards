package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"

VERTICAL_SPACING :: 66
// sqrt 3
HORIZONTAL_SPACING :: 1.732 * VERTICAL_SPACING * 0.5

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

zone_indices: [Region_ID][dynamic]IVec2

spawnpoints := [?]Spawnpoint_Marker{
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

GRID_WIDTH :: 21
GRID_HEIGHT :: 20

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
}

Space_Flags :: bit_set[Space_Flag]

SPAWNPOINT :: Space_Flags{.MELEE_MINION_SPAWNPOINT, .RANGED_MINION_SPAWNPOINT, .HEAVY_MINION_SPAWNPOINT, .HERO_SPAWNPOINT}

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
    spawn_point_team: Team,
    unit_team: Team,
}

board: [GRID_WIDTH][GRID_HEIGHT]Space

board_render_texture: rl.RenderTexture2D


BOARD_TEXTURE_SIZE :: Vec2{1200, 1200}

BOARD_POSITION_RECT :: rl.Rectangle{0, 0, BOARD_TEXTURE_SIZE.x, BOARD_TEXTURE_SIZE.y}


render_board_to_texture :: proc(board_element: UI_Board_Element) {
    rl.BeginTextureMode(board_render_texture)

    rl.ClearBackground(rl.BLACK)

    for arr in board {
        for space in arr {
            color := rl.WHITE
            if .TERRAIN in space.flags do color = CLIFF_COLOR
            else do color = region_colors[space.region_id]
            rl.DrawCircleV(space.position, VERTICAL_SPACING * 0.45, color)

            spawnpoint_flags := space.flags & SPAWNPOINT
            if spawnpoint_flags != {} {
                color = team_colors[space.spawn_point_team]
                if .HERO_SPAWNPOINT in space.flags {
                    rl.DrawRing(space.position, VERTICAL_SPACING * 0.35, VERTICAL_SPACING * 0.26, 0, 360, 20, color)
                } else {
                    // spawnpoint_type := Space_Flag(log2(transmute(int) spawnpoint_flags))
                    spawnpoint_type: Space_Flag
                    slice := []Space_Flag{.MELEE_MINION_SPAWNPOINT, .RANGED_MINION_SPAWNPOINT, .HEAVY_MINION_SPAWNPOINT}
                    for flag in slice {
                        if flag in spawnpoint_flags {
                            spawnpoint_type = flag
                            break
                        }
                    }
                    initial := spawnpoint_initials[spawnpoint_type]

                    FONT_SIZE :: 0.8 * VERTICAL_SPACING

                    text_size := rl.MeasureTextEx(rl.GetFontDefault(), initial, FONT_SIZE, 0)
                    rl.DrawText(initial, i32(space.position.x - text_size.x / 2), i32(space.position.y - text_size.y / 2.2), i32(math.round_f32(FONT_SIZE)), color)
                }
            }

        }
    }

    if board_element.hovered_cell != {-1, -1} {
        pos := board[board_element.hovered_cell.x][board_element.hovered_cell.y].position
        rl.DrawRing(pos, VERTICAL_SPACING * 0.45, VERTICAL_SPACING * 0.5, 0, 360, 100, rl.WHITE)
    }

    rl.EndTextureMode()
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
    board[GRID_WIDTH - x - 1][GRID_HEIGHT - y - 1].flags += {.TERRAIN}
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
        assert(marker.spawnpoint_flag in SPAWNPOINT)
        assert(marker.team != .NONE)
        space := &board[marker.loc.x][marker.loc.y]
        symmetric_space := &board[GRID_WIDTH - marker.loc.x - 1][GRID_HEIGHT - marker.loc.y - 1]
        space.flags += {marker.spawnpoint_flag}
        symmetric_space.flags += {marker.spawnpoint_flag}

        space.spawn_point_team = marker.team
        symmetric_space.spawn_point_team = .BLUE if marker.team == .RED else .RED
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
        board_element.hovered_cell = {-1, -1}
        return false
    }

    output = true

    #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, Space_Clicked_Event{board_element.hovered_cell})
    case Mouse_Motion_Event:
        mouse_within_board := ui_state.mouse_pos - {element.bounding_rect.x, element.bounding_rect.y}

        mouse_within_board *= BOARD_TEXTURE_SIZE / {element.bounding_rect.width, element.bounding_rect.height}
        // mouse_within_board += {VERTICAL_SPACING / 2, VERTICAL_SPACING / 2}

        // x_idx := int((mouse_within_board.x - BOARD_TEXTURE_SIZE.x / 2) / HORIZONTAL_SPACING + GRID_WIDTH / 2)

        // y_idx := int((BOARD_TEXTURE_SIZE.y / 2 - mouse_within_board.y) / VERTICAL_SPACING + 0.5 * GRID_HEIGHT - 0.25 - 0.5 * f32(x_idx + 1) + 0.25 * GRID_WIDTH)
        // if x_idx < 0 || x_idx >= GRID_WIDTH || y_idx < 0 || y_idx >= GRID_HEIGHT do board_element.hovered_cell = {-1, -1}
        // else do board_element.hovered_cell = {x_idx, y_idx}

        closest_idx := IVec2{-1, -1}
        closest_dist: f32 = 1e6
        for arr, x in board {
            for space, y in arr {
                diff := (mouse_within_board - space.position)
                dist := diff.x * diff.x + diff.y * diff.y
                if dist < closest_dist && dist < VERTICAL_SPACING * VERTICAL_SPACING * 0.25 {
                    closest_idx = {x, y}
                    closest_dist = dist
                }
            }
        }
        board_element.hovered_cell = closest_idx
    }

    return
}

draw_board: UI_Render_Proc : proc(element: UI_Element) {
    board_element, ok := element.variant.(UI_Board_Element)
    assert(ok)
    // render_board_to_texture(board_element)
    rl.DrawTexturePro(board_render_texture.texture, {0, 0, BOARD_TEXTURE_SIZE.x, -BOARD_TEXTURE_SIZE.y}, element.bounding_rect, {0, 0}, 0, rl.WHITE)

    rl.DrawRectangleLinesEx(BOARD_POSITION_RECT, 4, rl.WHITE)

}
