package guards

import clay "clay-odin"
import "core:reflect"


hero_bar_scroll_offset: f32

clay_lobby_player_sidebar :: proc(gs: ^Game_State, team: Team) {
    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = {
                width = clay.SizingFit(),
                height = clay.SizingGrow(),
            },
            childAlignment = {x = .Center},
            childGap = u16(16 * ui_scale),  // @Magic
            padding = clay.PaddingAll(u16((4 + 16) * ui_scale)),
        },
        backgroundColor = team_dark_colors[team],
        border = {
            width = clay.BorderOutside(u16(4 * ui_scale)),
            color = team_mid_colors[team],
        },
        cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),  // @Magic
    }) {
        // if get_my_player(gs).team != .Red

        if clay.UI()({
            layout = {
                layoutDirection = .LeftToRight,
                sizing = {width = clay.SizingGrow()},
                childAlignment = {
                    y = .Center,
                },
            },
        }) {
            button_id := clay.ID("change_to_team_button_id", u32(team))

            change_button :: proc(id: clay.ElementId, team: Team) -> bool {
                return clay_button(
                    id,
                    sizing = clay.Sizing {
                        clay.SizingFixed(1.5 * INFO_FONT_SIZE * ui_scale),
                        clay.SizingFixed(1.5 * INFO_FONT_SIZE * ui_scale),
                    },
                    padding = clay.PaddingAll(0),
                    // idle_border_color = team_mid_colors[team],
                    idle_background_color = team_mid_colors[team],
                    active_background_color = team_mid_colors[team],
                    idle_text_color = team_dark_colors[team],
                    arrow_direction = .Right if team == .Blue else .Left,
                    corner_radius = 0.75 * INFO_FONT_SIZE * ui_scale,
                    border_width = u16(1.5 * HOT_BUTTON_BORDER_WIDTH * ui_scale),
                )
            }

            my_team := get_my_player(gs).team
            if team == .Blue {
                if my_team != team do if change_button(button_id, team) {
                    append(&gs.event_queue, Change_Team_Event{})
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
                if my_team != team do if change_button(button_id, team) {
                    append(&gs.event_queue, Change_Team_Event{})
                }
            }
        }
        for &player in gs.players {
            if player.team == team do clay_player_info(&player)
        }
        if clay.UI()({
            layout = {sizing = {width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale)}},
        }) {}
    }
}

