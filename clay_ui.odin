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
    Inter_Regular,
    Inter_Semibold,
    Inter_Bold,
    Inconsolata,
}

Board_Element :: struct {
    hovered_space: Target,
}

Arrow_Direction :: enum {
    Up,
    Down,
    Left,
    Right,
}

Arrow_Indicator :: struct {
    direction: Arrow_Direction,
    line_thick: f32,
    color: clay.Color,
}

Custom_UI_Element :: union {
    Board_Element,
    Arrow_Indicator,
}

Palette_Font :: enum {
    Default_Regular,
    Default_Semibold,
    Default_Bold,
    Monospace,
}

Palette_Color :: enum {
    Background,

    Red_Team_Light,
    Red_Team_Mid,
    Red_Team_Dark,

    Blue_Team_Light,
    Blue_Team_Mid,
    Blue_Team_Dark,

    Light_Gray,
    Gray,
    Dark_Gray,

    Card_Gold,
    Card_Silver,
    Card_Red,
    Card_Green,
    Card_Blue,

    White,
    Black,

    Undefined_Magenta,
}

@rodata
PALETTE := [Palette_Color]clay.Color {
    .Background = {30, 30, 30, 255},
    // .Background = {170, 139, 93, 255},

    .Red_Team_Light = {237, 92, 2, 255},
    .Red_Team_Mid = {158, 61, 1, 255},  // 2/3 of light
    .Red_Team_Dark = {79, 31, 1, 255},  // 1/3 of light

    .Blue_Team_Light = {22, 147, 255, 255},
    .Blue_Team_Mid = {15, 98, 170, 255},  // 2/3 of light
    .Blue_Team_Dark = {7, 49, 85, 255},   // 1/3 of light

    .Light_Gray = {200, 200, 200, 255},
    .Gray = {125, 125, 125, 255},
    .Dark_Gray = {75, 75, 75, 255},

    .Card_Gold = {255, 203, 0, 255},
    .Card_Silver = {130, 130, 130, 255},
    .Card_Red = {230, 41, 55, 255},
    .Card_Green = {0, 158, 47, 255},
    .Card_Blue = {0, 121, 241, 255},

    .White = {255, 255, 255, 255},
    .Black = {0, 0, 0, 255},

    .Undefined_Magenta = {255, 0, 255, 255},
}

@rodata
FONT_PALETTE := [Palette_Font]u16 {
    .Default_Regular =  u16(Font_ID.Inter_Regular),
    .Default_Semibold = u16(Font_ID.Inter_Semibold),
    .Default_Bold =     u16(Font_ID.Inter_Bold),
    .Monospace =        u16(Font_ID.Inconsolata),
}

team_light_colors := [Team]clay.Color {
    .Red = PALETTE[.Red_Team_Light],
    .Blue = PALETTE[.Blue_Team_Light],
}

team_mid_colors := [Team]clay.Color {
    .Red = PALETTE[.Red_Team_Mid],
    .Blue = PALETTE[.Blue_Team_Mid],
}

team_dark_colors := [Team]clay.Color {
    .Red = PALETTE[.Red_Team_Dark],
    .Blue = PALETTE[.Blue_Team_Dark],
}

card_colors := [Card_Color]clay.Color {
    .Gold = PALETTE[.Card_Gold],
    .Silver = PALETTE[.Card_Silver],
    .Red = PALETTE[.Card_Red],
    .Green = PALETTE[.Card_Green],
    .Blue = PALETTE[.Card_Blue],
}

BUTTON_HEIGHT :: 100
BUTTON_WIDTH  :: 400
BUTTON_TEXT_PADDING :: 20

INFO_FONT_SIZE :: 40

DEFAULT_ELEMENT_BORDER_WIDTH :: 4
HOT_BUTTON_BORDER_WIDTH :: 4
HOT_CARD_BORDER_WIDTH :: DEFAULT_ELEMENT_BORDER_WIDTH


SIZING_GROW :: clay.Sizing {
    clay.SizingAxis {
        type = .Grow,
    },
    clay.SizingAxis {
        type = .Grow,
    },
}

Clay_User_Data :: bit_field uintptr {
    image_rotated: bool | 1,
}

game_fonts: [Font_ID]Font

hot_element_id: clay.ElementId
active_element_id: clay.ElementId

ui_scale: f32 = 0.5

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

clay_button_logic :: proc(element_id: clay.ElementId) -> (result, hot, active: bool) {
    hot = hot_element_id == element_id
    active = active_element_id == element_id

    if active {
        if .LEFT in ui_state.released_this_frame {
            if hot {
                result = true
            }
            active_element_id = {}
        }
    } else if hot {
        if .LEFT in ui_state.pressed_this_frame {
            active_element_id = element_id
        }
    }

    if clay.PointerOver(element_id) {
        if active_element_id == {} || active {
            hot_element_id = element_id
        }
    } else if hot {
        hot_element_id = {}
    }
    return
}

