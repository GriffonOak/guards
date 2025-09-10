package guards

import rl "vendor:raylib"
import "core:strings"
import "core:fmt"
import "core:math"
import "core:log"



Card_Color :: enum {
    RED,
    GREEN,
    BLUE,
    GOLD,
    SILVER,
}

Card_State :: enum {
    NONEXISTENT,
    IN_HAND,
    PLAYED,
    RESOLVED,
    DISCARDED,
    ITEM,
}

// I philosophically dislike this enum
Ability_Kind :: enum {
    // NONE,
    ATTACK,
    SKILL,
    DEFENSE_SKILL,
    DEFENSE,
    MOVEMENT,
}

Item_Kind :: enum {
    ATTACK,
    DEFENSE,
    INITIATIVE,
    RANGE,
    MOVEMENT,
    RADIUS,
}

item_initials: [Item_Kind]cstring = {
    .ATTACK = "A",
    .DEFENSE = "D",
    .INITIATIVE = "I",
    .RANGE = "Rn",
    .MOVEMENT = "M",
    .RADIUS = "Ra",
}

Range  :: distinct int
Radius :: distinct int

Action_Reach :: union {
    Range,
    Radius,
}

PLUS_SIGN: cstring : "+"

Sign :: enum {
    NONE,
    PLUS,
    MINUS,
}

Card_ID :: struct {
    owner: Player_ID,
    color: Card_Color,
    tier: int,
    alternate: bool,
}

// @Note: The null card ID is understood to be invalid because it is a red card of tier 0, which does not exist.
//        If refactoring the Card id, ensure the zero value stays invalid.
NULL_CARD_ID :: Card_ID {}

Card :: struct {
    name: cstring,

    using id: Card_ID,
    
    initiative: int,
    values: [Ability_Kind]int,
    primary: Ability_Kind,
    primary_sign: Sign,
    reach: Action_Reach,
    reach_sign: Sign,
    item: Item_Kind,
    text: string,

    // !!This cannot be sent over the network :(
    primary_effect: []Action,

    texture: rl.Texture2D,
    state: Card_State,
    turn_played: int,
}


CARD_TEXTURE_SIZE :: Vec2{500, 700}

CARD_SCALING_FACTOR :: 1

CARD_HOVER_POSITION_RECT :: rl.Rectangle {
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

OTHER_PLAYER_PLAYED_CARD_POSITION_RECT :: rl.Rectangle {
    BOARD_TEXTURE_SIZE.x - RESOLVED_CARD_WIDTH / 2,
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}
// Copy and paste of above but with +constant on x
OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT :: rl.Rectangle {
    BOARD_TEXTURE_SIZE.x + RESOLVED_CARD_WIDTH / 2 + RESOLVED_CARD_PADDING + 450, // @Magic
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}

OTHER_PLAYER_DISCARDED_CARD_POSITION_RECT :: rl.Rectangle {
    OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT.x + 4 * (RESOLVED_CARD_WIDTH + RESOLVED_CARD_PADDING),
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}  // Mouse contribution: h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h h 


FIRST_CARD_RESOLVED_POSITION_RECT :: rl.Rectangle {
    RESOLVED_CARD_PADDING + 450,  // @Magic this comes from the amount of space we give items when rendering player info
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}


FIRST_DISCARDED_CARD_POSITION_RECT :: rl.Rectangle {
    4 * (RESOLVED_CARD_PADDING + RESOLVED_CARD_WIDTH) + FIRST_CARD_RESOLVED_POSITION_RECT.x,
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}

CARD_PLAYED_POSITION_RECT :: rl.Rectangle{BOARD_POSITION_RECT.width - PLAYED_CARD_SIZE.x - RESOLVED_CARD_PADDING, BOARD_POSITION_RECT.height - PLAYED_CARD_SIZE.y / 4, PLAYED_CARD_SIZE.x, PLAYED_CARD_SIZE.y}


@rodata
ability_initials := [Ability_Kind]string {
    .ATTACK = "A",
    .SKILL = "S",
    .DEFENSE = "D",
    .DEFENSE_SKILL = "DS",
    .MOVEMENT = "M",
}

card_hand_position_rects: [Card_Color]rl.Rectangle

@rodata
card_color_values := [Card_Color]rl.Color {
    .GOLD   = rl.GOLD,
    .SILVER = rl.GRAY,
    .RED    = rl.RED,
    .GREEN  = rl.LIME,
    .BLUE   = rl.BLUE,
}



card_input_proc: UI_Input_Proc : proc(gs: ^Game_State, input: Input_Event, element: ^UI_Element) -> (output: bool = false) {

    card_element := assert_variant(&element.variant, UI_Card_Element)

    if !check_outside_or_deselected(input, element^) {
        card_element.hovered = false
        return false
    }

    try_to_play: #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&gs.event_queue, Card_Clicked_Event{card_element})
    }

    card_element.hovered = true
    return true
}

