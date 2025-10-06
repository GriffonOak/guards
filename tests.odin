package guards

import "core:testing"
import "core:log"
import "core:fmt"
import "core:reflect"

_ :: fmt

testing_process_events :: proc(gs: ^Game_State, events: []Event, loc := #caller_location) {

    for event, index in events {
        log.infof("Beginning test event %v: %w", index, reflect.union_variant_typeid(event), location = loc)
        append(&gs.event_queue, event)

        if _, ok := event.(Marker_Event); ok {
            breakpoint()
        }

        for q_event in gs.event_queue {
            resolve_event(gs, q_event)
        }
        clear(&gs.event_queue)
    }
}

@(test)
test_basic_setup :: proc(t: ^testing.T) {
    context.allocator = context.temp_allocator
    defer free_all(context.temp_allocator)

    gs: Game_State

    setup_board(&gs)
    testing.expect(t, .Terrain in gs.board[0][0].flags, "Corner terrain not set!")
    testing.expect(t, .Terrain in gs.board[GRID_WIDTH-1][GRID_HEIGHT-1].flags, "Corner terrain not set!")

    terrain_space := starting_terrain[5]
    testing.expect(t, .Terrain in gs.board[terrain_space.x][terrain_space.y].flags, "Bespoke terrain not set!")

    testing.expect(t, gs.board[3][8].region_id == .Red_Throne, "Incorrect region!")
    testing.expect(t, gs.board[7][6].region_id == .Red_Beach, "Incorrect region!")
    testing.expect(t, gs.board[4][15].region_id == .Red_Jungle, "Incorrect region!")
    testing.expect(t, gs.board[11][8].region_id == .Centre, "Incorrect region!")
    testing.expect(t, gs.board[16][5].region_id == .Blue_Jungle, "Incorrect region!")
    testing.expect(t, gs.board[11][14].region_id == .Blue_Beach, "Incorrect region!")
    testing.expect(t, gs.board[17][9].region_id == .Blue_Throne, "Incorrect region!")
    testing.expect(t, gs.board[10][10].region_id == .None, "Incorrect region!")

    events := []Event{Host_Game_Chosen_Event{}}

    testing_process_events(&gs, events)

    testing.expect(t, gs.stage == .In_Lobby)
    testing.expect(t, len(gs.players) == 1)
}

@(test)
test_sanity :: proc(t: ^testing.T) {
    gs: Game_State

    resolve_event(&gs, nil)
}

@(test)
test_basic_upgrade :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Halt, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {11, 11}},
        Space_Clicked_Event{space = {11, 11}},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 2, alternate = true}},
    }

    testing_process_events(&gs, event_log)

    testing.expect(t, get_my_player(&gs).hero.level == 2)
    testing.expect(t, get_my_player(&gs).hero.cards[.Blue].tier == 2)
    testing.expect(t, get_my_player(&gs).hero.cards[.Blue].alternate == true)
}

@(test)
test_single_player_minion_remove :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Halt, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
    }


    testing_process_events(&gs, event_log)

    action := get_current_action(&gs)
    // log.info(reflect.union_variant_typeid(action.variant))
    _, ok := get_current_action(&gs).variant.(Choose_Target_Action)
    testing.expect(t, ok)

    targets_iter := make_target_set_iterator(&action.targets) 
    for _, target in target_set_iter_members(&targets_iter) {
        space := gs.board[target.x][target.y]
        testing.expect(t, space.flags & {.Melee_Minion, .Ranged_Minion} != {})
        testing.expect(t, space.unit_team == .Blue)
    }
}

