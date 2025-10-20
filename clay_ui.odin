package guards

import clay "clay-odin"
import "base:runtime"
import "core:strings"
import "core:fmt"
import "core:math"
import "core:reflect"
import sa "core:container/small_array"
import ba "core:container/bit_array"

_ :: fmt
_ :: ba

Render_Command_Array :: clay.ClayArray(clay.RenderCommand)


Font_ID :: enum u16 {
    Inter,
    Inconsolata,
}

BUTTON_HEIGHT :: 100
BUTTON_WIDTH  :: 400
BUTTON_TEXT_PADDING :: 20
SELECTION_BUTTON_SIZE :: Vec2{400, 100}

INFO_FONT_SIZE :: 40


SIZING_GROW :: clay.Sizing {
    clay.SizingAxis {
        type = .Grow,
    },
    clay.SizingAxis {
        type = .Grow,
    },
}

game_fonts: [Font_ID]Font

hot_element_id: clay.ElementId
active_element_id: clay.ElementId

clay_to_raylib_color :: proc(col: clay.Color) -> (out: Colour) {
    for val, idx in col do out[idx] = u8(val)
    return out
}

raylib_to_clay_color :: proc(col: Colour) -> (out: clay.Color) {
    for val, idx in col do out[idx] = f32(val)
    return out
}

clay_measure_text :: proc "c" (
    text: clay.StringSlice,
    config: ^clay.TextElementConfig,
    userData: rawptr,
) -> clay.Dimensions {

    context = runtime.default_context()

    text_string := strings.string_from_ptr(text.chars, int(text.length))
    text_cstring := strings.clone_to_cstring(text_string, context.temp_allocator)
    text_font_size := f32(config.fontSize)
    text_spacing := f32(config.letterSpacing)
    font := game_fonts[Font_ID(config.fontId)]

    return transmute(clay.Dimensions) measure_text_ex(font, text_cstring, text_font_size, text_spacing)
}

clay_button :: proc(
    id_string: string,
    text: string,
    width: f32 = -1
) -> bool {
    button_id := clay.ID(id_string)
    button_active := button_id == active_element_id
    button_hot := button_id == hot_element_id

    result: bool

    if clay.UI(id = button_id)({
        layout = {
            sizing = {
                width = width == -1 ? clay.SizingFixed(BUTTON_WIDTH) : clay.SizingFixed(width),
                height = clay.SizingFit(),
            },
            childAlignment = {
                x = .Center,
                y = .Center,
            },
            padding = clay.PaddingAll(BUTTON_TEXT_PADDING),
        },
        backgroundColor = button_active ? {100, 100, 100, 255} : {128, 128, 128, 255},
        border = {
            color = {255, 255, 255, 255},
            width = button_hot ? clay.BorderOutside(8) : {},
        },
    }) {
        if button_active {
            if .LEFT in ui_state.released_this_frame {
                if button_hot {
                    result = true
                }
                active_element_id = {}
            }
        } else if button_hot {
            if .LEFT in ui_state.pressed_this_frame {
                active_element_id = button_id
            }
        }
        if clay.Hovered() {
            if active_element_id == {} || button_active {
                hot_element_id = button_id
            }
        } else if button_hot {
            hot_element_id = {}
        }

        clay.TextDynamic(text, clay.TextConfig({
            textColor = {0, 0, 0, 255},
            fontId = u16(Font_ID.Inter),
            fontSize = u16(BUTTON_HEIGHT - 2 * BUTTON_TEXT_PADDING),
        }))
    }

    return result
}

