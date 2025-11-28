package guards

import clay "clay-odin"
import "core:reflect"


hero_bar_scroll_offset: f32


PLAYER_INFO_WIDTH :: 4 * RESOLVED_CARD_WIDTH  // @Magic, this is kind of arbitrary :P

clay_player_info :: proc(player: ^Player) {

    text_color := team_mid_colors[player.team]

    if clay.UI()({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = {
                width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale),
                height = clay.SizingFit(),
            },
            childGap = u16(16 * ui_scale), // @Magic
            // padding = clay.PaddingAll(u16((16 + 4) * ui_scale)),  // @Magic
        },
        // border = {
        //     width = clay.BorderOutside(u16(4 * ui_scale)),  // @Magic
        //     color = border_color,
        // },
        // backgroundColor = background_color,
    }) {

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

        
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
            },
        }) {
            username := string(cstring(raw_data(player._username_buf[:])))
            hero_name, _ := reflect.enum_name_from_value(player.hero.id)
    
            clay.TextDynamic(hero_name, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = u16(1.2 * INFO_FONT_SIZE * ui_scale),
                textColor = text_color,
            }))

            clay.TextDynamic(username, clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Regular],
                fontSize = u16(0.8 * INFO_FONT_SIZE * ui_scale),
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
            childGap = u16(12 * ui_scale),  // @Magic
            padding = clay.PaddingAll(u16(16 * ui_scale)),
        },
        backgroundColor = team_dark_colors[team],
        // border = {
        //     width = clay.BorderOutside(u16(4 * ui_scale)),
        //     color = team_mid_colors[team],
        // },
        // cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),  // @Magic
        cornerRadius = clay.CornerRadiusAll(0.03 * BUTTON_WIDTH * ui_scale),  // @Magic
    }) {
        // if get_my_player(gs).team != .Red

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {width = clay.SizingGrow()},
                childAlignment = {
                    y = .Top,
                },
                padding = {
                    left = u16(8 * ui_scale),
                    right = u16(8 * ui_scale),
                },
            },
        }) {
            button_id := clay.ID("change_to_team_button_id", u32(team))

            change_button :: proc(id: clay.ElementId, team: Team, disabled: bool) -> bool {
                return clay_button(
                    id,
                    sizing = clay.Sizing {
                        clay.SizingFixed(1.4 * INFO_FONT_SIZE * ui_scale),
                        clay.SizingFixed(1.4 * INFO_FONT_SIZE * ui_scale),
                    },
                    padding = clay.PaddingAll(0),
                    disabled = disabled,
                    idle_background_color = team_light_colors[team] if !disabled else team_mid_colors[team],
                    active_background_color = team_mid_colors[team],
                    idle_text_color = team_dark_colors[team],
                    icon = .Arrow_Right if team == .Blue else .Arrow_Left,
                    corner_radius = 0.75 * INFO_FONT_SIZE * ui_scale,
                    border_width = u16(DEFAULT_BORDER * ui_scale),
                    // strikethrough = Strikethrough_Config {
                    //     offset = false,
                    //     proportion = 1.35,
                    // }
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
                fontSize = u16(1.5 * INFO_FONT_SIZE * ui_scale),
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
                    width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale),
                    height = clay.SizingFixed(4 * ui_scale),  // @Magic border
                },
            },
            backgroundColor = team_mid_colors[team],
            cornerRadius = clay.CornerRadiusAll(2 * ui_scale),  // @Magic border / 2
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
                    width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale),
                    height = clay.SizingFixed(4 * ui_scale),  // @Magic border
                },
            },
            backgroundColor = team_mid_colors[team],
            cornerRadius = clay.CornerRadiusAll(2 * ui_scale),  // @Magic border / 2
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
            childGap = u16(16 * ui_scale),  // @Magic
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
                childGap = u16(16 * ui_scale),  // @Magic
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
                    childGap = u16(12 * ui_scale),  // @Magic
                    padding = clay.PaddingAll(u16(16 * ui_scale)),
                },
                cornerRadius = clay.CornerRadiusAll(0.03 * BUTTON_WIDTH * ui_scale),  // @Magic
                backgroundColor = PALETTE[.Dark_Gray],
            }) {
                clay.Text("Heroes", clay.TextConfig({
                    fontId = FONT_PALETTE[.Default_Semibold],
                    fontSize = u16(1.5 * INFO_FONT_SIZE * ui_scale),
                    textColor = PALETTE[.Gray],
                }))

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        childGap = u16(4 * ui_scale),  //@Magic border
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
                                height = clay.SizingFixed(4 * ui_scale),  // @Magic border
                            },
                        },
                        backgroundColor = PALETTE[.Gray],
                        cornerRadius = clay.CornerRadiusAll(2 * ui_scale),  // @Magic border / 2
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
                            childGap = u16(16 * ui_scale),  // @Magic
                            padding = clay.Padding{
                                top = u16(8 * ui_scale),
                                bottom = u16(8 * ui_scale),
                                left = u16(4 * ui_scale),
                                right = u16(4 * ui_scale),
                            },
                            // padding = clay.PaddingAll(u16(12 * ui_scale))
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
                                height = clay.SizingFixed(4 * ui_scale),  // @Magic border
                            },
                        },
                        backgroundColor = PALETTE[.Gray],
                        cornerRadius = clay.CornerRadiusAll(2 * ui_scale),  // @Magic border / 2
                    }) {}



                    SCROLL_INDICATOR_SIZE :: 2 * DEFAULT_PADDING
                    // arrow_width := 0.3 * scroll_indicator_size

                    for i in 0..<2 {
                        arrow_id := clay.ID("up_arrow") if i == 0 else clay.ID("down_arrow")
                        condition := hero_bar_scroll_offset < 0
                        if i != 0 {
                            condition = data.scrollContainerDimensions.height - hero_bar_scroll_offset < data.contentDimensions.height - 0.5
                        }
                        if condition || arrow_id == active_element_id  {
                            clay_button(
                                arrow_id, sizing = clay.Sizing {
                                    width = clay.SizingFixed(SCROLL_INDICATOR_SIZE),
                                    height = clay.SizingFixed(SCROLL_INDICATOR_SIZE),
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
                                corner_radius = SCROLL_INDICATOR_SIZE * 0.5,
                            )
                            if active_element_id == arrow_id {
                                data.scrollPosition.y += (3 if i == 0 else -3) * ui_scale
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
                padding = clay.PaddingAll(u16((4 + 16) * ui_scale)),
                childGap = u16(16 * ui_scale),
            },
            backgroundColor = PALETTE[.Background],
            border = {
                width = clay.BorderOutside(u16(4 * ui_scale)),
                color = PALETTE[.Dark_Gray],
            },
            cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),  // @Magic
        }) {
            clay.TextDynamic("Game Setup" if gs.is_host else "Game Setup (Host only)", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = u16(INFO_FONT_SIZE * ui_scale),
                textColor = PALETTE[.Dark_Gray],
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