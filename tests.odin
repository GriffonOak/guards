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
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Halt, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {11, 11}},
        Space_Clicked_Event{space = {11, 11}},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 2, alternate = true}, hidden = false, selected = false}},
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
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, hidden = false, selected = true}},
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
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {0, 0}},
        Entity_Translocation_Event{src = {18, 8}, dest = {8, 16}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {0, 0}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Blue, tier = 1, alternate = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Add_Active_Effect_Event{effect_id = Active_Effect_ID{kind = Active_Effect_Kind.Xargatha_Freeze, parent_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Blue, tier = 1, alternate = false}}},
        End_Resolution_Event{player_id = 1},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Halt, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 1, color = Card_Color.Silver, tier = 0, alternate = false}},
    }

    testing_process_events(&gs, event_log)

    action_index := get_my_player(&gs).hero.current_action_index
    // action := get_action_at_index(&gs, action_index)

    choice_action, ok := get_current_action(&gs).variant.(Choice_Action)
    testing.expect(t, ok)

    card_data, ok2 := get_card_data_by_id(&gs, action_index.card_id)
    testing.expect(t, ok2)

    for choice in choice_action.choices {
        #partial switch choice.jump_index.sequence {
        case .Primary:
            if card_data.primary != .Movement do break
            fallthrough
        case .Basic_Movement, .Basic_Fast_Travel:
            testing.expect(t, !choice.valid)
        }
    }
}

@(test)
test_xargatha_charm :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log1 := []Event {
        Host_Game_Chosen_Event{},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {10, 12}},
        Space_Clicked_Event{space = {10, 12}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {0, 0}},
    }

    testing_process_events(&gs, event_log1)

    action := get_current_action(&gs)
    choice_action, ok := action.variant.(Choice_Action)
    testing.expect(t, ok)

    second_choice := choice_action.choices[1]

    maybe_action := get_action_at_index(&gs, second_choice.jump_index)
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
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Xargatha, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 1}},
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
//         Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {7, 9}},
//         Space_Clicked_Event{space = {7, 9}},
//         Space_Hovered_Event{space = {0, 0}},
//         Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = true}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {8, 11}},
//         Space_Clicked_Event{space = {8, 11}},
//         Space_Hovered_Event{space = {0, 0}},
//         Resolve_Current_Action_Event{jump_index = nil},
//         Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, hidden = false, selected = true}},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
//         Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
//         Space_Hovered_Event{space = {0, 0}},
//         Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, hidden = false, selected = true}},
//         Marker_Event{},
//         Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
//         Space_Hovered_Event{space = {14, 7}},
//         Space_Clicked_Event{space = {14, 7}},
//         Space_Hovered_Event{space = {0, 0}},
//         Marker_Event{},
//         Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, hidden = false, selected = false}},
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
test_choose_targets_purged :: proc(t: ^testing.T) {

    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Change_Hero_Event{hero_id = Hero_ID.Dodger},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {0, 0}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Silver, tier = 0, alternate = false}},
        Space_Hovered_Event{space = {14, 7}},
        Space_Clicked_Event{space = {14, 7}},
        Space_Hovered_Event{space = {0, 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Red, tier = 1, alternate = false}, hidden = false, selected = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Red, tier = 2, alternate = false}, hidden = false, selected = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.Dodger, owner_id = 0, color = Card_Color.Gold, tier = 0, alternate = false}},
        Marker_Event{},
    }

    testing_process_events(&gs, event_log)

    // action := get_current_action(&gs)

    // choice_action, ok := action.variant.(Choice_Action)
    // testing.expect(t, ok)

    // third_choice := choice_action.choices[0]
    // cta_action := get_action_at_index(&gs, calculate_implicit_action_index(third_choice.jump_index)
    // cta, ok2 := cta_action.variant.(Choose_Target_Action)
    // testing.expect(t, ok2)

    // testing.expect(t, len(cta.result) == 0)
}


@(test)
test_dread_razor :: proc(t: ^testing.T) {
    
}