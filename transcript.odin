package guards

import "core:fmt"
import "core:reflect"
import clay "clay-odin"

Begin_Game_Entry :: struct {}

Begin_Round_Entry :: struct {
    round: int,
}

Begin_Turn_Entry :: struct {
    turn: int,
}

Card_Revealed_Entry :: struct {
    player_id: Player_ID,
    card_id: Maybe(Card_ID),
}

Transript_Entry :: union {
    Begin_Game_Entry,
    Begin_Round_Entry,
    Begin_Turn_Entry,
    Card_Revealed_Entry,
}

add_transcript_entry :: proc(gs: ^Game_State, entry: Transript_Entry) {
    append(&gs.transcript, entry)
}

format_transcript_entry :: proc(gs: ^Game_State, entry: Transript_Entry) {
    basic_text_config := clay.TextConfig({
        fontId = FONT_PALETTE[.Default_Regular],
        fontSize = scaled_info_font_size,
        textColor = PALETTE[.Light_Gray],
    })

    switch entry_variant in entry {
    case Begin_Game_Entry:
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingFit(),
                },
                layoutDirection = .LeftToRight,
                childAlignment = {
                    y = .Center,
                },
                childGap = scaled_padding,
            },
        }) {
            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFixed(f32(scaled_border)),
                    },
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                backgroundColor = PALETTE[.Light_Gray],
            }) {}
            clay.TextDynamic("The game begins!", basic_text_config)
            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFixed(f32(scaled_border)),
                    },
                },
                cornerRadius = clay.CornerRadiusAll(0.5 * f32(scaled_border)),
                backgroundColor = PALETTE[.Light_Gray],
            }) {}
        }
    case Begin_Round_Entry:
        clay.TextDynamic(fmt.tprintf("Start of Round %v", entry_variant.round + 1), basic_text_config)
    case Begin_Turn_Entry:
        clay.TextDynamic(fmt.tprintf("Start of Turn %v", entry_variant.turn + 1), basic_text_config)
    case Card_Revealed_Entry:
        player := get_player_by_id(gs, entry_variant.player_id)
        hero_name, _ := reflect.enum_name_from_value(player.hero.id)
        card_id, ok := entry_variant.card_id.?
        if ok {
            card_data, _ := get_card_data_by_id(card_id)
            clay.TextDynamic(
                fmt.tprintf(
                    "%v played %v with a total Initiative of %v.",
                    hero_name, card_data.name, calculate_implicit_quantity(gs, Card_Value{.Initiative}, {card_id = card_id}),
                ),
                basic_text_config,
            )
        } else {
            clay.TextDynamic(
                fmt.tprintf(
                    "%v could not play a card this turn.",
                    hero_name,
                ),
                basic_text_config,
            )
        }
    }

    return 
}