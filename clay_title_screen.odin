package guards

import clay "clay-odin"
import "core:math"
import "core:strings"
import sa "core:container/small_array"
import "core:net"

ip_allowed_characters: Rune_Set
username_allowed_characters: Rune_Set

username_text_box := UI_Text_Box_Element {
    default_string = "Enter Username...",
}

ip_text_box := UI_Text_Box_Element {
    default_string = "Enter IP...",
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
                    angle := -f32(i) * math.TAU / 16 - math.TAU / 16
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
                layoutDirection = .TopToBottom,
                sizing = {
                    height = clay.SizingFit(),
                    width = clay.SizingFit(),
                },
                childAlignment = {
                    x = .Center,
                    y = .Center,
                },
                padding = clay.PaddingAll(scaled_padding),
                childGap = scaled_padding,
            },
            backgroundColor = PALETTE[.Dark_Gray],
            cornerRadius = clay.CornerRadiusAll(f32(scaled_large_corner_radius)),
        }) {

            clay_text_box(
                clay.ID("username_text_box"),
                &username_text_box,
                username_allowed_characters,
                18,
            )

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFixed(f32(scaled_border)),
                    },
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                backgroundColor = PALETTE[.Mid_Gray],
            }) {}

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
                join_button_id := clay.ID("join_game_button")

                if clay.UI()({
                    layout = {
                        layoutDirection = .TopToBottom,
                        sizing = {
                            height = clay.SizingFit(),
                            width = clay.SizingFit(),
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
                        ip_allowed_characters,
                        15,
                    )
        
                    ip := string(sa.slice(&ip_text_box.field))
                    _, ip_ok := net.parse_ip4_address(ip)
                    ip_ok &&= strings.count(ip, ".") == 3
                    ip_ok ||= sa.len(ip_text_box.field) == 0
                    ip_ok &&= sa.len(username_text_box.field) > 0
            
                    if clay_button(
                        join_button_id,
                        "Join network game" if sa.len(ip_text_box.field) > 0 else "Join local game",
                        corner_radius = f32(scaled_large_corner_radius),
                        sizing = clay.Sizing {
                            width = clay.SizingGrow(),
                            height = clay.SizingFit(),
                        },
                        disabled = !ip_ok,
                    ) {
                        append(&gs.event_queue, Join_Network_Game_Chosen_Event{})
                    }
                }

                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(f32(scaled_border)),
                            height = clay.SizingGrow(),
                        },
                    },
                    cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                    backgroundColor = PALETTE[.Mid_Gray],
                }) {}

                join_button_data := clay.GetElementData(join_button_id)
        
                if clay_button(
                    clay.ID("host_game_button"),
                    "Host a game",
                    sizing = clay.Sizing {
                        width = clay.SizingFixed(join_button_data.boundingBox.width),
                        height = clay.SizingFit(),
                    },
                    corner_radius = f32(scaled_large_corner_radius),
                    disabled = sa.len(username_text_box.field) == 0,
                ) {
                    append(&gs.event_queue, Host_Game_Chosen_Event{})
                }
            }

        }

    }
}
