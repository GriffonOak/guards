package guards

// import "core:strings"
import "core:fmt"
// import "core:reflect"
import "core:math"

import clay "clay-odin"



Card_Color :: enum {
    Red,
    Green,
    Blue,
    Gold,
    Silver,
}

Card_State :: enum {
    In_Deck,
    In_Hand,
    Played,
    Resolved,
    Discarded,
}

Primary_Kind :: enum {
    Attack,
    Skill,
    Movement,
    Defense,
    Defense_Skill,
}

Card_Value_Kind :: enum {
    Attack,
    Defense,
    Initiative,
    Range,
    Movement,
    Radius,
}

Sign :: enum {
    None,
    Plus,
    Minus,
}

Card_ID :: struct {
    owner_id: Player_ID,
    hero_id: Hero_ID,
    color: Card_Color,
    tier: int,
    alternate: bool,
}

// @Note: The null card ID is understood to be invalid because it is a red card of tier 0, which does not exist.
//        If refactoring the Card id, ensure the zero value stays invalid.
_NULL_CARD_ID :: Card_ID {}

Card_Data :: struct {
    using id: Card_ID,

    name: string,
    values: [Card_Value_Kind]int,
    primary: Primary_Kind,
    primary_sign: Sign,
    reach_sign: Sign,
    item: Card_Value_Kind,
    text: string,

    // !!This cannot be sent over the network !!!!
    primary_effect: []Action,
    texture: Texture,
    preview_texture: Texture,
    background_image: Texture,
}

Card :: struct {
    using id: Card_ID,
    state: Card_State,
    turn_played: int,
}


CARD_TEXTURE_SIZE :: Vec2{500, 700}

RESOLVED_CARD_HEIGHT :: 150
RESOLVED_CARD_WIDTH :: RESOLVED_CARD_HEIGHT / 1.5

HAND_CARD_WIDTH :: 2 * RESOLVED_CARD_WIDTH
HAND_CARD_HEIGHT :: 2 * RESOLVED_CARD_HEIGHT

// Mouse contribution: h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h 


@rodata
primary_to_value := [Primary_Kind]Card_Value_Kind {
    .Attack = .Attack,
    .Skill = .Attack, // Presumably the attack value will be 0 for skills
    .Movement = .Movement,
    .Defense = .Defense,
    .Defense_Skill = .Defense,
}

@rodata
primary_to_name := [Primary_Kind]string {
    .Attack = "Attack",
    .Skill = "Skill",
    .Movement = "Movement",
    .Defense = "Defense",
    .Defense_Skill = "Defense/Skill",
}

temp_card_texture: Render_Texture_2D

shitty_outlined_text :: proc(text: string, config: clay.TextElementConfig, border_thickness: f32, border_color: clay.Color) {

    border_config := config
    border_config.textColor = border_color

    NUM_STEPS :: 16
    for i in 0..<NUM_STEPS {
        angle := f32(i) * math.TAU / NUM_STEPS

        offset := border_thickness * Vec2{math.cos(angle), math.sin(angle)}
        
        if clay.UI()({
            floating = {
                attachTo = .Parent,
                attachment = {.CenterCenter, .CenterCenter},
                offset = offset,
            },
        }) {
            clay.TextDynamic(fmt.tprintf(text), clay.TextConfig(border_config))
        }
    }

    if clay.UI()({
        floating = {attachTo = .Parent, attachment = {.CenterCenter, .CenterCenter}},
    }) {
        clay.TextDynamic(text, clay.TextConfig(config))
    }
}