clay_button :: proc(
    button_id: clay.ElementId,
    text: string = "",
    image: ^Texture = nil,
    disabled: bool = false,
    arrow_direction: Maybe(Arrow_Direction) = nil,
    sizing: Maybe(clay.Sizing) = nil,
    padding: Maybe(clay.Padding) = nil,
    floating: Maybe(clay.FloatingElementConfig) = nil,
    idle_background_color: Maybe(clay.Color) = nil,
    active_background_color: Maybe(clay.Color) = nil,
    idle_text_color: Maybe(clay.Color) = nil,
    active_text_color: Maybe(clay.Color) = nil,
    idle_border_color: Maybe(clay.Color) = nil,
    corner_radius: Maybe(f32) = nil,
    do_strike: bool = true,
    border_width: Maybe(u16) = nil,
) -> (result: bool) {

    // button_active := button_id == active_element_id
    // button_hot := button_id == hot_element_id

    button_hot, button_active: bool
    if !disabled {
        result, button_hot, button_active = clay_button_logic(button_id)
    }

    // border_width := border_width.? or_else u16(HOT_BUTTON_BORDER_WIDTH * ui_scale)

    background_color := button_active ? (active_background_color.? or_else PALETTE[.Dark_Gray]) : (idle_background_color.? or_else PALETTE[.Gray])
    if clay.UI(id = button_id)({
        layout = {
            sizing = sizing.? or_else {
                width = clay.SizingFixed(BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            childAlignment = {
                x = .Center,
                y = .Center,
            },
            padding = padding.? or_else clay.PaddingAll(u16(BUTTON_TEXT_PADDING * ui_scale)),
        },
        floating = floating.? or_else {},
        backgroundColor = background_color,
        cornerRadius = clay.CornerRadiusAll(corner_radius.? or_else 0.03 * BUTTON_WIDTH * ui_scale),
        border = {
            color = PALETTE[.White] if button_hot else idle_border_color.? or_else background_color,
            width = clay.BorderOutside(u16(HOT_BUTTON_BORDER_WIDTH * ui_scale)),
        },
    }) {
        if direction, ok := arrow_direction.?; ok {
            arrow := new(Custom_UI_Element, context.temp_allocator)
            arrow^ = Arrow_Indicator {
                direction = direction, line_thick = f32(border_width.? or_else u16(HOT_BUTTON_BORDER_WIDTH * ui_scale)),
                color = idle_text_color.? or_else background_color if !button_active else PALETTE[.White],
            }
            if clay.UI()({
                layout = {
                    sizing = SIZING_GROW,
                },
                custom = {arrow}, 
            }) {}
        }

        font_size := (BUTTON_HEIGHT - 2 * BUTTON_TEXT_PADDING) * ui_scale
        if image != nil {
            image_width := font_size * f32(image.width) / f32(image.height)
            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(image_width),
                        height = clay.SizingFixed(font_size),
                    },
                },
                image = {
                    image,
                },
            }) {}
        }

        if text != "" {
            if image != nil {
                if clay.UI()({
                    layout = {sizing = {width = clay.SizingGrow()}},
                }) {}
            }
            clay.TextDynamic(text, clay.TextConfig({
                textColor = idle_text_color.? or_else PALETTE[.Black] if !button_active else active_text_color.? or_else PALETTE[.White],
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(font_size),
            }))
            if image != nil {
                if clay.UI()({
                    layout = {sizing = {width = clay.SizingGrow()}},
                }) {}
            }
        }


        if disabled && do_strike {
            // Strikethrough line
            element := clay.GetElementData(button_id)
            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(element.boundingBox.width - (2 * BUTTON_TEXT_PADDING - 4 * HOT_BUTTON_BORDER_WIDTH) * ui_scale),
                        height = clay.SizingFixed(3 * HOT_BUTTON_BORDER_WIDTH * ui_scale),
                    },
                },
                border = {
                    width = clay.BorderOutside(u16(HOT_BUTTON_BORDER_WIDTH * ui_scale)),
                    color = idle_background_color.? or_else PALETTE[.Gray],
                },
                backgroundColor = idle_text_color.? or_else PALETTE[.White],
                floating = {
                    attachTo = .Parent,
                    offset = {0, 0.08 * font_size},  // Small offset here to move the line down so it goes through the centres of lowercase letters
                    attachment = {
                        element = .CenterCenter,
                        parent = .CenterCenter,
                    },
                    clipTo = .AttachedParent,
                },
                cornerRadius = clay.CornerRadiusAll(1.5 * HOT_BUTTON_BORDER_WIDTH * ui_scale),
            }) {}
        }
    }

    return result
}

is_alt_key_down :: proc() -> bool {
    return ba.get(&ui_state.keyboard_state, uint(Keyboard_Key.LEFT_ALT)) || ba.get(&ui_state.keyboard_state, uint(Keyboard_Key.RIGHT_ALT))
}

clay_card_element :: proc(
    gs: ^Game_State,
    card: Card,
    width: f32,
    preview_attach_points: clay.FloatingAttachPoints,
    floating: clay.FloatingElementConfig = {},
) {
    card_id_string := fmt.tprintf("%v", card.id)
    card_clay_id := clay.ID(card_id_string, u32(card.state))
    card_data, _ := get_card_data_by_id(gs, card.id)

    card_should_be_hidden := gs.stage == .Selection && card.owner_id != gs.my_player_id && card.state == .Played
    card_should_be_preview := card.hero_id != get_my_player(gs).hero.id && card.state == .In_Deck
    card_should_be_rotated := card.active != .None

    texture := nil if card_should_be_hidden else (&card_data.preview_texture if card_should_be_preview else &card_data.texture)

    if active_element_id == card_clay_id {
        if .LEFT in ui_state.released_this_frame {
            if hot_element_id == card_clay_id {
                append(&gs.event_queue, Card_Clicked_Event{card})
                hot_element_id = {}
            }
            active_element_id = {}
        }
    } else if hot_element_id == card_clay_id {
        if .LEFT in ui_state.pressed_this_frame {
            active_element_id = card_clay_id
        }
    }

    if clay.PointerOver(card_clay_id) {
        if (active_element_id == {} || active_element_id == card_clay_id) && !card_should_be_hidden {
            hot_element_id = card_clay_id
        }
    } else if hot_element_id == card_clay_id {
        hot_element_id = {}
    }

    // card_active := active_element_id == card_clay_id
    card_hot := hot_element_id == card_clay_id

    border := clay.BorderElementConfig {
        width = clay.BorderAll(0),
    }
    hot_width := clay.BorderAll(u16(HOT_CARD_BORDER_WIDTH * ui_scale))
    if card_hot {
        border = {
            color = PALETTE[.White],
            width = hot_width,
        }
    } else if card_should_be_hidden {
        border = {
            color = PALETTE[.Dark_Gray],
            width = hot_width,
        }
    } else {
        should_highlight: bool
        my_player := get_my_player(gs)
        #partial switch my_player.stage {
        case .Upgrading:
            if card_is_valid_upgrade_option(gs, card) do should_highlight = true
        }

        if should_highlight {
            time := get_time()
            t := (f32(math.sin(4 * time)) + 1) / 2
            // ???
            highlight_color := lerp(clay.Color{255, 150, 200, 255}, clay.Color{200, 100, 150, 255}, t)
            border = {
                color = highlight_color,
                width = hot_width,
            }
        }
    }

    if card_should_be_rotated {
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingFixed(width),
                    height = clay.SizingFixed(1.5 * width),
                },
            },
            floating = floating,
        }) {
            if clay.UI(id = card_clay_id) ({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(1.5 * width),
                        height = clay.SizingFixed(width),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Center,
                    },
                },
                image = {
                    texture,
                },
                floating = {
                    attachTo = .Parent,
                    attachment = {
                        .CenterCenter,
                        .CenterCenter,
                    },
                },
                border = border,
                cornerRadius = clay.CornerRadiusAll(0.5 * width * CARD_CORNER_RADIUS_PROPORTION),
                userData = cast(rawptr) Clay_User_Data {
                    image_rotated = true,
                },
            }) {}
        }
    } else {
        if clay.UI(id = card_clay_id) ({
            layout = {
                sizing = {
                    width = clay.SizingFixed(width),
                    height = clay.SizingFixed(1.5 * width),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
            },
            image = {
                texture,
            },
            floating = floating,
            border = border,
            cornerRadius = clay.CornerRadiusAll(0.5 * width * CARD_CORNER_RADIUS_PROPORTION),
            backgroundColor = PALETTE[.White],
        }) {
            if card_should_be_hidden {
                icon := &hero_icons[get_player_by_id(gs, card.owner_id).hero.id]
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingPercent(0.5),
                        },
                    },
                    aspectRatio = {1},
                    image = {icon},
                }) {}
            }
        } 
    }

    if card_hot && is_alt_key_down() {
        if clay.UI()({
            layout = {
                sizing = {
                    clay.SizingFixed(CARD_TEXTURE_SIZE.x * ui_scale),
                    clay.SizingFixed(CARD_TEXTURE_SIZE.y * ui_scale),
                },
            },
            image = {
                texture,
            },
            floating = {
                attachment = preview_attach_points,
                attachTo = .ElementWithId,
                pointerCaptureMode = .Passthrough,
                parentId = card_clay_id.id,
                zIndex = 200,
            },
        }) {}
    }
}

