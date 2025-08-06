package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"


// Todo list
// Separate cards out of the ui stack
// Unify different side buttons and have proc for adding / removing them
// Add attacking and skills to the game
// Add dummy blue player that acts randomly
// Snorri runes


// Ideas
// Could maybe be an idea to use bit_set[0..<GRID_WIDTH*GRID_HEIGHT] types for calculating the intersection between targets
// Might also be overkill :)

Window_Size :: enum {
    SMALL,
    BIG,
    FULL_SCREEN,
}


WIDTH :: 1280 * 2
HEIGHT :: 720 * 2

window_size: Window_Size = .SMALL

default_font: rl.Font
font_spacing :: 0

NULL_SPACE :: IVec2{-1, -1}

main :: proc() {

    fmt.println(BOARD_TEXTURE_SIZE.y / VERTICAL_SPACING)

    input_queue: [dynamic]Input_Event

    active_element_index: int = -1

    for color, index in Card_Color {
        // Add 100 to height here so the bounding rect goes offscreen
        card_hand_position_rects[color] = {f32(index - 1) * CARD_HAND_WIDTH, CARD_HAND_Y_POSITION, CARD_HAND_WIDTH, CARD_HAND_HEIGHT + 100}
    }

    append(&ui_stack, UI_Element {
        BOARD_POSITION_RECT,
        UI_Board_Element{},
        board_input_proc,
        draw_board,
    })

    window_scale: i32 = 2 if window_size == .SMALL else 1

    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(WIDTH / window_scale, HEIGHT / window_scale, "guards")
    defer rl.CloseWindow()

    default_font = rl.LoadFontEx("times.ttf", 200, nil, 0)
    // default_font = rl.LoadFont("Inconsolata-Regular.ttf")

    board_render_texture = rl.LoadRenderTexture(i32(BOARD_TEXTURE_SIZE.x), i32(BOARD_TEXTURE_SIZE.y))

    window_texture := rl.LoadRenderTexture(i32(WIDTH), i32(HEIGHT))

    setup_board()

    for &card, index in xargatha_cards {   
        create_texture_for_card(&card)
        card.state = .IN_HAND
        append(&ui_stack, UI_Element{
            card_hand_position_rects[card.color],
            UI_Card_Element{&card, false},
            card_input_proc,
            draw_card,
        })
    }

    append(&game_state.players, &player)
    begin_game()

    for !rl.WindowShouldClose() {

        // Handle input
        check_for_input_events(&input_queue)

        for event in input_queue {
            #partial switch var in event {
            case Key_Pressed_Event:
                if var.key == .EQUAL && window_size == .SMALL {
                    window_size = .BIG
                    rl.SetWindowSize(WIDTH, HEIGHT)
                } else if var.key == .MINUS && window_size == .BIG {
                    window_size = .SMALL
                    rl.SetWindowSize(WIDTH / 2, HEIGHT / 2)
                }
            }

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
        for event in event_queue {
            resolve_event(event)
        }
        clear(&event_queue)


        rl.BeginDrawing()

        render_board_to_texture(ui_stack[0].variant.(UI_Board_Element))

        rl.BeginTextureMode(window_texture)

        rl.ClearBackground(rl.BLACK)

        for element in ui_stack {
            element.render(element)
        }

        rl.EndTextureMode()

        rl.ClearBackground(rl.BLACK)

        // rl.DrawCircleV({200, 200}, 200, rl.RED)

        scale_factor: f32 = 1.0 if window_size == .BIG else 0.5
        rl.DrawTexturePro(
            window_texture.texture,
            {0, 0, WIDTH, -HEIGHT},
            {0, 0, scale_factor * WIDTH, scale_factor * HEIGHT},
            {0, 0}, 0, rl.WHITE
        )

        // rl.DrawCircleV({200, 200}, 200, rl.RED)

        rl.EndDrawing()
    }
}