clay_text_box :: proc(id_string: string, text_box: ^UI_Text_Box_Element) {
    text_box_id := clay.ID(id_string)
    text_box_active := active_element_id == text_box_id
    text_box_hot := hot_element_id == text_box_id
    if clay.UI(id = text_box_id)({
        layout = {
            sizing = {
                width = clay.SizingFixed(SELECTION_BUTTON_SIZE.x * 2),
                height = clay.SizingFit(),
            },
            padding = clay.PaddingAll(BUTTON_TEXT_PADDING),
        },
        backgroundColor = {0, 0, 0, 255},
        border = {
            color = {255, 255, 255, 255},
            width = clay.BorderOutside(4),
        },
    }) {
        TEXT_BOX_FONT_SIZE :: BUTTON_HEIGHT - 2 * BUTTON_TEXT_PADDING
        bounding_box := clay.GetElementData(text_box_id).boundingBox
        single_character_width := measure_text_ex(game_fonts[.Inconsolata], "_", TEXT_BOX_FONT_SIZE, 0).x
        mouse_pos := ui_state.mouse_pos

        // Mouse input
        if .LEFT in ui_state.pressed_this_frame {
            if text_box_hot {
                active_element_id = text_box_id

                index := int(math.round((mouse_pos.x - bounding_box.x - BUTTON_TEXT_PADDING) / single_character_width))
                index = clamp(index, 0, sa.len(text_box.field))

                text_box.cursor_index = index
                text_box.last_click_time = get_time()

            } else if text_box_active {
                active_element_id = {}
            }
        }

        if clay.Hovered() {
            if active_element_id == {} || text_box_active {
                hot_element_id = text_box_id
            }
        } else if text_box_hot {
            hot_element_id = {}
        }


        // Keyboard input
        if text_box_active {
            iterator := ba.make_iterator(&ui_state.keys_pressed_this_frame)
            for key_idx in ba.iterate_by_set(&iterator) {
                key := Keyboard_Key(key_idx)
                #partial switch key {
                case .BACKSPACE:
                    if text_box.cursor_index <= 0 do break
                    sa.ordered_remove(&text_box.field, text_box.cursor_index - 1)
                    text_box.cursor_index -= 1
                case .DELETE:
                    if text_box.cursor_index >= sa.len(text_box.field) do break
                    sa.ordered_remove(&text_box.field, text_box.cursor_index)
                case .LEFT:
                    text_box.cursor_index -= 1
                    text_box.cursor_index = clamp(text_box.cursor_index, 0, sa.len(text_box.field))
                    text_box.last_click_time = get_time()
                case .RIGHT:
                    text_box.cursor_index += 1
                    text_box.cursor_index = clamp(text_box.cursor_index, 0, sa.len(text_box.field))
                    text_box.last_click_time = get_time()
                case .V:
                    if !ba.get(&ui_state.keyboard_state, uint(Keyboard_Key.LEFT_CONTROL)) && !ba.get(&ui_state.keyboard_state, uint(Keyboard_Key.RIGHT_CONTROL)) do break
                    clipboard := cast([^]u8) get_clipboard_text()
                    for i := 0 ; clipboard[i] != 0; i += 1 {
                        if !sa.inject_at(&text_box.field, clipboard[i], text_box.cursor_index) {
                            break
                        }
                        text_box.cursor_index += 1
                    }
                }
            }

            switch ui_state.char_pressed_this_frame {
            case '0'..='9', '.':
                if sa.inject_at(&text_box.field, u8(ui_state.char_pressed_this_frame), text_box.cursor_index) {
                    text_box.cursor_index += 1
                }
            }
        }

        if text_box_active || sa.len(text_box.field) > 0 {
            clay.TextDynamic(string(sa.slice(&text_box.field)), clay.TextConfig({
                fontId = u16(Font_ID.Inconsolata),
                textColor = { 255, 255, 255, 255 },
                fontSize = u16(TEXT_BOX_FONT_SIZE),
            }))
        } else {
            clay.TextDynamic(text_box.default_string, clay.TextConfig({
                fontId = u16(Font_ID.Inconsolata),
                textColor = { 200, 200, 200, 255 },
                fontSize = u16(TEXT_BOX_FONT_SIZE),
            }))
        }

        // Prop to ensure box stays at correct height even with empty string
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingFixed(0),
                    height = clay.SizingFixed(TEXT_BOX_FONT_SIZE),
                },
            },
        }) {}
        
        // Cursor
        if text_box_active {
            CYCLE_TIME :: 1 // s
            time := (get_time() - text_box.last_click_time) / CYCLE_TIME
            time_remainder := (time - math.floor(time)) * CYCLE_TIME
            if time_remainder < CYCLE_TIME / 2.0 {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(0),
                            height = clay.SizingFixed(TEXT_BOX_FONT_SIZE),
                        },
                    },
                    border = {
                        {255, 255, 255, 255},
                        clay.BorderOutside(2),
                    },
                    floating = {
                        attachTo = .Parent,
                        offset = {
                            BUTTON_TEXT_PADDING + f32(text_box.cursor_index) * single_character_width,
                            BUTTON_TEXT_PADDING,
                        },
                    },
                    backgroundColor = {255, 0, 255, 255},
                }) {}
            }
        }
    }
}

