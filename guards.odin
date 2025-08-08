package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"
import "core:log"

import "core:mem"


// Todo list
// Separate cards out of the ui stack
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

Vec2 :: [2]f32
IVec2 :: [2]int

Void :: struct {}



WIDTH :: 1280 * 2
HEIGHT :: 720 * 2

FONT_SPACING :: 0



window_size: Window_Size = .SMALL

default_font: rl.Font



main :: proc() {


    when ODIN_DEBUG {
        default_allocator := context.allocator
        tracking_allocator: mem.Tracking_Allocator
        mem.tracking_allocator_init(&tracking_allocator, default_allocator)
        context.allocator = mem.tracking_allocator(&tracking_allocator)

        context.logger = log.create_console_logger()

        defer {
            for _, entry in tracking_allocator.allocation_map {
                log.debugf("- %v leaked %v bytes", entry.location, entry.size)
            }
            for entry in tracking_allocator.bad_free_array {
                log.debugf("- %v bad free", entry.location)
            }
            mem.tracking_allocator_destroy(&tracking_allocator)
        }
    } else {
        context.logger = log.create_console_logger(lowest = .Info)
    }

    
    // arena_buffer := make([]u8, 80000)
    // defer delete(arena_buffer)

    // arena: mem.Arena
    // mem.arena_init(&arena, arena_buffer[:])
    // arena_allocator := mem.arena_allocator(&arena)
    // context.allocator = arena_allocator

    // defer free_all(arena_allocator)

    // input_queue = make([dynamic]Input_Event)
    // event_queue = make([dynamic]Event)

    defer {
        delete(input_queue)
        delete(event_queue)
        for id in Region_ID do delete(zone_indices[id])
        delete(ui_stack)
        delete(game_state.players)
    }

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

        render_tooltip()

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

        free_all(context.temp_allocator)
    }
}