@(test)
test_xargatha_freeze :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.Blue, hero = Hero{id = Hero_ID.Xargatha, location = {0, 0}, cards = {.Red = Card{id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Green = Card{id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Blue = Card{id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Gold = Card{id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Silver = Card{id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}}, coins = 0, level = 0, dead = false, items = {Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}}, item_count = 0, current_action_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 0, alternate = false}, index = 0}}}},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Green, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {0, 0}},
        Entity_Translocation_Event{src = {18, 8}, dest = {8, 16}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {0, 0}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Add_Active_Effect_Event{from_action_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        End_Resolution_Event{player_id = 1},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Halt, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Marker_Event{},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Silver, tier = 0, alternate = false}},
    }

    testing_process_events(&gs, event_log)

    // There should have been no valid choices except to hold, so we should be resolved at this point.
    player := get_my_player(&gs)
    testing.expect(t, player.stage == .Resolved)

    loc := player.hero.location
    testing.expect(t, target_contains_any(&gs, loc, {.Terrain}))
}

@(test)
test_xargatha_charm :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log1 := []Event {
        Host_Game_Chosen_Event{},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {10, 12}},
        Space_Clicked_Event{space = {10, 12}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {0, 0}},
    }

    testing_process_events(&gs, event_log1)

    action_index := get_my_player(&gs).hero.current_action_index
    action := get_action_at_index(&gs, action_index)
    choice_action, ok := action.variant.(Choice_Action)
    testing.expect(t, ok)

    second_choice := choice_action.choices[1]
    jump_index := second_choice.jump_index
    jump_index.card_id = action_index.card_id

    maybe_action := get_action_at_index(&gs, jump_index)
    testing.expect(t, maybe_action != nil)

    _, ok2 := &maybe_action.variant.(Choose_Target_Action)
    testing.expect(t, ok2)

    targets_iter := make_target_set_iterator(&maybe_action.targets)
    count := 0
    original_space: ^Space
    for _, target in target_set_iter_members(&targets_iter) {
        count += 1
        space := &gs.board[target.x][target.y]
        testing.expect(t, .Ranged_Minion in space.flags)
        testing.expect(t, space.unit_team == .Blue)
        original_space = space
    }
    testing.expect(t, count == 1)
    testing.expect(t, original_space != nil)

    event_log2 := []Event {
        Choice_Taken_Event{choice_index = 0, jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 1}},
        Space_Hovered_Event{space = {12, 11}},
        Space_Clicked_Event{space = {12, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {12, 8}},
        Space_Clicked_Event{space = {12, 8}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Space_Hovered_Event{space = {0, 0}},
    }

    testing_process_events(&gs, event_log2)

    testing.expect(t, .Ranged_Minion not_in original_space.flags)
    new_space := gs.board[12][8]
    testing.expect(t, .Ranged_Minion in new_space.flags)
}

// @(test)  // @Todo: Rerun this
// test_correct_upgrade_options :: proc(t: ^testing.T) {
//     gs: Game_State
//     setup_board(&gs)

//     event_log := []Event {
//         Host_Game_Chosen_Event{},
//         Change_Hero_Event{hero_id = Hero_ID.Dodger},
//         Begin_Game_Event{},
//         Space_Hovered_Event{space = {0, 0}},
//         Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {7, 9}},
//         Space_Clicked_Event{space = {7, 9}},
//         Space_Hovered_Event{space = {0, 0}},
//         Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {8, 11}},
//         Space_Clicked_Event{space = {8, 11}},
//         Space_Hovered_Event{space = {0, 0}},
//         Resolve_Current_Action_Event{jump_index = nil},
//         Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {0, 0}},
//         Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
//         Marker_Event{},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
//         Space_Hovered_Event{space = {14, 7}},
//         Space_Clicked_Event{space = {14, 7}},
//         Space_Hovered_Event{space = {0, 0}},
//         Marker_Event{},
//         Card_Clicked_Event{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
//     }

//     testing_process_events(&gs, event_log)

//     testing.expect(t, len(gs.ui_stack[.Cards]) > 0)
//     card_1 := gs.ui_stack[.Cards][len(gs.ui_stack[.Cards]) - 2]
//     card_2 := gs.ui_stack[.Cards][len(gs.ui_stack[.Cards]) - 1]

//     card_1_element , ok := card_1.variant.(UI_Card_Element)
//     testing.expect(t, ok)
//     card_2_element , ok2 := card_2.variant.(UI_Card_Element)
//     testing.expect(t, ok2)


