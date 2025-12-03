package guards

import clay "clay-odin"


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
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * f32(scaled_button_width)),
                height = clay.SizingFit(),
            },
            corner_radius = f32(scaled_large_corner_radius),
        ) {
            append(&gs.event_queue, Join_Network_Game_Chosen_Event{})
        }

        if clay_button(
            clay.ID("host_game_button"),
            "Host a game",
            sizing = clay.Sizing {
                width = clay.SizingFixed(2 * f32(scaled_button_width)),
                height = clay.SizingFit(),
            },
            corner_radius = f32(scaled_large_corner_radius),
        ) {
            append(&gs.event_queue, Host_Game_Chosen_Event{})
        }
    }
}