clay_player_info :: proc(player: ^Player) {
    player_id_string := fmt.tprintf("player_%v", player.id)
    player_info_id := clay.ID(player_id_string)
    if clay.UI(id = player_info_id)({
        layout = {
            layoutDirection = .TopToBottom,
        },
    }) {
        username := string(cstring(raw_data(player._username_buf[:])))
        hero_name, _ := reflect.enum_name_from_value(player.hero.id)

        clay.TextDynamic(username, clay.TextConfig({
            fontId = u16(Font_ID.Inter),
            fontSize = INFO_FONT_SIZE,
            textColor = raylib_to_clay_color(team_colors[player.team]),
        }))

        clay.TextDynamic(hero_name, clay.TextConfig({
            fontId = u16(Font_ID.Inter),
            fontSize = INFO_FONT_SIZE,
            textColor = raylib_to_clay_color(team_colors[player.team]),
        }))

        // draw_text_ex(default_font, hero_name, next_pos, INFO_FONT_SIZE, FONT_SPACING, team_colors[player.team])
        // next_pos.y += INFO_FONT_SIZE + TEXT_PADDING

        // level_string := fmt.ctprintf("Level %v", player.hero.level)
        // draw_text_ex(default_font, level_string, next_pos, INFO_FONT_SIZE, FONT_SPACING, WHITE)
    }
}

clay_setup :: proc() {
    clay_min_memory_size := clay.MinMemorySize()

    arena_memory, _ := make([^]byte, clay_min_memory_size)
    clay_arena := clay.CreateArenaWithCapacityAndMemory(uint(clay_min_memory_size), arena_memory)
    clay.Initialize(clay_arena, {WIDTH, HEIGHT}, {})

    clay.SetMeasureTextFunction(clay_measure_text, nil)
}

clay_layout :: proc(gs: ^Game_State) -> Render_Command_Array {

    clay.SetLayoutDimensions({WIDTH, HEIGHT})

    mouse_position := ui_state.mouse_pos
    mouse_down := .LEFT in ui_state.mouse_state
    clay.SetPointerState(mouse_position, mouse_down)

    mouse_wheel := get_mouse_wheel_move_v()
    delta_time := get_frame_time()
    clay.UpdateScrollContainers(true, mouse_wheel, delta_time)
    
    tooltip_text := format_tooltip(gs, gs.tooltip)
    clay.BeginLayout()
    if clay.UI(id = clay.ID("outer_container"))({
        layout = {
            layoutDirection = .TopToBottom,
            childAlignment = {x = .Center},
            sizing = SIZING_GROW,
            padding = {16, 16, 16, 16},
        },
        backgroundColor = {10, 30, 40, 255},
    }) {
        clay.TextDynamic(
            tooltip_text,
            clay.TextConfig({
                textColor = {255, 255, 255, 255},
                fontSize = TOOLTIP_FONT_SIZE,
                fontId = u16(Font_ID.Inter),
            }),
        )

        #partial switch gs.stage {
        case .Pre_Lobby: clay_pre_lobby_screen(gs)
        case .In_Lobby:  clay_lobby_screen(gs)
        }
    }

    return clay.EndLayout()

}

clay_render :: proc(commands: ^Render_Command_Array) {
    for command_index in 0..<commands.length {
        command := clay.RenderCommandArray_Get(commands, command_index)
        bounding_box := command.boundingBox
        #partial switch command.commandType {
        case .Rectangle:
            draw_rectangle_rec(
                Rectangle(bounding_box),
                clay_to_raylib_color(command.renderData.rectangle.backgroundColor),
            )
        case .Text:
            text_data := command.renderData.text
            text_position := Vec2{bounding_box.x, bounding_box.y}
            text_string := strings.string_from_ptr(text_data.stringContents.chars, int(text_data.stringContents.length))
            text_cstring := strings.clone_to_cstring(text_string, context.temp_allocator)
            text_font_size := f32(text_data.fontSize)
            text_spacing := f32(text_data.letterSpacing)
            text_color := clay_to_raylib_color(text_data.textColor)
            font := game_fonts[Font_ID(text_data.fontId)]
            draw_text_ex(font, text_cstring, text_position, text_font_size, text_spacing, text_color)
        case .Border:
            config := command.renderData.border
            // Left border
            if config.width.left > 0 {
                draw_rectangle(i32(bounding_box.x), i32(bounding_box.y + config.cornerRadius.topLeft), i32(config.width.left), i32(bounding_box.height - config.cornerRadius.topLeft - config.cornerRadius.bottomLeft), clay_to_raylib_color(config.color))
            }
            // Right border
            if (config.width.right > 0) {
                draw_rectangle(i32(bounding_box.x + bounding_box.width - f32(config.width.right)), i32(bounding_box.y + config.cornerRadius.topRight), i32(config.width.right), i32(bounding_box.height - config.cornerRadius.topRight - config.cornerRadius.bottomRight), clay_to_raylib_color(config.color))
            }
            // Top border
            if (config.width.top > 0) {
                draw_rectangle(i32(bounding_box.x + config.cornerRadius.topLeft), i32(bounding_box.y), i32(bounding_box.width - config.cornerRadius.topLeft - config.cornerRadius.topRight), i32(config.width.top), clay_to_raylib_color(config.color))
            }
            // Bottom border
            if (config.width.bottom > 0) {
                draw_rectangle(i32(bounding_box.x + config.cornerRadius.bottomLeft), i32(bounding_box.y + bounding_box.height - f32(config.width.bottom)), i32(bounding_box.width - config.cornerRadius.bottomLeft - config.cornerRadius.bottomRight), i32(config.width.bottom), clay_to_raylib_color(config.color))
            }
            if (config.cornerRadius.topLeft > 0) {
                draw_ring(Vec2{ bounding_box.x + config.cornerRadius.topLeft, bounding_box.y + config.cornerRadius.topLeft }, (config.cornerRadius.topLeft - f32(config.width.top)), config.cornerRadius.topLeft, 180, 270, 10, clay_to_raylib_color(config.color))
            }
            if (config.cornerRadius.topRight > 0) {
                draw_ring(Vec2{ (bounding_box.x + bounding_box.width - config.cornerRadius.topRight), (bounding_box.y + config.cornerRadius.topRight) }, (config.cornerRadius.topRight - f32(config.width.top)), config.cornerRadius.topRight, 270, 360, 10, clay_to_raylib_color(config.color))
            }
            if (config.cornerRadius.bottomLeft > 0) {
                draw_ring(Vec2{ (bounding_box.x + config.cornerRadius.bottomLeft), (bounding_box.y + bounding_box.height - config.cornerRadius.bottomLeft) }, (config.cornerRadius.bottomLeft - f32(config.width.bottom)), config.cornerRadius.bottomLeft, 90, 180, 10, clay_to_raylib_color(config.color))
            }
            if (config.cornerRadius.bottomRight > 0) {
                draw_ring(Vec2 { (bounding_box.x + bounding_box.width - config.cornerRadius.bottomRight), (bounding_box.y + bounding_box.height - config.cornerRadius.bottomRight) }, (config.cornerRadius.bottomRight - f32(config.width.bottom)), config.cornerRadius.bottomRight, 0.1, 90, 10, clay_to_raylib_color(config.color))
            }
        }
    }
}


