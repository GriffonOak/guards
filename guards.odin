package guards

import "core:time"

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

/* BEYOND 0.1

--- ENGINE 
    ^ "Intention" system for choose_target_action to allow different types of immunity (Sort of??)
    ^ "Hooks" system to allow other heroes to interrupt players performing actions (brogan, swift)

    - Store dead minions & allow respawn actions

    v Refactor heroes "out of" players (allow for multiple heroes controlled by 1 player)
    v Ultimates
    v Minions outside battle zone if path blocked (can use skip_index on the minion move action for this)

    vv Snorri runes


--- TESTING
    ^ Add test for xarg retrieval
    ^ make a bunch of new tests

    v Figure out why tests are so slow


--- UI / UX
    ^ Highlight chooseable cards for defense, & upgrading
    
    v map reposition (sam's ticket)
    v Highlight items when hovering over upgrade options
    v Full deck viewer
    v basic animations?
    v more toast for more things
    v FPS stats tracker (kohl's ticket)


--- MISC / IDEAS

    * Experiment with putting spall stuff in @init and @fini procs for test profiling
    * Always send team captain the minion removal event and just skip the choose step if there are more minions to remove than exist
    * Model wave push as an action sequence to obviate the need for interrupt_variant
*/



// @init
// startup :: proc() {
//     // log.infof("This ran at the start!")
//     // fmt.println("This ran at the start!")
// }

RELEASE :: #config(RELEASE, false)
RECORD  :: #config(RECORD, false)
REPLAY  :: #config(REPLAY, false)

// when REPLAY {
event_log_index := 0
event_queue_index := 0
// }

log_directory_name :: "logs"

Window_Size :: enum {
    Small,
    Big,
    Fullscreen,
}

Vec2 :: [2]f32

Void :: struct {}

WIDTH :: 1280 * 2
HEIGHT :: 720 * 2

FONT_SPACING :: 0

window_size: Window_Size = .Small

window_scale: f32 = 1 if window_size == .Big else 2

default_font: Font

monospace_font: Font

assets := #load_directory("assets")
emoji := #load_directory("assets/emoji")

hero_icons: [Hero_ID]Texture

minion_icons: [Space_Flag]Texture

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

