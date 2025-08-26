package guards

import rl "vendor:raylib"
import "core:strings"
import "core:fmt"

import "core:log"



Card_Color :: enum {
    GOLD,
    SILVER,
    RED,
    GREEN,
    BLUE,
}

Card_State :: enum {
    NONEXISTENT,
    IN_HAND,
    PLAYED,
    RESOLVED,
    DISCARDED,
}

// I philosophically dislike this enum
Ability_Kind :: enum {
    NONE,
    ATTACK,
    SKILL,
    DEFENSE_SKILL,
    DEFENSE,
    MOVEMENT,
}

Item_Kind :: enum {
    INITIATIVE,
    ATTACK,
    DEFENSE,
    MOVEMENT,
    RANGE,
    RADIUS,
}

Range  :: distinct int
Radius :: distinct int

Action_Reach :: union {
    Range,
    Radius,
}

PLUS_SIGN: cstring : "+"

Card :: struct {
    name: cstring,
    color: Card_Color,
    tier: int,
    alternate: bool,

    initiative: int,
    values: [Ability_Kind]int,
    primary: Ability_Kind,
    primary_sign: cstring,
    reach: Action_Reach,
    reach_sign: cstring,
    item: Item_Kind,
    text: string,

    // !!This cannot be sent over the network :(
    primary_effect: []Action,

    owner: Player_ID,
    texture: rl.Texture2D,
    state: Card_State,
    turn_played: int,
}

Card_ID :: struct {
    player_id: Player_ID,
    hero_id: Hero_ID,
    color: Card_Color,
    tier: int,
    alternate: bool,
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
    BOARD_TEXTURE_SIZE.x - RESOLVED_CARD_WIDTH / 2 + 300,
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}

OTHER_PLAYER_DISCARDED_CARD_POSITION_RECT :: rl.Rectangle {
    BOARD_TEXTURE_SIZE.x - RESOLVED_CARD_WIDTH / 2 + 300 + 4 * (RESOLVED_CARD_WIDTH + RESOLVED_CARD_PADDING) + RESOLVED_CARD_PADDING,
    TOOLTIP_FONT_SIZE + BOARD_HAND_SPACE * 0.1,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}


FIRST_CARD_RESOLVED_POSITION_RECT :: rl.Rectangle {
    RESOLVED_CARD_PADDING,
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH,
    RESOLVED_CARD_HEIGHT,
}


FIRST_DISCARDED_CARD_POSITION_RECT :: rl.Rectangle {
    4 * (RESOLVED_CARD_PADDING + RESOLVED_CARD_WIDTH) + RESOLVED_CARD_PADDING,
    BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING,
    RESOLVED_CARD_WIDTH * 0.75,
    RESOLVED_CARD_HEIGHT * 0.75,
}


CARD_PLAYED_POSITION_RECT :: rl.Rectangle{BOARD_POSITION_RECT.width * 0.8 - PLAYED_CARD_SIZE.x / 2, BOARD_POSITION_RECT.height - PLAYED_CARD_SIZE.y / 4, PLAYED_CARD_SIZE.x, PLAYED_CARD_SIZE.y}


ability_initials := [Ability_Kind]string {
    .NONE = "X",
    .ATTACK = "A",
    .SKILL = "S",
    .DEFENSE = "D",
    .DEFENSE_SKILL = "DS",
    .MOVEMENT = "M",
}

card_hand_position_rects: [Card_Color]rl.Rectangle

card_color_values := [Card_Color]rl.Color {
    .GOLD   = rl.GOLD,
    .SILVER = rl.GRAY,
    .RED    = rl.RED,
    .GREEN  = rl.LIME,
    .BLUE   = rl.BLUE,
}



