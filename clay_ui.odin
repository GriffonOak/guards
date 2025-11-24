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

Board_Element :: struct {
    hovered_space: Target,
}

Custom_UI_Element :: union {
    Board_Element,
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

    White,
    Black,
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
    .Gray = {128, 128, 128, 255},
    .Dark_Gray = {100, 100, 100, 255},

    .White = {255, 255, 255, 255},
    .Black = {0, 0, 0, 255},
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

BUTTON_HEIGHT :: 100
BUTTON_WIDTH  :: 400
BUTTON_TEXT_PADDING :: 20
SELECTION_BUTTON_SIZE :: Vec2{400, 100}

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

clay_button_logic :: proc(element_id: clay.ElementId) -> (result: bool) {
    hot := hot_element_id == element_id
    active := active_element_id == element_id

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
    return result
}

clay_button :: proc(
    button_id: clay.ElementId,
    text: string = "",
    image: ^Texture = nil,
    sizing: Maybe(clay.Sizing) = nil,
    padding: Maybe(clay.Padding) = nil,
    idle_background_color: Maybe(clay.Color) = nil,
    active_background_color: Maybe(clay.Color) = nil,
) -> (result: bool) {

    button_active := button_id == active_element_id
    button_hot := button_id == hot_element_id

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
        backgroundColor = button_active ? (active_background_color.? or_else PALETTE[.Dark_Gray]) : (idle_background_color.? or_else PALETTE[.Gray]),
        border = {
            color = PALETTE[.White],
            width = button_hot ? clay.BorderOutside(u16(HOT_BUTTON_BORDER_WIDTH * ui_scale)) : {},
        },
        
    }) {

        result = clay_button_logic(button_id)

        if image != nil {
            if clay.UI()({
                layout = {
                    sizing = SIZING_GROW,
                },
                image = {
                    image,
                },
            }) {}
        }

        if text != "" {
            clay.TextDynamic(text, clay.TextConfig({
                textColor = PALETTE[.Black],
                fontId = u16(Font_ID.Inter),
                fontSize = u16((BUTTON_HEIGHT - 2 * BUTTON_TEXT_PADDING) * ui_scale),
            }))
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
    sizing: clay.Sizing,
    preview_attach_points: clay.FloatingAttachPoints,
    floating: clay.FloatingElementConfig = {},
) {
    card_id_string := fmt.tprintf("%v", card.id)
    card_clay_id := clay.ID(card_id_string, u32(card.state))

    card_active := active_element_id == card_clay_id
    card_hot := hot_element_id == card_clay_id

    if card_active {
        if .LEFT in ui_state.released_this_frame {
            if card_hot {
                append(&gs.event_queue, Card_Clicked_Event{card})
                hot_element_id = {}
            }
            active_element_id = {}
        }
    } else if card_hot {
        if .LEFT in ui_state.pressed_this_frame {
            active_element_id = card_clay_id
        }
    }

    if clay.PointerOver(card_clay_id) {
        if active_element_id == {} || active_element_id == card_clay_id {
            hot_element_id = card_clay_id
            card_hot = true
        }
    } else if card_hot {
        hot_element_id = {}
        card_hot = false
    }

    card_should_be_hidden := gs.stage == .Selection && card.owner_id != gs.my_player_id && card.state == .Played

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

    card_data, _ := get_card_data_by_id(gs, card.id)
    if clay.UI(id = card_clay_id) ({
        layout = {
            sizing = sizing,
            childAlignment = {
                x = .Center,
                y = .Center,
            },
        },
        image = {
            nil if card_should_be_hidden else &card_data.texture,
        },
        floating = floating,
        border = border,
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

        if card_hot && is_alt_key_down() {
            if clay.UI()({
                layout = {
                    sizing = {
                        clay.SizingFixed(CARD_TEXTURE_SIZE.x * ui_scale),
                        clay.SizingFixed(CARD_TEXTURE_SIZE.y * ui_scale),
                    },
                },
                image = {
                    &card_data.texture,
                },
                floating = {
                    attachment = preview_attach_points,
                    attachTo = .Parent,
                    pointerCaptureMode = .Passthrough,
                },
            }) {}
        }
    } 
}

clay_text_box :: proc(id_string: string, text_box: ^UI_Text_Box_Element) {
    text_box_id := clay.ID(id_string)
    text_box_active := active_element_id == text_box_id
    text_box_hot := hot_element_id == text_box_id
    if clay.UI(id = text_box_id)({
        layout = {
            sizing = {
                width = clay.SizingFixed(SELECTION_BUTTON_SIZE.x * 2 * ui_scale),
                height = clay.SizingFit(),
            },
            padding = clay.PaddingAll(u16(BUTTON_TEXT_PADDING * ui_scale)),
        },
        backgroundColor = PALETTE[.Black],
        border = {
            color = PALETTE[.White],
            width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
        },
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
                fontId = u16(Font_ID.Inconsolata),
                textColor = PALETTE[.White],
                fontSize = u16(TEXT_BOX_FONT_SIZE * ui_scale),
            }))
        } else {
            clay.TextDynamic(text_box.default_string, clay.TextConfig({
                fontId = u16(Font_ID.Inconsolata),
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
            if time_remainder < CYCLE_TIME / 2.0 {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(0),
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

clay_player_info :: proc(player: ^Player) {
    player_id_string := fmt.tprintf("player_%v", player.id)
    player_info_id := clay.ID(player_id_string)

    text_color := team_light_colors[player.team]
    background_color := team_dark_colors[player.team]
    border_color := team_light_colors[player.team]

    if clay.UI(id = player_info_id)({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = {
                width = clay.SizingFixed(4 * RESOLVED_CARD_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            // childGap = u16(16 * ui_scale), // @Magic
            padding = clay.PaddingAll(u16((16 + 4) * ui_scale)),  // @Magic
        },
        border = {
            width = clay.BorderOutside(u16(4 * ui_scale)),
            color = border_color,
        },
        backgroundColor = background_color,
    }) {
        username := string(cstring(raw_data(player._username_buf[:])))
        hero_name, _ := reflect.enum_name_from_value(player.hero.id)

        clay.TextDynamic(username, clay.TextConfig({
            fontId = u16(Font_ID.Inter),
            fontSize = u16(INFO_FONT_SIZE * ui_scale),
            textColor = text_color,
        }))

        clay.TextDynamic(hero_name, clay.TextConfig({
            fontId = u16(Font_ID.Inter),
            fontSize = u16(INFO_FONT_SIZE * ui_scale),
            textColor = text_color,
        }))
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
                        fontId = u16(Font_ID.Inter),
                        fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                        textColor = border_color,
                    }))

                    deck_button_id := clay.ID("deck_button", u32(player.id))
                    deck_button_data := clay.GetElementData(deck_button_id)

                    if clay_button(
                        deck_button_id,
                        image = &hero_icons[player.hero.id],
                        sizing = clay.Sizing {
                            width = clay.SizingFixed(deck_button_data.boundingBox.height),
                            height = clay.SizingGrow(),
                        },
                        padding = clay.PaddingAll(u16(16 * ui_scale)), // @Magic
                        idle_background_color = border_color,
                    ) {}

                    // if clay.UI(id = deck_button_id)({
                    //     layout = {
                    //         layoutDirection = .TopToBottom,
                    //         sizing = 
                            
                    //     },
                    //     // border = {
                    //     //     width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
                    //     //     color = border_color,
                    //     // },
                        
                    // }) {
                    //     if clay.UI()({
                    //         layout = {sizing = SIZING_GROW},
                    //         image = {&hero_icons[player.hero.id]},
                    //     }) {}
                    // }
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
                        fontId = u16(Font_ID.Inter),
                        fontSize = u16(INFO_FONT_SIZE * ui_scale),
                        textColor = text_color,
                        wrapMode = .None,
                    }))
    
                    clay.TextDynamic(hero_name, clay.TextConfig({
                        fontId = u16(Font_ID.Inter),
                        fontSize = u16(INFO_FONT_SIZE * ui_scale),
                        textColor = text_color,
                        wrapMode = .None,
                    }))
    
                    clay.TextDynamic(hero_stats_string, clay.TextConfig({
                        fontId = u16(Font_ID.Inter),
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
                            fontId = u16(Font_ID.Inconsolata),
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

                    text_with_icon(attack_string, &card_icons[.Attack], text_color)
                    text_with_icon(defense_string, &card_icons[.Defense], text_color)
                    text_with_icon(initiative_string, &card_icons[.Initiative], text_color)
                }

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                    },
                }) {
                    range_string := fmt.tprintf("+%v", item_values[.Range])
                    movement_string := fmt.tprintf("+%v", item_values[.Movement])
                    radius_string := fmt.tprintf("+%v", item_values[.Radius])

                    text_with_icon(range_string, &card_icons[.Range], text_color)
                    text_with_icon(movement_string, &card_icons[.Movement], text_color)
                    text_with_icon(radius_string, &card_icons[.Radius], text_color)
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
                        border = {
                            width = clay.BorderOutside(u16(4 * ui_scale)),
                            color = border_color,
                        },
                    }) {
                        clay.Text("Turn", clay.TextConfig({
                            fontId = u16(Font_ID.Inter),
                            fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),
                            textColor = border_color,
                        }))

                        clay.TextDynamic(fmt.tprintf("%v", i + 1), clay.TextConfig({
                            fontId = u16(Font_ID.Inter),
                            fontSize = u16(2 * INFO_FONT_SIZE * ui_scale),
                            textColor = border_color,
                        }))

                        for card in player.hero.cards {
                            if card.state != .Resolved || card.turn_played != i do continue
                            clay_card_element(
                                gs, card,
                                sizing = {
                                    clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                                    clay.SizingFixed(RESOLVED_CARD_HEIGHT * ui_scale),
                                },
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
                fontId = u16(Font_ID.Inter),
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
                        sizing = {
                            clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                            clay.SizingFixed(RESOLVED_CARD_HEIGHT * ui_scale),
                        },
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
                fontId = u16(Font_ID.Inter),
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
                fontId = u16(Font_ID.Inter),
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
                border = {
                    width = clay.BorderOutside(u16(4 * ui_scale)),
                    color = border_color,
                },
            }) {
                for card in player.hero.cards {
                    if card.state != .Played do continue
                    clay_card_element(
                        gs, card,
                        sizing = {
                            clay.SizingFixed(RESOLVED_CARD_WIDTH * ui_scale),
                            clay.SizingFixed(RESOLVED_CARD_HEIGHT * ui_scale),
                        },
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
    DECK_VIEWER_PADDING_GAP :: 8

    preview_card_sizing := clay.Sizing {
        clay.SizingFixed(RESOLVED_CARD_WIDTH * 1.5 * ui_scale),
        clay.SizingFixed(RESOLVED_CARD_HEIGHT * 1.5 * ui_scale),
    }

    if clay.UI()({
        layout = {
            sizing = {
                width = clay.SizingFit({min = 200 * ui_scale}),
                height = clay.SizingFit({min = 200 * ui_scale}),
            },
            padding = clay.PaddingAll(u16(2 * DECK_VIEWER_PADDING_GAP * ui_scale)),
            childGap = u16(2 * DECK_VIEWER_PADDING_GAP * ui_scale),
            childAlignment = {
                x = .Center,
                y = .Center,
            },
        },
        floating = {
            attachTo = .Root,
            attachment = {
                element = .CenterCenter,
                parent  = .CenterCenter,
            },
        },
        backgroundColor = {0, 0, 0, 255},
    }) {
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFit(),
                    height = clay.SizingFit(),
                },
                childGap = u16(2 * DECK_VIEWER_PADDING_GAP * ui_scale),
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
                sizing = preview_card_sizing,
                preview_attach_points = {.CenterCenter, .CenterCenter},
            )
            silver_card := Card {
                hero_id = hero_id,
                color = .Silver,
                state = .In_Deck,
            }
            clay_card_element(
                gs, silver_card,
                sizing = preview_card_sizing,
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
                                sizing = preview_card_sizing,
                                preview_attach_points = {.CenterCenter, .CenterCenter},
                            )
                        }
                    }
                }
            }
        }
    }
}

