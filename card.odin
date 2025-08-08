package guards

import rl "vendor:raylib"
import "core:strings"
import "core:fmt"



Card_Color :: enum {
    NONE,
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

Range  :: distinct int
Radius :: distinct int

Action_Reach :: union {
    Range,
    Radius,
}

Card :: struct {
    name: string,
    color: Card_Color,
    initiative: int,
    tier: int,
    values: [Ability_Kind]int,
    primary: Ability_Kind,
    reach: Action_Reach,
    text: string,
    primary_effect: []Action,
    texture: rl.Texture2D,
    state: Card_State,
}



CARD_TEXTURE_SIZE :: Vec2{500, 700}

CARD_SCALING_FACTOR :: 1

CARD_HOVER_POSITION_RECT :: rl.Rectangle{WIDTH - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x, HEIGHT - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y, CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x, CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y}
PLAYED_CARD_SIZE :: Vec2{150, 210}

CARD_HAND_WIDTH :: BOARD_POSITION_RECT.width / 5
CARD_HAND_HEIGHT :: 48 // CARD_HAND_WIDTH * 1.5
CARD_HAND_Y_POSITION :: HEIGHT - CARD_HAND_HEIGHT

BOARD_HAND_SPACE :: CARD_HAND_Y_POSITION - BOARD_TEXTURE_SIZE.y
RESOLVED_CARD_HEIGHT :: BOARD_HAND_SPACE * 0.8
RESOLVED_CARD_PADDING :: (BOARD_HAND_SPACE - RESOLVED_CARD_HEIGHT) / 2

FIRST_CARD_RESOLVED_POSITION_RECT :: rl.Rectangle{RESOLVED_CARD_PADDING, BOARD_POSITION_RECT.height + RESOLVED_CARD_PADDING, RESOLVED_CARD_HEIGHT / 1.5, RESOLVED_CARD_HEIGHT}

CARD_PLAYED_POSITION_RECT :: rl.Rectangle{BOARD_POSITION_RECT.width * 0.8 - PLAYED_CARD_SIZE.x / 2, BOARD_POSITION_RECT.height - PLAYED_CARD_SIZE.y / 2, PLAYED_CARD_SIZE.x, PLAYED_CARD_SIZE.y}




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
    .NONE = rl.MAGENTA,
    .SILVER = rl.GRAY,
    .GOLD = rl.GOLD,
    .RED = rl.RED,
    .GREEN = rl.LIME,
    .BLUE = rl.BLUE,
}



card_input_proc: UI_Input_Proc : proc(input: Input_Event, element: ^UI_Element) -> (output: bool = false) {

    card_element := assert_variant(&element.variant, UI_Card_Element)

    if !check_outside_or_deselected(input, element^) {
        card_element.hovered = false
        return false
    }

    try_to_play: #partial switch var in input {
    case Mouse_Pressed_Event:
        append(&event_queue, Card_Clicked_Event{element})
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

    rl.DrawRectangleRec({0, 0, COLORED_BAND_WIDTH, CARD_TEXTURE_SIZE.y / 2}, card_color_values[card.color])
    // rl.DrawRectangleRec({0, 0, CARD_TEXTURE_SIZE.x, COLORED_BAND_WIDTH}, card_color_values[card.color])

    rl.DrawTextEx(default_font, fmt.ctprintf("%dI", card.initiative), {TEXT_PADDING, TEXT_PADDING}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    secondaries_index := 1
    for val, ability in card.values {
        if val == 0 || ability == card.primary do continue
        rl.DrawTextEx(default_font, fmt.ctprintf("%d%s", val, ability_initials[ability]), {TEXT_PADDING, TEXT_PADDING + f32(secondaries_index) * TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
        secondaries_index += 1
    }

    name_cstring := strings.clone_to_cstring(card.name)
    text_cstring := strings.clone_to_cstring(card.text)

    name_length_px := rl.MeasureTextEx(default_font, name_cstring, TITLE_FONT_SIZE, FONT_SPACING).x
    name_offset := COLORED_BAND_WIDTH + (CARD_TEXTURE_SIZE.x - COLORED_BAND_WIDTH - name_length_px) / 2
    rl.DrawTextEx(default_font, name_cstring, {name_offset, TEXT_PADDING}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)

    text_dimensions := rl.MeasureTextEx(default_font, text_cstring, TEXT_FONT_SIZE, FONT_SPACING)

    rl.DrawTextEx(default_font, text_cstring, {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TEXT_PADDING}, TEXT_FONT_SIZE, FONT_SPACING, rl.BLACK)

    primary_value := card.values[card.primary]
    switch card.primary {
    case .ATTACK, .DEFENSE, .MOVEMENT, .DEFENSE_SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%d%s", primary_value, ability_initials[card.primary]), {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    case .SKILL:
        rl.DrawTextEx(default_font, fmt.ctprintf("%s", ability_initials[card.primary]), {TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    case .NONE:
    }

    if card.reach != nil {
        _, is_radius := card.reach.(Radius)
        reach_string := fmt.ctprintf("%d%s", card.reach, "Rd" if is_radius else "Rn")
        reach_dimensions := rl.MeasureTextEx(default_font, reach_string, TITLE_FONT_SIZE, FONT_SPACING).x
        rl.DrawTextEx(default_font, reach_string, {CARD_TEXTURE_SIZE.x - reach_dimensions - TEXT_PADDING, CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE}, TITLE_FONT_SIZE, FONT_SPACING, rl.BLACK)
    }


    
    rl.EndTextureMode()

    card.texture = render_texture.texture
}

draw_card: UI_Render_Proc: proc(element: UI_Element) {
    card_element, ok := element.variant.(UI_Card_Element)
    assert(ok) 

    amount_to_show := element.bounding_rect.height / element.bounding_rect.width * CARD_TEXTURE_SIZE.y
    rl.DrawRectangleRec(element.bounding_rect, card_color_values[card_element.card.color])

    // Looks a little bunk but I should revisit this
    // rl.DrawTexturePro(card_element.card.texture, {0, CARD_TEXTURE_SIZE.y - amount_to_show, CARD_TEXTURE_SIZE.x, -amount_to_show}, element.bounding_rect, {}, 0, rl.WHITE)

    if card_element.hovered {
        rl.DrawTexturePro(card_element.card.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, CARD_HOVER_POSITION_RECT, {}, 0, rl.WHITE)
        rl.DrawRectangleLinesEx(element.bounding_rect, 10, rl.WHITE)
        // rl.DrawRectangleLinesEx(CARD_HOVER_POSITION_RECT, 2, rl.RAYWHITE)
    }
}