//     _, ok3 := get_card_by_id(&gs, card_1_element.card_id)
//     testing.expect(t, !ok3)
//     _, ok4 := get_card_by_id(&gs, card_2_element.card_id)
//     testing.expect(t, !ok4)

//     testing.expect(t, card_1_element.card_id.hero_id == get_my_player(&gs).hero.id)
//     testing.expect(t, card_2_element.card_id.hero_id == get_my_player(&gs).hero.id)
//     testing.expect(t, card_1_element.card_id.alternate == false)
//     testing.expect(t, card_2_element.card_id.alternate == true)
// }

@(test)
test_dread_razor :: proc(t: ^testing.T) {
    
}


// Maybe this doesn't need to be quite so long lol
@(test)
test_swap :: proc(t: ^testing.T) {

    gs: Game_State
    setup_board(&gs)

    event_log1 := []Event {
        Host_Game_Chosen_Event{},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.Blue, hero = Hero{id = Hero_ID.Xargatha, location = {0, 0}, cards = {.Red = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Green = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Blue = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Gold = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Silver = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}}, coins = 0, level = 0, dead = false, items = {Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}}, item_count = 0, markers = {}, current_action_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, index = 0}}}},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Xargatha},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Dodger},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Swift},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Swift},
        Change_Hero_Event{player_id = 1, hero_id = Hero_ID.Arien},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Tigerclaw},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Tigerclaw},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {12, 0}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Green, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {19, 13}},
        Entity_Translocation_Event{src = {18, 8}, dest = {12, 11}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {18, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {20, 4}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Silver, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Silver, tier = 0, alternate = false}},
        Space_Hovered_Event{space = {20, 2}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Blue, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {20, 6}},
        Entity_Translocation_Event{src = {12, 11}, dest = {12, 9}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {19, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 14}},
        Space_Clicked_Event{space = {8, 14}},
        Space_Hovered_Event{space = {14, 0}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Gold, tier = 0, alternate = false}},
        Space_Hovered_Event{space = {12, 0}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Blue, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {19, 0}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Blue, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {20, 6}},
        Entity_Translocation_Event{src = {11, 10}, dest = {10, 11}},
        Minion_Defeat_Event{target = {11, 9}, defeating_player = 1},
        Minion_Removal_Event{target = {11, 9}, removing_player = 1},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {20, 11}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {11, 11}},
        Space_Clicked_Event{space = {11, 11}},
        Space_Hovered_Event{space = {19, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Red, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {16, 9}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Red, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {18, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Red, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {19, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Space_Hovered_Event{space = {20, 2}},
        Begin_Interrupt_Event{interrupt = Interrupt{interrupted_player = 1, interrupting_player = 0, variant = Attack_Interrupt{strength = 6, flags = {}}}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Die, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, index = 0}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {13, 11}},
        Space_Clicked_Event{space = {13, 11}},
        Space_Hovered_Event{space = {12, 9}},
        Space_Clicked_Event{space = {12, 9}},
        Space_Hovered_Event{space = {14, 10}},
        Space_Clicked_Event{space = {14, 10}},
        Space_Hovered_Event{space = {2, 5}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Red, tier = 2, alternate = false}},
        Space_Hovered_Event{space = {20, 4}},
        End_Upgrading_Event{player_id = 1},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.Blue, hero = Hero{id = Hero_ID.Arien, location = {12, 9}, cards = {.Red = Card{id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Red, tier = 1, alternate = false}, state = Card_State.In_Hand, turn_played = 3}, .Green = Card{id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Green, tier = 2, alternate = true}, state = Card_State.In_Hand, turn_played = 0}, .Blue = Card{id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Blue, tier = 2, alternate = true}, state = Card_State.In_Hand, turn_played = 1}, .Gold = Card{id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Gold, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 2}, .Silver = Card{id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Silver, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}}, coins = 0, level = 3, dead = false, items = {Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Green, tier = 2, alternate = false}, Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Blue, tier = 2, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}}, item_count = 2, markers = {}, current_action_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Red, tier = 1, alternate = false}, index = 3}}}},
        Space_Hovered_Event{space = {20, 4}},
        Space_Clicked_Event{space = {20, 4}},
        Space_Hovered_Event{space = {2, 5}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Tigerclaw, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Arien, color = Card_Color.Green, tier = 2, alternate = true}},
    }

    testing_process_events(&gs, event_log1)

    pre_swap_space1 := gs.board[12][9]
    pre_swap_space2 := gs.board[9][9]

    event_log2 := []Event {
        Entity_Swap_Event{target1 = {12, 9}, target2 = {9, 9}},
    }

    testing_process_events(&gs, event_log2)

    post_swap_space1 := gs.board[12][9]
    post_swap_space2 := gs.board[9][9]

    testing.expect(t, pre_swap_space1.transient == post_swap_space2.transient)
    testing.expect(t, pre_swap_space2.transient == post_swap_space1.transient)

    testing.expect(t, pre_swap_space1.flags - PERMANENT_FLAGS == post_swap_space2.flags - PERMANENT_FLAGS)
    testing.expect(t, pre_swap_space2.flags - PERMANENT_FLAGS == post_swap_space1.flags - PERMANENT_FLAGS)

}