clay_text_box :: proc(
    text_box_id: clay.ElementId,
    text_box: ^UI_Text_Box_Element,
    sizing: Maybe(clay.Sizing) = nil,
    corner_radius: f32 = 0.03 * BUTTON_WIDTH,
) {
    text_box_active := active_element_id == text_box_id
    text_box_hot := hot_element_id == text_box_id
    if clay.UI(id = text_box_id)({
        layout = {
            sizing = sizing.? or_else {
                width = clay.SizingFixed(BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            padding = clay.PaddingAll(u16(BUTTON_TEXT_PADDING * ui_scale)),
        },
        backgroundColor = PALETTE[.Black],
        border = {
            color = PALETTE[.White],
            width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
        },
        cornerRadius = clay.CornerRadiusAll(corner_radius),
    }) {
        TEXT_BOX_FONT_SIZE :: BUTTON_HEIGHT - 2 * BUTTON_TEXT_PADDING
        bounding_box := clay.GetElementData(text_box_id).boundingBox
        single_character_width := measure_text_ex(game_fonts[.Inconsolata], "_", TEXT_BOX_FONT_SIZE * ui_scale, 0).x
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
                fontId = FONT_PALETTE[.Monospace],
                textColor = PALETTE[.White],
                fontSize = u16(TEXT_BOX_FONT_SIZE * ui_scale),
            }))
        } else {
            clay.TextDynamic(text_box.default_string, clay.TextConfig({
                fontId = FONT_PALETTE[.Monospace],
                textColor = PALETTE[.Light_Gray],
                fontSize = u16(TEXT_BOX_FONT_SIZE * ui_scale),
            }))
        }

        // Prop to ensure box stays at correct height even with empty string
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingFixed(0),
                    height = clay.SizingFixed(TEXT_BOX_FONT_SIZE * ui_scale),
                },
            },
        }) {}

        // Cursor
        if text_box_active {
            CYCLE_TIME :: 1 // s
            time := (get_time() - text_box.last_click_time) / CYCLE_TIME
            time_remainder := (time - math.floor(time)) * CYCLE_TIME
            if time_remainder < CYCLE_TIME * 0.5 {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(4 * ui_scale),
                            height = clay.SizingFixed(TEXT_BOX_FONT_SIZE * ui_scale),
                        },
                    },
                    border = {
                        PALETTE[.White],
                        clay.BorderOutside(max(1, u16(2 * ui_scale))),  // @Magic
                    },
                    floating = {
                        attachTo = .Parent,
                        offset = {
                            BUTTON_TEXT_PADDING * ui_scale + f32(text_box.cursor_index) * single_character_width,
                            BUTTON_TEXT_PADDING * ui_scale,
                        },
                    },
                }) {}
            }
        }
    }
}

PLAYER_INFO_WIDTH :: 4 * RESOLVED_CARD_WIDTH  // @Magic, this is kind of arbitrary :P

clay_player_info :: proc(player: ^Player) {

    text_color := team_dark_colors[player.team]
    background_color := team_mid_colors[player.team]
    // border_color := team_light_colors[player.team]

    if clay.UI()({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = {
                width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            childGap = u16(16 * ui_scale), // @Magic
            padding = clay.PaddingAll(u16((16 + 4) * ui_scale)),  // @Magic
        },
        cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
        // border = {
        //     width = clay.BorderOutside(u16(4 * ui_scale)),
        //     color = border_color,
        // },
        backgroundColor = background_color,
    }) {

        text_info_id := clay.ID("player_info_text", u32(player.id))
        text_info_data := clay.GetElementData(text_info_id)

        image := &hero_icons[player.hero.id]
        aspectRatio := f32(image.width) / f32(image.height)
        height := 2 * INFO_FONT_SIZE * ui_scale
        if clay.UI() ({
            layout = {
                sizing = {
                    width = clay.SizingFixed(aspectRatio * height),
                    height = clay.SizingFixed(height),
                },
            },
            image = {image},
        }) {}

        
        if clay.UI(text_info_id) ({
            layout = {
                layoutDirection = .TopToBottom,
            },
        }) {
            username := string(cstring(raw_data(player._username_buf[:])))
            hero_name, _ := reflect.enum_name_from_value(player.hero.id)
    
            clay.TextDynamic(username, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(INFO_FONT_SIZE * ui_scale),
                textColor = text_color,
            }))
    
            clay.TextDynamic(hero_name, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(INFO_FONT_SIZE * ui_scale),
                textColor = text_color,
            }))
        }
    }
}

