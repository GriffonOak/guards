package guards

import "core:testing"


something_else :: proc(gs: ^Game_State, events: []Event) {

    for event in events {
        append(&gs.event_queue, event)

        for q_event in gs.event_queue {
            resolve_event(gs, q_event)
        }
        clear(&gs.event_queue)
    }
}

@(test)
test_basic_setup :: proc(t: ^testing.T) {
    gs: Game_State

    setup_board(&gs)
    testing.expect(t, .TERRAIN in gs.board[0][0].flags, "Corner terrain not set!")
    testing.expect(t, .TERRAIN in gs.board[GRID_WIDTH-1][GRID_HEIGHT-1].flags, "Corner terrain not set!")

    terrain_space := starting_terrain[5]
    testing.expect(t, .TERRAIN in gs.board[terrain_space.x][terrain_space.y].flags, "Bespoke terrain not set!")

    testing.expect(t, gs.board[3][8].region_id == .RED_BASE, "Incorrect region!")
    testing.expect(t, gs.board[7][6].region_id == .RED_BEACH, "Incorrect region!")
    testing.expect(t, gs.board[4][15].region_id == .RED_JUNGLE, "Incorrect region!")
    testing.expect(t, gs.board[11][8].region_id == .CENTRE, "Incorrect region!")
    testing.expect(t, gs.board[16][5].region_id == .BLUE_JUNGLE, "Incorrect region!")
    testing.expect(t, gs.board[11][14].region_id == .BLUE_BEACH, "Incorrect region!")
    testing.expect(t, gs.board[17][9].region_id == .BLUE_BASE, "Incorrect region!")
    testing.expect(t, gs.board[10][10].region_id == .NONE, "Incorrect region!")

    events := []Event{Host_Game_Chosen_Event{}}

    append(&gs.event_queue, events[0])
    resolve_event(&gs, events[0])
    // something_else(&gs, events)

    // testing.expect(t, gs.stage == .IN_LOBBY)
}