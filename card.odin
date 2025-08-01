package guards

import rl "vendor:raylib"
import "core:strings"
import "core:fmt"

CARD_TEXTURE_SIZE :: Vec2{500, 700}

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

card_color_values := [Card_Color]rl.Color {
    .NONE = rl.MAGENTA,
    .SILVER = rl.GRAY,
    .GOLD = rl.GOLD,
    .RED = rl.RED,
    .GREEN = rl.LIME,
    .BLUE = rl.BLUE,
}

Action_Kind :: enum {
    NONE,
    ATTACK,
    SKILL,
    DEFENSE_SKILL,
    DEFENSE,
    MOVEMENT,
}

ability_initials := [Action_Kind]string {
    .NONE = "X",
    .ATTACK = "A",
    .SKILL = "S",
    .DEFENSE = "D",
    .DEFENSE_SKILL = "DS",
    .MOVEMENT = "M",
}

Range  :: distinct int
Radius :: distinct int

Action_Reach :: union {
    Range,
    Radius,
}

// reach_names := [Action_Reach]string {
//     .NONE = "foobar",
//     .RANGE = "Rn",
//     .RADIUS = "Rd",
// }

Card :: struct {
    name: string,
    color: Card_Color,
    initiative: int,
    tier: int,
    secondaries: [Action_Kind]int,
    primary: Action_Kind,
    value: int,
    reach: Action_Reach,
    text: string,
    primary_effect: proc(),
    texture: rl.Texture2D
}

CARD_SCALING_FACTOR :: 1

CARD_HOVER_POSITION_RECT :: rl.Rectangle{WIDTH - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x, HEIGHT - CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y, CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.x, CARD_SCALING_FACTOR * CARD_TEXTURE_SIZE.y}
PLAYED_CARD_SIZE :: Vec2{150, 210}

CARD_PLAYED_POSITION_RECT :: rl.Rectangle{BOARD_POSITION_RECT.width * 0.8 - PLAYED_CARD_SIZE.x / 2, BOARD_POSITION_RECT.height - PLAYED_CARD_SIZE.y / 2, PLAYED_CARD_SIZE.x, PLAYED_CARD_SIZE.y}

card_hand_position_rects: [Card_Color]rl.Rectangle


create_texture_for_card :: proc(card: ^Card) {
    render_texture := rl.LoadRenderTexture(i32(CARD_TEXTURE_SIZE.x), i32(CARD_TEXTURE_SIZE.y))

    TEXT_PADDING :: 6
    COLORED_BAND_WIDTH :: 60
    TITLE_FONT_SIZE :: COLORED_BAND_WIDTH - 2 * TEXT_PADDING
    TEXT_FONT_SIZE :: 22

    rl.BeginTextureMode(render_texture)

    rl.ClearBackground(rl.RAYWHITE)

    rl.DrawRectangleRec({0, 0, COLORED_BAND_WIDTH, CARD_TEXTURE_SIZE.y / 2}, card_color_values[card.color])
    // rl.DrawRectangleRec({0, 0, CARD_TEXTURE_SIZE.x, COLORED_BAND_WIDTH}, card_color_values[card.color])

    rl.DrawText(fmt.ctprintf("%dI", card.initiative), TEXT_PADDING, TEXT_PADDING, TITLE_FONT_SIZE, rl.BLACK)
    secondaries_index := 1
    for val, ability in card.secondaries {
        if val == 0 do continue
        rl.DrawText(fmt.ctprintf("%d%s", val, ability_initials[ability]), TEXT_PADDING, TEXT_PADDING + i32(secondaries_index) * TITLE_FONT_SIZE, TITLE_FONT_SIZE, rl.BLACK)
        secondaries_index += 1
    }

    name_cstring := strings.clone_to_cstring(card.name)
    defer delete(name_cstring)
    text_cstring := strings.clone_to_cstring(card.text)
    defer delete(text_cstring)

    name_length_px := rl.MeasureText(name_cstring, TITLE_FONT_SIZE)
    name_offset := COLORED_BAND_WIDTH + (i32(CARD_TEXTURE_SIZE.x) - COLORED_BAND_WIDTH - name_length_px) / 2
    rl.DrawText(name_cstring, name_offset, TEXT_PADDING, TITLE_FONT_SIZE, rl.BLACK)

    text_dimensions := rl.MeasureTextEx(rl.GetFontDefault(), text_cstring, TEXT_FONT_SIZE, 1)

    rl.DrawText(text_cstring, TEXT_PADDING, i32(CARD_TEXTURE_SIZE.y - text_dimensions.y) - TEXT_PADDING, TEXT_FONT_SIZE, rl.BLACK)

    switch card.primary {
    case .ATTACK, .DEFENSE, .MOVEMENT, .DEFENSE_SKILL:
        rl.DrawText(fmt.ctprintf("%d%s", card.value, ability_initials[card.primary]), TEXT_PADDING, i32(CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE), TITLE_FONT_SIZE, rl.BLACK)
    case .SKILL:
        rl.DrawText(fmt.ctprintf("%s", ability_initials[card.primary]), TEXT_PADDING, i32(CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE), TITLE_FONT_SIZE, rl.BLACK)
    case .NONE:
    }

    if card.reach != nil {
        _, is_radius := card.reach.(Radius)
        reach_string := fmt.ctprintf("%d%s", card.reach, "Rd" if is_radius else "Rn")
        reach_dimensions := rl.MeasureText(reach_string, TITLE_FONT_SIZE)
        rl.DrawText(reach_string, i32(CARD_TEXTURE_SIZE.x) - reach_dimensions - TEXT_PADDING, i32(CARD_TEXTURE_SIZE.y - text_dimensions.y - TITLE_FONT_SIZE), TITLE_FONT_SIZE, rl.BLACK)
    }


    
    rl.EndTextureMode()

    card.texture = render_texture.texture
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

draw_card: UI_Render_Proc: proc(element: UI_Element) {
    card_element, ok := element.variant.(UI_Card_Element)
    assert(ok)
    rl.DrawRectangleRec(element.bounding_rect, card_color_values[card_element.card.color])

    if card_element.hovered {
        rl.DrawTexturePro(card_element.card.texture, {0, 0, CARD_TEXTURE_SIZE.x, -CARD_TEXTURE_SIZE.y}, CARD_HOVER_POSITION_RECT, {0, 0}, 0, rl.WHITE)
        // rl.DrawRectangleLinesEx(CARD_HOVER_POSITION_RECT, 2, rl.RAYWHITE)
    }
}