create_texture_for_card :: proc(card: ^Card_Data, preview: bool = false) {
    if card.tier > 3 do return

    context.allocator = context.temp_allocator

    if temp_card_texture == {} do temp_card_texture = load_render_texture(i32(CARD_TEXTURE_SIZE.x), i32(CARD_TEXTURE_SIZE.y))

    COLORED_BAND_WIDTH :: 80

    TEXT_FONT_SIZE :: 24

    clay.SetCurrentContext(clay_main_context)

    clay.SetLayoutDimensions(transmute(clay.Dimensions) CARD_TEXTURE_SIZE)

    clay.BeginLayout()

    if clay.UI()({
        layout = {
            layoutDirection = .TopToBottom,
            sizing = SIZING_GROW,
        },
        image = {
            &card.background_image if card.background_image != {} else nil,
        },
        backgroundColor = PALETTE[.Black] if card.background_image == {} else {},
    }) {

        // Top Bar

        TOP_BAR_WIDTH: f32 = COLORED_BAND_WIDTH * 0.6
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingFixed(TOP_BAR_WIDTH),
                },
            },
            backgroundColor = PALETTE[.Dark_Gray],
        }) {}

        OUTSIDE_PADDING :: COLORED_BAND_WIDTH * 0.25
        // Sidebar
        if clay.UI()({
            layout = {
                layoutDirection = .TopToBottom,
                sizing = {
                    width = clay.SizingFixed(COLORED_BAND_WIDTH),
                    height = clay.SizingFixed(CARD_TEXTURE_SIZE.y / 2),
                },
                childAlignment = {
                    x = .Center,
                },
                padding = clay.PaddingAll(COLORED_BAND_WIDTH * 0.05),
                childGap = COLORED_BAND_WIDTH * 0.1,
            },
            floating = {
                attachTo = .Parent,
                attachment = {
                    element = .LeftTop,
                    parent = .LeftTop,
                },
                offset = {OUTSIDE_PADDING, 0},
            },
            backgroundColor = card_colors[card.color],
        }) {
            BORDER_THICKNESS :: 4
            // Spacer
            if clay.UI() ({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingFixed(TOP_BAR_WIDTH),
                    },
                },
            }) {
                // Title
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(CARD_TEXTURE_SIZE.x * 0.75),
                            height = clay.SizingFixed(TOP_BAR_WIDTH),
                        },
                        childAlignment = {
                            x = .Center,
                            y = .Center,
                        },
                    },
                    floating = {
                        attachTo = .Parent,
                        attachment = {
                            element = .LeftCenter,
                            parent = .RightBottom,
                        },
                    },
                    cornerRadius = clay.CornerRadiusAll(TOP_BAR_WIDTH * 0.5),
                    backgroundColor = PALETTE[.Light_Gray],
                }) {

                    if clay.UI()({
                        layout = {
                            sizing = SIZING_GROW,
                        },
                    }) {}

                    clay.TextDynamic(card.name, clay.TextConfig({
                        fontSize = u16(TOP_BAR_WIDTH * 0.7),
                        fontId = FONT_PALETTE[.Default_Bold],
                        textColor = PALETTE[.Black],
                        wrapMode = .None,
                    }))

                    if clay.UI()({
                        layout = {
                            sizing = SIZING_GROW,
                        },
                    }) {}

                    if clay.UI()({
                        layout = {
                            sizing = {
                                width = clay.SizingFixed(TOP_BAR_WIDTH),
                                height = clay.SizingFixed(TOP_BAR_WIDTH),
                            },
                            childAlignment = {
                                x = .Center,
                                y = .Center,
                            },
                        },
                        cornerRadius = clay.CornerRadiusAll(TOP_BAR_WIDTH * 0.5),
                        backgroundColor = PALETTE[.Gray]
                    }) {
                        tier_text := [?]string{"", "I", "II", "III", "IV"}
                        clay.TextDynamic(tier_text[card.tier], clay.TextConfig({
                            fontId = FONT_PALETTE[.Default_Bold],
                            fontSize = u16(TOP_BAR_WIDTH * 0.8),
                            textColor = PALETTE[.White],
                        }))
                    }
                }

                // Initiative
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(COLORED_BAND_WIDTH * 1.3),
                            height = clay.SizingFixed(COLORED_BAND_WIDTH * 1.3),
                        },
                        childAlignment = {
                            x = .Center,
                            y = .Center,
                        }
                    },
                    floating = {
                        attachTo = .Parent,
                        attachment = {
                            element = .CenterCenter,
                            parent = .CenterBottom,
                        },
                    },
                    image = {
                        &card_icons[.Initiative],
                    },
                }) && !preview {

                    shitty_outlined_text(fmt.tprintf("%v", card.values[.Initiative]), clay.TextElementConfig{
                        fontId = FONT_PALETTE[.Default_Bold],
                        fontSize = COLORED_BAND_WIDTH * 1.3,
                        textColor = PALETTE[.White],
                    }, BORDER_THICKNESS, PALETTE[.Black])
                }
            }

            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingGrow(),
                        height = clay.SizingGrow(),
                    },
                },
            }) {}

            for value, value_kind in card.values {
                if (
                    value == 0 ||
                    value_kind == primary_to_value[card.primary] ||
                    value_kind == .Initiative ||
                    value_kind == .Range ||
                    value_kind == .Radius
                ) { continue }

                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(COLORED_BAND_WIDTH * 0.9),
                            height = clay.SizingFixed(COLORED_BAND_WIDTH * 0.9),
                        },
                    },
                    image = {
                        &card_icons[value_kind]
                    },
                }) && !preview {
                    shitty_outlined_text(fmt.tprintf("%v", value), clay.TextElementConfig{
                        fontId = FONT_PALETTE[.Default_Bold],
                        fontSize = COLORED_BAND_WIDTH * 0.9,
                        textColor = PALETTE[.White],
                    }, BORDER_THICKNESS, PALETTE[.Black])
                }

            }
        }

        // Spacer 
        if clay.UI()({
            layout = {
                sizing = SIZING_GROW
            },
        }) {}

        // Bottom Bar
        item_showing := false
        if card.tier > 1 && card.color != .Silver && card.color != .Gold {
            item_showing = true
        }
        if clay.UI()({
            layout = {
                sizing = {
                    width = clay.SizingGrow(),
                    height = clay.SizingFixed(2 * TOP_BAR_WIDTH),
                },
                childAlignment = {
                    x = .Center,
                    y = .Bottom,
                },
                padding = clay.PaddingAll(8),
            },
            backgroundColor = PALETTE[.Dark_Gray],
        }) {
            if item_showing {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(1.2 * TOP_BAR_WIDTH),
                            height = clay.SizingFixed(1.2 * TOP_BAR_WIDTH),
                        },
                    },
                    aspectRatio = {1},
                    image = {
                        nil if preview else &item_icons[card.item]
                    },
                }) {}
            }  
        }

        // Text Box
        TEXT_BOX_WIDTH :: CARD_TEXTURE_SIZE.x - 2 * OUTSIDE_PADDING
        text_box_id := clay.ID("text_box")
        if clay.UI(id = text_box_id)({
            layout = {
                sizing = {
                    width = clay.SizingFixed(TEXT_BOX_WIDTH),
                    height = clay.SizingFit({min = 2 * TOP_BAR_WIDTH}),
                },
                padding = clay.PaddingAll(OUTSIDE_PADDING),
                childAlignment = {
                    x = .Center,
                    y = .Center,
                }
            },
            floating = {
                attachTo = .Parent,
                attachment = {.CenterBottom, .CenterBottom},
                offset = {0, -OUTSIDE_PADDING - (1.2 * TOP_BAR_WIDTH if item_showing else 0)},
            },
            border = {
                width = clay.BorderOutside(4),
                color = PALETTE[.Gray],
            },
            backgroundColor = PALETTE[.Light_Gray],
            cornerRadius = clay.CornerRadiusAll(0.5 * TOP_BAR_WIDTH)
        }) {
            clay.TextDynamic(card.text, clay.TextConfig({
                fontSize = TEXT_FONT_SIZE,
                fontId = FONT_PALETTE[.Default_Regular],
                textColor = PALETTE[.Black],
                wrapMode = .Newlines,
            }))

            // Descriptor
            if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(0.6 * TEXT_BOX_WIDTH),
                        height = clay.SizingFixed(40),
                    },
                    childAlignment = {
                        x = .Center,
                        y = .Center,
                    }
                },
                floating = {
                    attachTo = .ElementWithId,
                    attachment = {.CenterBottom, .CenterTop},
                    parentId = text_box_id.id,
                    offset = {0, 4},
                },
                border = {
                    width = clay.BorderOutside(4),
                    color = PALETTE[.Gray],
                },
                // cornerRadius = clay.CornerRadiusAll(25),
                backgroundColor = card_colors[card.color],
            }) {
                descriptor_text := fmt.tprintf(
                    "%v%v%v",
                    "Basic " if card.color == .Silver || card.color == .Gold else "",
                    primary_to_name[card.primary],
                    " - Ranged" if card.values[.Range] > 0 else "",
                )
                shitty_outlined_text(descriptor_text, clay.TextElementConfig{
                    fontSize = 30,
                    fontId = FONT_PALETTE[.Default_Bold],
                    textColor = PALETTE[.White],
                }, 2, PALETTE[.Black])
            }

            // Primary Icon
            ICON_SIZE :: 0.2 * TEXT_BOX_WIDTH
            primary_icon: if clay.UI()({
                layout = {
                    sizing = {
                        width = clay.SizingFixed(ICON_SIZE),
                        height = clay.SizingFixed(ICON_SIZE),
                    },
                },
                image = {
                    &primary_icons[card.primary],
                },
                floating = {
                    attachTo = .Parent,
                    attachment = {
                        element = .LeftBottom,
                        parent = .LeftTop,
                    },
                    offset = {
                        0,
                        0.05 * TEXT_BOX_WIDTH,
                    }
                },
            }) && !preview {
                primary_value := card.values[primary_to_value[card.primary]]
                if primary_value == 0 do break primary_icon
                text := fmt.tprintf("%v%v", primary_value, "+" if card.primary_sign == .Plus else "")
                shitty_outlined_text(text, clay.TextElementConfig{
                    fontSize = u16(ICON_SIZE),
                    fontId = FONT_PALETTE[.Default_Bold],
                    textColor = PALETTE[.White],
                }, 4, PALETTE[.Black])
            }

            // Reach Icon
            card_reach, is_radius := (card.values[.Radius] if card.values[.Radius] > 0 else card.values[.Range]), card.values[.Radius] > 0
            if card_reach > 0 {
                if clay.UI()({
                    layout = {
                        sizing = {
                            width = clay.SizingFixed(ICON_SIZE),
                            height = clay.SizingFixed(ICON_SIZE),
                        },
                    },
                    image = {
                        &card_icons[.Radius] if is_radius else &card_icons[.Range],
                    },
                    floating = {
                        attachTo = .Parent,
                        attachment = {
                            element = .RightBottom,
                            parent = .RightTop,
                        },
                        offset = {
                            0,
                            0.05 * TEXT_BOX_WIDTH,
                        }
                    },
                }) && !preview {
                    text := fmt.tprintf("%v%v", card_reach, "+" if card.reach_sign == .Plus else "")
                    shitty_outlined_text(text, clay.TextElementConfig{
                        fontSize = u16(ICON_SIZE),
                        fontId = FONT_PALETTE[.Default_Bold],
                        textColor = PALETTE[.White],
                    }, 4, PALETTE[.Black])
                }
            }

        }

        // Unimplemented warning
        if len(card.primary_effect) == 0 {
            if clay.UI()({
                floating = {
                    attachTo = .Parent,
                    attachment = {
                        .CenterCenter,
                        .CenterCenter,
                    },
                },
            }) {
                clay.Text("NO IMPLEMENTADO", clay.TextConfig({
                    fontId = FONT_PALETTE[.Default_Semibold],
                    fontSize = 40,
                    textColor = PALETTE[.Card_Red],
                }))
            }
        }
    }

    render_commands := clay.EndLayout()



    begin_texture_mode(temp_card_texture)

    clay_render(nil, &render_commands)
    
    end_texture_mode()



    render_texture := load_render_texture(i32(CARD_TEXTURE_SIZE.x), i32(CARD_TEXTURE_SIZE.y))

    begin_texture_mode(render_texture)

    clear_background(BLANK)

    draw_rectangle_rounded({0, 0, CARD_TEXTURE_SIZE.x, CARD_TEXTURE_SIZE.y}, 0.1, 8, WHITE)

    begin_blend_mode(.MULTIPLIED)

    draw_texture_pro(temp_card_texture.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, {0, 0, CARD_TEXTURE_SIZE.x, CARD_TEXTURE_SIZE.y}, {}, 0, WHITE)

    end_blend_mode()

    end_texture_mode()

    set_texture_filter(render_texture.texture, .BILINEAR)

    if preview {
        card.preview_texture = render_texture.texture
    } else {
        card.texture = render_texture.texture
    }

}

