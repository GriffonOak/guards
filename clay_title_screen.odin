package guards

import clay "clay-odin"
import "core:math"


ip_text_box := UI_Text_Box_Element {
    default_string = "Enter IP Address...",
}

current_deck_viewer: Maybe(Hero_ID) = nil

clay_title_screen :: proc(gs: ^Game_State) {
    if clay.UI()({
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
                layoutDirection = .TopToBottom,
                sizing = SIZING_GROW,
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
                childGap = scaled_padding,
            },
        }) {
            TITLE_TEXT :: "Guards of Atlantis II"
            title_text_offset := f32(scaled_border)

            if clay.UI()({}) {
                clay.Text(TITLE_TEXT, clay.TextConfig({
                    fontId = FONT_PALETTE[.Default_Bold],
                    fontSize = 4 * scaled_title_font_size,
                    textColor = PALETTE[.Background],
                }))
    
                for i in 0..<3 {
                    angle := f32(i) * math.TAU / 16 + math.TAU / 16
                    for team in Team {
                        if clay.UI()({
                            floating = {
                                attachTo = .Parent,
                                attachment = {
                                    .CenterCenter,
                                    .CenterCenter,
                                },
                                offset = title_text_offset * Vec2{math.cos(angle), math.sin(angle)} * (1 if team == .Blue else -1),
                            },
                        }) {
                            clay.Text(TITLE_TEXT, clay.TextConfig({
                                fontId = FONT_PALETTE[.Default_Bold],
                                fontSize = 4 * scaled_title_font_size,
                                textColor = team_light_colors[team],
                            }))
                        }
                    }
                }
                
                if clay.UI()({
                    floating = {
                        attachTo = .Parent,
                        attachment = {
                            .CenterCenter,
                            .CenterCenter,
                        },
                    },
                }) {
                    clay.Text(TITLE_TEXT, clay.TextConfig({
                        fontId = FONT_PALETTE[.Default_Bold],
                        fontSize = 4 * scaled_title_font_size,
                        textColor = PALETTE[.Background],
                    }))
                }
            }


            clay.Text("Designed by Artyom Nichipurov", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = scaled_info_font_size,
                textColor = PALETTE[.Mid_Gray],
            }))
            clay.Text("Written for the screen by Griffon Thomas", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = scaled_info_font_size,
                textColor = PALETTE[.Mid_Gray],
            }))
            clay.Text("Card artwork by:", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = scaled_info_font_size,
                textColor = PALETTE[.Mid_Gray],
            }))
            clay.Text("Kohl Hedley", clay.TextConfig({
                fontId = FONT_PALETTE[.Default_Semibold],
                fontSize = scaled_info_font_size,
                textColor = PALETTE[.Mid_Gray],
            }))
        }
        
        if clay.UI()({
            layout = {
                sizing = {
                    height = clay.SizingFit(),
                    width = clay.SizingGrow(),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
                childGap = scaled_padding,
            },
        }) {
            clay_text_box(
                clay.ID("ip_text_box"), 
                &ip_text_box,
                sizing = clay.Sizing {
                    width = clay.SizingFixed(2 * f32(scaled_button_width)),
                    height = clay.SizingFit(),
                },
            )
    
            if clay_button(
                clay.ID("join_game_button"),
                "Join a game",
                // sizing = clay.Sizing {
                //     width = clay.SizingFixed(2 * f32(scaled_button_width)),
                //     height = clay.SizingFit(),
                // },
                corner_radius = f32(scaled_large_corner_radius),
            ) {
                append(&gs.event_queue, Join_Network_Game_Chosen_Event{})
            }
    
            if clay_button(
                clay.ID("host_game_button"),
                "Host a game",
                // sizing = clay.Sizing {
                //     width = clay.SizingFixed(2 * f32(scaled_button_width)),
                //     height = clay.SizingFit(),
                // },
                corner_radius = f32(scaled_large_corner_radius),
            ) {
                append(&gs.event_queue, Host_Game_Chosen_Event{})
            }
        }

    }
}
