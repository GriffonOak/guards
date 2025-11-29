package guards

import clay "clay-odin"
import "core:reflect"


hero_bar_scroll_offset: f32

clay_player_info :: proc(player: ^Player) {

    text_color := team_mid_colors[player.team]

    if clay.UI()({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = {
                width = clay.SizingFixed(f32(4 * scaled_resolved_card_size.x)),
                height = clay.SizingFit(),
            },
            childGap = scaled_padding,
        },
    }) {

        image := &hero_icons[player.hero.id]
        aspectRatio := f32(image.width) / f32(image.height)
        height := f32(2 * scaled_info_font_size)
        if clay.UI() ({
            layout = {
                sizing = {
                    width = clay.SizingFixed(aspectRatio * height),
                    height = clay.SizingFixed(height),
                },
            },
            image = {image},
        }) {}

        
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
            },
        }) {
            username := string(cstring(raw_data(player._username_buf[:])))
            hero_name, _ := reflect.enum_name_from_value(player.hero.id)
    
            clay.TextDynamic(hero_name, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = u16(1.2 * f32(scaled_info_font_size)),
                textColor = text_color,
            }))

            clay.TextDynamic(username, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(0.8 * f32(scaled_info_font_size)),
                textColor = text_color,
            }))
    
        }
    }
}

clay_lobby_player_sidebar :: proc(gs: ^Game_State, team: Team) {
    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = {
                width = clay.SizingFit(),
                height = clay.SizingGrow(),
            },
            childAlignment = {x = .Center},
            childGap = 3 * scaled_border,
            padding = clay.PaddingAll(scaled_padding),
        },
        backgroundColor = team_dark_colors[team],
        cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
    }) {

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {width = clay.SizingGrow()},
                childAlignment = {
                    y = .Top,
                },
                padding = {
                    left = 2 * scaled_border,
                    right = 2 * scaled_border,
                },
            },
        }) {
            button_id := clay.ID("change_to_team_button_id", u32(team))

            change_button :: proc(id: clay.ElementId, team: Team, disabled: bool) -> bool {
                return clay_button(
                    id,
                    sizing = clay.Sizing {
                        clay.SizingFixed(f32(scaled_title_font_size)),
                        clay.SizingFixed(f32(scaled_title_font_size)),
                    },
                    padding = clay.PaddingAll(0),
                    disabled = disabled,
                    idle_background_color = team_light_colors[team] if !disabled else team_mid_colors[team],
                    active_background_color = team_mid_colors[team],
                    idle_text_color = team_dark_colors[team],
                    icon = .Arrow_Right if team == .Blue else .Arrow_Left,
                    corner_radius = 0.5 * f32(scaled_title_font_size),
                    border_width = scaled_border,
                )
            }

            my_team := get_my_player(gs).team
            if team == .Blue {
                if change_button(button_id, team, my_team == team) {
                    append(&gs.event_queue, Change_Team_Event{gs.my_player_id})
                }
                if clay.UI()({layout = {sizing = {width = clay.SizingGrow()}}}) {}
            }

            clay.TextDynamic("Red Team" if team == .Red else "Blue Team", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = u16(scaled_title_font_size),
                textColor = team_mid_colors[team],
            }))

            if team == .Red {
                if clay.UI()({layout = {sizing = {width = clay.SizingGrow()}}}) {}
                if change_button(button_id, team, my_team == team) {
                    append(&gs.event_queue, Change_Team_Event{gs.my_player_id})
                }
            }
        }

        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingFixed(f32(4 * scaled_resolved_card_size.x)),
                    height = clay.SizingFixed(f32(scaled_border)),
                },
            },
            backgroundColor = team_mid_colors[team],
            cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
        }) {}

        for &player in gs.players {
            if player.team == team do clay_player_info(&player)
        }
        if clay.UI()({
            layout = {sizing = {height = clay.SizingGrow()}},
        }) {}

        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingFixed(f32(4 * scaled_resolved_card_size.x)),
                    height = clay.SizingFixed(f32(scaled_border)),
                },
            },
            backgroundColor = team_mid_colors[team],
            cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
        }) {}
    }
}

