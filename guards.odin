package guards

import "core:time"

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"
import "core:log"
import "core:os"
import "core:mem"
import "core:prof/spall"
// import "base:runtime"
// import "core:sync"

_ :: fmt
_ :: mem
_ :: math
_ :: strings
_ :: os
_ :: time

// Todo list
// Dodger  (Primary defense, choose minion type ????)
// Card values refactor?
// Refactor heroes "out of" players (allow for multiple heroes controlled by 1 player)
// Test for xarg retrieval
// Figure out why tests are so slow

// Highlight chooseable cards for defense, & upgrading
// Highlight items when hovering over upgrade options
// Full deck viewer
// Xargatha ult

// Xargatha LITERALLY DONE after this point !!!!

// Toast, for a bit of flair & usability
// basic animations?

// Enter IP for joining games

// Minions outside battle zone if path blocked
// Snorri runes

// Experiment with putting spall stuff in @init and @fini procs for test profiling


// Ideas
// Could maybe be an idea to use bit_set[0..<GRID_WIDTH*GRID_HEIGHT] types for calculating the intersection between targets
// Alternatively, Could use a fixed array of bit field structs
// Might also be overkill :)
// Refactor ability_kind and item_kind together
// Refactor skip_index in actions as next_index and use that to skip to the halt sequence instead of having a literal halt action
// Always send team captain the minion removal event and just skip the choose step if there are more minions to remove than exist
// Model wave push as an action sequence to obviate the need for interrupt_variant




@init
startup :: proc() {
    log.infof("This ran at the start!")
    fmt.println("This ran at the start!")
}

Window_Size :: enum {
    SMALL,
    BIG,
    FULL_SCREEN,
}

Vec2 :: [2]f32
// IVec2 :: [2]int

Rectangle :: rl.Rectangle

Void :: struct {}



WIDTH :: 1280 * 2
HEIGHT :: 720 * 2

FONT_SPACING :: 0



window_size: Window_Size = .SMALL

window_scale: f32 = 1 if window_size == .BIG else 2

default_font: rl.Font

monospace_font: rl.Font

assets := #load_directory("assets")

spall_ctx: spall.Context
@(thread_local) spall_buffer: spall.Buffer

// @(instrumentation_enter)
// spall_enter :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
// 	spall._buffer_begin(&spall_ctx, &spall_buffer, "", "", loc)
// }

// @(instrumentation_exit)
// spall_exit :: proc "contextless" (proc_address, call_site_return_address: rawptr, loc: runtime.Source_Code_Location) {
// 	spall._buffer_end(&spall_ctx, &spall_buffer)
// }