clay_lobby_screen :: proc(gs: ^Game_State) {
    lobby_id := clay.ID("lobby_screen")
    if clay.UI(id = lobby_id)({
        layout = {
            layoutDirection = .LeftToRight,
            sizing = SIZING_GROW,
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
                    height = clay.SizingGrow(),
                },
                childGap = u16(16 * ui_scale),  // @Magic
                childAlignment = {x = .Center},
            },
        }) {
            if clay.UI()({
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
                        padding = {
                            bottom = u16(2 * 4 * ui_scale),
                        },
                    },
                }) {
                    clay.Text("Heroes", clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Semibold],
                        fontSize = u16(1.5 * INFO_FONT_SIZE * ui_scale),
                        textColor = PALETTE[.Dark_Gray],
                    }))

                    hero_scroll_id := clay.ID("hero_scroll_container")
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
                        },
                        clip = {
                            vertical = true,
                            childOffset = {0, hero_bar_scroll_offset},
                        },
                    }) {
                        data := clay.GetScrollContainerData(hero_scroll_id)
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
                                idle_background_color = nil if !disabled else team_dark_colors[occupying_team],
                                active_background_color = team_mid_colors[get_my_player(gs).team],
                                idle_text_color = nil if !disabled else team_mid_colors[occupying_team],
                                image = &hero_icons[hero],
                            ) {
                                broadcast_game_event(gs, Change_Hero_Event{gs.my_player_id, hero})
                            }
                        }

                        scroll_indicator_size := BUTTON_HEIGHT * 0.3 * ui_scale
                        // arrow_width := 0.3 * scroll_indicator_size

                        for i in 0..<2 {
                            arrow_id := clay.ID("up_arrow") if i == 0 else clay.ID("down_arrow")
                            condition := hero_bar_scroll_offset < 0
                            if i != 0 {
                                condition = data.scrollContainerDimensions.height - hero_bar_scroll_offset < data.contentDimensions.height - 0.5
                            }
                            if condition {  // Top bar
                                if clay.UI()({
                                    layout = {
                                        sizing = {
                                            width = clay.SizingFixed(data.scrollContainerDimensions.width + 4 * 4 * ui_scale),
                                            height = clay.SizingFixed(3 * 4 * ui_scale),  // @Magic, 3 * border
                                        },
                                    },
                                    backgroundColor = PALETTE[.Dark_Gray],
                                    border = {
                                        width = clay.BorderAll(u16(4 * ui_scale)),
                                        color = PALETTE[.Background],
                                    },
                                    floating = {
                                        attachTo = .Parent,
                                        attachment = {
                                            element = .CenterCenter,
                                            parent = .CenterTop if i == 0 else .CenterBottom,
                                        },
                                    },
                                    cornerRadius = clay.CornerRadiusAll(1.5 * 4 * ui_scale),
                                }) {}
                            }
                            if condition || arrow_id == active_element_id  {
                                clay_button(
                                    arrow_id, sizing = clay.Sizing {
                                        width = clay.SizingFixed(scroll_indicator_size),
                                        height = clay.SizingFixed(scroll_indicator_size),
                                    },
                                    floating = clay.FloatingElementConfig {
                                        attachTo = .Parent,
                                        attachment = {
                                            element = .CenterCenter,
                                            parent = .CenterTop if i == 0 else .CenterBottom,
                                        },
                                    },
                                    padding = clay.PaddingAll(0),
                                    arrow_direction = Arrow_Direction.Up if i == 0 else Arrow_Direction.Down,
                                    idle_background_color = PALETTE[.Dark_Gray],
                                    active_background_color = PALETTE[.Dark_Gray],
                                    idle_border_color = PALETTE[.Background],
                                    idle_text_color = PALETTE[.Background],
                                    corner_radius = scroll_indicator_size * 0.5,
                                )
                                if active_element_id == arrow_id {
                                    data.scrollPosition.y += (3 if i == 0 else -3) * ui_scale
                                }
                            }
                        }
                    }
                }

                clay_lobby_player_sidebar(gs, .Blue)

                // if clay.UI()({
                //     layout = {
                //         layoutDirection = .TopToBottom,
                //         sizing = {
                //             width = clay.SizingFit(),
                //             height = clay.SizingGrow(),
                //         },
                //         childGap = u16(16 * ui_scale),  // @Magic
                //         childAlignment = {x = .Center},
                //         padding = clay.PaddingAll(u16((4 + 16) * ui_scale)),
                //     },
                //     backgroundColor = team_dark_colors[.Blue],
                //     border = {
                //         width = clay.BorderOutside(u16(4 * ui_scale)),
                //         color = team_mid_colors[.Blue],
                //     },
                //     cornerRadius = clay.CornerRadiusAll(0.5 * RESOLVED_CARD_WIDTH * CARD_CORNER_RADIUS_PROPORTION * ui_scale),
                // }) {
                //     clay.Text("Blue Team", clay.TextConfig({
                //         fontId = FONT_PALETTE[.Default_Semibold],
                //         fontSize = u16(1.5 * INFO_FONT_SIZE * ui_scale),
                //         textColor = team_mid_colors[.Blue],
                //     }))
                //     for &player in gs.players {
                //         if player.team == .Blue do clay_player_info(&player)
                //     }
                //     if clay.UI()({
                //         layout = {sizing = {width = clay.SizingFixed(PLAYER_INFO_WIDTH * ui_scale)}},
                //     }) {}

                //     if gs.is_host {
                //         if clay_button(clay.ID("begin_game_button"), "Begin game") {
                //             broadcast_game_event(gs, Begin_Game_Event{})
                //         }
                //     }
                // }
            }
        }
    }
}