create_texture_for_card :: proc(card: ^Card) {
    context.allocator = context.temp_allocator

    render_texture := rl.LoadRenderTexture(i32(CARD_TEXTURE_SIZE.x), i32(CARD_TEXTURE_SIZE.y))

    TEXT_PADDING :: 6
    COLORED_BAND_WIDTH :: 60
    TITLE_FONT_SIZE :: COLORED_BAND_WIDTH - 2 * TEXT_PADDING
    TEXT_FONT_SIZE :: 31

    rl.BeginTextureMode(render_texture)

    rl.ClearBackground(rl.RAYWHITE)

    // Secondaries ribbon & initiative
    rl.DrawRectangleRec({0, 0, COLORED_BAND_WIDTH, CARD_TEXTURE_SIZE.y / 2}, card_color_values[card.color])

    rl.DrawTextEx(default_font, fmt.ctprintf("I%d", card.initiative), {TEXT_PADDING, TEXT_PADDING}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    secondaries_index := 1
    for val, ability in card.values {
        if val == 0 || ability == card.primary do continue
        rl.DrawTextEx(default_font, fmt.ctprintf("%s%d", ability_initials[ability], val), {TEXT_PADDING, TEXT_PADDING + f32(secondaries_index) * TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
        secondaries_index += 1
    }
    

    // Name
    name_length_px := rl.MeasureTextEx(default_font, card.name, TITLE_FONT_SIZE, FONT_SPACING).x
    name_offset := COLORED_BAND_WIDTH + (CARD_TEXTURE_SIZE.x - COLORED_BAND_WIDTH - name_length_px) / 2
    rl.DrawTextEx(default_font, card.name, {name_offset, TEXT_PADDING}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)


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
    primary_value := card.values[card.primary]
    switch card.primary {
    case .ATTACK, .DEFENSE, .MOVEMENT, .DEFENSE_SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%s%d%s", ability_initials[card.primary], primary_value, PLUS_SIGN if card.primary_sign == .PLUS else ""), {TEXT_PADDING, y_offset - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    case .SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%s", ability_initials[card.primary]), {TEXT_PADDING, y_offset - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    }

    // Reach & sign
    if card.reach != nil {
        _, is_radius := card.reach.(Radius)
        reach_string := fmt.ctprintf("%s%d%s", "Rd" if is_radius else "Rn", card.reach, PLUS_SIGN if card.reach_sign == .PLUS else "")
        reach_dimensions := rl.MeasureTextEx(default_font, reach_string, TITLE_FONT_SIZE, FONT_SPACING).x
        rl.DrawTextEx(default_font, reach_string, {CARD_TEXTURE_SIZE.x - reach_dimensions - TEXT_PADDING, y_offset - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
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
        unimplemented_text: cstring = "UNIMPLEMENTADO"
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

    card, ok := get_card_by_id(gs, card_element.card_id)

    log.assert(ok, "Tried to draw card element with no assigned card!")

    // amount_to_show := element.bounding_rect.height / element.bounding_rect.width * CARD_TEXTURE_SIZE.y
    if card_element.hidden {
        rl.DrawRectangleRec(element.bounding_rect, rl.RAYWHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 4, rl.LIGHTGRAY)
    } else {
        rl.DrawRectangleRec(element.bounding_rect, card_color_values[card.color])
    
        name_font_size := element.bounding_rect.width / 7
        text_padding := element.bounding_rect.width / 80

        name_size := rl.MeasureTextEx(default_font, card.name, name_font_size, FONT_SPACING)

        remaining_width := element.bounding_rect.width - name_size.x
        rl.DrawTextEx(default_font, card.name, {element.bounding_rect.x + remaining_width / 2, element.bounding_rect.y + text_padding}, name_font_size, FONT_SPACING, rl.BLACK)
    }
    // Looks a little bunk but I should revisit this
    // rl.DrawTexturePro(card_element.card.texture, {0, CARD_TEXTURE_SIZE.y - amount_to_show, CARD_TEXTURE_SIZE.x, -amount_to_show}, element.bounding_rect, {}, 0, rl.WHITE)

    action := get_current_action(gs)
    if action != nil {
        if choose_card, ok2 := action.variant.(Choose_Card_Action); ok2 {
            available: bool 
            for card_id in choose_card.card_targets {
                if card.id == card_id {
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
                // color: = color_lerp(rl.BLUE, rl.ORANGE, color_blend)
                color := color_lerp(base_color, highlight_color, color_blend)
                rl.DrawRectangleLinesEx(element.bounding_rect, 8, color)
            }
        }
    }

    if card_element.selected {
        rl.DrawRectangleLinesEx(element.bounding_rect, 8, rl.PURPLE)
    }
    if card_element.hovered && !card_element.hidden {
        rl.DrawTexturePro(card.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, CARD_HOVER_POSITION_RECT, {}, 0, rl.WHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 4, rl.WHITE)
        // rl.DrawRectangleLinesEx(CARD_HOVER_POSITION_RECT, 2, rl.RAYWHITE)
    }
}
}

get_card_by_id :: proc(gs: ^Game_State, card_id: Card_ID) -> (card: ^Card, ok: bool) { // #optional_ok {
    if card_id == NULL_CARD_ID do return nil, false
    player := &gs.players[card_id.owner]

    // If a player is holding the card, return a pointer to that
    player_card := &player.hero.cards[card_id.color]

    if player_card.tier != card_id.tier || player_card.alternate != card_id.alternate {
        // Walk the card array
        // log.info("This should not be happening outside of upgrades")
        for &hero_card in hero_cards[player.hero.id] {
            if hero_card.color == card_id.color {
                if hero_card.color == .GOLD || hero_card.color == .SILVER {
                    return &hero_card, true
                }
                if hero_card.tier == card_id.tier && hero_card.alternate == card_id.alternate {
                    return &hero_card, true
                }
            }
        }
    }

    // log.info("default return")
    return player_card, true
}

find_upgrade_options :: proc(gs: ^Game_State, card: Card) -> []Card {

    // Walk the hero cards to view upgrade options
    for other_card, index in hero_cards[get_player_by_id(gs, card.owner).hero.id] {
        if other_card.color == card.color && other_card.tier == card.tier + 1 {
            return hero_cards[get_my_player(gs).hero.id][index:][:2]
        }
    }
    return {}
}

// make_card_id :: proc(card: Card, player_id: Player_ID) -> Card_ID {
//     return Card_ID {
//         player_id,
//         card.color,
//         card.tier,
//         card.alternate,
//     }
// }

get_ui_card_slice :: proc(gs: ^Game_State, player_id: Player_ID) -> []UI_Element {
    return gs.ui_stack[1 + 5 * player_id:][:5]
}

find_element_for_card :: proc(gs: ^Game_State, card: Card) -> (^UI_Element, int) {
    ui_slice := get_ui_card_slice(gs, card.owner)

    for &element, index in ui_slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        if card_element.card_id.color == card.color {
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

    if card.owner == gs.my_player_id {
        element.bounding_rect = CARD_PLAYED_POSITION_RECT
    } else {
        card_element.hidden = true

        element.bounding_rect = OTHER_PLAYER_PLAYED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner)) * BOARD_HAND_SPACE
    }

    card.turn_played = gs.turn_counter
    card.state = .PLAYED
}

retrieve_card :: proc(gs: ^Game_State, card: ^Card) {

    element, _ := find_element_for_card(gs, card^)
    if card.owner == gs.my_player_id {
        element.bounding_rect = card_hand_position_rects[card.color]
    } else {
        element.bounding_rect = {}
    }

    card.state = .IN_HAND
}

resolve_card :: proc(gs: ^Game_State, card: ^Card) {
    
    element, _ := find_element_for_card(gs, card^)
    
    if card.owner == gs.my_player_id {
        element.bounding_rect = FIRST_CARD_RESOLVED_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner)) * BOARD_HAND_SPACE
    }
    element.bounding_rect.x +=  f32(gs.turn_counter) * (RESOLVED_CARD_PADDING + FIRST_CARD_RESOLVED_POSITION_RECT.width)
    
    card.state = .RESOLVED
}

discard_card :: proc(gs: ^Game_State, card: ^Card) {
    element, index := find_element_for_card(gs, card^)

    if card.owner == gs.my_player_id {
        element.bounding_rect = FIRST_DISCARDED_CARD_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_DISCARDED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(gs, card.owner)) * BOARD_HAND_SPACE
    }

    player := get_player_by_id(gs, card.owner)
    prev_discarded_cards := 0

    for card in player.hero.cards {
        if card.state == .DISCARDED do prev_discarded_cards += 1
    }
    
    offset := f32(prev_discarded_cards) * RESOLVED_CARD_PADDING
    element.bounding_rect.x += offset
    element.bounding_rect.y += offset

    ui_card_slice := get_ui_card_slice(gs, card.owner)

    ui_card_slice[prev_discarded_cards], ui_card_slice[index] = ui_card_slice[index], ui_card_slice[prev_discarded_cards]

    card.state = .DISCARDED
}