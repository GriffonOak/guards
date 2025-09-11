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

    testing_process_events(&gs, events)

    testing.expect(t, gs.stage == .IN_LOBBY)
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
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_FAST_TRAVEL, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_MOVEMENT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.HALT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {11, 11}},
        Space_Clicked_Event{space = {11, 11}},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, hovered = false, hidden = false, selected = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 2, alternate = true}, hovered = true, hidden = false, selected = false}},
    }

    testing_process_events(&gs, event_log)

    testing.expect(t, get_my_player(&gs).hero.level == 2)
    testing.expect(t, get_my_player(&gs).hero.cards[.BLUE].tier == 2)
    testing.expect(t, get_my_player(&gs).hero.cards[.BLUE].alternate == true)
}

@(test)
test_single_player_minion_remove :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_FAST_TRAVEL, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_MOVEMENT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {8, 11}},
        Space_Clicked_Event{space = {8, 11}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GOLD, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.HALT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, index = 0}},
    }


    testing_process_events(&gs, event_log)

    action := get_current_action(&gs)
    // log.info(reflect.union_variant_typeid(action.variant))
    _, ok := get_current_action(&gs).variant.(Choose_Target_Action)
    testing.expect(t, ok)

    targets_iter := make_target_set_iterator(&action.targets) 
    for _, target in target_set_iter_members(&targets_iter) {
        space := gs.board[target.x][target.y]
        testing.expect(t, space.flags & {.MELEE_MINION, .RANGED_MINION} != {})
        testing.expect(t, space.unit_team == .BLUE)
    }
}

@(test)
test_xargatha_freeze :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)

    event_log := []Event {
        Host_Game_Chosen_Event{},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.BLUE, is_team_captain = true, hero = Hero{id = Hero_ID.XARGATHA, location = {0, 0}, cards = {.RED = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .GREEN = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .BLUE = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .GOLD = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .SILVER = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}}, coins = 0, level = 0, dead = false, items = {Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}}, item_count = 0, current_action_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, index = 0}}}},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_FAST_TRAVEL, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {-1, -1}},
        Unit_Translocation_Event{src = {18, 8}, dest = {8, 16}},
        End_Resolution_Event{player_id = 1},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.BLUE, tier = 1, alternate = false}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}},
        Add_Active_Effect_Event{effect_id = Active_Effect_ID{kind = Active_Effect_Kind.XARGATHA_FREEZE, parent_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.BLUE, tier = 1, alternate = false}}},
        End_Resolution_Event{player_id = 1},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.HALT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.SILVER, tier = 0, alternate = false}, index = 0}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.SILVER, tier = 0, alternate = false}},
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
        case .PRIMARY:
            if card_data.primary != .MOVEMENT do break
            fallthrough
        case .BASIC_MOVEMENT, .BASIC_FAST_TRAVEL:
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
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_FAST_TRAVEL, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {6, 16}},
        Space_Clicked_Event{space = {6, 16}},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_MOVEMENT, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {10, 12}},
        Space_Clicked_Event{space = {10, 12}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {-1, -1}},
    }

    testing_process_events(&gs, event_log1)

    action := get_current_action(&gs)
    choice_action, ok := action.variant.(Choice_Action)
    testing.expect(t, ok)

    second_choice := choice_action.choices[1]

    maybe_action := get_action_at_index(&gs, second_choice.jump_index)
    testing.expect(t, maybe_action != nil)

    minion_target_action, ok2 := &maybe_action.variant.(Choose_Target_Action)
    testing.expect(t, ok2)

    targets_iter := make_target_set_iterator(&maybe_action.targets)
    count := 0
    original_space: ^Space
    for _, target in target_set_iter_members(&targets_iter) {
        count += 1
        space := &gs.board[target.x][target.y]
        testing.expect(t, .RANGED_MINION in space.flags)
        testing.expect(t, space.unit_team == .BLUE)
        original_space = space
    }
    testing.expect(t, count == 1)
    testing.expect(t, original_space != nil)

    event_log2 := []Event {
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, index = 1}},
        Space_Hovered_Event{space = {12, 11}},
        Space_Clicked_Event{space = {12, 11}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Space_Hovered_Event{space = {11, 10}},
        Space_Clicked_Event{space = {11, 10}},
        Space_Hovered_Event{space = {12, 8}},
        Space_Clicked_Event{space = {12, 8}},
        Space_Hovered_Event{space = {-1, -1}},
        Resolve_Current_Action_Event{jump_index = nil},
        Space_Hovered_Event{space = {-1, -1}},
    }

    testing_process_events(&gs, event_log2)

    testing.expect(t, .RANGED_MINION not_in original_space.flags)
    new_space := gs.board[12][8]
    testing.expect(t, .RANGED_MINION in new_space.flags)
}

@(test)
test_something :: proc(t: ^testing.T) {
    gs: Game_State
    setup_board(&gs)
    event_log := []Event {
        Host_Game_Chosen_Event{},
        Update_Player_Data_Event{player_base = Player_Base{id = 1, _username_buf = {80, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, team = Team.BLUE, is_team_captain = true, hero = Hero{id = Hero_ID.XARGATHA, location = {0, 0}, cards = {.RED = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .GREEN = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .BLUE = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .GOLD = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}, .SILVER = Card{id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, state = Card_State.NONEXISTENT, turn_played = 0}}, coins = 0, level = 0, dead = false, items = {Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}}, item_count = 0, current_action_index = Action_Index{sequence = Action_Sequence_ID.PRIMARY, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.RED, tier = 0, alternate = false}, index = 0}}}},
        Begin_Game_Event{},
        Space_Hovered_Event{space = {-1, -1}},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Resolve_Current_Action_Event{jump_index = Action_Index{sequence = Action_Sequence_ID.BASIC_FAST_TRAVEL, card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.BLUE, tier = 1, alternate = false}, index = 0}},
        Space_Hovered_Event{space = {7, 9}},
        Space_Clicked_Event{space = {7, 9}},
        Space_Hovered_Event{space = {-1, -1}},
        Unit_Translocation_Event{src = {18, 8}, dest = {10, 14}},
        End_Resolution_Event{player_id = 1},
        Card_Clicked_Event{card_element = &UI_Card_Element{card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}, hovered = false, hidden = false, selected = true}},
        Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 0, color = Card_Color.GREEN, tier = 1, alternate = false}},
        Card_Confirmed_Event{player_id = 1, maybe_card_id = Card_ID{hero_id = Hero_ID.XARGATHA, owner_id = 1, color = Card_Color.RED, tier = 1, alternate = false}},
        Unit_Translocation_Event{src = {10, 14}, dest = {9, 12}},
        End_Resolution_Event{player_id = 1},
    }

    testing_process_events(&gs, event_log)
}