package guards

import "core:time"

import "core:fmt"
import "core:math"
import "core:math/rand"
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

/*  FOR 0.6

--- ENGINE
    * Garrus
    * Bain
--- UI / UX
    * Display markers
*/

/* GENERAL

--- ENGINE
    ^^ Rewrite action value system (get rid of so many variant types, rely more on labels)

    * refactor choose target action to just repeat its begin_next_action when cancelling, like movement action
        * obviates the need for pop side button

    v Refactor heroes "out of" players (allow for multiple heroes controlled by 1 player)
    v Ultimates
    v Minions outside battle zone if path blocked (can use skip_index on the minion move action for this)

    vv Snorri runes


--- TESTING
    ^ Add test for xarg retrieval
    ^ make a bunch of new tests

    v Figure out why tests are so slow


--- UI / UX

    ^ Highlight chooseable cards for defense
    
    v Highlight items when hovering over upgrade options
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

Vec2 :: [2]f32

Void :: struct {}

STARTING_WIDTH :: 1280
STARTING_HEIGHT :: 720

FONT_SPACING :: 0

assets := #load_directory("assets")
card_backgrounds := #load_directory("assets/card_backgrounds")
emoji := #load_directory("assets/emoji")
icons := #load_directory("assets/icons")

UI_Icon_Kind :: enum {
    File_Box,
}

ui_icons: [UI_Icon_Kind]Texture

hero_icons: [Hero_ID]Texture

minion_icons: [Space_Flag]Texture

card_icons: [Card_Value_Kind]Texture
item_icons: [Card_Value_Kind]Texture
primary_icons: [Primary_Kind]Texture

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

    for char in '0'..='9' {
        ip_allowed_characters[char] = {}
        username_allowed_characters[char] = {}
    }
    for char in 'a'..='z' {
        username_allowed_characters[char] = {}
    }
    for char in 'A'..='Z' {
        username_allowed_characters[char] = {}
    }
    ip_allowed_characters['.'] = {}
    username_allowed_characters['_'] = {}

    // set_config_flags({.WINDOW_TOPMOST})
    set_trace_log_level(.NONE)
    set_config_flags({.MSAA_4X_HINT, .WINDOW_RESIZABLE, .WINDOW_MAXIMIZED})
    clay_setup()
    init_window(i32(STARTING_WIDTH), i32(STARTING_HEIGHT), "Guards")
    toggle_borderless_windowed()
    set_exit_key(.KEY_NULL)
    // fmt.println()
    
    // fmt.println(get_window_scale_dpi())
    scaled_border = u16(math.round(f32(get_render_width()) / 640))
    fmt.println(scaled_border)
    defer close_window()

    for file in assets {
        switch file.name {
        case "Inter_28pt-Regular.ttf":
            game_fonts[.Inter_Regular] = load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        case "Inter_28pt-Bold.ttf":
            game_fonts[.Inter_Bold] = load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
        case "Inter_28pt-SemiBold.ttf":
            font := load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
            game_fonts[.Inter_Semibold] = font
        case "Inconsolata-Regular.ttf":
            font := load_font_from_memory(".ttf", raw_data(file.data), i32(len(file.data)), 200, nil, 0)
            game_fonts[.Inconsolata] = font
        }
    }
    setup_icons()

    // window_texture := load_render_texture(i32(WIDTH), i32(HEIGHT))
    // set_texture_filter(window_texture.texture, .BILINEAR)

    gs: Game_State = {
        confirmed_players = 0,
        screen = .Title,
        tooltip = "Enter a username, then host or join a game.",
    }

    setup_board(&gs)
    random_tiebreaker := rand.int31_max(2)
    append(&gs.event_queue, Update_Tiebreaker_Event{.Red if random_tiebreaker == 0 else .Blue})

    for !window_should_close() {

        // Handle input
        // when !REPLAY {
            check_for_input_events(&input_queue)
        //

        for event in input_queue {
            #partial switch var in event {
            case Key_Pressed_Event:
                #partial switch var.key {
                case .F11:
                    if is_window_state({.BORDERLESS_WINDOWED_MODE}) {
                        new_width := get_render_width() / 2
                        new_height := get_render_height() / 2
                        toggle_borderless_windowed()
                        set_window_size(new_width, new_height)
                        scaled_border /= 2
                        if scaled_border < 1 do scaled_border = 1
                    } else {
                        toggle_borderless_windowed()
                        scaled_border *= 2
                    }
                case .M: add_marker(&gs)
                case .EQUAL:
                    scaled_border = clamp(scaled_border + 1, 1, 20)
                case .MINUS:
                    scaled_border = clamp(scaled_border - 1, 1, 20)
                case: 
                }
            }
        }
        clear(&input_queue)

        clay_layout(&gs)

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
        
        clay_render_commands := clay_layout(&gs)

        begin_drawing()

        clay_render(&gs, &clay_render_commands)

        end_drawing()


        free_all(context.temp_allocator)
    }
}