clay_setup :: proc() {
    clay_min_memory_size := clay.MinMemorySize()

    arena_memory, _ := make([^]byte, clay_min_memory_size)
    clay_arena := clay.CreateArenaWithCapacityAndMemory(uint(clay_min_memory_size), arena_memory)
    clay.Initialize(clay_arena, {STARTING_WIDTH, STARTING_HEIGHT}, {})

    clay.SetMeasureTextFunction(clay_measure_text, nil)
}

clay_layout :: proc(gs: ^Game_State) -> Render_Command_Array {

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
                fontId = u16(Font_ID.Inter),
            }),
        )

        #partial switch gs.screen {
        case .Pre_Lobby:    clay_pre_lobby_screen(gs)
        case .In_Lobby:     clay_lobby_screen(gs)
        case .In_Game:      clay_game_screen(gs)
        }
    }

    return clay.EndLayout()

}

clay_render :: proc(gs: ^Game_State, commands: ^Render_Command_Array) {
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
        case .Image:
            texture := cast(^Texture) command.renderData.image.imageData
            draw_texture_pro(texture^, {0, 0, f32(texture.width), -f32(texture.height)}, Rectangle(bounding_box), {}, 0, WHITE)
        case .Custom:
            custom_data := cast(^Custom_UI_Element) command.renderData.custom.customData
            switch custom_variant in custom_data {
            case Board_Element:
                begin_scissor_mode(i32(bounding_box.x), i32(bounding_box.y), i32(bounding_box.width), i32(bounding_box.height))
                render_board(gs, Rectangle(bounding_box), custom_variant)
                end_scissor_mode()
            }
        }
    }
}


