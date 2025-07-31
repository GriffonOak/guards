package guards

import rl "vendor:raylib"
import "core:fmt"

VERTICAL_SPACING :: 50 / 2
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

GRID_WIDTH :: 21
GRID_HEIGHT :: 20

Space_Flag :: enum {
    TERRAIN,
    MINION,
}

Space_Flags :: bit_set[Space_Flag]

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
}

board: [GRID_WIDTH][GRID_HEIGHT]Space

board_render_texture: rl.RenderTexture2D


BOARD_TEXTURE_SIZE :: Vec2{500, 500}

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
        }
    }

    if board_element.hovered_cell != {-1, -1} {
        pos := board[board_element.hovered_cell.x][board_element.hovered_cell.y].position
        rl.DrawRing(pos, VERTICAL_SPACING * 0.45, VERTICAL_SPACING * 0.5, 0, 360, 100, rl.WHITE)
    }

    rl.EndTextureMode()
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
        append(&event_queue, Space_Clicked{board_element.hovered_cell})
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
    render_board_to_texture(board_element)
    rl.DrawTexturePro(board_render_texture.texture, {0, 0, BOARD_TEXTURE_SIZE.x, -BOARD_TEXTURE_SIZE.y}, element.bounding_rect, {0, 0}, 0, rl.WHITE)

    rl.DrawRectangleLinesEx(BOARD_POSITION_RECT, 4, rl.WHITE)

}
