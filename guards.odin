package guards


import rl "vendor:raylib"
import "core:fmt"
// import "core:math"
// import "core:strings"
import "core:log"

import "core:mem"


// Todo list
// Once those are figured out, do xargatha minion defeat greens
// Finish implementing xargatha cards (retrieval blues)
// Reaffirm stone gaze works lol
// Highlight chooseable cards for selection, defense, & upgrading
// Highlight items when hovering over upgrade options
// Xargatha ult

// Xargatha LITERALLY DONE after this point !!!!

// Toast, for a bit of flair & usability
// basic animations?
// Other heroes / hero picker
// Lobby that isn't ass
// Minions outside battle zone if path blocked
// Snorri runes


// Ideas
// Could maybe be an idea to use bit_set[0..<GRID_WIDTH*GRID_HEIGHT] types for calculating the intersection between targets
// Might also be overkill :)
// Refactor skip_index in actions as next_index and use that to skip to the halt sequence instead of having a literal halt action
// Always send team captain the minion removal event and just skip the choose step if there are more minions to remove than exist
// Model wave push as an action sequence to obviate the need for interrupt_variant



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

window_scale: f32 = 1 if window_size == .BIG else 2

default_font: rl.Font



main :: proc() {

    {  // Do the heroes!
        hero_cards[.XARGATHA] = xargatha_cards
    }

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
        card_hand_position_rects[color] = {f32(index) * CARD_HAND_WIDTH, CARD_HAND_Y_POSITION, CARD_HAND_WIDTH, CARD_HAND_HEIGHT + 100}
    }



    // window_scale: i32 = 2 if window_size == .SMALL else 1

    // rl.SetConfigFlags({.WINDOW_TOPMOST})
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(i32(WIDTH / window_scale), i32(HEIGHT / window_scale), "guards")
    defer rl.CloseWindow()

    default_font = rl.LoadFontEx("times.ttf", 200, nil, 0)
    // default_font = rl.LoadFont("Inconsolata-Regular.ttf")

    board_render_texture = rl.LoadRenderTexture(i32(BOARD_TEXTURE_SIZE.x), i32(BOARD_TEXTURE_SIZE.y))

    window_texture := rl.LoadRenderTexture(i32(WIDTH), i32(HEIGHT))
    rl.SetTextureFilter(window_texture.texture, .BILINEAR)

    setup_board()

    game_state.stage = .PRE_LOBBY
    tooltip = "Choose to host a game or join a game."
    add_choose_host_ui_elements()

    // append(&event_queue, Toggle_Fullscreen_Event{})
    // begin_game()

    for !rl.WindowShouldClose() {

        // Handle input
        check_for_input_events(&input_queue)

        for event in input_queue {
            #partial switch var in event {
            case Key_Pressed_Event:
                #partial switch var.key {
                case .EQUAL: append(&event_queue, Increase_Window_Size_Event{})
                case.MINUS: append(&event_queue, Decrease_Window_Size_Event{})
                case .F: append(&event_queue, Toggle_Fullscreen_Event{})
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

        process_network_packets()

        // Handle events
        for event in event_queue {
            resolve_event(event)
        }
        clear(&event_queue)


        rl.BeginDrawing()

        if game_state.stage != .PRE_LOBBY && game_state.stage != .IN_LOBBY {
            render_board_to_texture(ui_stack[0].variant.(UI_Board_Element))
        }

        rl.BeginTextureMode(window_texture)

        rl.ClearBackground(rl.BLACK)

        for element in ui_stack {
            element.render(element)
        }

        if game_state.stage == .IN_LOBBY {
            pos := Vec2{10, 10}
            for player_id in 0..<len(game_state.players) {
                render_player_info_at_position(player_id, pos)
                pos.y += 200
            }
        }

        if game_state.stage != .PRE_LOBBY && game_state.stage != .IN_LOBBY {
            render_player_info()
        }
        render_tooltip()

        rl.EndTextureMode()

        rl.ClearBackground(rl.BLACK)

        // rl.DrawCircleV({200, 200}, 200, rl.RED)

        // scale_factor: f32 = 1.0 if window_size == .BIG else 0.5
        rl.DrawTexturePro(
            window_texture.texture,
            {0, 0, WIDTH, -HEIGHT},
            {0, 0, WIDTH / window_scale, HEIGHT / window_scale},
            {0, 0}, 0, rl.WHITE,
        )

        // rl.DrawCircleV({200, 200}, 200, rl.RED)

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}