get_card_by_id :: proc(gs: ^Game_State, card_id: Card_ID) -> (card: ^Card, ok: bool) {
    player := get_player_by_id(gs, card_id.owner_id)
    player_card := &player.hero.cards[card_id.color]
    if player_card.id != card_id do return nil, false
    return player_card, true
}

get_card_data_by_id :: proc(_gs: ^Game_State, card_id: Card_ID) -> (card: ^Card_Data, ok: bool) { // #optional_ok {
    if card_id == {} do return {}, false

    for &hero_card in hero_cards[card_id.hero_id] {
        if hero_card.color == card_id.color {
            if hero_card.color == .Gold || hero_card.color == .Silver {
                return &hero_card, true
            }
            if hero_card.tier == card_id.tier && (hero_card.alternate == card_id.alternate) {
                return &hero_card, true
            }
        }
    }

    return {}, false
}

find_upgrade_options :: proc(gs: ^Game_State, card_id: Card_ID) -> (out: [2]Card_ID, ok: bool) {

    // Walk the hero cards to view upgrade options
    for other_card, index in hero_cards[card_id.hero_id] {
        if other_card.color == card_id.color && other_card.tier == card_id.tier + 1 {
            out[0] = other_card.id
            out[0].hero_id = card_id.hero_id  // Remember that the card data's hero id is not set by default
            out[1] = hero_cards[card_id.hero_id][index + 1].id
            out[1].hero_id = card_id.hero_id  // Remember that the card data's hero id is not set by default
            ok = true
            return
        }
    }
    return
}

get_ui_card_slice :: proc(gs: ^Game_State, player_id: Player_ID) -> []UI_Element {
    if len(gs.ui_stack[.Cards]) < 5 * (player_id + 1) do return {}
    return gs.ui_stack[.Cards][5 * player_id:][:5]
}

retrieve_card :: proc(gs: ^Game_State, card: ^Card) {
    card.state = .In_Hand
}

resolve_card :: proc(gs: ^Game_State, card: ^Card) {
    card.turn_played = gs.turn_counter
    card.state = .Resolved
}

discard_card :: proc(gs: ^Game_State, card: ^Card) {
    card.turn_played = gs.turn_counter
    card.state = .Discarded
}