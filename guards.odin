package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"


Vec2 :: [2]f32

IVec2 :: [2]int


WIDTH :: 1000
HEIGHT :: 750

Region_ID :: enum {
    NONE,
    RED_BASE,
    RED_BEACH,
    RED_JUNGLE,
    CENTRE,
    BLUE_JUNGLE,
    BLUE_BEACH,
    BLUE_BASE,
}

CLIFF_COLOR :: rl.Color{80, 76, 75, 255}
SAND_COLOR :: rl.Color{240, 200, 138, 255}
STONE_COLOR :: rl.Color{185, 140, 93, 255}
JUNGLE_COLOR :: rl.Color{157, 177, 58, 255}

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

set_terrain_symmetric :: proc(x, y: int) {
    board[x][y].flags += {.TERRAIN}
    board[GRID_WIDTH - x - 1][GRID_HEIGHT - y - 1].flags += {.TERRAIN}
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
    board[GRID_WIDTH - x - 1][GRID_HEIGHT - y - 1].region_id = Region_ID(len(Region_ID) - int(region_id))
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

ui_stack: [dynamic]UI_Element

// hand: [dynamic]UI_Card_Element

main :: proc() {

    input_queue: [dynamic]Input_Event

    active_element_index: int = -1

    for color, index in Card_Color {
        CARD_HAND_WIDTH := BOARD_POSITION_RECT.width / 5
        card_hand_position_rects[color] = {f32(index - 1) * CARD_HAND_WIDTH, HEIGHT - 50, CARD_HAND_WIDTH, 50}
    }

    append(&ui_stack, UI_Element {
        BOARD_POSITION_RECT,
        UI_Board_Element{},
        board_input_proc,
        draw_board,
    })

    rl.InitWindow(WIDTH, HEIGHT, "guards")
    defer rl.CloseWindow()

    board_render_texture = rl.LoadRenderTexture(i32(BOARD_TEXTURE_SIZE.x), i32(BOARD_TEXTURE_SIZE.y))

    setup_space_positions()

    setup_terrain()

    setup_regions()

    for &card, index in xargatha_cards {
        
        create_texture_for_card(&card)
        append(&ui_stack, UI_Element{
            card_hand_position_rects[card.color],
            UI_Card_Element{.IN_HAND, &card, false},
            card_input_proc,
            draw_card,
        })
    }

    for !rl.WindowShouldClose() {

        // Handle input
        check_for_input_events(&input_queue)

        for event in input_queue {
            next_active_element_index := -1
            #reverse for &element, index in ui_stack {
                if element.consume_input(event, &element) {
                    next_active_element_index = index
                    break
                }
            }
            if next_active_element_index != active_element_index && active_element_index >= 0 && active_element_index < len(ui_stack){
                active_element := &ui_stack[active_element_index]
                active_element.consume_input(Input_Already_Consumed{}, active_element)
            }
            active_element_index = next_active_element_index
        }
        clear(&input_queue)

        // Handle events
        // for event in event_queue {
        //     resolve_event(event)
        // }


        rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)

        for element in ui_stack {
            element.render(element)
        }

        rl.EndDrawing()
    }
}