clay_player_panel :: proc(gs: ^Game_State, player: ^Player) -> clay.ElementId {
    player_panel_id := clay.ID("player_panel", u32(player.id))

    text_color := team_light_colors[player.team]
    border_color := team_mid_colors[player.team]
    background_color := team_dark_colors[player.team]

    preview_attach_points := clay.FloatingAttachPoints{
        element = .LeftTop,
        parent = .LeftTop,
    } if player.team == .Red else clay.FloatingAttachPoints{
        element = .RightTop,
        parent = .RightTop,
    }

    if clay.UI(id = player_panel_id)({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = {
                width = clay.SizingFit(),
                height = clay.SizingFit(),
            },
            childGap = u16(16 * ui_scale), // @Magic
            padding = clay.PaddingAll(u16((16 + 4) * ui_scale)),
        },
        border = {
            width = clay.BorderOutside(u16(4 * ui_scale)),
            color = border_color,
        },
        cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
        backgroundColor = background_color,
    }) {
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFit(),
                    height = clay.SizingFit(),
                },
                childGap = u16(16 * ui_scale), // @Magic
            },
        }) {
            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFit(),
                    },
                    childGap = u16(16 * ui_scale),
                },
            }) {

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingGrow(),
                        },
                        childGap = u16(8 * ui_scale), // @Magic
                        childAlignment = {
                            x = .Center,
                        },
                    },
                }) {
                    clay.Text("Deck", clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                        textColor = border_color,
                    }))

                    deck_button_id := clay.ID("deck_button", u32(player.id))
                    deck_button_data := clay.GetElementData(deck_button_id)

                    current_deck_open := false
                    if current_deck, ok := current_deck_viewer.?; ok && current_deck == player.hero.id {
                        current_deck_open = true
                    }

                    if clay_button(
                        deck_button_id,
                        image = &hero_icons[player.hero.id],
                        sizing = clay.Sizing {
                            width = clay.SizingFixed(deck_button_data.boundingBox.height),
                            height = clay.SizingGrow(),
                        },
                        corner_radius = 0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale,
                        padding = clay.PaddingAll(u16(16 * ui_scale)), // @Magic
                        idle_background_color = text_color if current_deck_open else border_color,
                        active_background_color = background_color,
                    ) {
                        if current_deck_open {
                            current_deck_viewer = nil
                        } else {
                            current_deck_viewer = player.hero.id
                        }
                    }
                }
    
                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                    },
                }) {
                    username := string(cstring(raw_data(player._username_buf[:])))
                    hero_name, _ := reflect.enum_name_from_value(player.hero.id)
                    hero_stats_string := fmt.tprintf("L%v, %vC", player.hero.level, player.hero.coins)
    
                    clay.TextDynamic(username, clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = u16(INFO_FONT_SIZE * ui_scale),
                        textColor = text_color,
                        wrapMode = .None,
                    }))
    
                    clay.TextDynamic(hero_name, clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = u16(INFO_FONT_SIZE * ui_scale),
                        textColor = text_color,
                        wrapMode = .None,
                    }))
    
                    clay.TextDynamic(hero_stats_string, clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = u16(INFO_FONT_SIZE * ui_scale),
                        textColor = text_color,
                        wrapMode = .None,
                    }))
                }

                item_values: [Card_Value_Kind]int
                for card_id in player.hero.items[:player.hero.item_count] {
                    card_data := get_card_data_by_id(gs, card_id) or_continue
                    item_values[card_data.item] += 1
                }

                text_with_icon :: proc(text: string, icon: ^Texture, text_color: clay.Color) {
                    if clay.UI()({
                        layout = {
                            layoutDirection = .LeftToRight,
                            childAlignment = {y = .Center},
                        },
                    }) {
                        clay.TextDynamic(text, clay.TextConfig({
                            fontId = FONT_PALETTE[.Monospace],
                            fontSize = u16(INFO_FONT_SIZE * ui_scale),
                            textColor = text_color,
                            wrapMode = .None,
                        }))
                        if clay.UI()({
                            layout = {
                                sizing = {
                                    clay.SizingFixed(0.9 * INFO_FONT_SIZE * ui_scale),
                                    clay.SizingFixed(0.9 * INFO_FONT_SIZE * ui_scale),
                                },
                            },
                            image = {icon},
                        }) {}
                    }
                }

                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingGrow(),
                            // height = clay.SizingFit(),
                        },
                    },
                }) {}

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                    },
                }) {
                    attack_string := fmt.tprintf("+%v", item_values[.Attack])
                    defense_string := fmt.tprintf("+%v", item_values[.Defense])
                    initiative_string := fmt.tprintf("+%v", item_values[.Initiative])

                    text_with_icon(attack_string, &item_icons[.Attack], text_color)
                    text_with_icon(defense_string, &item_icons[.Defense], text_color)
                    text_with_icon(initiative_string, &item_icons[.Initiative], text_color)
                }

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                    },
                }) {
                    range_string := fmt.tprintf("+%v", item_values[.Range])
                    movement_string := fmt.tprintf("+%v", item_values[.Movement])
                    radius_string := fmt.tprintf("+%v", item_values[.Radius])

                    text_with_icon(range_string, &item_icons[.Range], text_color)
                    text_with_icon(movement_string, &item_icons[.Movement], text_color)
                    text_with_icon(radius_string, &item_icons[.Radius], text_color)
                }
            }
    
            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = {
                        clay.SizingFit(),
                        clay.SizingFit(),
                    },
                    childGap = u16(16 * ui_scale), // @Magic
                },
            }) {
                for i in 0..<4 {
                    // resolved_card_string := fmt.tprintf("player_%v_resolved_card_%v", player.id, i)
                    if clay.UI()({
                        layout = {
                            layoutDirection = .TopToBottom,
                            sizing = {
                                clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                                clay.SizingFixed(RESOLVED_CARD_HEIGHT * ui_scale),
                            },
                            childAlignment = {
                                x = .Center,
                                y = .Center,
                            },
                        },
                        cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
                        border = {
                            width = clay.BorderOutside(u16(4 * ui_scale)),
                            color = border_color,
                        },
                    }) {
                        clay.Text("Turn", clay.TextConfig({
                            fontId = FONT_PALETTE[.Default_Regular],
                            fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                            textColor = border_color,
                        }))

                        clay.TextDynamic(fmt.tprintf("%v", i + 1), clay.TextConfig({
                            fontId = FONT_PALETTE[.Default_Regular],
                            fontSize = u16(2 * INFO_FONT_SIZE * ui_scale),
                            textColor = border_color,
                        }))

                        for card in player.hero.cards {
                            if card.state != .Resolved || card.turn_played != i do continue
                            clay_card_element(
                                gs, card,
                                width = RESOLVED_CARD_WIDTH * ui_scale,
                                floating = {
                                    attachment = {
                                        element = .LeftTop,
                                        parent = .LeftTop,
                                    },
                                    attachTo = .Parent,
                                },
                                preview_attach_points = preview_attach_points,
                            )
                            break
                        }
                    }
                }
            }
        }

        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                    height = clay.SizingGrow(),
                },
                childGap = u16(8 * ui_scale), // @Magic
                childAlignment = {
                    x = .Center,
                },
            },
        }) {
            clay.Text("Discard", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                textColor = border_color,
            }))

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                        height = clay.SizingGrow(),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Top,
                    },
                    padding = clay.PaddingAll(u16(16 * ui_scale)),
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
                border = {
                    width = clay.BorderOutside(u16(4 * ui_scale)),
                    color = border_color,
                },
            }) {
                discard_offset: f32 = 0
                for card in player.hero.cards {
                    if card.state != .Discarded do continue 
                    clay_card_element(
                        gs, card,
                        width = RESOLVED_CARD_WIDTH * ui_scale,
                        floating = {
                            attachment = {
                                element = .LeftTop,
                                parent = .LeftTop,
                            },
                            attachTo = .Parent,
                            offset = {
                                0, discard_offset,
                            },
                        },
                        preview_attach_points = preview_attach_points,
                    )
                    discard_offset += INFO_FONT_SIZE             
                }
            }
        }

        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                    height = clay.SizingGrow(),
                },
                childGap = u16(8 * ui_scale), // @Magic
                childAlignment = {
                    x = .Center,
                    y = .Bottom,
                },
            },
        }) {
            clay.Text("Markers", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                textColor = border_color,
            }))
            
            if clay.UI()({
                layout = {
                    sizing = {
                        height = clay.SizingGrow(),
                    },
                },
            }) {
                // @Todo: Draw markers here!
            }

            clay.Text("Played", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                textColor = border_color,
            }))

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                        height = clay.SizingFixed(RESOLVED_CARD_HEIGHT * ui_scale),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Top,
                    },
                    padding = clay.PaddingAll(u16(16 * ui_scale)),
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
                border = {
                    width = clay.BorderOutside(u16(4 * ui_scale)),
                    color = border_color,
                },
            }) {
                for card in player.hero.cards {
                    if card.state != .Played do continue
                    clay_card_element(
                        gs, card,
                        width = RESOLVED_CARD_WIDTH * ui_scale,
                        floating = {
                            attachment = {
                                element = .LeftTop,
                                parent = .LeftTop,
                            },
                            attachTo = .Parent,
                        },
                        preview_attach_points = preview_attach_points,
                    )
                    break
                }
            }
        }
    }


    return player_panel_id
}