ip_text_box := UI_Text_Box_Element {
    default_string = "Enter IP Address...",
}

clay_pre_lobby_screen :: proc(gs: ^Game_State) {
    pre_lobby_id := clay.ID("pre_lobby_screen")
    if clay.UI(id = pre_lobby_id)({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = SIZING_GROW,
            childAlignment = {
                x = .Center,
                y = .Center,
            },
            childGap = 16,
        },
    }) {
        clay_text_box("ip_text_box", &ip_text_box)

        if clay_button("join_game_button", "Join a game", width = 2 * BUTTON_WIDTH) {
            append(&gs.event_queue, Join_Network_Game_Chosen_Event{})
        }

        // Spacer
        if clay.UI() ({
            layout = {
                sizing = {
                    // width = clay.SizingFixed(100),
                    height = clay.SizingFixed(100),
                },
            },
        }) {}

        if clay_button("host_game_button", "Host a game", width = 2 * BUTTON_WIDTH) {
            append(&gs.event_queue, Host_Game_Chosen_Event{})
        }
    }
}

clay_lobby_screen :: proc(gs: ^Game_State) {
    lobby_id := clay.ID("lobby_screen")
    if clay.UI(id = lobby_id)({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = SIZING_GROW,
            childGap = 16,
        },
    }) {
        // Player_sidebar
        player_sidebar_id := clay.ID("player_sidebar")
        if clay.UI(id = player_sidebar_id)({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingGrow({}),
                    height = clay.SizingGrow({}),
                },
            },
        }) {
            for &player in gs.players {
                clay_player_info(&player)
            }
        }

        // Central buttons
        central_button_area_id := clay.ID("central_button_area")
        if clay.UI(id = central_button_area_id)({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFit({}),
                    height = clay.SizingGrow({}),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
                childGap = 16,
            },
        }) {
            if gs.is_host {
                if clay_button("begin_game_button", "Begin game") {
                    broadcast_game_event(gs, Begin_Game_Event{})
                }
            }
            if clay_button("change_team_button", "Change team") {
                broadcast_game_event(gs, Change_Team_Event{gs.my_player_id})
            }
        }

        hero_sidebar_id := clay.ID("hero_sidebar")
        if clay.UI(id = hero_sidebar_id)({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingGrow({}),
                    height = clay.SizingGrow({}),
                },
                childAlignment = {
                    x = .Right,
                    y = .Center,
                },
                childGap = 16,
            },
        }) {
            for hero in Hero_ID {
                hero_name, _ := reflect.enum_name_from_value(hero)
                if clay_button(hero_name, hero_name) {
                    broadcast_game_event(gs, Change_Hero_Event{gs.my_player_id, hero})
                }
            }
        }
    }
}