main :: proc() {

    // spall_ctx = spall.context_create("trace_test.spall")
	// defer spall.context_destroy(&spall_ctx)

	// buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
	// defer delete(buffer_backing)

	// spall_buffer = spall.buffer_create(buffer_backing, u32(sync.current_thread_id()))
	// defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

	// spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

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
    defer log.destroy_console_logger(context.logger)

    defer if recording_events {
        stop_recording_events()
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

    active_element_index := UI_Index{}
    hovered_element_index := UI_Index{}

    for color, index in Card_Color {
        // Add 100 to height here so the bounding rect goes offscreen
        card_hand_position_rects[color] = {f32(index) * CARD_HAND_WIDTH, CARD_HAND_Y_POSITION, CARD_HAND_WIDTH, CARD_HAND_HEIGHT + 100}
    }

    // window_scale: i32 = 2 if window_size == .SMALL else 1

    // rl.SetConfigFlags({.WINDOW_TOPMOST})
    rl.SetConfigFlags({.MSAA_4X_HINT})
    rl.InitWindow(i32(WIDTH / window_scale), i32(HEIGHT / window_scale), "guards")
    defer rl.CloseWindow()

    for file in assets {
        switch file.name {
        case "Inter-VariableFont.ttf":
            default_font = rl.LoadFontFromMemory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        case "Inconsolata-Regular.ttf":
            monospace_font = rl.LoadFontFromMemory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        }
    }

    window_texture := rl.LoadRenderTexture(i32(WIDTH), i32(HEIGHT))
    rl.SetTextureFilter(window_texture.texture, .BILINEAR)

    gs: Game_State = {
        confirmed_players = 0,
        stage = .PRE_LOBBY,
        tooltip = "Choose to host a game or join a game.",
    }

    setup_board(&gs)

    add_pre_lobby_ui_elements(&gs)

    // append(&gs.event_queue, Toggle_Fullscreen_Event{})
    // begin_game()

    for !rl.WindowShouldClose() {

        // Handle input
        check_for_input_events(&input_queue)

        for event in input_queue {
            #partial switch var in event {
            case Key_Pressed_Event:
                #partial switch var.key {
                case .EQUAL: increase_window_size()
                case .MINUS: decrease_window_size()
                case .F: toggle_fullscreen()
                case .M: add_marker(&gs)
                case: 
                    if active_element_index.domain != .NONE && active_element_index.index < len(gs.ui_stack[active_element_index.domain]) {
                        active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                        active_element.consume_input(&gs, event, active_element)
                    }
                }

            case Mouse_Motion_Event:
                // First "de-hover" the previous hovered element
                if hovered_element_index.domain != .NONE && hovered_element_index.index < len(gs.ui_stack[hovered_element_index.domain]) {
                    hovered_element := &gs.ui_stack[hovered_element_index.domain][hovered_element_index.index]
                    if _, ok := hovered_element.variant.(UI_Card_Element); ok {
                        breakpoint()
                    }
                    hovered_element.flags -= {.HOVERED}
                }
                hovered_element_index = {}
                ui_search: for i := len(UI_Domain) - 1; i >= 0; i -= 1 {
                    domain := UI_Domain(i)
                    #reverse for &element, index in gs.ui_stack[domain] {
                        when ODIN_TEST {
                            continue
                        } else {
                            if !rl.CheckCollisionPointRec(var.pos, element.bounding_rect) do continue
                        }
                        if element.consume_input(&gs, event, &element) {
                            element.flags += {.HOVERED}
                            hovered_element_index = {domain, index}
                            break ui_search
                        }
                    }
                }
            case Mouse_Pressed_Event:
                if active_element_index.domain != .NONE && active_element_index.index < len(gs.ui_stack[active_element_index.domain]) {
                    active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                    active_element.flags -= {.ACTIVE}
                }
                active_element_index = hovered_element_index
                if hovered_element_index != {} {
                    active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                    active_element.flags += {.ACTIVE}
                    active_element.consume_input(&gs, event, active_element)
                }
            }
        }
        clear(&input_queue)

        process_network_packets(&gs)

        // Record "Fresh" events this frame
        if recording_events {
            record_events(gs.event_queue[:])
        }

        // Handle events
        for event in gs.event_queue {
            resolve_event(&gs, event)
        }
        clear(&gs.event_queue)


        rl.BeginDrawing()

        if gs.stage != .PRE_LOBBY && gs.stage != .IN_LOBBY {
            render_board_to_texture(&gs, gs.ui_stack[.BOARD][0])
        }

        rl.BeginTextureMode(window_texture)

        rl.ClearBackground(rl.BLACK)

        for domain in UI_Domain {
            for element in gs.ui_stack[domain] {
                element.render(&gs, element)
            }
        }

        if gs.stage == .IN_LOBBY {
            pos := Vec2{10, 10}
            for player_id in 0..<len(gs.players) {
                render_player_info_at_position(&gs, player_id, pos)
                pos.y += 200
            }
        }

        if gs.stage != .PRE_LOBBY && gs.stage != .IN_LOBBY {
            render_player_info(&gs)
        }
        render_tooltip(&gs)

        #reverse for &toast, index in gs.toasts {
            if rl.GetTime() > toast.start_time + toast.duration {
                ordered_remove(&gs.toasts, index)
            } else {
                draw_toast(&toast)
            }
        }

        rl.EndTextureMode()

        rl.ClearBackground(rl.BLACK)

        rl.DrawTexturePro(
            window_texture.texture,
            {0, 0, WIDTH, -HEIGHT},
            {0, 0, WIDTH / window_scale, HEIGHT / window_scale},
            {0, 0}, 0, rl.WHITE,
        )

        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
}

