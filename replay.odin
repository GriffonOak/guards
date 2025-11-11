package guards


when REPLAY {
event_log := []Event {
    Host_Game_Chosen_Event{},
    Begin_Game_Event{},
    Space_Hovered_Event{space = {0, 0}},
    Card_Clicked_Event{card = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Blue, tier = 1, alternate = false}, state = Card_State.In_Hand, turn_played = 0}},
    Space_Hovered_Event{space = {0, 0}},
    Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Blue, tier = 1, alternate = false}},
    Choice_Taken_Event{choice_index = 2, jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Fast_Travel, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Blue, tier = 1, alternate = false}, index = 0}},
    Space_Hovered_Event{space = {7, 9}},
    Space_Clicked_Event{space = {7, 9}},
    Space_Hovered_Event{space = {0, 0}},
    Card_Clicked_Event{card = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 1, alternate = false}, state = Card_State.In_Hand, turn_played = 0}},
    Space_Hovered_Event{space = {0, 0}},
    Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 1, alternate = false}},
    Choice_Taken_Event{choice_index = 1, jump_index = Action_Index{sequence = Action_Sequence_ID.Basic_Movement, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Red, tier = 1, alternate = false}, index = 0}},
    Space_Hovered_Event{space = {9, 12}},
    Space_Clicked_Event{space = {9, 12}},
    Space_Hovered_Event{space = {0, 0}},
    Resolve_Current_Action_Event{jump_index = nil},
    Space_Hovered_Event{space = {0, 0}},
    Card_Clicked_Event{card = Card{id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Green, tier = 1, alternate = false}, state = Card_State.In_Hand, turn_played = 0}},
    Space_Hovered_Event{space = {0, 0}},
    Card_Confirmed_Event{player_id = 0, maybe_card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Green, tier = 1, alternate = false}},
    Space_Hovered_Event{space = {0, 0}},
    Choice_Taken_Event{choice_index = 0, jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Green, tier = 1, alternate = false}, index = 0}},
    Space_Hovered_Event{space = {0, 0}},
    Choice_Taken_Event{choice_index = 1, jump_index = Action_Index{sequence = Action_Sequence_ID.Primary, card_id = Card_ID{owner_id = 0, hero_id = Hero_ID.Xargatha, color = Card_Color.Green, tier = 1, alternate = false}, index = 3}},
    Space_Hovered_Event{space = {11, 10}},
    Space_Clicked_Event{space = {11, 10}},
    Space_Hovered_Event{space = {10, 12}},
    Space_Clicked_Event{space = {10, 12}},
    Space_Hovered_Event{space = {0, 0}},
    Resolve_Current_Action_Event{jump_index = nil},
}
}