card_input_proc: UI_Input_Proc : proc(input: Input_Event, element: ^UI_Element) -> (output: bool = false) {

    card_element := assert_variant(&element.variant, UI_Card_Element)

    if !check_outside_or_deselected(input, element^) {
        card_element.hovered = false
        return false
    }

    try_to_play: #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, Card_Clicked_Event{card_element})
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
    

    // Body text
    text_cstring := strings.clone_to_cstring(card.text)
    text_dimensions := rl.MeasureTextEx(default_font, text_cstring, TEXT_FONT_SIZE, FONT_SPACING)
    rl.DrawTextEx(default_font, text_cstring, {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TEXT_PADDING}, TEXT_FONT_SIZE, FONT_SPACING, rl.BLACK)


    // Primary & its value & sign
    primary_value := card.values[card.primary]
    switch card.primary {
    case .ATTACK, .DEFENSE, .MOVEMENT, .DEFENSE_SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%s%d%s", ability_initials[card.primary], primary_value, card.primary_sign), {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    case .SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%s", ability_initials[card.primary]), {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    case .NONE:
    }


    // Reach & sign
    if card.reach != nil {
        _, is_radius := card.reach.(Radius)
        reach_string := fmt.ctprintf("%s%d%s", "Rd" if is_radius else "Rn", card.reach, card.reach_sign)
        reach_dimensions := rl.MeasureTextEx(default_font, reach_string, TITLE_FONT_SIZE, FONT_SPACING).x
        rl.DrawTextEx(default_font, reach_string, {CARD_TEXTURE_SIZE.x - reach_dimensions - TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    }


    
    rl.EndTextureMode()

    card.texture = render_texture.texture

    rl.SetTextureFilter(card.texture, .BILINEAR)
}

draw_card: UI_Render_Proc: proc(element: UI_Element) {
    card_element := assert_variant_rdonly(element.variant, UI_Card_Element)

    card, ok := get_card_by_id(card_element.card_id)

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

    if card_element.selected {
        rl.DrawRectangleLinesEx(element.bounding_rect, 8, rl.PURPLE)
    }
    if card_element.hovered && !card_element.hidden {
        rl.DrawTexturePro(card.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, CARD_HOVER_POSITION_RECT, {}, 0, rl.WHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 4, rl.WHITE)
        // rl.DrawRectangleLinesEx(CARD_HOVER_POSITION_RECT, 2, rl.RAYWHITE)
    }
}

get_card_by_id :: proc(card_id: Card_ID) -> (card: ^Card, ok: bool) { // #optional_ok {
    player := &game_state.players[card_id.player_id]

    // If a player is holding the card, return a pointer to that
    if player.hero.id != card_id.hero_id do return
    player_card := &player.hero.cards[card_id.color]

    if player_card.tier != card_id.tier || player_card.alternate != card_id.alternate {
        // Walk the card array
        // log.info("This should not be happening outside of upgrades")
        for &hero_card in hero_cards[card_id.hero_id] {
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

find_upgrade_options :: proc(card: Card) -> []Card {

    // Walk the hero cards to view upgrade options
    for other_card, index in hero_cards[get_player_by_id(card.owner).hero.id] {
        if other_card.color == card.color && other_card.tier == card.tier + 1 {
            return hero_cards[get_my_player().hero.id][index:][:2]
        }
    }
    return {}
}

make_card_id :: proc(card: Card, player_id: Player_ID) -> Card_ID {
    return Card_ID {
        player_id,
        get_player_by_id(player_id).hero.id,
        card.color,
        card.tier,
        card.alternate,
    }
}

get_ui_card_slice :: proc(player_id: Player_ID) -> []UI_Element {
    return ui_stack[1 + 5 * player_id:][:5]
}

find_element_for_card :: proc(card: Card) -> (^UI_Element, int) {
    ui_slice := get_ui_card_slice(card.owner)

    for &element, index in ui_slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        if card_element.card_id.color == card.color {
            return &element, index
        }
    }

    return nil, -1
}

find_selected_card_element :: proc() -> (^UI_Element, bool) {
    ui_slice := get_ui_card_slice(my_player_id)
    for &element in ui_slice {
        card_element := assert_variant(&element.variant, UI_Card_Element)
        if card_element.selected {
            return &element, true
        }
    }
    return nil, false
}

play_card :: proc(card: ^Card) {

    element, _ := find_element_for_card(card^)
    card_element := &element.variant.(UI_Card_Element)
    card_element.selected = false

    if card.owner == my_player_id {
        element.bounding_rect = CARD_PLAYED_POSITION_RECT
    } else {
        card_element.hidden = true

        element.bounding_rect = OTHER_PLAYER_PLAYED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(card.owner)) * BOARD_HAND_SPACE
    }

    card.turn_played = game_state.turn_counter
    card.state = .PLAYED
}

retrieve_card :: proc(card: ^Card) {

    element, _ := find_element_for_card(card^)
    if card.owner == my_player_id {
        element.bounding_rect = card_hand_position_rects[card.color]
    } else {
        element.bounding_rect = {0, 0, 0, 0}
    }

    card.state = .IN_HAND
}

resolve_card :: proc(card: ^Card) {
    
    element, _ := find_element_for_card(card^)
    
    if card.owner == my_player_id {
        element.bounding_rect = FIRST_CARD_RESOLVED_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_RESOLVED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(card.owner)) * BOARD_HAND_SPACE
    }
    element.bounding_rect.x += f32(game_state.turn_counter) * (FIRST_CARD_RESOLVED_POSITION_RECT.x + FIRST_CARD_RESOLVED_POSITION_RECT.width)
    
    card.state = .RESOLVED
}

discard_card :: proc(card: ^Card) {
    element, index := find_element_for_card(card^)

    if card.owner == my_player_id {
        element.bounding_rect = FIRST_DISCARDED_CARD_POSITION_RECT
    } else {
        element.bounding_rect = OTHER_PLAYER_DISCARDED_CARD_POSITION_RECT
        element.bounding_rect.y += f32(player_offset(card.owner)) * BOARD_HAND_SPACE
    }

    player := get_player_by_id(card.owner)
    prev_discarded_cards := 0

    for card in player.hero.cards {
        if card.state == .DISCARDED do prev_discarded_cards += 1
    }
    
    offset := f32(prev_discarded_cards) * RESOLVED_CARD_PADDING
    element.bounding_rect.x += offset
    element.bounding_rect.y += offset

    ui_card_slice := get_ui_card_slice(card.owner)

    ui_card_slice[prev_discarded_cards], ui_card_slice[index] = ui_card_slice[index], ui_card_slice[prev_discarded_cards]

    card.state = .DISCARDED
}