start_time: time.Time
main :: proc() {
    start_time = time.now()
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
    }
    when RELEASE || RECORD {
        if !os.exists(log_directory_name) {
            os.make_directory(log_directory_name)
        }

        time_buf: [time.MIN_HMS_LEN]u8
        date_buf: [time.MIN_YYYY_DATE_LEN]u8

        now := time.now()

        time_string := time.to_string_hms(now, time_buf[:])
        date_string := time.to_string_yyyy_mm_dd(now, date_buf[:])
        for &r in time_buf do if r == ':' do r = '-'

        current_log_directory_name := fmt.tprintf("%v/log_%v_%v", log_directory_name, date_string, time_string)
        os.make_directory(current_log_directory_name)

        log_file_name := fmt.tprintf("%v/game.log", current_log_directory_name)
        record_file_name := fmt.tprintf("%v/events.log", current_log_directory_name)


        record_file, _ := os.open(record_file_name, os.O_RDWR | os.O_CREATE)
        defer stop_recording_events(record_file)
        begin_recording_events(record_file)

    }

    when RELEASE {
        log_file, _ := os.open(log_file_name, os.O_RDWR | os.O_CREATE)
        defer os.close(log_file)

        context.logger = log.create_file_logger(log_file, lowest = .Info)
        defer log.destroy_file_logger(context.logger)

        context.assertion_failure_proc = {}
    } else {
        context.logger = log.create_console_logger(lowest = .Info)
        defer log.destroy_console_logger(context.logger)
    }

    when REPLAY {
        fmt.println(len(event_log))
    }

    active_element_index := UI_Index{}
    hovered_element_index := UI_Index{}

    for color, index in Card_Color {
        // Add 100 to height here so the bounding rect goes offscreen
        card_hand_position_rects[color] = {f32(index) * CARD_HAND_WIDTH, CARD_HAND_Y_POSITION, CARD_HAND_WIDTH, CARD_HAND_HEIGHT + 100}
    }

    // window_scale: i32 = 2 if window_size == .Small else 1

    // set_config_flags({.WINDOW_TOPMOST})
    set_trace_log_level(.NONE)
    set_config_flags({.MSAA_4X_HINT})
    init_window(i32(WIDTH / window_scale), i32(HEIGHT / window_scale), "guards")
    defer close_window()

    for file in assets {
        switch file.name {
        case "Inter-VariableFont.ttf":
            default_font = load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        case "Inconsolata-Regular.ttf":
            monospace_font = load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        }
    }

    window_texture := load_render_texture(i32(WIDTH), i32(HEIGHT))
    set_texture_filter(window_texture.texture, .BILINEAR)

    gs: Game_State = {
        confirmed_players = 0,
        stage = .Pre_Lobby,
        tooltip = "Choose to host a game or join a game.",
    }

    setup_board(&gs)

    add_pre_lobby_ui_elements(&gs)

    for !window_should_close() {

        // Handle input
        // when !REPLAY {
            check_for_input_events(&input_queue)
        //

        for event in input_queue {
            #partial switch var in event {
            case Key_Pressed_Event:
                #partial switch var.key {
                case .EQUAL: increase_window_size()
                case .MINUS: decrease_window_size()
                case .F: toggle_fullscreen()
                case .M: add_marker(&gs)
                case: 
                    if active_element_index.domain != .None && active_element_index.index < len(gs.ui_stack[active_element_index.domain]) {
                        active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                        active_element.consume_input(&gs, event, active_element)
                    }
                }

            case Mouse_Motion_Event:
                // First "de-hover" the previous hovered element
                if hovered_element_index.domain != .None && hovered_element_index.index < len(gs.ui_stack[hovered_element_index.domain]) {
                    hovered_element := &gs.ui_stack[hovered_element_index.domain][hovered_element_index.index]
                    if board_element, ok := &hovered_element.variant.(UI_Board_Element); ok {
                        board_element.hovered_space = INVALID_TARGET
                    }
                    hovered_element.flags -= {.Hovered}
                }
                hovered_element_index = {}
                ui_search: for i := len(UI_Domain) - 1; i >= 0; i -= 1 {
                    domain := UI_Domain(i)
                    #reverse for &element, index in gs.ui_stack[domain] {
                        when ODIN_TEST {
                            continue
                        } else {
                            if !check_collision_point_rec(var.pos, element.bounding_rect) do continue
                        }
                        if element.consume_input(&gs, event, &element) {
                            element.flags += {.Hovered}
                            hovered_element_index = {domain, index}
                            break ui_search
                        }
                    }
                }
            case Mouse_Pressed_Event:
                if active_element_index.domain != .None && active_element_index.index < len(gs.ui_stack[active_element_index.domain]) {
                    active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                    active_element.flags -= {.Active}
                }
                active_element_index = hovered_element_index
                if hovered_element_index != {} {
                    active_element := &gs.ui_stack[active_element_index.domain][active_element_index.index]
                    active_element.flags += {.Active}
                    active_element.consume_input(&gs, event, active_element)
                }
            }
        }
        clear(&input_queue)

        // when !REPLAY {
            process_network_packets(&gs)
        // }

        // Record "Fresh" events this frame
        when RELEASE || RECORD {
            record_events(record_file, gs.event_queue[:])
        }

        // Handle events
        when REPLAY {
            if is_key_pressed(.SPACE) || is_key_pressed_repeat(.SPACE) {
                if event_queue_index >= len(gs.event_queue) {
                    clear(&gs.event_queue)
                    event_queue_index = 0
                    if event_log_index < len(event_log) {
                        append(&gs.event_queue, (&event_log[event_log_index])^)
                        event_log_index += 1
                    }
                }
                if event_queue_index < len(gs.event_queue) {
                    resolve_event(&gs, gs.event_queue[event_queue_index])
                    event_queue_index += 1
                }
            }
        } else {
            for event in gs.event_queue {
                if gs.game_over do break
                resolve_event(&gs, event)
            }
            clear(&gs.event_queue)
        }
        


        begin_drawing()

        if gs.stage != .Pre_Lobby && gs.stage != .In_Lobby {
            render_board_to_texture(&gs, gs.ui_stack[.Board][0])
        }

        begin_texture_mode(window_texture)

        clear_background(BLACK)

        for domain in UI_Domain {
            for element in gs.ui_stack[domain] {
                element.render(&gs, element)
            }
        }

        if gs.stage == .In_Lobby {
            pos := Vec2{10, 10}
            for player_id in 0..<len(gs.players) {
                render_player_info_at_position(&gs, player_id, pos)
                pos.y += 200
            }
        }

        if gs.stage != .Pre_Lobby && gs.stage != .In_Lobby {
            render_player_info(&gs)
        }
        render_tooltip(&gs)

        #reverse for &toast, index in gs.toasts {
            if get_time() > toast.start_time + toast.duration {
                ordered_remove(&gs.toasts, index)
            } else {
                draw_toast(&toast)
            }
        }

        end_texture_mode()

        clear_background(BLACK)

        draw_texture_pro(
            window_texture.texture,
            {0, 0, WIDTH, -HEIGHT},
            {0, 0, WIDTH / window_scale, HEIGHT / window_scale},
            {0, 0}, 0, WHITE,
        )

        end_drawing()

        free_all(context.temp_allocator)
    }
}