clay_deck_viewer :: proc(gs: ^Game_State, hero_id: Hero_ID) {
    DECK_VIEWER_PADDING_GAP :: 16

    preview_width := RESOLVED_CARD_WIDTH * 1.5 * ui_scale

    show_preview_cards := get_my_player(gs).hero.id != hero_id

    background_color := PALETTE[.Background]
    border_color := PALETTE[.Dark_Gray]
    highlight_color := PALETTE[.Gray]

    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            childGap = u16(DECK_VIEWER_PADDING_GAP * ui_scale),
            childAlignment = {x = .Center},
            padding = clay.PaddingAll(u16((4 + DECK_VIEWER_PADDING_GAP) * ui_scale)),
        },
        floating = {
            attachTo = .Root,
            attachment = {
                element = .CenterCenter,
                parent  = .CenterCenter,
            },
        },
        backgroundColor = background_color,
        border = {
            color = border_color,
            width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
        },
    }) {
        close_deck_viewer_id := clay.ID("close_deck_viewer")

        close_button_result, close_button_hot, close_button_active := clay_button_logic(close_deck_viewer_id)

        if clay.UI(id = close_deck_viewer_id)({
            layout = {
                sizing = {
                    clay.SizingFixed(40 * ui_scale),
                    clay.SizingFixed(40 * ui_scale),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
            },
            border = {
                color = PALETTE[.White] if close_button_hot else border_color,
                width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
            },
            floating = {
                attachTo = .Parent,
                attachment = {
                    element = .RightTop,
                    parent = .RightTop,
                },
            },
            backgroundColor = highlight_color if close_button_active else background_color,
        }) {
            clay.Text("X", clay.TextConfig({
                fontSize = u16(30 * ui_scale), // @Magic
                fontId = FONT_PALETTE[.Default_Regular],
                textColor = border_color,
            }))
        }

        if close_button_result {
            current_deck_viewer = nil
        }

        hero_name, _ := reflect.enum_name_from_value(hero_id)
        title := fmt.tprintf("%v's Deck%v", hero_name, " (Preview)" if show_preview_cards else "")
        clay.TextDynamic(title, clay.TextConfig({
            fontSize = u16(INFO_FONT_SIZE * ui_scale),
            fontId = FONT_PALETTE[.Default_Regular],
            textColor = border_color,
        }))

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                childGap = u16(DECK_VIEWER_PADDING_GAP * ui_scale),  // @Magic
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
            },
        }) {
            if clay.UI()({
                layout = {
                    layoutDirection = .TopToBottom,
                    sizing = {
                        width = clay.SizingFit(),
                        height = clay.SizingFit(),
                    },
                    childGap = u16(DECK_VIEWER_PADDING_GAP * ui_scale),
                    childAlignment = {
                        x = .Center,
                        y = .Center,
                    },
                },
            }) {
                gold_card := Card {
                    hero_id = hero_id,
                    color = .Gold,
                    state = .In_Deck,
                }
                clay_card_element(
                    gs, gold_card,
                    width = preview_width,
                    preview_attach_points = {.CenterCenter, .CenterCenter},
                )
                silver_card := Card {
                    hero_id = hero_id,
                    color = .Silver,
                    state = .In_Deck,
                }
                clay_card_element(
                    gs, silver_card,
                    width = preview_width,
                    preview_attach_points = {.CenterCenter, .CenterCenter},
                )
            }

            colors := bit_set[Card_Color]{.Red, .Green, .Blue}
            for color in colors {
                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingFit(),
                        },
                        childGap = u16(DECK_VIEWER_PADDING_GAP * ui_scale),
                        childAlignment = {
                            x = .Center,
                            y = .Center,
                        },
                    },
                }) {
                    for tier := 3; tier >= 1; tier -= 1 {
                        if clay.UI()({
                            layout = {
                                sizing = {
                                    width = clay.SizingFit(),
                                    height = clay.SizingFit(),
                                },
                                childGap = u16(DECK_VIEWER_PADDING_GAP * ui_scale),
                                childAlignment = {
                                    x = .Center,
                                    y = .Center,
                                },
                            },
                        }) {
                            for alternate_index in 0..=(tier == 1 ? 0 : 1) {
                                alternate := alternate_index == 1
                                card := Card {
                                    hero_id = hero_id,
                                    color = color,
                                    tier = tier,
                                    alternate = alternate,
                                    state = .In_Deck,
                                }
                                clay_card_element(
                                    gs, card,
                                    width = preview_width,
                                    preview_attach_points = {.CenterCenter, .CenterCenter},
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

clay_main_context, clay_card_context: ^clay.Context

clay_setup :: proc() {
    clay_min_memory_size := clay.MinMemorySize()

    main_arena_memory, _ := make([^]byte, clay_min_memory_size)
    card_arena_memory, _ := make([^]byte, clay_min_memory_size)
    main_clay_arena := clay.CreateArenaWithCapacityAndMemory(uint(clay_min_memory_size), main_arena_memory)
    card_clay_arena := clay.CreateArenaWithCapacityAndMemory(uint(clay_min_memory_size), card_arena_memory)
    clay_main_context = clay.Initialize(main_clay_arena, {STARTING_WIDTH, STARTING_HEIGHT}, {})
    clay_card_context = clay.Initialize(card_clay_arena, transmute(clay.Dimensions)(CARD_TEXTURE_SIZE), {})

    clay.SetMeasureTextFunction(clay_measure_text, nil)
}

clay_layout :: proc(gs: ^Game_State) -> Render_Command_Array {

    clay.SetCurrentContext(clay_main_context)

    clay.SetLayoutDimensions({f32(get_render_width()), f32(get_render_height())})

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
            padding = clay.PaddingAll(u16(8 * ui_scale)),  // @Magic
            childGap = u16(16 * ui_scale),  // @Magic
        },
        backgroundColor = PALETTE[.Background],
    }) {
        clay.TextDynamic(
            tooltip_text,
            clay.TextConfig({
                textColor = PALETTE[.White],
                fontSize = u16(TOOLTIP_FONT_SIZE * ui_scale),
                fontId = FONT_PALETTE[.Default_Regular],
            }),
        )

        #partial switch gs.screen {
        case .Pre_Lobby:    clay_pre_lobby_screen(gs)
        case .In_Lobby:     clay_lobby_screen(gs)
        case .In_Game:      clay_game_screen(gs)
        }
    }

    command_array := clay.EndLayout()

    return command_array

}

clay_render :: proc(gs: ^Game_State, commands: ^Render_Command_Array) {
    for command_index in 0..<commands.length {
        command := clay.RenderCommandArray_Get(commands, command_index)
        bounding_box := command.boundingBox
        #partial switch command.commandType {
        case .ScissorStart:
            begin_scissor_mode(i32(bounding_box.x), i32(bounding_box.y), i32(bounding_box.width), i32(bounding_box.height))
        case .ScissorEnd:
            end_scissor_mode()
        case .Rectangle:
            // draw_rectangle_rec(
            //     Rectangle(bounding_box),
            //     clay_to_raylib_color(command.renderData.rectangle.backgroundColor),
            // )
            config := command.renderData.rectangle
            if config.cornerRadius.topLeft > 0 {
                radius: f32 = (config.cornerRadius.topLeft * 2) / min(bounding_box.width, bounding_box.height)
                draw_rectangle_rounded(Rectangle(bounding_box), radius, 8, clay_to_raylib_color(config.backgroundColor))  // @Magic num segments for rounded rect
            } else {
                draw_rectangle_rec(Rectangle(bounding_box), clay_to_raylib_color(config.backgroundColor))
            }
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
            if config.cornerRadius.topLeft > 0 {
                rect := Rectangle(bounding_box)
                border_width := f32(config.width.top)
                rect.x += border_width
                rect.y += border_width
                rect.width -= 2 * border_width
                rect.height -= 2 * border_width
                // Weirdo formula. Phew!
                radius: f32 = (config.cornerRadius.topLeft * 2 - 2 * border_width) / min(rect.width, rect.height)
                draw_rectangle_rounded_lines_ex(rect, radius, 8, f32(config.width.top), clay_to_raylib_color(config.color))
            } else {
                draw_rectangle_lines_ex(Rectangle(bounding_box), f32(config.width.top), clay_to_raylib_color(config.color))
            }

            // // Left border
            // if config.width.left > 0 {
            //     draw_rectangle(i32(bounding_box.x), i32(bounding_box.y + config.cornerRadius.topLeft), i32(config.width.left), i32(bounding_box.height - config.cornerRadius.topLeft - config.cornerRadius.bottomLeft), clay_to_raylib_color(config.color))
            // }
            // // Right border
            // if (config.width.right > 0) {
            //     draw_rectangle(i32(bounding_box.x + bounding_box.width - f32(config.width.right)), i32(bounding_box.y + config.cornerRadius.topRight), i32(config.width.right), i32(bounding_box.height - config.cornerRadius.topRight - config.cornerRadius.bottomRight), clay_to_raylib_color(config.color))
            // }
            // // Top border
            // if (config.width.top > 0) {
            //     draw_rectangle(i32(bounding_box.x + config.cornerRadius.topLeft), i32(bounding_box.y), i32(bounding_box.width - config.cornerRadius.topLeft - config.cornerRadius.topRight), i32(config.width.top), clay_to_raylib_color(config.color))
            // }
            // // Bottom border
            // if (config.width.bottom > 0) {
            //     draw_rectangle(i32(bounding_box.x + config.cornerRadius.bottomLeft), i32(bounding_box.y + bounding_box.height - f32(config.width.bottom)), i32(bounding_box.width - config.cornerRadius.bottomLeft - config.cornerRadius.bottomRight), i32(config.width.bottom), clay_to_raylib_color(config.color))
            // }
            // if (config.cornerRadius.topLeft > 0) {
            //     draw_ring(Vec2{ bounding_box.x + config.cornerRadius.topLeft - 1, bounding_box.y + config.cornerRadius.topLeft }, (config.cornerRadius.topLeft - f32(config.width.top)), config.cornerRadius.topLeft, 180, 270, 10, clay_to_raylib_color(config.color))
            // }
            // if (config.cornerRadius.topRight > 0) {
            //     draw_ring(Vec2{ (bounding_box.x + bounding_box.width - config.cornerRadius.topRight - 1), (bounding_box.y + config.cornerRadius.topRight) }, (config.cornerRadius.topRight - f32(config.width.top)), config.cornerRadius.topRight, 270, 360, 10, clay_to_raylib_color(config.color))
            // }
            // if (config.cornerRadius.bottomLeft > 0) {
            //     draw_ring(Vec2{ (bounding_box.x + config.cornerRadius.bottomLeft - 1), (bounding_box.y + bounding_box.height - config.cornerRadius.bottomLeft) }, (config.cornerRadius.bottomLeft - f32(config.width.bottom)), config.cornerRadius.bottomLeft, 90, 180, 10, clay_to_raylib_color(config.color))
            // }
            // if (config.cornerRadius.bottomRight > 0) {
            //     draw_ring(Vec2 { (bounding_box.x + bounding_box.width - config.cornerRadius.bottomRight - 1), (bounding_box.y + bounding_box.height - config.cornerRadius.bottomRight) }, (config.cornerRadius.bottomRight - f32(config.width.bottom)), config.cornerRadius.bottomRight, 0.1, 90, 10, clay_to_raylib_color(config.color))
            // }
        case .Image:
            texture := cast(^Texture) command.renderData.image.imageData
            user_data := cast(Clay_User_Data) command.userData
            dest_rect := Rectangle(bounding_box)
            origin := Vec2{}
            rotate_angle: f32
            if user_data.image_rotated {
                origin = Vec2{dest_rect.height, dest_rect.width} / 2
                rotate_angle = 90
                dest_rect.x += origin.y
                dest_rect.y += origin.x
                dest_rect.width, dest_rect.height = dest_rect.height, dest_rect.width
                // origin := Vec2{bounding_box.x, bounding_box.y} + Vec2{f32(texture.width), f32(texture.height)} / 2 if user_data.image_rotated else {}
                // rotate_angle: f32 = 90 if user_data.image_rotated else 0
            }
            draw_texture_pro(texture^, {0, 0, f32(texture.width), -f32(texture.height)}, dest_rect, origin, rotate_angle, WHITE)
        case .Custom:
            custom_data := cast(^Custom_UI_Element) command.renderData.custom.customData
            switch custom_variant in custom_data {
            case Board_Element:
                render_board(gs, Rectangle(bounding_box), custom_variant)
            case Arrow_Indicator:
                line_thick := custom_variant.line_thick
                color := clay_to_raylib_color(custom_variant.color)
                origin := Vec2{bounding_box.x, bounding_box.y}
                horizontal_offset := Vec2{bounding_box.width / 24, 0}
                vertical_offset := Vec2{0, bounding_box.height / 24}
                top := origin  + {bounding_box.width / 2, bounding_box.height / 3}
                left := origin + {bounding_box.width / 3, bounding_box.height / 2}
                right := origin + {bounding_box.width * 2 / 3, bounding_box.height / 2}
                bottom := origin + {bounding_box.width / 2, bounding_box.height * 2 / 3}
                points: [3]Vec2

                switch custom_variant.direction {
                case .Up:
                    points = {
                        left + vertical_offset,
                        top + vertical_offset,
                        right + vertical_offset,
                    }
                case .Down:
                    points = {
                        left - vertical_offset,
                        bottom - vertical_offset,
                        right - vertical_offset,
                    }
                case .Left:
                    points = {
                        top + horizontal_offset,
                        left + horizontal_offset,
                        bottom + horizontal_offset,
                    }
                case .Right:
                    points = {
                        top - horizontal_offset,
                        right - horizontal_offset,
                        bottom - horizontal_offset,
                    }
                }
                draw_spline_linear(raw_data(points[:]), 3, line_thick, color)
                draw_circle_v(points[0], line_thick / 2, color)
                draw_circle_v(points[1], line_thick / 2, color)
                draw_circle_v(points[2], line_thick / 2, color)
            }
        }
    }
}


