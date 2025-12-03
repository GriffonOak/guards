package guards

import "core:fmt"
import "core:reflect"
import clay "clay-odin"


board_element := Custom_UI_Element(Board_Element{})


clay_player_panel :: proc(gs: ^Game_State, player: ^Player) {

    text_color := team_mid_colors[player.team]
    border_color := team_mid_colors[player.team]
    background_color := team_dark_colors[player.team]

    preview_attach_points := clay.FloatingAttachPoints{
        element = .LeftTop,
        parent = .LeftTop,
    } if player.team == .Red else clay.FloatingAttachPoints{
        element = .RightTop,
        parent = .RightTop,
    }

    if clay.UI()({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = {
                width = clay.SizingFit(),
                height = clay.SizingFit(),
            },
            childGap = scaled_padding,
            padding = clay.PaddingAll(scaled_padding),
        },
        cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
        backgroundColor = background_color,
    }) {
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFit(),
                    height = clay.SizingFit(),
                },
                childGap = scaled_padding,
            },
        }) {
            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFit(),
                    },
                    childGap = scaled_padding,
                },
            }) {

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingGrow(),
                        },
                        childGap = 2 * scaled_border,
                        childAlignment = {
                            x = .Center,
                        },
                    },
                }) {
                    clay.Text("Deck", clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = scaled_small_font_size,
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
                        corner_radius = f32(scaled_large_corner_radius),
                        padding = clay.PaddingAll(scaled_padding),
                        idle_background_color = team_light_colors[player.team],
                        active_background_color = team_mid_colors[player.team],
                        idle_text_color = team_dark_colors[player.team],
                        disabled = gs.preview_mode == .Self_Only && player.id != gs.my_player_id,
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
                    hero_stats_string := fmt.tprintf("L%v, %vC", player.hero.level, player.hero.coins)
                    
                    clay_hero_title(player)
    
                    clay.TextDynamic(hero_stats_string, clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Regular],
                        fontSize = u16(scaled_info_font_size),
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
                            fontSize = scaled_info_font_size,
                            textColor = text_color,
                            wrapMode = .None,
                        }))
                        if clay.UI()({
                            layout = {
                                sizing = {
                                    clay.SizingFixed(0.9 * f32(scaled_info_font_size)),
                                    clay.SizingFixed(0.9 * f32(scaled_info_font_size)),
                                },
                            },
                            image = {icon},
                        }) {}
                    }
                }

                if clay.UI()({layout = {sizing = SIZING_GROW}}) {}

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
                    childGap = scaled_padding,
                },
            }) {
                for i in 0..<4 {
                    if clay.UI()({
                        layout = {
                            layoutDirection = .TopToBottom,
                            sizing = {
                                clay.SizingFixed(f32(scaled_resolved_card_size.x)),
                                clay.SizingFixed(f32(scaled_resolved_card_size.y)),
                            },
                            childAlignment = {
                                x = .Center,
                                y = .Center,
                            },
                        },
                        cornerRadius = clay.CornerRadiusAll(f32(scaled_small_corner_radius)),
                        border = {
                            width = clay.BorderOutside(scaled_border),
                            color = border_color,
                        },
                    }) {
                        clay.Text("Turn", clay.TextConfig({
                            fontId = FONT_PALETTE[.Default_Regular],
                            fontSize = scaled_small_font_size,
                            textColor = border_color,
                        }))

                        clay.TextDynamic(fmt.tprintf("%v", i + 1), clay.TextConfig({
                            fontId = FONT_PALETTE[.Default_Regular],
                            fontSize = 3 * scaled_small_font_size,
                            textColor = border_color,
                        }))

                        for card in player.hero.cards {
                            if card.state != .Resolved || card.turn_played != i do continue
                            clay_card_element(
                                gs, card,
                                width = f32(scaled_resolved_card_size.x),
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
                    width = clay.SizingFit(),
                    height = clay.SizingGrow(),
                },
                childGap = 2 * scaled_border,
                childAlignment = {
                    x = .Center,
                },
            },
        }) {
            clay.Text("Discard", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = scaled_small_font_size,
                textColor = border_color,
            }))

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(f32(scaled_resolved_card_size.x)),
                        height = clay.SizingGrow(),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Top,
                    },
                    padding = clay.PaddingAll(scaled_padding),
                },
                cornerRadius = clay.CornerRadiusAll(f32(scaled_small_corner_radius)),
                border = {
                    width = clay.BorderOutside(scaled_border),
                    color = border_color,
                },
            }) {
                discard_offset: f32 = 0
                for card in player.hero.cards {
                    if card.state != .Discarded do continue 
                    clay_card_element(
                        gs, card,
                        width = f32(scaled_resolved_card_size.x),
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
                    discard_offset += f32(scaled_info_font_size)  // ????
                }
            }
        }

        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFit(),
                    height = clay.SizingGrow(),
                },
                childGap = 2 * scaled_border,
                childAlignment = {
                    x = .Center,
                },
            },
        }) {
            clay.Text("Markers", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = scaled_small_font_size,
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
                fontSize = scaled_small_font_size,
                textColor = border_color,
            }))

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(f32(scaled_resolved_card_size.x)),
                        height = clay.SizingFixed(f32(scaled_resolved_card_size.y)),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Top,
                    },
                    padding = clay.PaddingAll(scaled_padding),
                },
                cornerRadius = clay.CornerRadiusAll(f32(scaled_small_corner_radius)),
                border = {
                    width = clay.BorderOutside(scaled_border),
                    color = border_color,
                },
            }) {
                for card in player.hero.cards {
                    if card.state != .Played do continue
                    clay_card_element(
                        gs, card,
                        width = f32(scaled_resolved_card_size.x),
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

clay_deck_viewer :: proc(gs: ^Game_State, hero_id: Hero_ID) {
    preview_width := f32(scaled_resolved_card_size.x) * 3 / 2

    show_preview_cards := gs.preview_mode == .Partial && get_my_player(gs).hero.id != hero_id

    background_color := PALETTE[.Dark_Gray]
    text_color := PALETTE[.Mid_Gray]
    // highlight_color := PALETTE[.Light_Gray]

    border_width: u16 = scaled_border
    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            childGap = scaled_padding,
            childAlignment = {x = .Center},
            padding = clay.PaddingAll(border_width + scaled_padding),
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
            color = PALETTE[.Mid_Gray],
            width = clay.BorderOutside(border_width),
        },
        cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
    }) {
        close_deck_viewer_id := clay.ID("close_deck_viewer")

        // close_button_result, _, close_button_active := clay_button_logic(close_deck_viewer_id)

        if clay_button(
            close_deck_viewer_id,
            sizing = clay.Sizing {
                width = clay.SizingFixed(f32(2 * scaled_padding)),
                height = clay.SizingFixed(f32(2 * scaled_padding)),
            },
            padding = clay.PaddingAll(scaled_border),
            floating = clay.FloatingElementConfig {
                attachTo = .Parent,
                attachment = {
                    element = .RightTop,
                    parent = .RightTop,
                },
                offset = {-f32(2 * scaled_border), f32(2 * scaled_border)},
            },
            idle_background_color = PALETTE[.Card_Red],
            active_background_color = PALETTE[.Mid_Red],
            icon = .X,
        ) {
            current_deck_viewer = nil
        }

        hero_name, _ := reflect.enum_name_from_value(hero_id)
        title := fmt.tprintf("%v's Deck%v", hero_name, " (Preview)" if show_preview_cards else "")
        clay.TextDynamic(title, clay.TextConfig({
            fontSize = scaled_info_font_size,
            fontId = FONT_PALETTE[.Default_Regular],
            textColor = text_color,
        }))

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                childGap = scaled_padding,
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
                    childGap = scaled_padding,
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
                        childGap = scaled_padding,
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
                                childGap = scaled_padding,
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
            childGap = scaled_padding,
        },
    }) {
        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingGrow(),
                },
                childGap = scaled_padding,
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
                    childGap = scaled_padding,
                },
            }) {
                for &player in gs.players {
                    if player.team != .Red do continue
                    clay_player_panel(gs, &player)
                }
            }

            board_id := clay.ID("board")
            board_hot := board_id.id == hot_element_id.id
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
                    childGap = scaled_padding,
                },
            }) {
                for &player in gs.players {
                    if player.team != .Blue do continue
                    clay_player_panel(gs, &player)
                }
            }
        }

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
                childGap = scaled_padding,
            },
        }) {

            my_player := get_my_player(gs)
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
                    padding = clay.PaddingAll(scaled_padding),
                    childGap = scaled_padding,
                },
                cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
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
                        fontSize = scaled_small_font_size,
                        fontId = FONT_PALETTE[.Default_Regular],
                        textColor = border_color,
                    }))
                }

                if clay.UI() ({
                    layout = {
                        layoutDirection = .LeftToRight,
                        sizing = {
                            width = clay.SizingFixed(f32(5 * scaled_hand_card_size.x + 4 * scaled_padding)),
                            height = clay.SizingFixed(f32(scaled_hand_card_size.y)),
                        },
                        childGap = scaled_padding,
                        childAlignment = {x = .Center},
                    },
                }) {
                    for card in my_player.hero.cards {
                        if card.state != .In_Hand do continue
                        clay_card_element(
                            gs, card,
                            width = f32(scaled_hand_card_size.x),
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
                    childGap = scaled_padding,
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
                            childGap = scaled_padding,
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
                                    width = clay.SizingFixed(f32(2 * scaled_hand_card_size.x)),
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