package guards

import rl "vendor:raylib"
import "core:strings"
import "core:fmt"
import "core:math"
import "core:log"
import "core:reflect"



Card_Color :: enum {
    Red,
    Green,
    Blue,
    Gold,
    Silver,
}

Card_State :: enum {
    In_Hand,
    Played,
    Resolved,
    Discarded,
}

// I philosophically dislike this enum
Primary_Kind :: enum {
    // None,
    Attack,
    Skill,
    Defense_Skill,
    Defense,
    Movement,
}

Card_Value_Kind :: enum {
    Attack,
    Defense,
    Initiative,
    Range,
    Movement,
    Radius,
}

item_initials: [Card_Value_Kind]cstring = {
    .Attack = "A",
    .Defense = "D",
    .Initiative = "I",
    .Range = "Rn",
    .Movement = "M",
    .Radius = "Ra",
}

PLUS_SIGN: cstring : "+"

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

    name: cstring,
    values: [Card_Value_Kind]int,
    primary: Primary_Kind,
    primary_sign: Sign,
    reach_sign: Sign,
    item: Card_Value_Kind,
    text: string,

    // !!This cannot be sent over the network !!!!
    primary_effect: []Action,
    texture: rl.Texture2D,
    background_image: rl.Texture2D,
}

Card :: struct {
    using id: Card_ID,
    state: Card_State,
    turn_played: int,
}


CARD_TEXTURE_SIZE :: Vec2{500, 700}

CARD_SCALING_FACTOR :: 1

CARD_HOVER_POSITION_RECT :: Rectangle {
    WIDTH - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x,
    HEIGHT - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y,
    CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x,
    CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y,
}

PLAYED_CARD_SIZE :: Vec2{150, 210}

CARD_HAND_WIDTH :: BOARD_POSITION_RECT.width / 5
CARD_HAND_HEIGHT :: 48 // CARD_HAND_WIDTH * 1.5
CARD_HAND_Y_POSITION :: HEIGHT - CARD_HAND_HEIGHT

BOARD_HAND_SPACE :: CARD_HAND_Y_POSITION - BOARD_TEXTURE_SIZE.y
RESOLVED_CARD_HEIGHT :: BOARD_HAND_SPACE * 0.8
RESOLVED_CARD_WIDTH :: RESOLVED_CARD_HEIGHT / 1.5
RESOLVED_CARD_PADDING :: (BOARD_HAND_SPACE - RESOLVED_CARD_HEIGHT) / 2

OTHER_PLAYER_PLAYED_CARD_POSITION_RECT :: Rectangle {
    BOARD_TEXTURE_SIZE.x - RESOLVED_CARD_WIDTH / 2,
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}
// Copy and paste of above but with +constant on x
OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT :: Rectangle {
    BOARD_TEXTURE_SIZE.x + RESOLVED_CARD_WIDTH / 2 + RESOLVED_CARD_PADDING + 450, // @Magic
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}

OTHER_PLAYER_Discarded_CARD_POSITION_RECT :: Rectangle {
    OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT.x + 4 * (RESOLVED_CARD_WIDTH + RESOLVED_CARD_PADDING),
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}  // Mouse contribution: h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h 


FIRST_CARD_RESOLVED_POSITION_RECT :: Rectangle {
    RESOLVED_CARD_PADDING + 450,  // @Magic this comes from the amount of space we give items when rendering player info
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}


FIRST_Discarded_CARD_POSITION_RECT :: Rectangle {
    4 * (RESOLVED_CARD_PADDING + RESOLVED_CARD_WIDTH) + FIRST_CARD_RESOLVED_POSITION_RECT.x,
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}

CARD_PLAYED_POSITION_RECT :: Rectangle{BOARD_POSITION_RECT.width - PLAYED_CARD_SIZE.x - RESOLVED_CARD_PADDING, BOARD_POSITION_RECT.height - PLAYED_CARD_SIZE.y / 4, PLAYED_CARD_SIZE.x, PLAYED_CARD_SIZE.y}


@rodata
primary_initials := [Primary_Kind]string {
    .Attack = "A",
    .Skill = "S",
    .Defense = "D",
    .Defense_Skill = "DS",
    .Movement = "M",
}

card_hand_position_rects: [Card_Color]Rectangle

@rodata
card_color_values := [Card_Color]rl.Color {
    .Gold   = rl.GOLD,
    .Silver = rl.GRAY,
    .Red    = rl.RED,
    .Green  = rl.LIME,
    .Blue   = rl.BLUE,
}



card_input_proc: UI_Input_Proc : proc(gs: ^Game_State, input: Input_Event, element: ^UI_Element) -> (output: bool = false) {

    card_element := assert_variant(&element.variant, UI_Card_Element)

    #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&gs.event_queue, Card_Clicked_Event{card_element})
    }

    return true
}