ip_text_box := UI_Text_Box_Element {
    default_string = "Enter IP Address...",
}

current_deck_viewer: Maybe(Hero_ID) = nil

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
            childGap = u16(16 * ui_scale),  // @Magic
        },
    }) {
        clay_text_box(
            clay.ID("ip_text_box"), 
            &ip_text_box,
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
        )

        if clay_button(
            clay.ID("join_game_button"),
            "Join a game",
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            corner_radius = 0.03 * BUTTON_WIDTH * ui_scale,
        ) {
            append(&gs.event_queue, Join_Network_Game_Chosen_Event{})
        }

        // Spacer
        if clay.UI() ({
            layout = {
                sizing = {
                    // width = clay.SizingFixed(100),
                    height = clay.SizingFixed(100 * ui_scale),  // @Magic
                },
            },
        }) {}

        if clay_button(
            clay.ID("host_game_button"),
            "Host a game",
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            corner_radius = 0.03 * BUTTON_WIDTH * ui_scale,
        ) {
            append(&gs.event_queue, Host_Game_Chosen_Event{})
        }
    }
}


board_element := Custom_UI_Element(Board_Element{})

clay_game_screen :: proc(gs: ^Game_State) {
    game_screen_id := clay.ID("game_screen")
    if clay.UI(id = game_screen_id)({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = SIZING_GROW,
            childAlignment = {
                x = .Center,
                y = .Center,
            },
            childGap = u16(16 * ui_scale),  // @Magic
        },
    }) {
        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingGrow(),
                },
                childGap = u16(16 * ui_scale),  // @Magic
                childAlignment = {
                    x = .Center,
                },
            },
        }) {
            if clay.UI()({
                layout = {
                    layoutDirection = .TopToBottom,
                    sizing = {
                        width = clay.SizingFit(),
                        height = clay.SizingFit(),
                    },
                    childGap = u16(16 * ui_scale),  // @Magic
                },
            }) {
                for &player in gs.players {
                    if player.team != .Red do continue
                    clay_player_panel(gs, &player)
                }
            }

            board_id := clay.ID("board")
            board_hot := board_id == hot_element_id
            if clay.UI(id = board_id)({
                layout = {
                    sizing = SIZING_GROW,
                },
                aspectRatio = {1},
                backgroundColor = raylib_to_clay_color(BLUE),
                custom = {
                    &board_element,
                },
            }) {
                bounding_rect := Rectangle(clay.GetElementData(board_id).boundingBox)
                setup_space_positions(gs, bounding_rect)
    
                prev_hovered_space := board_element.(Board_Element).hovered_space
                defer {
                    if board_element.(Board_Element).hovered_space != prev_hovered_space {
                        append(&gs.event_queue, Space_Hovered_Event{board_element.(Board_Element).hovered_space})
                    }
                }
    
                addressable_board_element := &board_element.(Board_Element)
                addressable_board_element.hovered_space = INVALID_TARGET
                VERTICAL_SPACING := bounding_rect.height / 17.9  // @Magic
    
                if clay.Hovered() && active_element_id == {} {
                    hot_element_id = board_id
                    closest_idx := INVALID_TARGET
                    closest_dist: f32 = 1e6
                    for arr, x in gs.board {
                        for space, y in arr {
                            diff := (ui_state.mouse_pos - space.position)
                            dist := diff.x * diff.x + diff.y * diff.y
                            if dist < closest_dist && dist < VERTICAL_SPACING * VERTICAL_SPACING * 0.5 {
                                closest_idx = {u8(x), u8(y)}
                                closest_dist = dist
                            }
                        }
                    }
                    if closest_idx != INVALID_TARGET  {
                        addressable_board_element.hovered_space = closest_idx
                    }
                } else if board_hot {
                    hot_element_id = {}
                }
    
                if board_hot && .LEFT in ui_state.pressed_this_frame {
                    append(&gs.event_queue, Space_Clicked_Event{board_element.(Board_Element).hovered_space})
                }
            }

            right_sidebar_id := clay.ID("left_sidebar")
            if clay.UI(id = right_sidebar_id)({
                layout = {
                    layoutDirection = .TopToBottom,
                    sizing = {
                        width = clay.SizingFit(),
                        height = clay.SizingGrow(),
                    },
                    childGap = u16(16 * ui_scale),  // @Magic
                },
            }) {
                for &player in gs.players {
                    if player.team != .Blue do continue
                    clay_player_panel(gs, &player)
                }
            }
        }

        DECK_BUTTON_SIZE :: 100
        HAND_PANEL_CHILD_GAP :: 16

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingFit(),
                },
                childAlignment = {
                    x = .Center,
                },
                childGap = u16(16 * ui_scale),  // @Magic
            },
        }) {

            my_player := get_my_player(gs)
            // highlight_color := team_light_colors[my_player.team]
            background_color := team_dark_colors[my_player.team]
            border_color := team_mid_colors[my_player.team]

            // Left Button Panel

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingGrow(),
                    },
                },
            }) {}

            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = {
                        width = clay.SizingFit(),
                        height = clay.SizingFit(),
                    },
                    padding = clay.PaddingAll(u16((16 + 4) * ui_scale)),  // @Magic
                    childGap = u16(HAND_PANEL_CHILD_GAP * ui_scale),
                },
                border = {
                    width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
                    color = border_color,
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
                backgroundColor = background_color,
            }) {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingFit(),
                        },
                    },
                }) {
                    clay.Text("Hand", clay.TextConfig({
                        fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),  // @Magic
                        fontId = FONT_PALETTE[.Default_Regular],
                        textColor = border_color,
                    }))
                }

                if clay.UI() ({
                    layout = {
                        layoutDirection = .LeftToRight,
                        sizing = {
                            width = clay.SizingFixed((HAND_CARD_WIDTH * 5 + HAND_PANEL_CHILD_GAP * 4) * ui_scale),
                            height = clay.SizingFit(),
                        },
                        childGap = u16(HAND_PANEL_CHILD_GAP * ui_scale),
                        childAlignment = {x = .Center},
                    },
                }) {
                    for card in my_player.hero.cards {
                        if card.state != .In_Hand do continue
                        clay_card_element(
                            gs, card,
                            width = HAND_CARD_WIDTH * ui_scale,
                            preview_attach_points = {
                                element = .CenterBottom,
                                parent = .CenterBottom,
                            },
                        )
                    }
                }
            }
            // Right Button Panel

            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingGrow(),
                    },
                    childGap = u16(16 * ui_scale),  // @Magic
                },
            }) {
                for column_index := 0; column_index < len(gs.side_button_manager.button_data); column_index += 3 {
                    if clay.UI()({
                        layout = {
                            layoutDirection = .TopToBottom,
                            sizing = {
                                width = clay.SizingFit(),
                                height = clay.SizingGrow(),
                            },
                            childGap = u16(16 * ui_scale),  // @Magic
                        },
                    }) {
                        for row_index := 0; row_index < 3; row_index += 1 {
                            if row_index + column_index >= len(gs.side_button_manager.button_data) {
                                if clay.UI()({
                                    layout = {
                                        sizing = SIZING_GROW,
                                    },
                                }) {}
                                continue
                            }
                            button_data := &gs.side_button_manager.button_data[row_index + column_index]
                            if clay_button(
                                button_data.id, button_data.text,
                                sizing = clay.Sizing{
                                    width = clay.SizingFixed(1.8 * HAND_CARD_WIDTH * ui_scale),
                                    height = clay.SizingGrow(),
                                },
                            ) {
                                if button_data.global {
                                    broadcast_game_event(gs, button_data.event)
                                } else {
                                    append(&gs.event_queue, button_data.event)
                                }
                            }
                        }
                    }
                }
            }
        }

        if hero_id, ok := current_deck_viewer.?; ok {
            clay_deck_viewer(gs, hero_id)
        }
    }
}