@(test)
test_invalid_double_upgrade :: proc(t: ^testing.T) {
    event_log := []Event {
        Host_Game_Chosen_Event{},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.Blue, hero = Hero{id = Hero_ID.Xargatha, location = {0, 0}, cards = {.Red = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Green = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Blue = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Gold = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}, .Silver = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, state = Card_State.In_Hand, turn_played = 0}}, coins = 0, level = 0, dead = false, items = {Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}}, item_count = 0, markers = {}, current_action_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 0, alternate = false}, index = 0}}}},
        Change_Hero_Event{player_id = 0, hero_id = Hero_ID.Brogan},
        Begin_Game_Event{},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Xargatha, color = Card_Color.Green, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {6, 3}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {4, 10}},
        Space_Clicked_Event{space = {4, 10}},
        Space_Hovered_Event{space = {16, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Entity_Translocation_Event{src = {18, 8}, dest = {13, 10}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {9, 1}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Blue, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {19, 2}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Xargatha, color = Card_Color.Blue, tier = 1, alternate = false}},
        Entity_Translocation_Event{src = {13, 10}, dest = {12, 8}},
        End_Resolution_Event{player_id = 1},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 9}},
        Space_Clicked_Event{space = {6, 9}},
        Space_Hovered_Event{space = {17, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Xargatha, color = Card_Color.Gold, tier = 0, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Gold, tier = 0, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 10}},
        Space_Clicked_Event{space = {6, 10}},
        Space_Hovered_Event{space = {16, 1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Minion_Defeat_Event{target = {11, 9}, defeating_player = 1},
        Minion_Removal_Event{target = {11, 9}, removing_player = 1},
        End_Resolution_Event{player_id = 1},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{owner_id = 1, hero_id = Hero_ID.Xargatha, color = Card_Color.Silver, tier = 0, alternate = false}},
        Space_Hovered_Event{space = {19, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Red, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 10}},
        Space_Clicked_Event{space = {8, 10}},
        Space_Hovered_Event{space = {18, 1}},
        Resolve_Current_Action_Event{jump_index = nil},
        End_Resolution_Event{player_id = 1},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Blue, tier = 2, alternate = false}},
    }

    gs: Game_State
    setup_board(&gs)

    testing_process_events(&gs, event_log)

    player := get_my_player(&gs)
    testing.expect(t, player.stage == .Upgraded)

    event_log2 := []Event {
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Green, tier = 1, alternate = false}},
        Card_Clicked_Event{card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Brogan, color = Card_Color.Green, tier = 2, alternate = false}},
    }

    testing_process_events(&gs, event_log2)

    testing.expect(t, player.hero.cards[.Green].tier == 1)

}