create_texture_for_card :: proc(card: ^Card_Data) {
    context.allocator = context.temp_allocator

    render_texture := rl.LoadRenderTexture(i32(CARD_TEXTURE_SIZE.x), i32(CARD_TEXTURE_SIZE.y))

    TEXT_PADDING :: 6
    COLORED_BAND_WIDTH :: 60
    TITLE_FONT_SIZE :: COLORED_BAND_WIDTH - 2 * TEXT_PADDING
    TEXT_FONT_SIZE :: 28

    rl.BeginTextureMode(render_texture)

    if card.background_image != {} {
        rl.DrawTexturePro(card.background_image, {0, 0, 500, 700}, {0, 0, 500, 700}, {}, 0, rl.WHITE)
    } else {
        color := rl.DARKBLUE / 2
        color.a = 255
        rl.ClearBackground(color)
    }
    
    // Secondaries ribbon & initiative
    rl.DrawRectangleRec({0, 0, COLORED_BAND_WIDTH, CARD_TEXTURE_SIZE.y / 2}, card_color_values[card.color])

    rl.DrawTextEx(default_font, fmt.ctprintf("I%d", card.values[.Initiative]), {TEXT_PADDING, TEXT_PADDING}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    secondaries_index := 1
    primary_to_value := [Primary_Kind]Card_Value_Kind {
        .Attack = .Attack,
        .Skill = .Attack, // Presumably the attack value will be 0 for skills
        .Movement = .Movement,
        .Defense = .Defense,
        .Defense_Skill = .Defense,
    }

    for value, value_kind in card.values {
        if (
            value == 0 ||
            value_kind == primary_to_value[card.primary] ||
            value_kind == .Initiative ||
            value_kind == .Range ||
            value_kind == .Radius
        ) { continue }
        value_name, _ := reflect.enum_name_from_value(value_kind)
        rl.DrawTextEx(default_font, fmt.ctprintf("%s%d", value_name[:1], value), {TEXT_PADDING, TEXT_PADDING + f32(secondaries_index) * TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
        secondaries_index += 1
    }
    

    // Name
    name_length_px := rl.MeasureTextEx(default_font, card.name, TITLE_FONT_SIZE, FONT_SPACING).x
    name_offset := (CARD_TEXTURE_SIZE.x + COLORED_BAND_WIDTH - name_length_px) / 2
    name_rect := Rectangle{name_offset - 2 * TEXT_PADDING, 2 * TEXT_PADDING, name_length_px + 4 * TEXT_PADDING, COLORED_BAND_WIDTH + 2 * TEXT_PADDING}
    rl.DrawRectangleRounded(name_rect, 0.5, 20, rl.WHITE)
    rl.DrawRectangleRoundedLinesEx(name_rect, 0.5, 20, TEXT_PADDING, rl.BLACK)
    rl.DrawTextEx(default_font, card.name, {name_rect.x, name_rect.y} + 2 * TEXT_PADDING, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)


    // Tier
    tier_ball_loc := Vec2{CARD_TEXTURE_SIZE.x - COLORED_BAND_WIDTH / 2, COLORED_BAND_WIDTH / 2}
    rl.DrawCircleV(tier_ball_loc, COLORED_BAND_WIDTH / 2, rl.DARKGRAY)
    TIER_FONT_SIZE :: TITLE_FONT_SIZE * 0.8
    if card.tier > 0 {
        tier_strings := []cstring{"I", "II", "III"}
        tier_string := tier_strings[card.tier - 1]

        tier_dimensions := rl.MeasureTextEx(default_font, tier_string, TIER_FONT_SIZE, FONT_SPACING)
        tier_text_location := tier_ball_loc - tier_dimensions / 2
        rl.DrawTextEx(default_font, tier_string, tier_text_location, TIER_FONT_SIZE, FONT_SPACING, rl.WHITE)
    }

    // Prep for bottom of card
    y_offset := CARD_TEXTURE_SIZE.y
    if card.tier > 1 {
        y_offset -= COLORED_BAND_WIDTH
    }

    text_cstring := strings.clone_to_cstring(card.text)
    text_dimensions := rl.MeasureTextEx(default_font, text_cstring, TEXT_FONT_SIZE, FONT_SPACING)

    // Primary & its value & sign
    primary_value := card.values[primary_to_value[card.primary]]
    primary_value_string := fmt.ctprintf("%d", primary_value) if primary_value > 0 else ""
    if card.primary == .Defense && len(card.primary_effect) > 0 {
        defense_action := card.primary_effect[0].variant.(Defend_Action)
        if defense_action.block_condition != nil do primary_value_string = "!"
    }
    primary_value_loc := Vec2{TEXT_PADDING, y_offset - text_dimensions.y - TITLE_FONT_SIZE}
    rl.DrawRectangleV({0, primary_value_loc.y - TEXT_PADDING}, CARD_TEXTURE_SIZE, rl.WHITE)
    rl.DrawLineEx({0, primary_value_loc.y - TEXT_PADDING}, {CARD_TEXTURE_SIZE.x, primary_value_loc.y - TEXT_PADDING}, TEXT_PADDING, rl.BLACK)
    rl.DrawTextEx(default_font, fmt.ctprintf("%s%s%s", primary_initials[card.primary], primary_value_string, PLUS_SIGN if card.primary_sign == .Plus else ""), primary_value_loc, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)

    // Reach & sign
    card_reach, is_radius := (card.values[.Radius] if card.values[.Radius] > 0 else card.values[.Range]), card.values[.Radius] > 0
    if card_reach > 0 {
        reach_string := fmt.ctprintf("%s%d%s", "Rd" if is_radius else "Rn", card_reach, PLUS_SIGN if card.reach_sign == .Plus else "")
        reach_dimensions := rl.MeasureTextEx(default_font, reach_string, TITLE_FONT_SIZE, FONT_SPACING).x
        rl.DrawTextEx(default_font, reach_string, {CARD_TEXTURE_SIZE.x - reach_dimensions - TEXT_PADDING, primary_value_loc.y}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    }

    // Body text
    rl.DrawTextEx(default_font, text_cstring, {TEXT_PADDING, y_offset - text_dimensions.y - TEXT_PADDING}, TEXT_FONT_SIZE, FONT_SPACING, rl.BLACK)

    // Item
    if card.tier > 1 {
        rl.DrawRectangleRec({0, y_offset, CARD_TEXTURE_SIZE.x, COLORED_BAND_WIDTH}, rl.DARKGRAY)
        item_initial := item_initials[card.item]
        item_text_dimensions := rl.MeasureTextEx(default_font, item_initial, TITLE_FONT_SIZE, FONT_SPACING)
        rl.DrawTextEx(default_font, item_initial, {0, y_offset} + ({CARD_TEXTURE_SIZE.x, COLORED_BAND_WIDTH} - item_text_dimensions) / 2, TITLE_FONT_SIZE, FONT_SPACING, rl.WHITE)
    }

    // Unimplemented warning
    if len(card.primary_effect) == 0 {
        unimplemented_text: cstring = "NO IMPLEMENTADO"
        unimplemented_dimensions := rl.MeasureTextEx(default_font, unimplemented_text, TITLE_FONT_SIZE, FONT_SPACING)
        rl.DrawTextEx(default_font, unimplemented_text, (CARD_TEXTURE_SIZE - unimplemented_dimensions) / 2, TITLE_FONT_SIZE, FONT_SPACING, rl.RED)
    }
    
    rl.EndTextureMode()

    card.texture = render_texture.texture

    rl.SetTextureFilter(card.texture, .BILINEAR)
}

draw_card: UI_Render_Proc: proc(gs: ^Game_State, element: UI_Element) {
    if element.bounding_rect == {} do return
when !ODIN_TEST {
    card_element := assert_variant_rdonly(element.variant, UI_Card_Element)

    card_data, ok := get_card_data_by_id(gs, card_element.card_id)

    log.assert(ok, "Tried to draw card element with no assigned card!")

    // amount_to_show := element.bounding_rect.height / element.bounding_rect.width * CARD_TEXTURE_SIZE.y
    if card_element.hidden {
        rl.DrawRectangleRec(element.bounding_rect, rl.RAYWHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 4, rl.LIGHTGRAY)
    } else {
        rl.DrawRectangleRec(element.bounding_rect, card_color_values[card_data.color])
    
        name_font_size := element.bounding_rect.width / 7
        text_padding := element.bounding_rect.width / 80

        name_size := rl.MeasureTextEx(default_font, card_data.name, name_font_size, FONT_SPACING)

        remaining_width := element.bounding_rect.width - name_size.x
        rl.DrawTextEx(default_font, card_data.name, {element.bounding_rect.x + remaining_width / 2, element.bounding_rect.y + text_padding}, name_font_size, FONT_SPACING, rl.BLACK)
    }
    // Looks a little bunk but I should revisit this
    // rl.DrawTexturePro(card_element.card_data.texture, {0, CARD_TEXTURE_SIZE.y - amount_to_show, CARD_TEXTURE_SIZE.x, -amount_to_show}, element.bounding_rect, {}, 0, rl.WHITE)

    action := get_current_action(gs)
    if action != nil {
        if choose_card, ok2 := action.variant.(Choose_Card_Action); ok2 {
            available: bool 
            for card_id in choose_card.card_targets {
                if card_element.card_id == card_id {
                    available = true
                    break
                }
            }
            if available {
                // Copy n paste from board highlighting
                frequency: f64 = 8
                color_blend := (math.sin(frequency * rl.GetTime()) + 1) / 2
                color_blend = color_blend * color_blend
                base_color := rl.DARKGRAY
                highlight_color := rl.LIGHTGRAY
                // color: = color_lerp(rl.Blue, rl.ORange, color_blend)
                color := color_lerp(base_color, highlight_color, color_blend)
                rl.DrawRectangleLinesEx(element.bounding_rect, 8, color)
            }
        }
    }

    if card_element.selected {
        rl.DrawRectangleLinesEx(element.bounding_rect, 8, rl.PURPLE)
    }
    if .Hovered in element.flags && !card_element.hidden {
        rl.DrawTexturePro(card_data.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, CARD_HOVER_POSITION_RECT, {}, 0, rl.WHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 4, rl.WHITE)
        // rl.DrawRectangleLinesEx(CARD_HOVER_POSITION_RECT, 2, rl.RAYWHITE)
    }
}
}

get_card_by_id :: proc(gs: ^Game_State, card_id: Card_ID) -> (card: ^Card, ok: bool) {
    player := get_player_by_id(gs, card_id.owner_id)
    player_card := &player.hero.cards[card_id.color]
    if player_card.id != card_id do return nil, false
    return player_card, true
}

get_card_data_by_id :: proc(_gs: ^Game_State, card_id: Card_ID) -> (card: Card_Data, ok: bool) { // #optional_ok {
    if card_id == {} do return {}, false

    for &hero_card in hero_cards[card_id.hero_id] {
        if hero_card.color == card_id.color {
            if hero_card.color == .Gold || hero_card.color == .Silver {
                return hero_card, true
            }
            if hero_card.tier == card_id.tier && (hero_card.alternate == card_id.alternate) {
                return hero_card, true
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
    return gs.ui_stack[.Cards][5 * player_id:][:5]
}

find_element_for_card :: proc(gs: ^Game_State, card_id: Card_ID) -> (^UI_Element, int) {
    ui_slice := get_ui_card_slice(gs, card_id.owner_id)

    for &element, index in ui_slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        if card_element.card_id == card_id {
            return &element, index
        }
    }

    return nil, -1
}

find_selected_card_element :: proc(gs: ^Game_State) -> (^UI_Element, bool) {
    ui_slice := get_ui_card_slice(gs, gs.my_player_id)
    for &element in ui_slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        if card_element.selected {
            return &element, true
        }
    }
    return nil, false
}

play_card :: proc(gs: ^Game_State, card: ^Card) {

    element, _ := find_element_for_card(gs, card^)
    card_element := &element.variant.(UI_Card_Element)
    card_element.selected = false

    if card.owner_id == gs.my_player_id {
        element.bounding_rect = CARD_PLAYED_POSITION_RECT
    } else {
        card_element.hidden = true

        element.bounding_rect = OTHER_PLAYER_PLAYED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner_id)) * BOARD_HAND_SPACE
    }

    card.turn_played = gs.turn_counter
    card.state = .Played
}

retrieve_card :: proc(gs: ^Game_State, card: ^Card) {

    element, _ := find_element_for_card(gs, card^)
    if card.owner_id == gs.my_player_id {
        element.bounding_rect = card_hand_position_rects[card.color]
    } else {
        element.bounding_rect = {}
    }

    card.state = .In_Hand
}

resolve_card :: proc(gs: ^Game_State, card: ^Card) {
    
    element, _ := find_element_for_card(gs, card^)
    
    if card.owner_id == gs.my_player_id {
        element.bounding_rect = FIRST_CARD_RESOLVED_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner_id)) * BOARD_HAND_SPACE
    }
    element.bounding_rect.x +=  f32(gs.turn_counter) * (RESOLVED_CARD_PADDING + FIRST_CARD_RESOLVED_POSITION_RECT.width)
    
    card.state = .Resolved
}

discard_card :: proc(gs: ^Game_State, card: ^Card) {
    element, index := find_element_for_card(gs, card^)

    if card.owner_id == gs.my_player_id {
        element.bounding_rect = FIRST_Discarded_CARD_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_Discarded_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner_id)) * BOARD_HAND_SPACE
    }

    player := get_player_by_id(gs, card.owner_id)
    prev_discarded_cards := 0

    for card in player.hero.cards {
        if card.state == .Discarded do prev_discarded_cards += 1
    }
    
    offset := f32(prev_discarded_cards) * RESOLVED_CARD_PADDING
    element.bounding_rect.x += offset
    element.bounding_rect.y += offset

    ui_card_slice := get_ui_card_slice(gs, card.owner_id)

    ui_card_slice[prev_discarded_cards], ui_card_slice[index] = ui_card_slice[index], ui_card_slice[prev_discarded_cards]

    card.state = .Discarded
}