clay_lobby_screen :: proc(gs: ^Game_State) {

    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = {
                width = clay.SizingFit(),
                height = clay.SizingGrow(),
            },
            childGap = scaled_padding,
            childAlignment = {x = .Center},
        },
    }) {
        if clay.UI()({  // Top panel, sidebars, hero selector
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {
                    width = clay.SizingFit(),
                    height = clay.SizingGrow(),
                },
                childGap = scaled_padding,
            },
        }) {
            // Player_sidebars
            clay_lobby_player_sidebar(gs, .Red)

            if clay.UI()({
                layout = {
                    layoutDirection = .TopToBottom,
                    sizing = {
                        width = clay.SizingFit(),
                        height = clay.SizingGrow(),
                    },
                    childAlignment = {
                        x = .Center,
                    },
                    childGap = 3 * scaled_border,
                    padding = clay.PaddingAll(scaled_padding),
                },
                cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
                backgroundColor = PALETTE[.Dark_Gray],
            }) {
                clay.Text("Heroes", clay.TextConfig({
                    fontId = FONT_PALETTE[.Default_Semibold],
                    fontSize = scaled_title_font_size,
                    textColor = PALETTE[.Gray],
                }))

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        childGap = scaled_border,
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingGrow(),
                        },
                    },
                }) {
                    top_divider_id := clay.ID("top_hero_divider")
                    if clay.UI(id = top_divider_id)({
                        layout = {
                            sizing = {
                                width = clay.SizingGrow(),
                                height = clay.SizingFixed(f32(scaled_border)),
                            },
                        },
                        backgroundColor = PALETTE[.Gray],
                        cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                    }) {}
                    
                    hero_scroll_id := clay.ID("hero_scroll_container")
                    data := clay.GetScrollContainerData(hero_scroll_id)
                    if clay.UI(id = hero_scroll_id)({
                        layout = {
                            layoutDirection = .TopToBottom,
                            sizing = {
                                width = clay.SizingFit(),
                                height = clay.SizingGrow(),
                            },
                            childAlignment = {
                                x = .Center,
                            },
                            childGap = scaled_padding,
                            padding = clay.Padding {
                                top = scaled_border,
                                bottom = scaled_border,
                                left = scaled_border,
                                right = scaled_border,
                            },
                        },
                        clip = {
                            vertical = true,
                            childOffset = {0, hero_bar_scroll_offset},
                        },
                    }) {
                        scroll_offset := clay.GetScrollOffset().y
                        hero_bar_scroll_offset = scroll_offset
                        
                        for hero in Hero_ID {
                            hero_name, _ := reflect.enum_name_from_value(hero)
                            disabled: bool
                            occupying_team: Team
                            for player in gs.players {
                                if player.hero.id == hero {
                                    disabled = true
                                    occupying_team = player.team
                                }
                            }
    
                            button_id := clay.ID(hero_name)
                            if clay_button(
                                button_id,
                                hero_name,
                                disabled = disabled,
                                idle_background_color = nil,
                                active_background_color = team_mid_colors[get_my_player(gs).team] if !disabled else team_mid_colors[occupying_team],
                                idle_text_color = nil if !disabled else team_dark_colors[occupying_team],
                                image = &hero_icons[hero],
                                strikethrough = Strikethrough_Config {
                                    offset = true,
                                    proportion = 0.97,
                                },
                            ) {
                                broadcast_game_event(gs, Change_Hero_Event{gs.my_player_id, hero})
                            }
                        }
                    }

                    bottom_divider_id := clay.ID("bottom_hero_divider")
                    if clay.UI(id = bottom_divider_id)({
                        layout = {
                            sizing = {
                                width = clay.SizingGrow(),
                                height = clay.SizingFixed(f32(scaled_border)),
                            },
                        },
                        backgroundColor = PALETTE[.Gray],
                        cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                    }) {}

                    for i in 0..<2 {
                        arrow_id := clay.ID("up_arrow") if i == 0 else clay.ID("down_arrow")
                        condition := hero_bar_scroll_offset < 0
                        if i != 0 {
                            condition = data.scrollContainerDimensions.height - hero_bar_scroll_offset < data.contentDimensions.height - 0.5
                        }
                        if condition || arrow_id == active_element_id  {
                            clay_button(
                                arrow_id, sizing = clay.Sizing {
                                    width = clay.SizingFixed(f32(2 * scaled_padding)),
                                    height = clay.SizingFixed(f32(2 * scaled_padding)),
                                },
                                floating = clay.FloatingElementConfig {
                                    attachTo = .ElementWithId,
                                    attachment = {
                                        element = .CenterCenter,
                                        parent = .CenterCenter,
                                    },
                                    parentId = top_divider_id.id if i == 0 else bottom_divider_id.id,
                                },
                                padding = clay.PaddingAll(0),
                                icon = .Arrow_Up if i == 0 else .Arrow_Down,
                                idle_background_color = PALETTE[.Light_Gray],
                                active_background_color = PALETTE[.Gray],
                                idle_border_color = PALETTE[.Dark_Gray],
                                idle_text_color = PALETTE[.Dark_Gray],
                                corner_radius = f32(scaled_padding),
                            )
                            if active_element_id == arrow_id {
                                data.scrollPosition.y += 0.03 * f32(scaled_border) * (1 if i == 0 else -1)
                            }
                        }
                    }
                }
            }

            clay_lobby_player_sidebar(gs, .Blue)
        }

        if clay.UI()({  // Host controls
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingFit(),
                },
                padding = clay.PaddingAll(scaled_padding),
                childGap = scaled_padding,
            },
            backgroundColor = PALETTE[.Dark_Gray],
            cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
        }) {
            clay.TextDynamic("Game Setup" if gs.is_host else "Game Setup (Host only)", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = u16(scaled_info_font_size),
                textColor = PALETTE[.Gray],
            }))

            if clay.UI()({
                layout = {
                    layoutDirection = .LeftToRight,
                    sizing = SIZING_GROW,
                },
            }) {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFit(),
                            height = clay.SizingGrow(),
                        },
                    },
                }) {
                    clay_toggle(
                        clay.ID("enable_preview_toggle"),
                        &gs.enable_full_previews,
                        "Enable full previews",
                    )
                }

                if clay.UI()({
                    layout = {
                        sizing = SIZING_GROW,
                    },
                }) {}

                if clay_button(
                    clay.ID("begin_game_button"), "Begin Game",
                    disabled = !gs.is_host,
                ) {
                    broadcast_game_event(gs, Begin_Game_Event{})
                }
            }
        }
    }
}