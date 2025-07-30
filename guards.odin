package guards

import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"

VERTICAL_SPACING :: 50
// sqrt 3
HORIZONTAL_SPACING :: 1.732 * VERTICAL_SPACING * 0.5

Vec2 :: [2]f32

IVec2 :: [2]int

CARD_SIZE :: Vec2{250, 350}

board_offset := Vec2{50, -300}

starting_terrain := [?]IVec2 {
    {1,8}, {1,9}, {1,10}, {1,13}, {1,14}, {1,15}, {1,16}, {1,17}, {1,18},
    {2,14}, {2,15}, {2,16}, {2,17}, 
    {3,14}, {3,15},
    {4,5}, {4,11},
    {5,4}, {5,10}, {5,11}, {5,14},
    {6,3},
    {7,2},
    {8,1}, {8,2},
    {9,1}, {9,7},
    {10,1}, {10,9},
    {13,1}, {13,2}, {13,3},
    {14,1},
    {15,1}, {15,4},
    {16,1},
    {17,1},
    {18,1}
}

// red_base := [?]IVec2 {

// }

GRID_WIDTH :: 21
GRID_HEIGHT :: 20

spaces: [GRID_WIDTH][GRID_HEIGHT]Space

WIDTH :: 1920
HEIGHT :: 1080

Region_ID :: enum {
    NONE,
    RED_BASE,
    RED_BEACH,
    RED_JUNGLE,
    CENTRE,
    BLUE_JUNGLE,
    BLUE_BEACH,
    BLUE_BASE,
}

CLIFF_COLOR :: rl.Color{80, 76, 75, 255}
SAND_COLOR :: rl.Color{240, 200, 138, 255}
STONE_COLOR :: rl.Color{185, 140, 93, 255}
JUNGLE_COLOR :: rl.Color{157, 177, 58, 255}

region_colors := [Region_ID]rl.Color {
    .NONE = rl.MAGENTA,
    .RED_BASE = STONE_COLOR,
    .RED_BEACH = SAND_COLOR,
    .RED_JUNGLE = JUNGLE_COLOR,
    .CENTRE = STONE_COLOR,
    .BLUE_JUNGLE = JUNGLE_COLOR,
    .BLUE_BEACH = SAND_COLOR,
    .BLUE_BASE = STONE_COLOR,
}

Space_Flag :: enum {
    TERRAIN,
    MINION,
}

Minion_Kind :: enum {
    NONE,
    HEAVY,
}

Space_Flags :: bit_set[Space_Flag]

Space :: struct {
    position: Vec2,
    flags: Space_Flags,
    region_id: Region_ID,
    minion_kind: Minion_Kind

}

Card_Color :: enum {
    NONE,
    SILVER,
    GOLD,
    RED,
    GREEN,
    BLUE,
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
    MOVEMENT,
    DEFENSE,
}

Action_Reach :: enum {
    NONE,
    RANGE,
    RADIUS,
}

Card :: struct {
    color: Card_Color,
    initiative: int,
    tier: int,
    secondaries: [Action_Kind]int,
    primary: Action_Kind,
    reach: Action_Reach,
    length: int,
    name: string,
    text: string,
    primary_effect: proc(),
    texture: rl.Texture2D
}

set_terrain_symmetric :: proc(x, y: int) {
    spaces[x][y].flags += {.TERRAIN}
    spaces[GRID_WIDTH - x - 1][GRID_HEIGHT - y - 1].flags += {.TERRAIN}
}

setup_space_positions :: proc() {
    for &x_arr, x_idx in spaces {
        for &space, y_idx in x_arr {
            x_value := HORIZONTAL_SPACING * f32(x_idx)
            y_value := HEIGHT - (f32(x_idx) * 0.5 + f32(y_idx)) * VERTICAL_SPACING
            space.position = {x_value, y_value}
        }
    }
}

setup_terrain :: proc() {
    for x_idx in 0..<GRID_WIDTH {
        for y_idx in 0..<GRID_HEIGHT {
            if x_idx == 0 || y_idx == 0 || x_idx + y_idx <= 8 {
                set_terrain_symmetric(x_idx, y_idx)
            }
        }
    }

    for vec in starting_terrain {
        set_terrain_symmetric(vec.x, vec.y)
    }
}

assign_region_symmetric :: proc(x, y: int, region_id: Region_ID) {
    spaces[x][y].region_id = region_id
    spaces[GRID_WIDTH - x - 1][GRID_HEIGHT - y - 1].region_id = Region_ID(len(Region_ID) - int(region_id))
}

