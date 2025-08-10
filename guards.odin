package guards


import rl "vendor:raylib"
import "core:fmt"
import "core:math"
import "core:strings"
import "core:log"

import "core:mem"

STRUCT_LOC_TEST :: false


// Todo list
// Minion battles
// Heavy immunity / immunity in general
// Separate cards out of the ui stack
// Add dummy blue player that acts randomly
// Snorri runes


// Ideas
// Could maybe be an idea to use bit_set[0..<GRID_WIDTH*GRID_HEIGHT] types for calculating the intersection between targets
// Might also be overkill :)

Window_Size :: enum {
    SMALL,
    BIG,
    FULL_SCREEN,
}

Vec2 :: [2]f32
IVec2 :: [2]int

Void :: struct {}



WIDTH :: 1280 * 2
HEIGHT :: 720 * 2

FONT_SPACING :: 0



window_size: Window_Size = .BIG

default_font: rl.Font



main :: proc() {

}