ip_text_box := UI_Text_Box_Element {
    default_string = "Enter IP Address...",
}

deck_viewer_active := false

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
        clay_text_box("ip_text_box", &ip_text_box)

        if clay_button(
            clay.ID("join_game_button"),
            "Join a game",
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * BUTTON_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
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
        ) {
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
            childGap = u16(16 * ui_scale),  // @Magic
        },
    }) {
        // Player_sidebar
        player_sidebar_id := clay.ID("player_sidebar")
        if clay.UI(id = player_sidebar_id)({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingGrow(),
                },
                childGap = u16(16 * ui_scale),
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
                    width = clay.SizingFit(),
                    height = clay.SizingGrow(),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
                childGap = u16(16 * ui_scale),  // @Magic
            },
        }) {
            if gs.is_host {
                if clay_button(clay.ID("begin_game_button"), "Begin game") {
                    broadcast_game_event(gs, Begin_Game_Event{})
                }
            }
            if clay_button(clay.ID("change_team_button"), "Change team") {
                broadcast_game_event(gs, Change_Team_Event{gs.my_player_id})
            }
        }

        hero_sidebar_id := clay.ID("hero_sidebar")
        if clay.UI(id = hero_sidebar_id)({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingGrow(),
                },
                childAlignment = {
                    x = .Right,
                    y = .Center,
                },
                childGap = u16(16 * ui_scale),  // @Magic
            },
        }) {
            for hero in Hero_ID {
                hero_name, _ := reflect.enum_name_from_value(hero)
                if clay_button(clay.ID(hero_name), hero_name) {
                    broadcast_game_event(gs, Change_Hero_Event{gs.my_player_id, hero})
                }
            }
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
                backgroundColor = background_color,
            }) {
                if clay.UI()({
                    layout = {
                        // layoutDirection = .TopToBottom,
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingFit(),
                        },
                        // padding = {
                        //     left = u16(4 * ui_scale),
                        //     right = u16(4 * ui_scale),
                        // }
                        // childGap = u16(HAND_PANEL_CHILD_GAP * ui_scale),
                    },
                }) {
                    clay.Text("Hand", clay.TextConfig({
                        fontSize = u16(0.7 * INFO_FONT_SIZE * ui_scale),  // @Magic
                        fontId = u16(Font_ID.Inter),
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
                }){
                    for card in my_player.hero.cards {
                        if card.state != .In_Hand do continue
                        clay_card_element(
                            gs, card,
                            sizing = clay.Sizing {
                                clay.SizingFixed(HAND_CARD_WIDTH * ui_scale),
                                clay.SizingFixed(HAND_CARD_HEIGHT * ui_scale),
                            },
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
                                width = clay.SizingGrow(),
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

        if deck_viewer_active {
            clay_deck_viewer(gs, get_my_player(gs).hero.id)
        }
    }
}