setup_regions :: proc() {
    // Bases
    for x_idx in 1..=4 {
        for y_idx in 6..=17 {
            if .TERRAIN in spaces[x_idx][y_idx].flags do continue
            if y_idx <= 14-x_idx {
                assign_region_symmetric(x_idx, y_idx, .RED_BASE)
            } else {
                assign_region_symmetric(x_idx, y_idx, .RED_JUNGLE)
            }
        }
    }

    for x_idx in 5..=8 {
        for y_idx in 3..=17 {
            if .TERRAIN in spaces[x_idx][y_idx].flags do continue
            if x_idx <= 6 && y_idx >= 16 {
                assign_region_symmetric(x_idx, y_idx, .RED_JUNGLE)
            } else if y_idx <= 16 - x_idx {
                assign_region_symmetric(x_idx, y_idx, .RED_BEACH)
            }
        }
    }

    for x_idx in 9..=12 {
        for y_idx in 1..=15-x_idx {
            if .TERRAIN in spaces[x_idx][y_idx].flags do continue
            assign_region_symmetric(x_idx, y_idx, .RED_BEACH)
        }
    }

    for x_idx in 5..=14 {
        for y_idx in 16-x_idx..=19-x_idx {
            if .TERRAIN in spaces[x_idx][y_idx].flags || spaces[x_idx][y_idx].region_id != .NONE do continue
            assign_region_symmetric(x_idx, y_idx, .CENTRE)
        }
    }

}

create_texture_for_card :: proc(card: ^Card) {
    render_texture := rl.LoadRenderTexture(i32(CARD_SIZE.x), i32(CARD_SIZE.y))

    TEXT_PADDING :: 3
    COLORED_BAND_WIDTH :: 30
    FONT_SIZE :: COLORED_BAND_WIDTH - 2 * TEXT_PADDING

    rl.BeginTextureMode(render_texture)

    rl.ClearBackground(rl.MAGENTA)

    rl.DrawRectangleRec({0, 0, COLORED_BAND_WIDTH, CARD_SIZE.y}, card_color_values[card.color])
    rl.DrawRectangleRec({0, 0, CARD_SIZE.x, COLORED_BAND_WIDTH}, card_color_values[card.color])

    rl.DrawText(fmt.ctprintf("I%d", card.initiative), TEXT_PADDING, TEXT_PADDING, FONT_SIZE, rl.BLACK)

    name_cstring := strings.clone_to_cstring(card.name)
    name_length_px := rl.MeasureText(name_cstring, FONT_SIZE)
    name_offset := COLORED_BAND_WIDTH + (i32(CARD_SIZE.x) - COLORED_BAND_WIDTH - name_length_px) / 2
    rl.DrawText(strings.clone_to_cstring(card.name), name_offset, TEXT_PADDING, FONT_SIZE, rl.BLACK)

    rl.EndTextureMode()

    card.texture = render_texture.texture
}

main :: proc() {

    rl.InitWindow(WIDTH, HEIGHT, "guards")
    defer rl.CloseWindow()

    setup_space_positions()

    setup_terrain()

    setup_regions()

    test_card := Card {
        color = .RED,
        initiative = 13,
        name = "Fight as One"
    }

    create_texture_for_card(&test_card)

    for !rl.WindowShouldClose() {

        space, space_ok := get_selection(rl.GetMousePosition())

        rl.BeginDrawing()

        rl.ClearBackground(rl.BLACK)
        for arr in spaces {
            for space in arr {
                color := rl.WHITE
                if .TERRAIN in space.flags do color = CLIFF_COLOR
                else do color = region_colors[space.region_id]
                rl.DrawCircleV(space.position + board_offset, VERTICAL_SPACING * 0.45, color)
            }
        }

        rl.DrawTexturePro(test_card.texture, {0, 0, CARD_SIZE.x, -CARD_SIZE.y}, {WIDTH - 2 * CARD_SIZE.x - 20, HEIGHT - 2 * CARD_SIZE.y - 20, 2 * CARD_SIZE.x, 2 * CARD_SIZE.y}, {0, 0}, 0, rl.WHITE)
        
        if space_ok {
            pos := spaces[space.x][space.y].position
            rl.DrawRing(pos + board_offset, VERTICAL_SPACING * 0.45, VERTICAL_SPACING * 0.5, 0, 360, 100, rl.WHITE)
        }

        rl.EndDrawing()
    }
}

get_selection :: proc(mouse_pos: Vec2) -> (IVec2, bool) {
    offset_mouse_pos := mouse_pos - board_offset
    offset_mouse_pos.y = HEIGHT - offset_mouse_pos.y
    offset_mouse_pos += {VERTICAL_SPACING, VERTICAL_SPACING} * 0.5
    x_idx := offset_mouse_pos.x / HORIZONTAL_SPACING
    y_idx := offset_mouse_pos.y / VERTICAL_SPACING - math.floor(x_idx) / 2
    if x_idx < 0 || x_idx >= GRID_WIDTH || y_idx < 0 || y_idx >= GRID_HEIGHT do return {}, false
    return {int(x_idx), int(y_idx)}, true
}